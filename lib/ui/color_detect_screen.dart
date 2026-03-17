import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';
import 'package:eyeris/services/color_service.dart';
import 'package:eyeris/services/openai_service.dart';

// ─────────────────────────────────────────────
// COLOR DETECT SCREEN
//
// Tap-to-detect colour identification.
// User sees live camera preview with a centre
// crosshair, taps "Detect" to sample the colour,
// then hears the result spoken aloud via TTS
// with an AI-enhanced description.
// ─────────────────────────────────────────────

enum _DetectState { idle, detecting, result }
enum _ColorSource { camera, image }

class ColorDetectScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ColorDetectScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<ColorDetectScreen> createState() => _ColorDetectScreenState();
}

class _ColorDetectScreenState extends State<ColorDetectScreen> {
  CameraController? _cameraController;
  bool _cameraReady = false;

  _DetectState _state = _DetectState.idle;
  ColorResult? _result;
  String _aiDescription = '';
  bool _flashOn = false;
  _ColorSource _colorSource = _ColorSource.camera;

  final FlutterTts _tts = FlutterTts();
  final OpenAIService _openAI = OpenAIService();
  final ColorService _colorService = ColorService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Keep the latest camera image for on-demand sampling
  CameraImage? _latestImage;
  File? _selectedImage;
  ui.Image? _uploadedImageData;
  Offset? _eyedropperPosition;

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
    debugPrint('ColorDetect: Calling AI for "${colorResult.name}" (${colorResult.hex})');
    final description = await _openAI.describeColor(
      colorName: colorResult.name,
      hex: colorResult.hex,
    );
    debugPrint('ColorDetect: AI returned: "$description"');

    if (!mounted) return;
    setState(() {
      _aiDescription = description;
      _state = _DetectState.result;
    });

