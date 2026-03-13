// lib/ui/camera_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

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
    try {
      // Get image dimensions
      final width = image.width;
      final height = image.height;
      
      final planes = image.planes;
      
      if (planes.isEmpty) {
        debugPrint('No planes available');
        return null;
      }
      
      final firstPlane = planes[0];
      final buffer = firstPlane.bytes;
      final stride = firstPlane.bytesPerRow;
      
      // Print image preview to terminal (ASCII art)
      _printImagePreview(buffer, width, height, stride);
      
      if (buffer.isEmpty) {
        debugPrint('Empty buffer');
        return null;
      }
      
      // Create input tensor with uint8 values (0-255)
      const targetSize = 300;
      final inputBuffer = List<int>.filled(targetSize * targetSize * 3, 128); // Default to gray (128)
      
      // Enhanced image processing for better accuracy
      _processImageWithEnhancement(buffer, inputBuffer, width, height, stride, targetSize);
      
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

  /// Print ASCII art preview of the camera image to terminal
  void _printImagePreview(Uint8List buffer, int width, int height, int stride) {
    debugPrint('\n=== CAMERA PREVIEW ===');
    const previewSize = 20; // 20x20 ASCII preview
    
    for (int y = 0; y < previewSize && y < height; y += height ~/ previewSize) {
      String line = '';
      for (int x = 0; x < previewSize && x < width; x += width ~/ previewSize) {
        final index = y * stride + x * 4; // BGRA format
        if (index + 2 < buffer.length) {
          final b = buffer[index];
          final g = buffer[index + 1];
          final r = buffer[index + 2];
          
          // Convert to grayscale for ASCII
          final gray = (0.299 * r + 0.587 * g + 0.114 * b).round();
          
          // ASCII characters from dark to light
          if (gray < 51) {
            line += '█';
          } else if (gray < 102) {
            line += '▓';
          } else if (gray < 153) {
            line += '▒';
          } else if (gray < 204) {
            line += '░';
          } else {
            line += ' ';
          }
        } else {
          line += '?';
        }
      }
      debugPrint(line);
    }
    debugPrint('=== END PREVIEW ===\n');
  }

  /// Enhanced image processing for better accuracy and foreground focus
  void _processImageWithEnhancement(
    Uint8List buffer,
    List<int> inputBuffer,
    int width,
    int height,
    int stride,
    int targetSize,
  ) {
    try {
      // Higher quality sampling (every 2 pixels instead of 10)
      for (int y = 0; y < targetSize && y < height; y += 2) {
        for (int x = 0; x < targetSize && x < width; x += 2) {
          final index = y * stride + x * 4; // BGRA format
          if (index + 3 < buffer.length) {
            // Extract BGRA values
            final b = buffer[index];
            final g = buffer[index + 1];
            final r = buffer[index + 2];
            
            // Apply contrast enhancement for better object detection
            final enhancedR = _enhancePixel(r);
            final enhancedG = _enhancePixel(g);
            final enhancedB = _enhancePixel(b);
            
            // Set a small region around this pixel for better coverage
            for (int dy = 0; dy < 2 && y + dy < targetSize; dy++) {
              for (int dx = 0; dx < 2 && x + dx < targetSize; dx++) {
                final targetIndex = ((y + dy) * targetSize + (x + dx)) * 3;
                if (targetIndex + 2 < inputBuffer.length) {
                  inputBuffer[targetIndex] = enhancedR;
                  inputBuffer[targetIndex + 1] = enhancedG;
                  inputBuffer[targetIndex + 2] = enhancedB;
                }
              }
            }
          }
        }
      }
      debugPrint('Enhanced image processed successfully');
    } catch (e) {
      debugPrint('Error during enhanced processing: $e');
      // Fallback to simple gray fill
      for (int i = 0; i < inputBuffer.length; i++) {
        inputBuffer[i] = 128;
      }
    }
  }

  /// Enhance individual pixel for better contrast and detection
  int _enhancePixel(int value) {
    // Apply gamma correction and contrast enhancement
    final normalized = value / 255.0;
    final gamma = 0.8; // Slight gamma correction
    final contrast = 1.2; // Increase contrast
    
    final enhanced = math.pow(normalized, gamma) * contrast;
    final clamped = enhanced.clamp(0.0, 1.0);
    
    return (clamped * 255).round();
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
      debugPrint('=== DETECTION RESULTS ===');
      debugPrint('Number of detections: $numDet');
      
      // Sort detections by score (confidence) to prioritize high-confidence objects
      final List<Map<String, dynamic>> sortedDetections = [];
      for (int i = 0; i < math.min(numDet, 10); i++) {
        final score = scores[0][i];
        final classId = classes[0][i].toInt();
        final box = boxes[0][i];
        
        if (score > 0.3) { // Lower threshold initially, we'll filter later
          sortedDetections.add({
            'score': score,
            'classId': classId,
            'box': box,
            'className': classId > 0 && classId < _labels.length ? _labels[classId] : 'unknown'
          });
        }
      }
      
      // Sort by score (highest first)
      sortedDetections.sort((a, b) => b['score'].compareTo(a['score']));
      
      // Filter for foreground objects (larger boxes, higher confidence)
      final foregroundDetections = sortedDetections.where((detection) {
        final score = detection['score'] as double;
        final box = detection['box'] as List<double>;
        
        // Calculate box area (approximate size)
        final width = box[2] - box[0]; // x2 - x1
        final height = box[3] - box[1]; // y2 - y1
        final area = width * height;
        
        // Prioritize larger objects (likely foreground) and higher confidence
        final isLargeEnough = area > 0.01; // Minimum size threshold
        final isHighConfidence = score > 0.5; // Higher confidence threshold
        
        debugPrint('Detection: ${detection['className']} - Score: ${score.toStringAsFixed(3)}, Area: ${area.toStringAsFixed(3)}');
        
        return isLargeEnough && isHighConfidence;
      }).toList();
      
      // Take top 3-5 most confident foreground detections
      final topDetections = foregroundDetections.take(5).toList();
      
      for (final detection in topDetections) {
        final className = detection['className'] as String;
        if (!detected.contains(className)) {
          detected.add(className);
        }
      }
      
      debugPrint('Final detected objects: $detected');
    } catch (e) {
      debugPrint('Error parsing output: $e');
    }
    
    return detected;
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
