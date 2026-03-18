// lib/services/voice/intent_router.dart
//
// Hybrid intent router that uses AI when online, keywords when offline.
// Prioritizes low-latency responses by returning confident keyword matches
// immediately and enforcing timeouts on slower AI requests.
//
import 'dart:async';

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

  static const double _keywordConfidenceThreshold = 0.65;
  static const Duration _aiTimeout = Duration(milliseconds: 2000);
  static const Duration _connectivityCacheDuration = Duration(seconds: 10);

  bool _lastOfflineAnnounced = false;
  bool _lastConnectivityStatus = true;
  DateTime? _lastConnectivityCheck;

  /// Callback when switching to offline mode (for TTS announcement)
  void Function()? onOfflineModeActivated;

  /// Parse speech text into a VoiceCommand using the appropriate service
  Future<VoiceCommand> parseIntent(String text) async {
    // Parse keywords immediately for instant responses
    final keywordCommand = _keywordService.parseIntent(text);
    if (keywordCommand.isValid &&
        keywordCommand.confidence >= _keywordConfidenceThreshold) {
      debugPrint('IntentRouter: keyword match accepted '
          '(confidence ${keywordCommand.confidence.toStringAsFixed(2)})');
      _lastOfflineAnnounced = false;
      return keywordCommand;
    }

    // Check network connectivity (cached)
    final isOnline = await _checkConnectivity();

    if (isOnline && _aiService.isConfigured) {
      // Online: use AI for natural language understanding
      debugPrint('IntentRouter: using AI (online)');
      _lastOfflineAnnounced = false;
      
      try {
        final command = await _aiService
            .parseIntent(text)
            .timeout(_aiTimeout, onTimeout: () {
          debugPrint('IntentRouter: AI timeout, falling back to keywords');
          return VoiceCommand.unknown(text);
        });

        // If AI returns unknown, try keyword fallback result
        if (!command.isValid) {
          debugPrint('IntentRouter: AI returned unknown, using keyword fallback');
          return keywordCommand;
        }

        return command;
      } on TimeoutException {
        debugPrint('IntentRouter: AI timed out (exception), using keyword fallback');
        return keywordCommand;
      }
    } else {
      // Offline: use keyword matching
      debugPrint('IntentRouter: using keywords (offline)');
      
      // Announce offline mode once
      if (!_lastOfflineAnnounced) {
        _lastOfflineAnnounced = true;
        onOfflineModeActivated?.call();
      }
      
      return keywordCommand;
    }
  }

  Future<bool> _checkConnectivity({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastConnectivityCheck != null &&
        now.difference(_lastConnectivityCheck!) < _connectivityCacheDuration) {
      return _lastConnectivityStatus;
    }

    try {
      final result = await _connectivity.checkConnectivity();
      final hasConnection = result.any((r) => r != ConnectivityResult.none);
      _lastConnectivityStatus = hasConnection;
      _lastConnectivityCheck = now;
      return hasConnection;
    } catch (e) {
      debugPrint('IntentRouter: connectivity check error — $e');
      _lastConnectivityStatus = false;
      _lastConnectivityCheck = now;
      return false;
    }
  }

  /// Check current connectivity status
  Future<bool> get isOnline => _checkConnectivity(force: true);

  /// Stream of connectivity changes
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any((r) => r != ConnectivityResult.none);
    });
  }
}
