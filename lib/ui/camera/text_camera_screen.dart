// lib/ui/camera/text_camera_screen.dart
//
// Text camera screen for OCR functionality
// Used by Read screen for "Point and Read" feature
// Provides live camera preview with text recognition

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../../services/vision/text_recognition_service.dart';
import '../../services/vision/text_enhancement_service.dart';
import '../../services/voice/natural_voice_service.dart';
import '../../core/app_theme.dart';
import 'dart:developer' as developer;
import 'dart:io';

// ─────────────────────────────────────────────
// TEXT CAMERA SCREEN — OCR Text-to-Speech Reader
//
// Accessibility-first redesign:
//
//   Layout (top → bottom):
//     ScreenHeader  : back button (44px) + "DESCRIBE" title
//     CameraPreview : fills all remaining space
//     TextPanel     : large-text OCR result (min 3 lines)
//     ScanButton    : full-width, 88px, yellow — primary action
//
//   States:
//     idle      → "Point camera at text and tap SCAN"
//     scanning  → "Analysing text…" + spinner
//     speaking  → enhanced text + speaking indicator
//     error     → error message in danger colour
//
//   Touch targets:
//     Back button : 44 × 44 px (WCAG floor)
//     Scan button : full width × 88 px
//     Stop button : full width × 64 px (shown while speaking)
//
//   Screen reader:
//     Scan button label updates per state
//     Result text announces via SemanticsService on change
// ─────────────────────────────────────────────

enum _ScanState { idle, scanning, speaking, error }

class TextCameraScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onTextDetected;

  const TextCameraScreen({
    super.key,
    required this.onBack,
    this.onTextDetected,
  });

  @override
  State<TextCameraScreen> createState() => _TextCameraScreenState();
}

class _TextCameraScreenState extends State<TextCameraScreen> {
  // ── Camera
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  _ScanState _scanState = _ScanState.idle;
  String _resultText = 'Point camera at text and tap SCAN.';
  String _errorText = '';

