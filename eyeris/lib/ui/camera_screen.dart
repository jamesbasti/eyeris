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
  String _aiGeneratedText = 'Loading...'; // Updated default text

  final options = ObjectDetectorOptions(
    mode: DetectionMode.stream,
    classifyObjects: true,
    multipleObjects: true,
  );

  late final ObjectDetector _objectDetector = ObjectDetector(options: options);
  final OpenAIService _openAIService = OpenAIService();

  @override
  void initState() {
    super.initState();
    requestPermissions(); // Request permissions at app startup
    _initializeCamera();
  }

  Future<void> requestPermissions() async {
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

      // Start live detection stream
      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _generateAIText(List<String> labels) async {
    final generatedText = await _openAIService.generateAIText(labels);
    setState(() {
      _aiGeneratedText = generatedText;
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image, _cameraController!.description, _cameraController!);
    if (inputImage == null) return;

    try {
      final detectedObjects = await _objectDetector.processImage(inputImage);

      if (detectedObjects.isNotEmpty) {
        final labels = detectedObjects
            .expand((obj) => obj.labels)
            .map((label) => label.text)
            .toList();

        await _generateAIText(labels); // Generate descriptive text
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    }
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image, CameraDescription camera, CameraController controller) {
    // Get image rotation
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        // Front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // Back-facing
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
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
        children: [
          CameraPreview(_cameraController!),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                _aiGeneratedText,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('Scan pressed - implement TTS or capture here');
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}