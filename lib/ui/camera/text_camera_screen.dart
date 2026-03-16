// lib/ui/camera/text_camera_screen.dart
//
// Text camera screen for OCR functionality
// Used by Read screen for "Point and Read" feature
// UI styled after ColorDetectScreen for visual consistency

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/vision/text_recognition_service.dart';
import '../../services/vision/text_enhancement_service.dart';
import '../../services/voice/natural_voice_service.dart';
import '../../core/app_theme.dart';
import 'dart:developer' as developer;
import 'dart:io';

// ─────────────────────────────────────────────
// TEXT CAMERA SCREEN — OCR Text-to-Speech Reader
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
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _torchOn = false;
  _ScanState _scanState = _ScanState.idle;
  String _resultText = 'Point camera at text and tap SCAN.';
  String _errorText = '';

  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    _initCamera();
  }

  // ── TTS Initialization
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
      if (mounted && _scanState == _ScanState.speaking) {
        setState(() => _scanState = _ScanState.idle);
      }
    });
  }

  // ── Camera Initialization
  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('TextCamera: camera permission denied');
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
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);
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

  // ── Torch Toggle
  Future<void> _toggleTorch() async {
    if (_cameraController == null || !_cameraReady) return;
    try {
      await _cameraController!.setFlashMode(
        _torchOn ? FlashMode.off : FlashMode.torch,
      );
      if (!mounted) return;
      setState(() => _torchOn = !_torchOn);
    } catch (e) {
      developer.log('Torch toggle error: $e');
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
        if (mounted) setState(() => _scanState = _ScanState.speaking);
        // ElevenLabs disabled - no subscription
        // if (NaturalVoiceService.isApiKeyConfigured()) {
        //   try {
        //     developer.log('Attempting ElevenLabs with new API key...');
        //     await NaturalVoiceService.speakWithNaturalVoice(enhancedText);
        //     spokePrimary = true;
        //     developer.log('ElevenLabs playback completed successfully');
        //     if (mounted) setState(() => _scanState = _ScanState.idle);
        //   } catch (e) {
        //     developer.log('ElevenLabs failed: $e');
        //     developer.log('Falling back to Flutter TTS with Evan (enhanced)');
        //   }
        // }
        // if (!spokePrimary) {
          await _flutterTts.speak(enhancedText);
          // completion handler resets state to idle
        // }
        developer.log('TTS completed');
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
    _cameraController?.setFlashMode(FlashMode.off).catchError((_) {});
    _cameraController?.dispose();
    _flutterTts.stop();
    NaturalVoiceService.stop();
    TextRecognitionService.dispose();
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
          _scanState == _ScanState.speaking
              ? _buildStopButton()
              : _buildScanButton(),

          const SizedBox(height: EyerisSpacing.md),
        ],
      ),
    );
  }

  // ── Header — matches ColorDetectScreen style
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
                'POINT & READ',
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

  // ── Camera preview area — matches ColorDetectScreen style
  Widget _buildCameraArea() {
    if (_scanState == _ScanState.error && !_cameraReady) {
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(EyerisRadii.medium),
      child: CameraPreview(_cameraController!),
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

  // ── Result card — scrollable text, matches ColorDetectScreen card style
  Widget _buildResultCard() {
    final isPlaceholder = _scanState == _ScanState.idle &&
        _resultText.contains('Point camera');

    final textColor = _scanState == _ScanState.error
        ? EyerisColors.danger
        : (isPlaceholder ? EyerisColors.textMuted : EyerisColors.textPrimary);

    return Semantics(
      label: _resultText,
      child: Container(
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

              // Scanning spinner
              if (_scanState == _ScanState.scanning)
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
      ),
    );
  }

  // ── Scan button — matches ColorDetectScreen detect button style
  Widget _buildScanButton() {
    final isScanning = _scanState == _ScanState.scanning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EyerisSpacing.md2),
      child: Semantics(
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
            duration: const Duration(milliseconds: 120),
            height: 88,
            decoration: BoxDecoration(
              color: isScanning ? EyerisColors.primaryDim : EyerisColors.primary,
              borderRadius: BorderRadius.circular(EyerisRadii.medium),
            ),
            alignment: Alignment.center,
            child: isScanning
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: EyerisColors.black,
                    ),
                  )
                : const Text(
                    'SCAN TEXT',
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
        label: 'Stop speaking. Double tap to stop reading.',
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
