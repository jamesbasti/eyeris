import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:eyeris/ui/onboarding/onboarding_screen.dart';

// ─────────────────────────────────────────────
// VOICE SERVICE
//
// Centralized Text-to-Speech management
// Handles voice speed, language, and other TTS settings
// Based on user profile preferences
// ─────────────────────────────────────────────

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  static VoiceService get instance => _instance;
  VoiceService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  OnboardingProfile? _currentProfile;
  bool _isInitialized = false;

  // Getters
  FlutterTts get tts => _flutterTts;
  OnboardingProfile? get currentProfile => _currentProfile;
  bool get isInitialized => _isInitialized;

  // Initialize TTS with profile settings
  Future<void> initialize({OnboardingProfile? profile}) async {
    if (_isInitialized) return;

    try {
      debugPrint('VoiceService: Initializing with profile speed: ${profile?.voiceSpeed}');
      
      // Set default values
      await _flutterTts.setLanguage("en_US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.5); // Default normal speed

      // Try to set a default voice, but don't fail if it doesn't work
      try {
        final voices = await _flutterTts.getVoices;
        if (voices.isNotEmpty) {
          // Handle voice setting properly for iOS
          final voice = voices.first;
          if (voice is Map<String, String>) {
            await _flutterTts.setVoice(voice);
          } else {
            // Skip voice setting if format is unexpected
            debugPrint('VoiceService: Voice format not supported, using default');
          }
        }
      } catch (e) {
        debugPrint('VoiceService: Could not set voice, using default: $e');
      }

      _currentProfile = profile;
      if (profile != null) {
        await _updateSpeechRate();
      }

      _isInitialized = true;
      debugPrint('VoiceService: Initialized successfully with speed: ${_currentProfile?.voiceSpeed}');
    } catch (e) {
      debugPrint('VoiceService: Failed to initialize: $e');
    }
  }

  // Update profile and refresh TTS settings
  Future<void> updateProfile(OnboardingProfile profile) async {
    debugPrint('VoiceService: updateProfile called with speed: ${profile.voiceSpeed}');
    _currentProfile = profile;
    if (_isInitialized) {
      debugPrint('VoiceService: Already initialized, updating speech rate');
      await _updateSpeechRate();
      debugPrint('VoiceService: Updated with new profile');
    } else {
      debugPrint('VoiceService: Not initialized yet, will update when initialized');
    }
  }

  // Update speech rate based on current profile
  Future<void> _updateSpeechRate() async {
    double speechRate = 0.5; // Default to normal
    
    if (_currentProfile != null) {
      debugPrint('VoiceService: Updating speech rate for: ${_currentProfile!.voiceSpeed}');
      switch (_currentProfile!.voiceSpeed) {
        case 'slow':
          speechRate = 0.2;  // Much slower for noticeable difference
          break;
        case 'normal':
          speechRate = 0.5;  // Standard rate
          break;
        case 'fast':
          speechRate = 0.8;  // Much faster for noticeable difference
          break;
      }
    }
    
    debugPrint('VoiceService: Setting speech rate to: $speechRate');
    await _flutterTts.setSpeechRate(speechRate);
    debugPrint('VoiceService: Speech rate set successfully');
  }

  // Speak text with current settings
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await _flutterTts.speak(text);
      debugPrint('VoiceService: Speaking: "$text"');
    } catch (e) {
      debugPrint('VoiceService: Failed to speak: $e');
    }
  }

  // Stop current speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      debugPrint('VoiceService: Speech stopped');
    } catch (e) {
      debugPrint('VoiceService: Failed to stop speech: $e');
    }
  }

  // Pause speech
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      debugPrint('VoiceService: Speech paused');
    } catch (e) {
      debugPrint('VoiceService: Failed to pause speech: $e');
    }
  }

  
  // Set language
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
      debugPrint('VoiceService: Language set to: $language');
    } catch (e) {
      debugPrint('VoiceService: Failed to set language: $e');
    }
  }

  // Get available languages
  Future<List<dynamic>> getLanguages() async {
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      debugPrint('VoiceService: Failed to get languages: $e');
      return [];
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
      _isInitialized = false;
      debugPrint('VoiceService: VoiceService disposed');
    } catch (e) {
      debugPrint('VoiceService: Failed to dispose VoiceService: $e');
    }
  }
}
