// lib/services/voice/voice_control_manager.dart
//
// Voice control manager that coordinates speech recognition,
// intent parsing, and command execution.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:eyeris/models/voice_command.dart';
import 'package:eyeris/services/voice/speech_recognition_service.dart';
import 'package:eyeris/services/voice/intent_router.dart';
import 'package:eyeris/services/voice/audio_feedback_service.dart';

/// Voice control states
enum VoiceControlState {
  idle,
  listening,
  processing,
  executing,
}

/// Voice control manager - coordinates the entire voice control flow
class VoiceControlManager {
  VoiceControlManager._();
  static final VoiceControlManager instance = VoiceControlManager._();

  final SpeechRecognitionService _speech = SpeechRecognitionService.instance;
  final IntentRouter _intentRouter = IntentRouter.instance;
  final AudioFeedbackService _audio = AudioFeedbackService.instance;

  VoiceControlState _state = VoiceControlState.idle;
  String _lastTranscript = '';
  VoiceCommand? _lastCommand;
  bool _isInitialized = false;
  bool _speechAvailable = false;

  // ── Callbacks ──────────────────────────────────────────────────────
  
  /// Called when state changes
  void Function(VoiceControlState)? onStateChanged;

  /// Called when a command is recognized and ready to execute
  void Function(VoiceCommand)? onCommandRecognized;

  /// Called for navigation commands
  void Function(NavigationTarget)? onNavigate;

  /// Called for action commands
  void Function(ActionTarget)? onAction;

  /// Called for setting commands
  void Function(SettingTarget, Map<String, dynamic>)? onSetting;

  /// Called when an error occurs
  void Function(String)? onError;

  // ── Getters ────────────────────────────────────────────────────────

  VoiceControlState get state => _state;
  String get lastTranscript => _lastTranscript;
  VoiceCommand? get lastCommand => _lastCommand;
  bool get isListening => _state == VoiceControlState.listening;

  // ── Initialization ─────────────────────────────────────────────────

  Future<bool> initialize() async {
    if (_isInitialized) return _speechAvailable;

    await _audio.initialize();

    // Set up offline mode announcement
    _intentRouter.onOfflineModeActivated = () {
      _audio.speak('Offline mode. Using basic commands.');
    };

    // Set up speech recognition callbacks
    _speech.onResult = _onSpeechResult;
    _speech.onError = _onSpeechError;
    _speech.onListeningChanged = (listening) {
      if (!listening && _state == VoiceControlState.listening) {
        // Speech recognition stopped on its own
        _setState(VoiceControlState.processing);
      }
    };

    // Mark as initialized (audio + callbacks ready)
    _isInitialized = true;

    // DISABLED: speech_to_text native init still crashes on iOS 26 even with Flutter 3.41.4
    // The crash occurs in iOS speech recognition framework during background thread init
    debugPrint('VoiceControl: initialized (speech recognition disabled for iOS 26)');
    _speechAvailable = false;
    return false;
  }

  // ── Control Methods ────────────────────────────────────────────────

  /// Start listening for voice commands (call on press)
  Future<void> startListening() async {
    if (!_isInitialized) {
      debugPrint('VoiceControl: not initialized, ignoring startListening');
      return;
    }
    if (!_speechAvailable) {
      // Speech disabled on iOS 26 — give one-time TTS feedback
      debugPrint('VoiceControl: speech not available on this device');
      await _audio.speak('Voice commands temporarily unavailable.');
      return;
    }
    if (_state != VoiceControlState.idle) {
      debugPrint('VoiceControl: cannot start, state is $_state');
      return;
    }

    _setState(VoiceControlState.listening);
    _lastTranscript = '';
    _lastCommand = null;

    await _audio.playFeedback(FeedbackType.listeningStart);

    final started = await _speech.startListening(
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
    );

    if (!started) {
      _setState(VoiceControlState.idle);
      await _audio.playFeedback(FeedbackType.error);
      await _audio.speak('Could not start listening. Please try again.');
      onError?.call('Failed to start speech recognition');
    }
  }

