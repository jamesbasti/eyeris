import 'package:flutter_tts/flutter_tts.dart';
import 'package:eyeris/ui/onboarding/onboarding_screen.dart';
import 'dart:developer' as developer;

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
      print('VoiceService: Initializing with profile speed: ${profile?.voiceSpeed}');
      
      // Set default values
      await _flutterTts.setLanguage("en_US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.5); // Default normal speed

      // Try to set a default voice, but don't fail if it doesn't work
      try {
        final voices = await _flutterTts.getVoices;
        if (voices.isNotEmpty) {
          // Just use the first available voice
          await _flutterTts.setVoice(voices.first);
        }
      } catch (e) {
        print('VoiceService: Could not set voice, using default: $e');
      }

      _currentProfile = profile;
      if (profile != null) {
        await _updateSpeechRate();
      }

      _isInitialized = true;
      print('VoiceService: Initialized successfully with speed: ${_currentProfile?.voiceSpeed}');
    } catch (e) {
      print('VoiceService: Failed to initialize: $e');
    }
  }

  // Update profile and refresh TTS settings
  Future<void> updateProfile(OnboardingProfile profile) async {
    print('VoiceService: updateProfile called with speed: ${profile.voiceSpeed}');
    _currentProfile = profile;
    if (_isInitialized) {
      print('VoiceService: Already initialized, updating speech rate');
      await _updateSpeechRate();
      print('VoiceService: Updated with new profile');
    } else {
      print('VoiceService: Not initialized yet, will update when initialized');
    }
  }

  // Update speech rate based on current profile
  Future<void> _updateSpeechRate() async {
    double speechRate = 0.5; // Default to normal
    
    if (_currentProfile != null) {
      print('VoiceService: Updating speech rate for: ${_currentProfile!.voiceSpeed}');
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
    
    print('VoiceService: Setting speech rate to: $speechRate');
    await _flutterTts.setSpeechRate(speechRate);
    print('VoiceService: Speech rate set successfully');
  }

  // Speak text with current settings
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await _flutterTts.speak(text);
      developer.log('Speaking: "$text"');
    } catch (e) {
      developer.log('Failed to speak: $e');
    }
  }

  // Stop current speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      developer.log('Speech stopped');
    } catch (e) {
      developer.log('Failed to stop speech: $e');
    }
  }

  // Pause speech
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      developer.log('Speech paused');
    } catch (e) {
      developer.log('Failed to pause speech: $e');
    }
  }

  
  // Set language
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
      developer.log('Language set to: $language');
    } catch (e) {
      developer.log('Failed to set language: $e');
    }
  }

  // Get available languages
  Future<List<dynamic>> getLanguages() async {
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      developer.log('Failed to get languages: $e');
      return [];
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
      _isInitialized = false;
      developer.log('VoiceService disposed');
    } catch (e) {
      developer.log('Failed to dispose VoiceService: $e');
    }
  }
}
