// lib/ui/camera_screen.dart

import 'dart:async';
import 'dart:io'; // For Platform checks

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For DeviceOrientation
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/openai_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  /// Latest AI narration of the environment (Prompt A style).
  String _aiGeneratedText = 'Point your camera and tap the button to scan.';

  /// Latest set of labels detected by ML Kit from the live camera stream.
  List<String> _lastDetectedLabels = <String>[];

  /// Prevents overlapping ML Kit detection calls on the image stream.
  bool _isDetecting = false;

  final ObjectDetectorOptions _options = ObjectDetectorOptions(
    mode: DetectionMode.stream,
    classifyObjects: true,
    multipleObjects: true,
  );

  late final ObjectDetector _objectDetector = ObjectDetector(options: _options);
  final OpenAIService _openAIService = OpenAIService();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeCamera();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    debugPrint('Camera permission status: $status');
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('Camera permission denied');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      // Start live detection stream: we only update labels here,
      // and trigger AI narration on demand (scan button).
      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_cameraController == null || _isDetecting) return;

    final inputImage = _inputImageFromCameraImage(
      image,
      _cameraController!.description,
      _cameraController!,
    );
    if (inputImage == null) return;

    _isDetecting = true;
    try {
      final detectedObjects = await _objectDetector.processImage(inputImage);

      if (detectedObjects.isNotEmpty) {
        final labels = detectedObjects
            .expand((obj) => obj.labels)
            .map((label) => label.text)
            .where((text) => text.isNotEmpty)
            .toSet()
            .toList();

        if (labels.isNotEmpty && mounted) {
          debugPrint('ML Kit detected: $labels');
          setState(() {
            _lastDetectedLabels = labels;
          });
        }
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  final Map<DeviceOrientation, int> _orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    CameraController controller,
  ) {
    // Get image rotation
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        // Front-facing
        rotationCompensation =
            (sensorOrientation + rotationCompensation) % 360;
      } else {
        // Back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    // Get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // Validate format
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // Ensure only one plane exists
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // Create InputImage
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _runSceneNarration() async {
    // Use Prompt A rules to describe the current environment
    // based on the latest detected labels.
    if (_lastDetectedLabels.isEmpty) {
      if (!mounted) return;
      setState(() {
        _aiGeneratedText = 'Nothing notable in front of you right now.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _aiGeneratedText = 'Analyzing the scene...';
    });

    final description =
        await _openAIService.generateAIText(_lastDetectedLabels);

    if (!mounted) return;
    setState(() {
      _aiGeneratedText = description;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _objectDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CameraPreview(_cameraController!),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      // Keep the narration box compact so it
                      // doesn't block too much of the camera view.
                      maxHeight: 120,
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _aiGeneratedText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _runSceneNarration,
        child: const Icon(Icons.search),
      ),
    );
  }
}