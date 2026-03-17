// lib/services/user_preferences_service.dart
//
// Service for persisting and loading user preferences.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyeris/models/user_preferences.dart';

/// Service for managing user preferences persistence
class UserPreferencesService {
  UserPreferencesService._();
  static final UserPreferencesService instance = UserPreferencesService._();

  static const String _prefsKey = 'user_preferences';
  
  SharedPreferences? _prefs;
  UserPreferences _currentPreferences = const UserPreferences();

  /// Get current preferences (cached)
  UserPreferences get current => _currentPreferences;

  /// Initialize the service and load preferences
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPreferences();
      debugPrint('UserPreferences: initialized — $_currentPreferences');
    } catch (e) {
      debugPrint('UserPreferences: initialization error — $e');
    }
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    if (_prefs == null) return;

    try {
      final jsonString = _prefs!.getString(_prefsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _currentPreferences = UserPreferences.fromJson(json);
        debugPrint('UserPreferences: loaded from storage');
      } else {
        debugPrint('UserPreferences: no saved preferences, using defaults');
      }
    } catch (e) {
      debugPrint('UserPreferences: load error — $e');
    }
  }

  /// Save preferences to storage
  Future<bool> savePreferences(UserPreferences preferences) async {
    if (_prefs == null) {
      debugPrint('UserPreferences: not initialized, cannot save');
      return false;
    }

    try {
      final jsonString = jsonEncode(preferences.toJson());
      await _prefs!.setString(_prefsKey, jsonString);
      _currentPreferences = preferences;
      debugPrint('UserPreferences: saved — $preferences');
      return true;
    } catch (e) {
      debugPrint('UserPreferences: save error — $e');
      return false;
    }
  }

  /// Save onboarding profile
  Future<bool> saveOnboardingProfile({
    required Set<String> visionTypes,
    required String interactionMode,
    required String voiceSpeed,
  }) async {
    final preferences = UserPreferences(
      onboardingCompleted: true,
      visionTypes: visionTypes,
      interactionMode: interactionMode,
      voiceSpeed: voiceSpeed,
    );
    return await savePreferences(preferences);
  }

  /// Check if onboarding is completed
  bool get isOnboardingCompleted => _currentPreferences.onboardingCompleted;

  /// Get TTS rate from current preferences
  double get ttsRate => _currentPreferences.ttsRate;

  /// Get voice speed setting
  String get voiceSpeed => _currentPreferences.voiceSpeed;

  /// Get interaction mode
  String get interactionMode => _currentPreferences.interactionMode;

  /// Get vision types
  Set<String> get visionTypes => _currentPreferences.visionTypes;

  /// Check if voice-first mode is enabled
  bool get isVoiceFirst => _currentPreferences.isVoiceFirst;

  /// Clear all preferences (for testing)
  Future<void> clearPreferences() async {
    if (_prefs == null) return;
    await _prefs!.remove(_prefsKey);
    _currentPreferences = const UserPreferences();
    debugPrint('UserPreferences: cleared');
  }
}