  /// Stop listening and process the command (call on release)
  Future<void> stopListening() async {
    if (_state != VoiceControlState.listening) {
      return;
    }

    await _speech.stopListening();
    await _audio.playFeedback(FeedbackType.listeningStop);

    // If we have a transcript, process it
    if (_lastTranscript.isNotEmpty) {
      await _processTranscript(_lastTranscript);
    } else {
      _setState(VoiceControlState.idle);
      await _audio.speak('No speech detected. Please try again.');
    }
  }

  /// Cancel listening without processing
  Future<void> cancelListening() async {
    if (_state == VoiceControlState.listening) {
      await _speech.cancelListening();
      _setState(VoiceControlState.idle);
    }
  }

  // ── Private Methods ────────────────────────────────────────────────

  void _setState(VoiceControlState newState) {
    if (_state != newState) {
      _state = newState;
      onStateChanged?.call(newState);
      debugPrint('VoiceControl: state changed to $newState');
    }
  }

  void _onSpeechResult(SpeechResult result) {
    _lastTranscript = result.text;
    debugPrint('VoiceControl: transcript — "${result.text}" (final: ${result.isFinal})');

    // If this is a final result, process immediately
    if (result.isFinal && result.text.isNotEmpty) {
      _processTranscript(result.text);
    }
  }

  void _onSpeechError(String error) {
    debugPrint('VoiceControl: speech error — $error');
    _setState(VoiceControlState.idle);
    onError?.call(error);
  }

  Future<void> _processTranscript(String transcript) async {
    _setState(VoiceControlState.processing);

    try {
      // Parse intent using hybrid router (AI online, keywords offline)
      final command = await _intentRouter.parseIntent(transcript);
      _lastCommand = command;

      debugPrint('VoiceControl: command — $command');

      if (command.isValid) {
        await _executeCommand(command);
      } else {
        await _audio.playFeedback(FeedbackType.error);
        await _audio.speak(command.response.isNotEmpty 
            ? command.response 
            : "I didn't understand that command.");
        _setState(VoiceControlState.idle);
      }
    } catch (e) {
      debugPrint('VoiceControl: processing error — $e');
      await _audio.playFeedback(FeedbackType.error);
      await _audio.speak('Something went wrong. Please try again.');
      _setState(VoiceControlState.idle);
      onError?.call(e.toString());
    }
  }

  Future<void> _executeCommand(VoiceCommand command) async {
    _setState(VoiceControlState.executing);

    // Play success feedback (don't await - run in background)
    _audio.playFeedback(FeedbackType.success);

    // Notify listeners immediately for fast response
    onCommandRecognized?.call(command);

    // Execute based on intent type
    switch (command.intent) {
      case VoiceIntent.navigation:
        final target = command.navigationTarget;
        if (target != null) {
          onNavigate?.call(target);
        }
        break;

      case VoiceIntent.action:
        final target = command.actionTarget;
        if (target != null) {
          onAction?.call(target);
        }
        break;

      case VoiceIntent.setting:
        final target = command.settingTarget;
        if (target != null) {
          onSetting?.call(target, command.parameters);
          
          // Handle speech rate changes internally
          if (target == SettingTarget.speechRate) {
            final direction = command.speechRateDirection;
            if (direction == 'increase') {
              await _audio.increaseSpeechRate();
            } else if (direction == 'decrease') {
              await _audio.decreaseSpeechRate();
            }
          }
        }
        break;

      case VoiceIntent.unknown:
        // Already handled above
        break;
    }

    // Speak confirmation after action is triggered (non-blocking)
    if (command.response.isNotEmpty) {
      _audio.speak(command.response);
    }

    _setState(VoiceControlState.idle);
  }

  /// Dispose resources
  void dispose() {
    _speech.dispose();
    _audio.dispose();
  }
}
