import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/services/color_service.dart';
import 'package:eyeris/services/openai_service.dart';
import 'dart:io';

// ─────────────────────────────────────────────
// COLOR DETECT CAMERA SCREEN
//
// Tap-to-detect colour identification.
// User sees live camera preview, taps "Detect"
// to sample the colour, then hears the result
// spoken aloud via TTS with an AI-enhanced
// description.
// ─────────────────────────────────────────────

enum _DetectState { idle, detecting, result }


class ColorDetectCameraScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ColorDetectCameraScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<ColorDetectCameraScreen> createState() => _ColorDetectCameraScreenState();
}

class _ColorDetectCameraScreenState extends State<ColorDetectCameraScreen> {
  CameraController? _cameraController;
  bool _cameraReady = false;

  _DetectState _state = _DetectState.idle;
  ColorResult? _result;
  String _aiDescription = '';
  bool _torchOn = false;

  final FlutterTts _tts = FlutterTts();
  final OpenAIService _openAI = OpenAIService();
  final ColorService _colorService = ColorService.instance;

  // Keep the latest camera image for on-demand sampling
  CameraImage? _latestImage;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initCamera();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    if (Platform.isIOS) {
      try {
        // Set Evan enhanced voice using the display name
        await _tts.setVoice({
          'name': 'Evan (Enhanced)',
          'locale': 'en-US'
        });
      } catch (e) {
        // Voice setting failed, will use default
      }
    } else if (Platform.isAndroid) {
      try {
        final engines = await _tts.getEngines as List;
        final google = engines.firstWhere(
          (e) => e.toString().toLowerCase().contains('google'),
          orElse: () => '',
        );
        if (google.toString().isNotEmpty) {
          await _tts.setEngine(google.toString());
        }
      } catch (e) {
        // Engine selection failed, will use default
      }
    }

    _tts.setCompletionHandler(() {
      if (mounted && _state == _DetectState.result) {
        setState(() => _state = _DetectState.idle);
      }
    });
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('ColorDetect: camera permission denied');
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

      // Stream frames so we always have the latest image ready
      _cameraController!.startImageStream((image) {
        _latestImage = image;
      });

      setState(() => _cameraReady = true);
    } catch (e) {
      debugPrint('ColorDetect: camera init error — $e');
    }
  }

  Future<void> _detectColor() async {
    if (_latestImage == null || _state == _DetectState.detecting) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _state = _DetectState.detecting;
      _result = null;
      _aiDescription = '';
    });

    // 1. Sample colour from centre pixels
    final colorResult = _colorService.analyse(_latestImage!);
    if (colorResult == null || !mounted) {
      setState(() => _state = _DetectState.idle);
      return;
    }

    setState(() => _result = colorResult);

    // 2. Speak basic name immediately
    await _tts.stop();
    await _tts.speak(colorResult.name);

    // 3. Fetch AI-enhanced description in background
    final description = await _openAI.describeColor(
      colorName: colorResult.name,
      hex: colorResult.hex,
    );

    if (!mounted) return;
    setState(() {
      _aiDescription = description;
      _state = _DetectState.result;
    });

    // 4. If AI gave something richer than just the name, speak it
    if (description != colorResult.name) {
      await _tts.stop();
      await _tts.speak(description);
    }
  }

  @override
  void dispose() {
    _cameraController?.setFlashMode(FlashMode.off).catchError((_) {});
    _cameraController?.dispose();
    _tts.stop();
    super.dispose();
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
      debugPrint('ColorDetect: torch toggle error — $e');
    }
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

          // Camera preview with crosshair
          Expanded(child: _buildCameraArea()),

          // Result card
          if (_result != null) _buildResultCard(),

          // Detect button
          _buildDetectButton(),

          const SizedBox(height: EyerisSpacing.md),
        ],
      ),
    );
  }

  Widget _buildCameraArea() {
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

    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera preview
        ClipRRect(
          borderRadius: BorderRadius.circular(EyerisRadii.medium),
          child: CameraPreview(_cameraController!),
        ),

        // Centre crosshair overlay
        _buildCrosshair(),
      ],
    );
  }

  Widget _buildCrosshair() {
    return IgnorePointer(
      child: SizedBox(
        width: 80,
        height: 80,
        child: CustomPaint(painter: _CrosshairPainter()),
      ),
    );
  }

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
              onTap: widget.onBack,
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
                'COLOR DETECT',
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

  Widget _buildResultCard() {
    final r = _result!;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: EyerisSpacing.md2,
        vertical: EyerisSpacing.sm,
      ),
      padding: const EdgeInsets.all(EyerisSpacing.md2),
      decoration: BoxDecoration(
        color: EyerisColors.surface,
        border: Border.all(color: EyerisColors.border, width: EyerisBorders.card),
        borderRadius: BorderRadius.circular(EyerisRadii.card),
      ),
      child: Row(
        children: [
          // Colour swatch
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: r.color,
              borderRadius: BorderRadius.circular(EyerisRadii.small),
              border: Border.all(color: EyerisColors.border, width: EyerisBorders.thin),
            ),
          ),
          const SizedBox(width: EyerisSpacing.md),
          // Name + hex + AI description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: EyerisColors.textPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.hex,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: EyerisColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                if (_aiDescription.isNotEmpty &&
                    _aiDescription != r.name) ...[
                  const SizedBox(height: 6),
                  Text(
                    _aiDescription,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: EyerisColors.primary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectButton() {
    final isDetecting = _state == _DetectState.detecting;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EyerisSpacing.md2),
      child: Semantics(
        label: isDetecting
            ? 'Detecting colour, please wait.'
            : 'Detect colour. Double tap to identify the colour in front of you.',
        button: true,
        child: GestureDetector(
          onTap: isDetecting ? null : _detectColor,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 88,
            decoration: BoxDecoration(
              color: isDetecting ? EyerisColors.primaryDim : EyerisColors.primary,
              borderRadius: BorderRadius.circular(EyerisRadii.medium),
            ),
            alignment: Alignment.center,
            child: isDetecting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: EyerisColors.black,
                    ),
                  )
                : const Text(
                    'DETECT COLOUR',
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
}

// ── Crosshair painter ────────────────────────

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EyerisColors.primary.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final gap = r * 0.35;

    // Circle
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Cross lines with centre gap
    // Top
    canvas.drawLine(Offset(cx, 0), Offset(cx, cy - gap), paint);
    // Bottom
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, size.height), paint);
    // Left
    canvas.drawLine(Offset(0, cy), Offset(cx - gap, cy), paint);
    // Right
    canvas.drawLine(Offset(cx + gap, cy), Offset(size.width, cy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
