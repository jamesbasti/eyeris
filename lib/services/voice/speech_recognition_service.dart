// lib/services/voice/speech_recognition_service.dart
//
// Speech-to-text service using on-device speech recognition.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Result from speech recognition
class SpeechResult {
  final String text;
  final double confidence;
  final bool isFinal;

  const SpeechResult({
    required this.text,
    this.confidence = 1.0,
    this.isFinal = false,
  });
}

/// Service for on-device speech recognition
class SpeechRecognitionService {
  SpeechRecognitionService._();
  static final SpeechRecognitionService instance = SpeechRecognitionService._();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  /// Callback for speech results
  void Function(SpeechResult)? onResult;

  /// Callback for errors
  void Function(String)? onError;

  /// Callback when listening status changes
  void Function(bool)? onListeningChanged;

  /// Whether the service is currently listening
  bool get isListening => _isListening;

  /// Whether the service is initialized and available
  bool get isAvailable => _isInitialized;

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        debugPrint('SpeechRecognition: microphone permission denied');
        return false;
      }

      // Initialize speech recognition
      _isInitialized = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: kDebugMode,
      );

      if (!_isInitialized) {
        debugPrint('SpeechRecognition: failed to initialize');
        return false;
      }

      debugPrint('SpeechRecognition: initialized successfully');
      return true;
    } catch (e) {
      debugPrint('SpeechRecognition: initialization error — $e');
      return false;
    }
  }

  /// Start listening for speech
  Future<bool> startListening({
    Duration? listenFor,
    Duration? pauseFor,
    String localeId = 'en_US',
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isListening) {
      debugPrint('SpeechRecognition: already listening');
      return true;
    }

    try {
      await _speech.listen(
        onResult: _onResult,
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        localeId: localeId,
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.confirmation,
        ),
      );

      _isListening = true;
      onListeningChanged?.call(true);
      debugPrint('SpeechRecognition: started listening');
      return true;
    } catch (e) {
      debugPrint('SpeechRecognition: start listening error — $e');
      onError?.call('Failed to start listening: $e');
      return false;
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      onListeningChanged?.call(false);
      debugPrint('SpeechRecognition: stopped listening');
    } catch (e) {
      debugPrint('SpeechRecognition: stop listening error — $e');
    }
  }

  /// Cancel listening without processing
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speech.cancel();
      _isListening = false;
      onListeningChanged?.call(false);
      debugPrint('SpeechRecognition: cancelled listening');
    } catch (e) {
      debugPrint('SpeechRecognition: cancel listening error — $e');
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    final speechResult = SpeechResult(
      text: result.recognizedWords,
      confidence: result.confidence,
      isFinal: result.finalResult,
    );

    debugPrint('SpeechRecognition: "${result.recognizedWords}" '
        '(final: ${result.finalResult}, confidence: ${result.confidence})');

    onResult?.call(speechResult);

    // Auto-stop when we get a final result
    if (result.finalResult) {
      _isListening = false;
      onListeningChanged?.call(false);
    }
  }

  void _onStatus(String status) {
    debugPrint('SpeechRecognition: status — $status');

    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      onListeningChanged?.call(false);
    }
  }

  void _onError(dynamic error) {
    debugPrint('SpeechRecognition: error — $error');
    _isListening = false;
    onListeningChanged?.call(false);
    onError?.call(error.toString());
  }

  /// Dispose resources
  void dispose() {
    _speech.stop();
    _isListening = false;
    _isInitialized = false;
  }
}
