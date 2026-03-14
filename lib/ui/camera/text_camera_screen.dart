// lib/ui/camera/text_camera_screen.dart
//
// Text camera screen for OCR functionality
// Used by Read screen for "Point and Read" feature
// Provides live camera preview with text recognition

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../../services/vision/text_recognition_service.dart';
import '../../services/vision/text_enhancement_service.dart';
import '../../services/voice/natural_voice_service.dart';
import '../../core/app_theme.dart';
import 'dart:developer' as developer;

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
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _detectedText = 'Point camera at text and tap to read';
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTts();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _flutterTts.stop(); // Stop speech before disposing
    NaturalVoiceService.stop(); // Stop natural voice
    TextRecognitionService.dispose();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5); // Slower for better accessibility
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Get available voices and choose best one
    final voices = await _flutterTts.getVoices;
    developer.log('Available voices: ${voices.length} found');
    
    // Try to find a more natural voice
    String selectedVoice = '';
    for (var voice in voices) {
      // Check if voice is a Map or has name property
      String voiceName = '';
      if (voice is Map) {
        voiceName = voice['name']?.toString() ?? '';
      } else {
        voiceName = voice.name?.toString() ?? '';
      }
      
      if (voiceName.toLowerCase().contains('samantha') || 
          voiceName.toLowerCase().contains('alex') ||
          voiceName.toLowerCase().contains('daniel') ||
          voiceName.toLowerCase().contains('karen') ||
          voiceName.toLowerCase().contains('siri') ||
          voiceName.toLowerCase().contains('neural')) {
        selectedVoice = voiceName;
        break;
      }
    }
    
    // If no specific voice found, use the first available
    if (selectedVoice.isEmpty && voices.isNotEmpty) {
      final firstVoice = voices.first;
      if (firstVoice is Map) {
        selectedVoice = firstVoice['name']?.toString() ?? '';
      } else {
        selectedVoice = firstVoice.name?.toString() ?? '';
      }
    }
    
    if (selectedVoice.isNotEmpty) {
      await _flutterTts.setVoice({"name": selectedVoice, "locale": "en-US"});
      developer.log('Using voice: $selectedVoice');
    }
    
    // Add speech completion handler
    _flutterTts.setCompletionHandler(() {
      // Speech completed
    });
    
    // Add error handler
    _flutterTts.setErrorHandler((msg) {
      developer.log('TTS Error: $msg');
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final backCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      developer.log('Camera initialization error: $e');
    }
  }

  Future<void> _captureAndRecognizeText() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _detectedText = 'Processing...';
    });

    // Stop any ongoing speech before starting new recognition
    await _flutterTts.stop();
    await NaturalVoiceService.stop();

    try {
      // Take picture
      final XFile imageFile = await _cameraController!.takePicture();
      
      // Recognize text
      final recognizedText = await _recognizeTextFromImage(imageFile.path);
      
      if (recognizedText.isEmpty) {
        setState(() {
          _detectedText = 'No text found in image';
          _isProcessing = false;
        });
        return;
      }
      
      // Enhance text with OpenAI
      final enhancedText = await TextEnhancementService.enhanceText(recognizedText);
      
      setState(() {
        _detectedText = enhancedText;
        _isProcessing = false;
      });

      // Speak the enhanced text
      if (enhancedText.isNotEmpty) {
        try {
          // Use natural voice if available, otherwise fallback to Flutter TTS
          if (NaturalVoiceService.isApiKeyConfigured()) {
            developer.log('Using ElevenLabs natural voice');
            await NaturalVoiceService.speakWithNaturalVoice(enhancedText);
          } else {
            developer.log('Using Flutter TTS fallback');
            await _flutterTts.speak(enhancedText);
          }
        } catch (e) {
          developer.log('Speech synthesis error: $e');
          // Don't fail the whole process if speech fails
        }
      }

      // Notify parent if callback provided
      widget.onTextDetected?.call();
    } catch (e) {
      developer.log('Text recognition error: $e');
      setState(() {
        _detectedText = 'Error: Could not recognize text - $e';
        _isProcessing = false;
      });
    }
  }

  Future<String> _recognizeTextFromImage(String imagePath) async {
    try {
      // Create InputImage from file path
      final inputImage = InputImage.fromFilePath(imagePath);
      
      // Use TextRecognitionService to process the image
      final recognizedText = await TextRecognitionService.recognizeTextFromInputImage(inputImage);
      
      return recognizedText;
    } catch (e) {
      developer.log('OCR error: $e');
      return 'Could not recognize text. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EyerisTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(EyerisSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      // Stop both speech types before going back
                      await _flutterTts.stop();
                      await NaturalVoiceService.stop();
                      widget.onBack();
                    },
                    icon: const Icon(Icons.arrow_back, color: EyerisColors.textPrimary),
                  ),
                  const Expanded(
                    child: Text(
                      'Point and Read',
                      style: TextStyle(
                        color: EyerisColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Camera preview or placeholder
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(EyerisSpacing.md),
                decoration: BoxDecoration(
                  color: EyerisTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EyerisTheme.border),
                ),
                child: _isCameraInitialized
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CameraPreview(_cameraController!),
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: EyerisColors.primary),
                      ),
              ),
            ),

            // Detected text display
            Container(
              margin: const EdgeInsets.all(EyerisSpacing.md),
              padding: const EdgeInsets.all(EyerisSpacing.md),
              decoration: BoxDecoration(
                color: EyerisTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EyerisTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detected Text:',
                    style: TextStyle(
                      color: EyerisColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _detectedText,
                    style: const TextStyle(
                      color: EyerisColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Capture button
            Container(
              margin: const EdgeInsets.all(EyerisSpacing.md),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _captureAndRecognizeText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EyerisColors.primary,
                  foregroundColor: EyerisColors.background,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: EyerisColors.background,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : const Text(
                        'CAPTURE & READ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
