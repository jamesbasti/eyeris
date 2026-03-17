// lib/services/voice/intent_router.dart
//
// Hybrid intent router that uses AI when online, keywords when offline.

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eyeris/models/voice_command.dart';
import 'package:eyeris/services/voice/ai_intent_service.dart';
import 'package:eyeris/services/voice/keyword_intent_service.dart';

/// Hybrid intent router: AI online, keywords offline
class IntentRouter {
  IntentRouter._();
  static final IntentRouter instance = IntentRouter._();

  final AIIntentService _aiService = AIIntentService.instance;
  final KeywordIntentService _keywordService = KeywordIntentService.instance;
  final Connectivity _connectivity = Connectivity();

  bool _lastOfflineAnnounced = false;

  /// Callback when switching to offline mode (for TTS announcement)
  void Function()? onOfflineModeActivated;

  /// Parse speech text into a VoiceCommand using the appropriate service
  Future<VoiceCommand> parseIntent(String text) async {
    // Check network connectivity
    final isOnline = await _checkConnectivity();

    if (isOnline && _aiService.isConfigured) {
      // Online: use AI for natural language understanding
      debugPrint('IntentRouter: using AI (online)');
      _lastOfflineAnnounced = false;
      
      final command = await _aiService.parseIntent(text);
      
      // If AI returns unknown, try keyword fallback
      if (!command.isValid) {
        debugPrint('IntentRouter: AI returned unknown, trying keywords');
        return _keywordService.parseIntent(text);
      }
      
      return command;
    } else {
      // Offline: use keyword matching
      debugPrint('IntentRouter: using keywords (offline)');
      
      // Announce offline mode once
      if (!_lastOfflineAnnounced) {
        _lastOfflineAnnounced = true;
        onOfflineModeActivated?.call();
      }
      
      return _keywordService.parseIntent(text);
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      // Check if we have any connectivity (not none)
      return result.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      debugPrint('IntentRouter: connectivity check error — $e');
      return false;
    }
  }

  /// Check current connectivity status
  Future<bool> get isOnline => _checkConnectivity();

  /// Stream of connectivity changes
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any((r) => r != ConnectivityResult.none);
    });
  }
}
