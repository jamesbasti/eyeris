// lib/services/voice/keyword_intent_service.dart
//
// Offline keyword-based intent recognition service.
// Fast, local matching for voice commands when offline.

import 'package:eyeris/models/voice_command.dart';

/// Offline keyword-based intent recognition
class KeywordIntentService {
  KeywordIntentService._();
  static final KeywordIntentService instance = KeywordIntentService._();

  // ── KEYWORD PATTERNS ──────────────────────────────────────────────
  // Each pattern maps keywords/phrases to a target command
  
  static const Map<String, List<String>> _navigationPatterns = {
    'read': ['read', 'scan', 'document', 'text', 'ocr', 'scan this'],
    'colorDetect': ['color', 'colour', 'what color', 'identify color', 'color detect'],
    'sceneDescribe': ['describe', 'scene', 'what is this', 'looking at', 'what do you see', 'what is in front'],
    'communicate': ['call', 'message', 'communicate', 'contact', 'phone'],
    'back': ['back', 'go back', 'previous', 'return'],
    'home': ['home', 'main', 'start', 'menu', 'main menu'],
  };

  static const Map<String, List<String>> _actionPatterns = {
    'detectColor': ['detect color', 'detect the color', 'what color is this', 'identify this color'],
    'readText': ['read this', 'read text', 'scan this', 'what does this say'],
    'describeScene': ['describe this', 'what is this', 'what do you see', 'describe scene'],
  };

  static const Map<String, Map<String, List<String>>> _settingPatterns = {
    'torch': {
      'on': ['torch on', 'light on', 'flashlight on', 'turn on light', 'turn on torch', 'turn on flashlight', 'bright', 'too dark'],
      'off': ['torch off', 'light off', 'flashlight off', 'turn off light', 'turn off torch', 'turn off flashlight'],
    },
    'speechRate': {
      'increase': ['faster', 'speed up', 'quicker', 'speak faster', 'talk faster'],
      'decrease': ['slower', 'speed down', 'slow down', 'speak slower', 'talk slower'],
    },
  };

  /// Parse speech text into a VoiceCommand using keyword matching
  VoiceCommand parseIntent(String text) {
    final normalized = text.toLowerCase().trim();
    
    if (normalized.isEmpty) {
      return VoiceCommand.unknown(text);
    }

    // Try settings first (more specific patterns)
    final settingCommand = _matchSetting(normalized, text);
    if (settingCommand != null) return settingCommand;

    // Try actions (specific action triggers)
    final actionCommand = _matchAction(normalized, text);
    if (actionCommand != null) return actionCommand;

    // Try navigation (screen navigation)
    final navCommand = _matchNavigation(normalized, text);
    if (navCommand != null) return navCommand;

    // No match found
    return VoiceCommand.unknown(text);
  }

  VoiceCommand? _matchNavigation(String normalized, String original) {
    for (final entry in _navigationPatterns.entries) {
      final target = entry.key;
      final keywords = entry.value;
      
      for (final keyword in keywords) {
        if (normalized.contains(keyword)) {
          final response = _getNavigationResponse(target);
          return VoiceCommand(
            intent: VoiceIntent.navigation,
            target: target,
            confidence: _calculateConfidence(normalized, keyword),
            response: response,
            originalText: original,
          );
        }
      }
    }
    return null;
  }

  VoiceCommand? _matchAction(String normalized, String original) {
    for (final entry in _actionPatterns.entries) {
      final target = entry.key;
      final keywords = entry.value;
      
      for (final keyword in keywords) {
        if (normalized.contains(keyword)) {
          final response = _getActionResponse(target);
          return VoiceCommand(
            intent: VoiceIntent.action,
            target: target,
            confidence: _calculateConfidence(normalized, keyword),
            response: response,
            originalText: original,
          );
        }
      }
    }
    return null;
  }

  VoiceCommand? _matchSetting(String normalized, String original) {
    for (final settingEntry in _settingPatterns.entries) {
      final target = settingEntry.key;
      final statePatterns = settingEntry.value;
      
      for (final stateEntry in statePatterns.entries) {
        final state = stateEntry.key;
        final keywords = stateEntry.value;
        
        for (final keyword in keywords) {
          if (normalized.contains(keyword)) {
            final response = _getSettingResponse(target, state);
            return VoiceCommand(
              intent: VoiceIntent.setting,
              target: target,
              parameters: {
                if (target == 'torch') 'state': state,
                if (target == 'speechRate') 'direction': state,
              },
              confidence: _calculateConfidence(normalized, keyword),
              response: response,
              originalText: original,
            );
          }
        }
      }
    }
    return null;
  }

  double _calculateConfidence(String text, String keyword) {
    // Higher confidence for exact matches or longer keyword matches
    if (text == keyword) return 1.0;
    if (text.startsWith(keyword) || text.endsWith(keyword)) return 0.9;
    
    // Confidence based on keyword length relative to text
    final ratio = keyword.length / text.length;
    return (0.6 + ratio * 0.3).clamp(0.5, 0.95);
  }

  String _getNavigationResponse(String target) {
    switch (target) {
      case 'read': return 'Opening Read screen';
      case 'colorDetect': return 'Opening Color Detect';
      case 'sceneDescribe': return 'Opening Scene Describe';
      case 'communicate': return 'Opening Communicate';
      case 'back': return 'Going back';
      case 'home': return 'Going home';
      default: return 'Navigating';
    }
  }

  String _getActionResponse(String target) {
    switch (target) {
      case 'detectColor': return 'Detecting color';
      case 'readText': return 'Reading text';
      case 'describeScene': return 'Describing scene';
      default: return 'Executing action';
    }
  }

  String _getSettingResponse(String target, String state) {
    switch (target) {
      case 'torch':
        return state == 'on' ? 'Turning torch on' : 'Turning torch off';
      case 'speechRate':
        return state == 'increase' ? 'Speaking faster' : 'Speaking slower';
      default:
        return 'Changing setting';
    }
  }
}
