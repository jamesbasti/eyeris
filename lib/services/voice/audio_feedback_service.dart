// lib/services/voice/audio_feedback_service.dart
//
// Audio feedback service for voice control.
// Provides sound effects and TTS confirmations.

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:eyeris/services/user_preferences_service.dart';
import 'dart:io';

/// Audio feedback types
enum FeedbackType {
  listeningStart,
  listeningStop,
  success,
  error,
}

/// Audio feedback service for voice control
class AudioFeedbackService {
  AudioFeedbackService._();
  static final AudioFeedbackService instance = AudioFeedbackService._();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  double _speechRate = 0.5;

  /// Initialize the audio feedback service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load speech rate from user preferences
      _speechRate = UserPreferencesService.instance.ttsRate;
      
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(1.0);

      if (Platform.isIOS) {
        try {
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

      _isInitialized = true;
      debugPrint('AudioFeedback: initialized');
    } catch (e) {
      debugPrint('AudioFeedback: initialization error — $e');
    }
  }

  /// Play a feedback sound using haptics (since we don't have audio files)
  Future<void> playFeedback(FeedbackType type) async {
    switch (type) {
      case FeedbackType.listeningStart:
        // Short vibration to indicate listening started
        await HapticFeedback.mediumImpact();
        break;
      case FeedbackType.listeningStop:
        // Double vibration to indicate listening stopped
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.lightImpact();
        break;
      case FeedbackType.success:
        // Strong vibration for success
        await HapticFeedback.heavyImpact();
        break;
      case FeedbackType.error:
        // Triple short vibration for error
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 80));
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 80));
        await HapticFeedback.lightImpact();
        break;
    }
  }

  /// Speak a confirmation message
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    
    if (text.isEmpty) return;

    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('AudioFeedback: speak error — $e');
    }
  }

  /// Stop any ongoing speech
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('AudioFeedback: stop error — $e');
    }
  }

  /// Increase speech rate
  Future<void> increaseSpeechRate() async {
    _speechRate = (_speechRate + 0.1).clamp(0.1, 1.0);
    await _tts.setSpeechRate(_speechRate);
    debugPrint('AudioFeedback: speech rate increased to $_speechRate');
  }

  /// Decrease speech rate
  Future<void> decreaseSpeechRate() async {
    _speechRate = (_speechRate - 0.1).clamp(0.1, 1.0);
    await _tts.setSpeechRate(_speechRate);
    debugPrint('AudioFeedback: speech rate decreased to $_speechRate');
  }

  /// Get current speech rate
  double get speechRate => _speechRate;

  /// Dispose resources
  void dispose() {
    _tts.stop();
  }
}