  // ── OCR / AI / TTS
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    _initializeCamera();
  }

  // ── TTS Initialization
  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() {
      if (mounted && _scanState == _ScanState.speaking) {
        setState(() => _scanState = _ScanState.idle);
      }
    });
  }

  // ── Camera Initialization
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      developer.log('Camera init error: $e');
      if (mounted) {
        setState(() {
          _scanState = _ScanState.error;
          _errorText = 'Could not access camera. Please try again.';
        });
      }
    }
  }

  // ── Flash Toggle
  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
        setState(() => _isFlashOn = false);
        developer.log('Flash turned OFF');
      } else {
        await _cameraController!.setFlashMode(FlashMode.always);
        setState(() => _isFlashOn = true);
        developer.log('Flash turned ON');
      }
    } catch (e) {
      developer.log('Flash toggle error: $e');
    }
  }

  // ── OCR and Text Enhancement
  Future<void> _captureAndRecognizeText() async {
    developer.log('*** SCAN BUTTON PRESSED ***');
    developer.log('=== STARTING TEXT RECOGNITION ===');
    developer.log('Current state: $_scanState');
    developer.log('Camera controller exists: ${_cameraController != null}');
    developer.log('Camera initialized: ${_cameraController?.value.isInitialized}');
    
    if (_scanState == _ScanState.scanning ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      developer.log('Early return: scanning=$_scanState, controller=${_cameraController != null}, initialized=${_cameraController?.value.isInitialized}');
      return;
    }

    developer.log('Passed initial checks - proceeding with OCR');
    HapticFeedback.mediumImpact();

    // Stop any ongoing speech
    developer.log('Stopping any ongoing speech...');
    await _flutterTts.stop();
    await NaturalVoiceService.stop();

    developer.log('Setting state to scanning...');
    setState(() {
      _scanState = _ScanState.scanning;
      _resultText = 'Analysing text...';
    });

    developer.log('State updated - taking picture...');
    try {
      // Take picture silently to prevent camera movement
      developer.log('About to take picture...');
      final XFile imageFile = await _cameraController!.takePicture();
      developer.log('Image captured: ${imageFile.path}');

      // Check if file exists and has content
      final file = File(imageFile.path);
      developer.log('File exists: ${await file.exists()}');
      
      if (!await file.exists()) {
        developer.log('ERROR: Image file does not exist!');
        _updateResult('Error: Image file not found. Please try again.');
        return;
      }
      
      final fileSize = await file.length();
      developer.log('Image file size: $fileSize bytes');
      
      if (fileSize == 0) {
        developer.log('ERROR: Image file is empty!');
        _updateResult('Error: Captured image is empty. Please try again.');
        return;
      }

      // Recognize text using Google ML Kit
      developer.log('Creating InputImage from file path...');
      final inputImage = InputImage.fromFilePath(imageFile.path);
      developer.log('InputImage created successfully');
      developer.log('Starting text recognition...');
      
      final recognizedText =
          await TextRecognitionService.recognizeTextFromInputImage(inputImage);
      
      developer.log('Recognition completed. Result: "$recognizedText"');
      developer.log('Recognition result length: ${recognizedText.length}');

      if (recognizedText.isEmpty) {
        developer.log('WARNING: No text found in image');
        _updateResult('No text found. Try moving closer or adjusting lighting.');
        return;
      }

      // Enhance text using OpenAI
      developer.log('Enhancing text with OpenAI...');
      final enhancedText =
          await TextEnhancementService.enhanceText(recognizedText);
      developer.log('Enhanced text: "$enhancedText"');

      _updateResult(enhancedText.isNotEmpty
          ? enhancedText
          : 'Could not enhance text. Please try again.');

      // Speak the enhanced text
      if (enhancedText.isNotEmpty) {
        developer.log('Starting TTS for: "${enhancedText.length > 50 ? enhancedText.substring(0, 50) : enhancedText}..."');
        if (NaturalVoiceService.isApiKeyConfigured()) {
          developer.log('Using ElevenLabs natural voice');
          await NaturalVoiceService.speakWithNaturalVoice(enhancedText);
        } else {
          developer.log('Using Flutter TTS fallback');
          await _flutterTts.speak(enhancedText);
        }
        if (mounted) {
          developer.log('TTS started successfully');
          setState(() => _scanState = _ScanState.speaking);
        }
      } else {
        developer.log('Warning: enhancedText is empty, skipping TTS');
      }

      // Notify parent if callback provided
      widget.onTextDetected?.call();
    } catch (e, stackTrace) {
      developer.log('=== OCR ERROR ===');
      developer.log('Error type: ${e.runtimeType}');
      developer.log('Error message: $e');
      developer.log('Stack trace: $stackTrace');
      
      String errorMessage = 'Error: Could not recognize text.';
      if (e.toString().contains('permission')) {
        errorMessage = 'Error: Camera permission denied. Please enable camera access in Settings.';
      } else if (e.toString().contains('ML Kit') || e.toString().contains('TextRecognizer')) {
        errorMessage = 'Error: Text recognition service unavailable. Please try again.';
      } else if (e.toString().contains('file') || e.toString().contains('path')) {
        errorMessage = 'Error: Could not process image. Please try again.';
      } else if (e.toString().contains('Network') || e.toString().contains('connection')) {
        errorMessage = 'Error: Network issue. Please check connection and try again.';
      }
      
      _updateResult('$errorMessage Please try again.');
      if (mounted) setState(() => _scanState = _ScanState.error);
    }
  }

  Future<void> _stopSpeaking() async {
    HapticFeedback.lightImpact();
    await _flutterTts.stop();
    await NaturalVoiceService.stop();
    if (mounted) setState(() => _scanState = _ScanState.idle);
  }

  void _updateResult(String text) {
    if (!mounted) return;
    setState(() {
      _resultText = text;
      if (_scanState != _ScanState.speaking) {
        _scanState = _ScanState.idle;
      }
    });
    SemanticsService.sendAnnouncement(
      View.of(context),
      text,
      TextDirection.ltr,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _flutterTts.stop();
    NaturalVoiceService.stop();
    TextRecognitionService.dispose();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EyerisColors.background,
      body: Column(
        children: [
          // ── Top chrome
          SafeArea(
            bottom: false,
            child: _buildHeader(),
          ),

          // ── Camera preview
          Expanded(
            child: _buildCameraArea(),
          ),

          // ── Result panel + action button
          _buildBottomPanel(),

          // ── System nav area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  // ── Screen header — back + title
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: EyerisColors.black,
        border: Border(
          bottom: BorderSide(color: EyerisColors.primary, width: 3),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EyerisSpacing.lg,
        vertical: EyerisSpacing.md,
      ),
      child: Row(
        children: [
          // Back button — 44×44, yellow fill
          Semantics(
            label: 'Go back',
            hint: 'Returns to Read screen',
            button: true,
            child: GestureDetector(
              onTap: () {
                _flutterTts.stop();
                NaturalVoiceService.stop();
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
                'DESCRIBE',
                style: EyerisText.screenTitle,
              ),
            ),
          ),

          // Flash toggle button
          Semantics(
            label: _isFlashOn ? 'Flash on. Double tap to turn off.' : 'Flash off. Double tap to turn on.',
            hint: 'Toggles camera flash for better text recognition in low light',
            button: true,
            child: GestureDetector(
              onTap: _toggleFlash,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isFlashOn ? EyerisColors.primary : EyerisTheme.surface,
                  borderRadius: BorderRadius.circular(EyerisRadii.small),
                  border: Border.all(
                    color: EyerisColors.primary,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: _isFlashOn ? EyerisColors.black : EyerisColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: EyerisSpacing.sm),

          // State badge — visible indicator of current mode
          _buildStateBadge(),
        ],
      ),
    );
  }

  Widget _buildStateBadge() {
    String label;
    Color color;

    switch (_scanState) {
      case _ScanState.scanning:
        label = 'SCANNING';
        color = EyerisColors.primary;
      case _ScanState.speaking:
        label = 'SPEAKING';
        color = EyerisColors.primary;
      case _ScanState.error:
        label = 'ERROR';
        color = EyerisColors.danger;
      case _ScanState.idle:
        return const SizedBox.shrink();
    }

    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(EyerisRadii.small),
        ),
        child: Text(
          label,
          style: EyerisText.mono(
            size: 9,
            letterSpacing: 0.12,
            color: color,
          ),
        ),
      ),
    );
  }

  // ── Camera preview area
  Widget _buildCameraArea() {
    if (_scanState == _ScanState.error && !_isCameraInitialized) {
      return _buildErrorState();
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return _buildLoadingState();
    }

    return Stack(
      children: [
        // Camera preview
        CameraPreview(_cameraController!),

        // Scanning overlay — removed yellow border
        if (_scanState == _ScanState.scanning)
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: EyerisColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: EyerisColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: EyerisSpacing.base),
            Text(
              'STARTING CAMERA',
              style: EyerisText.mono(
                size: 11,
                letterSpacing: 0.12,
                color: EyerisColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: EyerisColors.background,
      padding: const EdgeInsets.all(EyerisSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: EyerisColors.danger, size: 56),
            const SizedBox(height: EyerisSpacing.base),
            Text(
              _errorText,
              style: EyerisText.mono(
                size: 15,
                weight: FontWeight.w400,
                color: EyerisColors.textPrimary,
                letterSpacing: 0.03,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom panel — result text + action button
  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: EyerisColors.black,
        border: Border(
          top: BorderSide(color: EyerisColors.primary, width: 3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Result text panel
          _buildResultPanel(),

          // Action button(s)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EyerisSpacing.md2,
              0,
              EyerisSpacing.md2,
              EyerisSpacing.md2,
            ),
            child: _scanState == _ScanState.speaking
                ? _buildStopButton()
                : _buildScanButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    final textColor = _scanState == _ScanState.error
        ? EyerisColors.danger
        : (_scanState == _ScanState.idle && _resultText.contains('Point camera')
            ? EyerisColors.textMuted
            : EyerisColors.textPrimary);

    return Semantics(
      label: _resultText,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 80,
          maxHeight: 150,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: EyerisSpacing.base,
          vertical: EyerisSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Speaking icon — yellow when active
              if (_scanState == _ScanState.speaking)
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

              Expanded(
                child: Text(
                  _resultText,
                  style: EyerisText.mono(
                    size: 15,
                    weight: FontWeight.w400,
                    color: textColor,
                    letterSpacing: 0.03,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Primary action: SCAN — full width, 88px
  Widget _buildScanButton() {
    final isScanning = _scanState == _ScanState.scanning;

    return Semantics(
      label: isScanning
          ? 'Scanning text. Please wait.'
          : 'Scan. Double tap to read text from camera.',
      button: true,
      enabled: !isScanning,
      child: GestureDetector(
        onTap: () {
          developer.log('*** BUTTON TAPPED ***');
          if (isScanning) {
            developer.log('Button disabled - currently scanning');
            return;
          }
          developer.log('Button enabled - calling _captureAndRecognizeText');
          _captureAndRecognizeText();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          height: 88,
          decoration: BoxDecoration(
            color: isScanning
                ? EyerisColors.primaryDim
                : EyerisColors.primary,
            borderRadius: BorderRadius.circular(EyerisRadii.card),
          ),
          child: Center(
            child: isScanning
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: EyerisColors.black,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SCANNING…',
                        style: EyerisText.mono(
                          size: 16,
                          letterSpacing: 0.12,
                          color: EyerisColors.black,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'SCAN',
                    style: EyerisText.mono(
                      size: 20,
                      letterSpacing: 0.14,
                      color: EyerisColors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Secondary action: STOP — shown while TTS is speaking
  Widget _buildStopButton() {
    return Semantics(
      label: 'Stop speaking. Double tap to stop reading.',
      button: true,
      child: GestureDetector(
        onTap: _stopSpeaking,
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            color: EyerisColors.surface,
            border: Border.all(
              color: EyerisColors.primary,
              width: EyerisBorders.card,
            ),
            borderRadius: BorderRadius.circular(EyerisRadii.card),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.stop_rounded,
                    color: EyerisColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'STOP',
                  style: EyerisText.mono(
                    size: 16,
                    letterSpacing: 0.12,
                    color: EyerisColors.primary,
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

// ─────────────────────────────────────────────
// SCANNING OVERLAY
// Pulsing yellow border over the camera preview
// when a scan is in progress.
// ─────────────────────────────────────────────

class _ScanningOverlay extends StatefulWidget {
  const _ScanningOverlay();

  @override
  State<_ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<_ScanningOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            border: Border.all(
              color: EyerisColors.primary.withValues(alpha: _anim.value),
              width: 4,
            ),
          ),
        ),
      ),
    );
  }
}