    // 4. If AI gave something richer than just the name, speak it
    if (description != colorResult.name) {
      debugPrint('ColorDetect: Speaking AI description');
      await _tts.stop();
      await _tts.speak(description);
    } else {
      debugPrint('ColorDetect: AI returned same as basic name, not speaking again');
    }
  }

  @override
  void dispose() {
    _cameraController?.setFlashMode(FlashMode.off).catchError((_) {});
    _cameraController?.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraReady) return;
    try {
      final next = _flashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(next);
      if (!mounted) return;
      setState(() => _flashOn = !_flashOn);
    } catch (e) {
      debugPrint('ColorDetect: flash toggle error — $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;
        
        setState(() {
          _selectedImage = file;
          _uploadedImageData = uiImage;
          _colorSource = _ColorSource.image;
          _result = null;
          _aiDescription = '';
          _state = _DetectState.idle;
        });
      }
    } catch (e) {
      debugPrint('ColorDetect: image pick error — $e');
    }
  }

  Future<void> _detectColorFromImage(Offset position) async {
    if (_uploadedImageData == null || _state == _DetectState.detecting) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _state = _DetectState.detecting;
      _result = null;
      _aiDescription = '';
      _eyedropperPosition = position;
    });

    try {
      // Convert position to image coordinates
      final imageSize = _uploadedImageData!.width;
      final imageHeight = _uploadedImageData!.height;
      
      // Get pixel data at the tapped position
      final byteData = await _uploadedImageData!.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        setState(() => _state = _DetectState.idle);
        return;
      }

      final x = (position.dx * imageSize).round();
      final y = (position.dy * imageHeight).round();
      
      // Calculate pixel index (4 bytes per pixel: RGBA)
      final pixelIndex = (y * imageSize + x) * 4;
      
      if (pixelIndex < byteData.lengthInBytes - 3) {
        final r = byteData.getUint8(pixelIndex);
        final g = byteData.getUint8(pixelIndex + 1);
        final b = byteData.getUint8(pixelIndex + 2);
        
        final color = Color.fromARGB(255, r, g, b);
        final colorResult = _colorService.analyzeColor(color);
        
        if (colorResult != null && mounted) {
          setState(() => _result = colorResult);

          // Speak basic name immediately
          await _tts.stop();
          await _tts.speak(colorResult.name);

          // Fetch AI-enhanced description
          debugPrint('ColorDetect: Calling AI for "${colorResult.name}" (${colorResult.hex})');
          final description = await _openAI.describeColor(
            colorName: colorResult.name,
            hex: colorResult.hex,
          );
          debugPrint('ColorDetect: AI returned: "$description"');

          if (!mounted) return;
          setState(() {
            _aiDescription = description;
            _state = _DetectState.result;
          });

          // Speak AI description if different
          if (description != colorResult.name) {
            debugPrint('ColorDetect: Speaking AI description');
            await _tts.speak(description);
          }
        }
      }
    } catch (e) {
      debugPrint('ColorDetect: image color detection error — $e');
      if (mounted) {
        setState(() => _state = _DetectState.idle);
      }
    }
  }

  void _switchToCamera() {
    setState(() {
      _colorSource = _ColorSource.camera;
      _selectedImage = null;
      _uploadedImageData = null;
      _eyedropperPosition = null;
      _result = null;
      _aiDescription = '';
      _state = _DetectState.idle;
    });
  }

  Widget _buildImageUploadButton() {
    return Semantics(
      label: 'Upload image. Double tap to select an image from gallery for color detection.',
      hint: 'Switch to image upload mode',
      button: true,
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(EyerisRadii.medium),
            border: Border.all(
              color: EyerisColors.primary,
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.photo_library,
              color: EyerisColors.primary,
              size: 24,
            ),
          ),
        ),
      ),
    );
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

          // Camera preview or uploaded image with crosshair
          Expanded(child: _buildImageArea()),

          // Result card
          if (_result != null) _buildResultCard(),

          // Detect button or eyedropper area
          _colorSource == _ColorSource.camera 
              ? _buildDetectButton()
              : _buildEyedropperArea(),

          const SizedBox(height: EyerisSpacing.md),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    if (_colorSource == _ColorSource.camera) {
      if (!_cameraReady || _cameraController == null) {
        return Stack(
          children: [
            const Center(
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
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildImageUploadButton(),
            ),
          ],
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

        // Image upload button overlay (bottom left)
        Positioned(
          bottom: 16,
          left: 16,
          child: _buildImageUploadButton(),
        ),
      ],
    );
    } else {
      // Image upload mode
      if (_uploadedImageData == null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image,
                size: 64,
                color: EyerisColors.textMuted,
              ),
              const SizedBox(height: EyerisSpacing.md),
              Text(
                'No image selected',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: EyerisColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: EyerisSpacing.lg),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Select Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EyerisColors.primary,
                  foregroundColor: EyerisColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: EyerisSpacing.lg,
                    vertical: EyerisSpacing.md,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return GestureDetector(
        onTapDown: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);
          final relativePosition = Offset(
            localPosition.dx / box.size.width,
            localPosition.dy / box.size.height,
          );
          _detectColorFromImage(relativePosition);
        },
        child: Stack(
          children: [
            // Display uploaded image
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          
          // Eyedropper cursor indicator
          if (_eyedropperPosition != null)
            Positioned(
              left: _eyedropperPosition!.dx * MediaQuery.of(context).size.width - 10,
              top: _eyedropperPosition!.dy * (MediaQuery.of(context).size.height - 200) - 10, // Approximate image area
              child: IgnorePointer(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(color: EyerisColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: EyerisColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      );
    }
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

          // Flash toggle button (camera mode only)
          if (_colorSource == _ColorSource.camera)
            Semantics(
              label: _flashOn ? 'Flash on. Double tap to turn off.' : 'Flash off. Double tap to turn on.',
              hint: 'Toggles camera flash for better colour detection in low light',
              button: true,
              child: GestureDetector(
                onTap: _toggleFlash,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _flashOn ? EyerisColors.primary : EyerisTheme.surface,
                    borderRadius: BorderRadius.circular(EyerisRadii.small),
                    border: Border.all(
                      color: EyerisColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _flashOn ? Icons.flash_on : Icons.flash_off,
                      color: _flashOn ? EyerisColors.black : EyerisColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

          // Spacing between buttons
          if (_colorSource == _ColorSource.camera)
            const SizedBox(width: EyerisSpacing.sm),

          // Image upload / camera toggle button
          if (_colorSource == _ColorSource.camera)
            Semantics(
              label: 'Upload image. Double tap to select an image from gallery.',
              hint: 'Switch to image upload mode for color detection',
              button: true,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: EyerisTheme.surface,
                    borderRadius: BorderRadius.circular(EyerisRadii.small),
                    border: Border.all(
                      color: EyerisColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: EyerisIcons.imageUpload(
                      color: EyerisColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

          // Switch back to camera button (image mode only)
          if (_colorSource == _ColorSource.image)
            Semantics(
              label: 'Switch to camera. Double tap to use camera for color detection.',
              hint: 'Switch back to camera mode',
              button: true,
              child: GestureDetector(
                onTap: _switchToCamera,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: EyerisTheme.surface,
                    borderRadius: BorderRadius.circular(EyerisRadii.small),
                    border: Border.all(
                      color: EyerisColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.camera_alt,
                      color: EyerisColors.primary,
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
            height: EyerisTouchTargets.primaryButton,
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
                      fontSize: 15,
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

  Widget _buildEyedropperArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EyerisSpacing.md2),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: EyerisTouchTargets.primaryButton,
            decoration: BoxDecoration(
              color: EyerisColors.primary,
              borderRadius: BorderRadius.circular(EyerisRadii.medium),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.colorize,
                  color: EyerisColors.black,
                  size: 20,
                ),
                const SizedBox(width: EyerisSpacing.sm),
                Text(
                  'Tap Image to Pick Color',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: EyerisColors.black,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EyerisSpacing.sm),
          Text(
            'Tap anywhere on the image to detect the color at that point',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: EyerisColors.textMuted,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
