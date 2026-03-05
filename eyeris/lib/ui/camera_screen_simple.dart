// lib/ui/camera_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
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

  /// Latest set of labels detected by TFLite from the live camera stream.
  List<String> _lastDetectedLabels = <String>[];

  /// Prevents overlapping TFLite inference calls on the image stream.
  bool _isDetecting = false;

  /// TFLite interpreter for object detection
  tfl.Interpreter? _interpreter;
  
  /// COCO dataset labels (90 classes)
  List<String> _labels = [];
  
  /// Debug flag for camera info
  static bool _printedCameraInfo = false;
  
  final OpenAIService _openAIService = OpenAIService();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadModel();
    _initTts();
    _requestPermissions();
    _initializeCamera();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await tfl.Interpreter.fromAsset('assets/ml/object_labeler.tflite');
      
      // COCO labels (90 classes)
      _labels = [
        'background', 'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck', 'boat',
        'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench', 'bird', 'cat', 'dog', 'horse',
        'sheep', 'cow', 'elephant', 'bear', 'zebra', 'giraffe', 'backpack', 'umbrella', 'handbag', 'tie',
        'suitcase', 'frisbee', 'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove',
        'skateboard', 'surfboard', 'tennis racket', 'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon',
        'bowl', 'banana', 'apple', 'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog', 'pizza', 'donut',
        'cake', 'chair', 'couch', 'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse',
        'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink', 'refrigerator', 'book',
        'clock', 'vase', 'scissors', 'teddy bear', 'hair drier', 'toothbrush'
      ];
      
      debugPrint('SSD MobileNet model loaded successfully');
    } catch (e) {
      debugPrint('Error loading model: $e');
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
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
    if (_cameraController == null || _isDetecting || _interpreter == null) {
      return;
    }

    // Debug: Print image format info once
    if (!_printedCameraInfo) {
      debugPrint('Camera format: ${image.format.group}, width: ${image.width}, height: ${image.height}');
      debugPrint('Planes: ${image.planes.length}');
      for (int i = 0; i < image.planes.length; i++) {
        final plane = image.planes[i];
        debugPrint('Plane $i: bytes=${plane.bytes.length}, stride=${plane.bytesPerRow}, pixels=${plane.bytesPerPixel}');
      }
      _printedCameraInfo = true;
    }

    _isDetecting = true;
    try {
      // Convert CameraImage to input tensor for TFLite
      final input = _convertCameraImageToInputTensor(image);
      if (input == null) return;

      // Prepare output buffers for SSD MobileNet
      // Output shapes: [1, 10, 4] for boxes, [1, 10] for classes, [1, 10] for scores, [1] for num_detections
      var boxes = List.generate(1, (i) => List.generate(10, (j) => List.filled(4, 0.0)));
      var classes = List.generate(1, (i) => List.filled(10, 0.0));
      var scores = List.generate(1, (i) => List.filled(10, 0.0));
      var numDetections = [0.0];

      // Run inference
      final output = {
        0: boxes,
        1: classes,
        2: scores,
        3: numDetections,
      };
      _interpreter!.runForMultipleInputs([input], output);

      // Parse results
      final detectedLabels = _parseOutput(boxes, classes, scores, numDetections);

      if (detectedLabels.isNotEmpty && mounted) {
        debugPrint('TFLite detected: $detectedLabels');
        setState(() {
          _lastDetectedLabels = detectedLabels;
        });
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  dynamic _convertCameraImageToInputTensor(CameraImage image) {
    debugPrint('=== FUNCTION CALLED ===');
    try {
      // Get image dimensions
      final width = image.width;
      final height = image.height;
      
      final planes = image.planes;
      debugPrint('=== CAMERA DEBUG ===');
      debugPrint('Planes: ${planes.length}');
      debugPrint('Format: ${image.format.group}');
      debugPrint('Width: $width, Height: $height');
      
      if (planes.isEmpty) {
        debugPrint('No planes available');
        return null;
      }
      
      final firstPlane = planes[0];
      final buffer = firstPlane.bytes;
      final stride = firstPlane.bytesPerRow;
      
      debugPrint('First plane: bytes=${buffer.length}, stride=$stride');
      
      if (buffer.isEmpty) {
        debugPrint('Empty buffer');
        return null;
      }
      
      // Create a simple test tensor - just use the first few pixels as a test
      const targetSize = 300;
      final inputBuffer = List.filled(targetSize * targetSize * 3, 0.5); // Default to gray
      
      // Try to sample a few pixels safely
      try {
        for (int y = 0; y < targetSize && y < height; y += 10) {
          for (int x = 0; x < targetSize && x < width; x += 10) {
            final index = y * stride + x;
            if (index < buffer.length) {
              final value = buffer[index] / 255.0;
              // Set a small region around this pixel
              for (int dy = 0; dy < 10 && y + dy < targetSize; dy++) {
                for (int dx = 0; dx < 10 && x + dx < targetSize; dx++) {
                  final targetIndex = ((y + dy) * targetSize + (x + dx)) * 3;
                  if (targetIndex + 2 < inputBuffer.length) {
                    inputBuffer[targetIndex] = value;
                    inputBuffer[targetIndex + 1] = value;
                    inputBuffer[targetIndex + 2] = value;
                  }
                }
              }
            }
          }
        }
        debugPrint('Successfully processed image');
      } catch (e) {
        debugPrint('Error during processing: $e');
        // Return gray tensor as fallback
        return inputBuffer.reshape([1, targetSize, targetSize, 3]);
      }
      
      // Reshape to [1, 300, 300, 3] for TFLite input
      return inputBuffer.reshape([1, targetSize, targetSize, 3]);
    } catch (e) {
      debugPrint('=== MAJOR ERROR ===');
      debugPrint('Error converting camera image: $e');
      debugPrint('Image: ${image.width}x${image.height}, ${image.planes.length} planes');
      if (image.planes.isNotEmpty) {
        debugPrint('First plane: ${image.planes[0].bytes.length} bytes');
      }
      return null;
    }
  }

  List<String> _parseOutput(
    List<List<List<double>>> boxes,
    List<List<double>> classes,
    List<List<double>> scores,
    List<double> numDetections,
  ) {
    final detected = <String>[];
    
    try {
      final numDet = numDetections[0].toInt();
      
      for (int i = 0; i < math.min(numDet, 10); i++) {
        final score = scores[0][i];
        if (score > 0.5) { // Confidence threshold
          final classId = classes[0][i].toInt();
          if (classId > 0 && classId < _labels.length) { // Skip background class (0)
            detected.add(_labels[classId]);
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing output: $e');
    }
    
    return detected.toSet().toList(); // Remove duplicates
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

    // Speak the generated description aloud for the user.
    if (description.isNotEmpty) {
      await _flutterTts.stop();
      await _flutterTts.speak(description);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        // Negative velocity = swipe left (right-to-left gesture).
        if (velocity < -300 && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
                      color: Colors.black.withValues(alpha: 0.6),
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
      ),
    );
  }
}
