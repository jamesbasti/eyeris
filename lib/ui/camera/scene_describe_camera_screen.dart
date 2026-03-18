import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/services/openai_service.dart';
import 'package:eyeris/services/voice/voice_control_manager.dart';
import 'package:eyeris/models/voice_command.dart';

// ─────────────────────────────────────────────
// SCENE DESCRIBE CAMERA SCREEN
//
// Hybrid approach: Tries OpenAI Vision API first, falls back to
// TFLite object detection when offline. Captures image and sends
// to AI for rich scene analysis, with local ML as backup.
// ─────────────────────────────────────────────

enum _DescribeState { idle, describing, speaking, error }


class SceneDescribeCameraScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SceneDescribeCameraScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<SceneDescribeCameraScreen> createState() => _SceneDescribeCameraScreenState();
}

class _SceneDescribeCameraScreenState extends State<SceneDescribeCameraScreen> {
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _torchOn = false;

  _DescribeState _state = _DescribeState.idle;
  String _resultText = 'Point your camera and tap DESCRIBE.';
  String _errorText = '';

  /// TFLite interpreter for object detection (fallback)
  tfl.Interpreter? _interpreter;

  /// COCO dataset labels (90 classes)
  List<String> _labels = [];

  final OpenAIService _openAIService = OpenAIService();
  final FlutterTts _flutterTts = FlutterTts();
  final VoiceControlManager _voiceControl = VoiceControlManager.instance;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _initTts();
    _initCamera();
    _initVoiceControl();
  }

  Future<void> _initVoiceControl() async {
    await _voiceControl.initialize();

    // Handle voice commands
    _voiceControl.onAction = (action) async {
      if (!mounted) return;
      
      switch (action) {
        case ActionTarget.describeScene:
          await _runSceneNarration();
          break;
        case ActionTarget.detectColor:
          // Navigate to color detect
          widget.onBack();
          break;
        case ActionTarget.readText:
          // Navigate to read screen
          widget.onBack();
          break;
      }
    };

    _voiceControl.onSetting = (setting, parameters) async {
      if (!mounted) return;
      
      switch (setting) {
        case SettingTarget.torch:
          final state = parameters['state'] as String?;
          if (state == 'on' && !_torchOn) {
            await _toggleTorch();
          } else if (state == 'off' && _torchOn) {
            await _toggleTorch();
          }
          break;
        case SettingTarget.speechRate:
          // Speech rate is handled globally by voice control
          break;
      }
    };

    _voiceControl.onNavigate = (target) async {
      if (!mounted) return;
      
      switch (target) {
        case NavigationTarget.back:
          widget.onBack();
          break;
        case NavigationTarget.home:
          widget.onBack();
          break;
        default:
          // Navigate to other screens
          widget.onBack();
          break;
      }
    };
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

    if (Platform.isIOS) {
      try {
        // Set Evan enhanced voice using the display name
        await _flutterTts.setVoice({
          'name': 'Evan (Enhanced)',
          'locale': 'en-US'
        });
      } catch (e) {
        // Voice setting failed, will use default
      }
    } else if (Platform.isAndroid) {
      try {
        final engines = await _flutterTts.getEngines as List;
        final google = engines.firstWhere(
          (e) => e.toString().toLowerCase().contains('google'),
          orElse: () => '',
        );
        if (google.toString().isNotEmpty) {
          await _flutterTts.setEngine(google.toString());
        }
      } catch (e) {
        // Engine selection failed, will use default
      }
    }

    _flutterTts.setCompletionHandler(() {
      if (mounted && _state == _DescribeState.speaking) {
        setState(() => _state = _DescribeState.idle);
      }
    });
  }

  Future<void> _initCamera() async {
    debugPrint('SceneDescribe: Starting camera initialization');
    final status = await Permission.camera.request();
    debugPrint('SceneDescribe: Camera permission status: $status');
    
    if (!mounted) return;
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('SceneDescribe: camera permission denied');
      if (mounted) {
        setState(() {
          _state = _DescribeState.error;
          _errorText = 'Camera permission denied. Please enable camera access in settings.';
        });
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      debugPrint('SceneDescribe: Found ${cameras.length} cameras');
      
      if (cameras.isEmpty) {
        debugPrint('SceneDescribe: No cameras available');
        if (mounted) {
          setState(() {
            _state = _DescribeState.error;
            _errorText = 'No camera found on this device.';
          });
        }
        return;
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      debugPrint('SceneDescribe: Using camera: ${back.name}');

      _cameraController = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      debugPrint('SceneDescribe: Initializing camera controller');
      await _cameraController!.initialize();
      debugPrint('SceneDescribe: Camera controller initialized successfully');
      
      if (!mounted) return;

      setState(() {
        _cameraReady = true;
        debugPrint('SceneDescribe: Camera ready state set to true');
      });
    } catch (e, stackTrace) {
      debugPrint('SceneDescribe: camera init error — $e');
      debugPrint('SceneDescribe: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _state = _DescribeState.error;
          _errorText = 'Could not access camera: $e';
        });
      }
    }
  }

  
  Future<void> _runSceneNarration() async {
    if (_state == _DescribeState.describing) return;

    HapticFeedback.mediumImpact();

    // Stop any ongoing speech
    await _flutterTts.stop();

    if (!mounted) return;
    setState(() {
      _state = _DescribeState.describing;
      _resultText = 'Analyzing the scene...';
    });

    try {
      String description = '';
      
      // 1. Try OpenAI Vision API first (internet required)
      try {
        final imageFile = await _captureImage();
        
        if (imageFile != null) {
          if (!mounted) return;
          setState(() => _resultText = 'Analyzing with AI...');
          
          description = await _openAIService.analyzeImage(
            imageFile, 
            isTorchOn: _torchOn
          ).timeout(const Duration(seconds: 8));
          
          // Clean up the temporary image file
          try {
            await imageFile.delete();
          } catch (e) {
            debugPrint('Error deleting temp file: $e');
          }
          
          // Check if the response indicates an error (network issue, API error, etc.)
          if (description.contains('Error') || 
              description.contains('Failed') || 
              description.contains('API key') ||
              description.contains('Could not')) {
            debugPrint('Vision API returned error: $description');
            description = ''; // Clear to trigger fallback
          }
        }
      } catch (e) {
        debugPrint('OpenAI Vision failed, falling back to TFLite: $e');
        description = ''; // Ensure fallback is triggered
      }

      // 2. Fallback to TFLite if Vision API failed or returned error
      if (description.isEmpty) {
        if (!mounted) return;
        setState(() => _resultText = 'Using offline detection...');
        
        final labels = await _detectOnce();
        
        if (!mounted) return;
        if (labels.isEmpty) {
          setState(() {
            _resultText = 'Nothing notable in front of you right now.';
            _state = _DescribeState.idle;
          });
          return;
        }

        // Try AI text generation, fall back to local description if offline
        try {
          description = await _openAIService.generateAIText(labels, isTorchOn: _torchOn)
              .timeout(const Duration(seconds: 3));
          
          // Check if the response indicates an error (no API key, network issue, etc.)
          if (description.contains('API key') || description.contains('Failed') || description.contains('Error')) {
            description = _generateLocalDescription(labels);
          }
        } catch (e) {
          debugPrint('AI text generation failed, using local: $e');
          description = _generateLocalDescription(labels);
        }
      }

      if (!mounted) return;
      setState(() {
        _resultText = description.isNotEmpty
            ? description
            : 'Could not describe the scene. Please try again.';
        _state = _DescribeState.speaking;
      });

      // Speak the generated description aloud
      if (description.isNotEmpty) {
        await _flutterTts.speak(description);
      }
    } catch (e) {
      debugPrint('Scene narration error: $e');
      if (!mounted) return;
      setState(() {
        _resultText = 'Error describing the scene. Please try again.';
        _state = _DescribeState.error;
      });
    }
  }

  /// Generates a local description from detected labels (offline fallback)
  String _generateLocalDescription(List<String> labels) {
    if (labels.isEmpty) return 'Nothing notable detected.';
    
    // Categorize objects
    final people = labels.where((l) => l == 'person').length;
    final vehicles = labels.where((l) => 
        ['car', 'bus', 'truck', 'motorcycle', 'bicycle', 'boat', 'airplane', 'train'].contains(l)).toList();
    final furniture = labels.where((l) => 
        ['chair', 'couch', 'bed', 'dining table', 'toilet', 'bench'].contains(l)).toList();
    final electronics = labels.where((l) => 
        ['tv', 'laptop', 'cell phone', 'keyboard', 'mouse', 'remote'].contains(l)).toList();
    final kitchen = labels.where((l) => 
        ['bottle', 'cup', 'bowl', 'fork', 'knife', 'spoon', 'microwave', 'oven', 'sink', 'refrigerator'].contains(l)).toList();
    final outdoor = labels.where((l) => 
        ['traffic light', 'stop sign', 'fire hydrant', 'parking meter'].contains(l)).toList();
    
    final parts = <String>[];
    
    // Build natural description
    if (people > 0) {
      parts.add(people == 1 ? 'a person' : '$people people');
    }
    
    if (vehicles.isNotEmpty) {
      parts.add(vehicles.length == 1 ? 'a ${vehicles.first}' : 'vehicles nearby');
    }
    
    if (outdoor.isNotEmpty) {
      parts.add('outdoor area with ${outdoor.join(' and ')}');
    }
    
    if (furniture.isNotEmpty) {
      if (furniture.contains('bed')) {
        parts.add('what looks like a bedroom');
      } else if (furniture.contains('couch')) {
        parts.add('a living area');
      } else if (furniture.contains('dining table')) {
        parts.add('a dining area');
      } else {
        parts.add(furniture.join(' and '));
      }
    }
    
    if (kitchen.isNotEmpty) {
      parts.add('kitchen items');
    }
    
    if (electronics.isNotEmpty) {
      parts.add(electronics.join(' and '));
    }
    
    // Add remaining objects not categorized
    final categorized = {...vehicles, ...furniture, ...electronics, ...kitchen, ...outdoor, 'person'};
    final other = labels.where((l) => !categorized.contains(l)).take(2).toList();
    if (other.isNotEmpty) {
      parts.addAll(other);
    }
    
    if (parts.isEmpty) {
      return 'I can see ${labels.take(3).join(', ')}.';
    }
    
    // Construct sentence
    if (parts.length == 1) {
      return 'I can see ${parts.first} in front of you.';
    } else if (parts.length == 2) {
      return 'I can see ${parts[0]} and ${parts[1]}.';
    } else {
      final last = parts.removeLast();
      return 'I can see ${parts.join(', ')}, and $last.';
    }
  }

  /// Captures an image from the camera and saves it to a temporary file
  Future<File?> _captureImage() async {
    if (_cameraController == null || !_cameraReady) return null;

    try {
      final XFile capturedImage = await _cameraController!.takePicture();

      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;
      
      // Create a unique filename
      final String fileName = 'scene_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(tempPath, fileName);
      
      // Copy the captured image to temp directory
      final File tempFile = File(capturedImage.path);
      final File savedFile = await tempFile.copy(filePath);
      
      return savedFile;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  /// Captures a single camera frame, runs TFLite inference, and
  /// returns the list of detected object labels.
  Future<List<String>> _detectOnce() async {
    if (_cameraController == null || _interpreter == null) return [];

    final completer = Completer<CameraImage>();
    try {
      await _cameraController!.startImageStream((image) {
        if (!completer.isCompleted) completer.complete(image);
      });

      final image = await completer.future
          .timeout(const Duration(seconds: 5));

      await _cameraController!.stopImageStream();

      final input = _convertCameraImageToInputTensor(image);
      if (input == null) return [];

      var boxes = List.generate(1, (i) => List.generate(10, (j) => List.filled(4, 0.0)));
      var classes = List.generate(1, (i) => List.filled(10, 0.0));
      var scores = List.generate(1, (i) => List.filled(10, 0.0));
      var numDetections = [0.0];

      final output = {
        0: boxes,
        1: classes,
        2: scores,
        3: numDetections,
      };
      _interpreter!.runForMultipleInputs([input], output);

      final labels = _parseOutput(boxes, classes, scores, numDetections);
      debugPrint('SceneDescribe: detected — $labels');
      return labels;
    } catch (e) {
      debugPrint('SceneDescribe: _detectOnce error — $e');
      try { await _cameraController?.stopImageStream(); } catch (_) {}
      return [];
    }
  }

  dynamic _convertCameraImageToInputTensor(CameraImage image) {
    try {
      final width = image.width;
      final height = image.height;
      final planes = image.planes;

      if (planes.isEmpty) {
        debugPrint('No planes available');
        return null;
      }

      const targetSize = 300;
      final inputBuffer = List<int>.filled(targetSize * targetSize * 3, 128);

      final format = image.format.group;
      debugPrint('TFLite: Image format=$format, planes=${planes.length}, size=${width}x$height');

      // Handle different image formats
      if (format == ImageFormatGroup.yuv420 || format == ImageFormatGroup.nv21 || planes.length >= 3) {
        // Android YUV420 format
        _processYuvImage(image, inputBuffer, targetSize);
      } else if (format == ImageFormatGroup.bgra8888 || planes.length == 1) {
        // iOS BGRA format
        _processBgraImage(image, inputBuffer, targetSize);
      } else {
        debugPrint('Unknown image format: $format');
        return null;
      }

      return inputBuffer.reshape([1, targetSize, targetSize, 3]);
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  /// Process YUV420 image (Android)
  void _processYuvImage(CameraImage image, List<int> inputBuffer, int targetSize) {
    final width = image.width;
    final height = image.height;
    
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    
    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;
    
    final yStride = yPlane.bytesPerRow;
    final uStride = uPlane.bytesPerRow;
    final vStride = vPlane.bytesPerRow;
    
    final uStep = uPlane.bytesPerPixel ?? 1;
    final vStep = vPlane.bytesPerPixel ?? 1;

    for (int ty = 0; ty < targetSize; ty++) {
      for (int tx = 0; tx < targetSize; tx++) {
        // Map target coordinates to source
        final sourceY = (ty * height / targetSize).floor();
        final sourceX = (tx * width / targetSize).floor();
        
        // Y plane index
        final yIdx = sourceY * yStride + sourceX;
        if (yIdx >= yBytes.length) continue;
        
        // UV plane indices (2x2 subsampled)
        final uvX = sourceX ~/ 2;
        final uvY = sourceY ~/ 2;
        final uIdx = uvY * uStride + uvX * uStep;
        final vIdx = uvY * vStride + uvX * vStep;
        
        if (uIdx >= uBytes.length || vIdx >= vBytes.length) continue;
        
        // YUV to RGB conversion (ITU-R BT.601)
        final y = yBytes[yIdx] & 0xFF;
        final u = (uBytes[uIdx] & 0xFF) - 128;
        final v = (vBytes[vIdx] & 0xFF) - 128;
        
        int r = (y + 1.402 * v).round().clamp(0, 255);
        int g = (y - 0.344136 * u - 0.714136 * v).round().clamp(0, 255);
        int b = (y + 1.772 * u).round().clamp(0, 255);
        
        // Apply enhancement
        r = _enhancePixel(r);
        g = _enhancePixel(g);
        b = _enhancePixel(b);
        
        final targetIndex = (ty * targetSize + tx) * 3;
        if (targetIndex + 2 < inputBuffer.length) {
          inputBuffer[targetIndex] = r;
          inputBuffer[targetIndex + 1] = g;
          inputBuffer[targetIndex + 2] = b;
        }
      }
    }
  }

  /// Process BGRA image (iOS)
  void _processBgraImage(CameraImage image, List<int> inputBuffer, int targetSize) {
    final width = image.width;
    final height = image.height;
    final plane = image.planes[0];
    final buffer = plane.bytes;
    final stride = plane.bytesPerRow;

    for (int ty = 0; ty < targetSize; ty++) {
      for (int tx = 0; tx < targetSize; tx++) {
        final sourceY = (ty * height / targetSize).floor();
        final sourceX = (tx * width / targetSize).floor();
        final index = sourceY * stride + sourceX * 4;

        if (index + 3 < buffer.length) {
          final b = buffer[index];
          final g = buffer[index + 1];
          final r = buffer[index + 2];

          final targetIndex = (ty * targetSize + tx) * 3;
          if (targetIndex + 2 < inputBuffer.length) {
            inputBuffer[targetIndex] = _enhancePixel(r);
            inputBuffer[targetIndex + 1] = _enhancePixel(g);
            inputBuffer[targetIndex + 2] = _enhancePixel(b);
          }
        }
      }
    }
  }

  int _enhancePixel(int value) {
    final normalized = value / 255.0;
    final gamma = 0.8;
    final contrast = 1.2;
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
      debugPrint('Number of detections: $numDet');

      final List<Map<String, dynamic>> sortedDetections = [];
      for (int i = 0; i < math.min(numDet, 10); i++) {
        final score = scores[0][i];
        final classId = classes[0][i].toInt();
        final box = boxes[0][i];

        if (score > 0.1) {
          sortedDetections.add({
            'score': score,
            'classId': classId,
            'box': box,
            'className': classId > 0 && classId < _labels.length ? _labels[classId] : 'unknown'
          });
        }
      }

      sortedDetections.sort((a, b) => b['score'].compareTo(a['score']));

      // Enhanced filtering with spatial analysis
      final foregroundDetections = sortedDetections.where((detection) {
        final score = detection['score'] as double;
        final box = detection['box'] as List<double>;

        final width = box[2] - box[0];
        final height = box[3] - box[1];
        final area = width * height;

        // Adaptive thresholds based on object size
        final isLargeEnough = area > 0.003; // Slightly smaller threshold
        final isHighConfidence = score > 0.15; // Lower confidence threshold
        
        // Add spatial context
        final centerX = (box[0] + box[2]) / 2;
        final centerY = (box[1] + box[3]) / 2;
        
        detection['centerX'] = centerX;
        detection['centerY'] = centerY;
        detection['area'] = area;
        
        // Determine position
        if (centerX < 0.33) {
          detection['position'] = 'left';
        } else if (centerX > 0.67) {
          detection['position'] = 'right';
        } else {
          detection['position'] = 'center';
        }

        return isLargeEnough && isHighConfidence;
      }).toList();

      // Group related objects and prioritize important ones
      final topDetections = _prioritizeDetections(foregroundDetections);

      for (final detection in topDetections) {
        final className = detection['className'] as String;
        if (!detected.contains(className)) {
          detected.add(className);
        }
      }

      debugPrint('SceneDescribe: detected — $detected');
      return detected;
    } catch (e) {
      debugPrint('Error parsing output: $e');
    }

    return detected;
  }

  /// Prioritizes detections based on importance, size, and confidence
  List<Map<String, dynamic>> _prioritizeDetections(List<Map<String, dynamic>> detections) {
    // Define importance weights for different object categories
    const Map<String, double> importanceWeights = {
      'person': 2.0,
      'car': 1.8,
      'bus': 1.7,
      'truck': 1.6,
      'motorcycle': 1.5,
      'bicycle': 1.4,
      'traffic light': 1.3,
      'stop sign': 1.3,
      'fire hydrant': 1.2,
      'bench': 1.1,
      'chair': 1.1,
      'couch': 1.1,
      'dining table': 1.1,
      'bed': 1.0,
      'toilet': 1.0,
      'tv': 0.9,
      'laptop': 0.9,
      'mouse': 0.8,
      'remote': 0.8,
      'keyboard': 0.8,
      'cell phone': 0.8,
      'book': 0.7,
      'clock': 0.7,
      'vase': 0.6,
      'scissors': 0.5,
      'teddy bear': 0.4,
      'hair drier': 0.3,
      'toothbrush': 0.3,
    };

    // Calculate priority score for each detection
    final prioritized = detections.map((detection) {
      final className = detection['className'] as String;
      final score = detection['score'] as double;
      final area = detection['area'] as double;
      final importance = importanceWeights[className] ?? 0.5;
      
      // Priority = confidence * importance * size_factor
      final sizeFactor = math.min(area * 100, 2.0); // Cap size factor at 2.0
      final priorityScore = score * importance * sizeFactor;
      
      detection['priorityScore'] = priorityScore;
      return detection;
    }).toList();

    // Sort by priority score and take top 5
    prioritized.sort((a, b) => b['priorityScore'].compareTo(a['priorityScore']));
    return prioritized.take(5).toList();
  }

  Future<void> _stopSpeaking() async {
    HapticFeedback.lightImpact();
    await _flutterTts.stop();
    if (mounted) setState(() => _state = _DescribeState.idle);
  }

  Future<void> _toggleTorch() async {
    if (_cameraController == null || !_cameraReady) return;
    try {
      await _cameraController!.setFlashMode(
        _torchOn ? FlashMode.off : FlashMode.torch,
      );
      if (!mounted) return;
      setState(() => _torchOn = !_torchOn);
    } catch (e) {
      debugPrint('SceneDescribe: torch toggle error — $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.setFlashMode(FlashMode.off).catchError((_) {});
    _cameraController?.dispose();
    _interpreter?.close();
    _flutterTts.stop();
    _voiceControl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EyerisColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _buildHeader(),
          ),

          // Camera preview
          Expanded(child: _buildCameraArea()),

          // Result card (scrollable text)
          _buildResultCard(),

          // Action button
          _state == _DescribeState.speaking
              ? _buildStopButton()
              : _buildDescribeButton(),

          const SizedBox(height: EyerisSpacing.md),
        ],
      ),
    );
  }

  // ── Header — matches unified camera style
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EyerisSpacing.md2,
        vertical: EyerisSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: EyerisColors.border,
            width: EyerisBorders.header,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          Semantics(
            label: 'Back',
            button: true,
            child: GestureDetector(
              onTap: () {
                _flutterTts.stop();
                widget.onBack();
              },
              child: Container(
                width: EyerisTouchTargets.backButton,
                height: EyerisTouchTargets.backButton,
                decoration: BoxDecoration(
                  color: EyerisColors.primary,
                  borderRadius: BorderRadius.circular(EyerisRadii.small),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back,
                    color: EyerisColors.black,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: EyerisSpacing.md),

          // Title
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'SCENE DESCRIBE',
                style: EyerisText.screenTitle,
              ),
            ),
          ),

          // Torch toggle button
          Semantics(
            label: _torchOn ? 'Torch on. Tap to turn off.' : 'Torch off. Tap to turn on.',
            button: true,
            child: GestureDetector(
              onTap: _toggleTorch,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _torchOn ? EyerisColors.primary : EyerisTheme.surface,
                  borderRadius: BorderRadius.circular(EyerisRadii.small),
                  border: Border.all(color: EyerisColors.primary, width: 2),
                ),
                child: Center(
                  child: Icon(
                    _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                    color: _torchOn ? EyerisColors.black : EyerisColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Camera preview area
  Widget _buildCameraArea() {
    if (_state == _DescribeState.error && !_cameraReady) {
      return _buildErrorState();
    }

    if (!_cameraReady || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: EyerisColors.primary),
            SizedBox(height: EyerisSpacing.md),
            Text(
              'INITIALISING CAMERA',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: EyerisColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(EyerisSpacing.md2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(EyerisRadii.medium),
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EyerisSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: EyerisColors.danger, size: 56),
            const SizedBox(height: EyerisSpacing.base),
            Text(
              _errorText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                color: EyerisColors.textPrimary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Result card — scrollable text
  Widget _buildResultCard() {
    final isPlaceholder = _state == _DescribeState.idle &&
        _resultText.contains('Point your camera');

    final textColor = _state == _DescribeState.error
        ? EyerisColors.danger
        : (isPlaceholder ? EyerisColors.textMuted : EyerisColors.textPrimary);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 80,
        maxHeight: 160,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: EyerisSpacing.md2,
        vertical: EyerisSpacing.sm,
      ),
      padding: const EdgeInsets.all(EyerisSpacing.md2),
      decoration: BoxDecoration(
        color: EyerisColors.surface,
        border: Border.all(
          color: EyerisColors.border,
          width: EyerisBorders.card,
        ),
        borderRadius: BorderRadius.circular(EyerisRadii.card),
      ),
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Speaking icon
            if (_state == _DescribeState.speaking)
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 2),
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: EyerisColors.primary,
                    size: 20,
                  ),
                ),
              ),

            // Describing spinner
            if (_state == _DescribeState.describing)
              const Padding(
                padding: EdgeInsets.only(right: 10, top: 2),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: EyerisColors.primary,
                  ),
                ),
              ),

            Expanded(
              child: Text(
                _resultText,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                  height: 1.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Describe button
  Widget _buildDescribeButton() {
    final isDescribing = _state == _DescribeState.describing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EyerisSpacing.md2),
      child: Semantics(
        label: isDescribing
            ? 'Describing scene. Please wait.'
            : 'Describe. Double tap to describe what the camera sees.',
        button: true,
        enabled: !isDescribing,
        child: GestureDetector(
          onTap: isDescribing ? null : _runSceneNarration,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 88,
            decoration: BoxDecoration(
              color: isDescribing ? EyerisColors.primaryDim : EyerisColors.primary,
              borderRadius: BorderRadius.circular(EyerisRadii.medium),
            ),
            alignment: Alignment.center,
            child: isDescribing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: EyerisColors.black,
                    ),
                  )
                : const Text(
                    'DESCRIBE SCENE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: EyerisColors.black,
                      letterSpacing: 1.6,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Stop button — shown while TTS is speaking
  Widget _buildStopButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EyerisSpacing.md2),
      child: Semantics(
        label: 'Stop speaking. Double tap to stop description.',
        button: true,
        child: GestureDetector(
          onTap: _stopSpeaking,
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              color: EyerisColors.surface,
              border: Border.all(
                color: EyerisColors.primary,
                width: EyerisBorders.card,
              ),
              borderRadius: BorderRadius.circular(EyerisRadii.medium),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stop_rounded,
                  color: EyerisColors.primary,
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'STOP',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: EyerisColors.primary,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
