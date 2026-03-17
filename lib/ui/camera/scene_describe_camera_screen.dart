import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/services/openai_service.dart';

// ─────────────────────────────────────────────
// SCENE DESCRIBE CAMERA SCREEN
//
// On-demand TFLite object detection triggered when
// user taps Describe — no live stream overhead.
// Captures a single frame, runs inference, then passes
// labels to OpenAI for a spoken scene description.
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

  /// TFLite interpreter for object detection
  tfl.Interpreter? _interpreter;

  /// COCO dataset labels (90 classes)
  List<String> _labels = [];

  final OpenAIService _openAIService = OpenAIService();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadModel();
    _initTts();
    _initCamera();
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
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('SceneDescribe: camera permission denied');
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _cameraReady = true);
    } catch (e) {
      debugPrint('SceneDescribe: camera init error — $e');
      if (mounted) {
        setState(() {
          _state = _DescribeState.error;
          _errorText = 'Could not access camera. Please try again.';
        });
      }
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

      final firstPlane = planes[0];
      final buffer = firstPlane.bytes;
      final stride = firstPlane.bytesPerRow;

      if (buffer.isEmpty) {
        debugPrint('Empty buffer');
        return null;
      }

      const targetSize = 300;
      final inputBuffer = List<int>.filled(targetSize * targetSize * 3, 128);

      _processImageWithEnhancement(buffer, inputBuffer, width, height, stride, targetSize);

      return inputBuffer.reshape([1, targetSize, targetSize, 3]);
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  void _processImageWithEnhancement(
    Uint8List buffer,
    List<int> inputBuffer,
    int width,
    int height,
    int stride,
    int targetSize,
  ) {
    try {
      for (int y = 0; y < targetSize && y < height; y += 2) {
        for (int x = 0; x < targetSize && x < width; x += 2) {
          final sourceY = (y * height / targetSize).floor();
          final sourceX = (x * width / targetSize).floor();
          final index = sourceY * stride + sourceX * 4;

          if (index + 3 < buffer.length) {
            final b = buffer[index];
            final g = buffer[index + 1];
            final r = buffer[index + 2];
            final a = buffer[index + 3];

            if (a == 0) continue;

            final enhancedR = _enhancePixel(r);
            final enhancedG = _enhancePixel(g);
            final enhancedB = _enhancePixel(b);

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
    } catch (e) {
      debugPrint('Error during enhanced processing: $e');
      for (int i = 0; i < inputBuffer.length; i++) {
        inputBuffer[i] = 128;
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

      final foregroundDetections = sortedDetections.where((detection) {
        final score = detection['score'] as double;
        final box = detection['box'] as List<double>;

        final width = box[2] - box[0];
        final height = box[3] - box[1];
        final area = width * height;

        final isLargeEnough = area > 0.005;
        final isHighConfidence = score > 0.2;

        return isLargeEnough && isHighConfidence;
      }).toList();

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
    if (_state == _DescribeState.describing) return;

    HapticFeedback.mediumImpact();

    // Stop any ongoing speech
    await _flutterTts.stop();

    if (!mounted) return;
    setState(() {
      _state = _DescribeState.describing;
      _resultText = 'Scanning the scene...';
    });

    try {
      // 1. Capture one frame and run TFLite on-demand
      final labels = await _detectOnce();

      if (!mounted) return;
      if (labels.isEmpty) {
        setState(() {
          _resultText = 'Nothing notable in front of you right now.';
          _state = _DescribeState.idle;
        });
        return;
      }

      setState(() => _resultText = 'Describing the scene...');

      final description =
          await _openAIService.generateAIText(labels);

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
        child: AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
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
