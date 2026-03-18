// lib/services/voice/keyword_intent_service.dart
//
// Offline keyword-based intent recognition service.
// Fast, local matching for voice commands when offline.

import 'dart:math' as math;
import 'package:eyeris/models/voice_command.dart';

/// Offline keyword-based intent recognition
class KeywordIntentService {
  KeywordIntentService._();
  static final KeywordIntentService instance = KeywordIntentService._();

  // ── KEYWORD PATTERNS ──────────────────────────────────────────────
  // Each pattern maps keywords/phrases to a target command
  
  static const Map<String, List<String>> _navigationPatterns = {
    'read': ['read', 'scan', 'document', 'text', 'ocr', 'scan this', 'read this', 'what does this say', 'scan document', 'read text', 'ocr scan'],
    'colorDetect': ['color', 'colour', 'what color', 'identify color', 'color detect', 'check color', 'detect color', 'what colour', 'colour detection'],
    'sceneDescribe': ['describe', 'scene', 'what is this', 'looking at', 'what do you see', 'what is in front', 'describe scene', 'what am i looking at', 'describe this', 'what\'s around me', 'what\'s in front of me'],
    'communicate': ['call', 'message', 'communicate', 'contact', 'phone', 'send message', 'make call', 'emergency', 'help', 'sos'],
    'back': ['back', 'go back', 'previous', 'return', 'go back to previous', 'return to previous'],
    'home': ['home', 'main', 'start', 'menu', 'main menu', 'go home', 'back to home', 'start screen'],
  };

  static const Map<String, List<String>> _actionPatterns = {
    'detectColor': ['detect color', 'detect the color', 'what color is this', 'identify this color', 'check the color', 'tell me the color', 'what\'s the color'],
    'readText': ['read this', 'read text', 'scan this', 'what does this say', 'what\'s written', 'read the text', 'scan text', 'what does it say'],
    'describeScene': ['describe this', 'what is this', 'what do you see', 'describe scene', 'tell me what you see', 'what\'s around', 'describe what\'s here'],
  };

  static const Map<String, Map<String, List<String>>> _settingPatterns = {
    'torch': {
      'on': ['torch on', 'light on', 'flashlight on', 'turn on light', 'turn on torch', 'turn on flashlight', 'bright', 'too dark', 'it\'s dark', 'need light', 'can\'t see'],
      'off': ['torch off', 'light off', 'flashlight off', 'turn off light', 'turn off torch', 'turn off flashlight', 'too bright', 'lights off'],
    },
    'speechRate': {
      'increase': ['faster', 'speed up', 'quicker', 'speak faster', 'talk faster', 'too slow', 'increase speed'],
      'decrease': ['slower', 'speed down', 'slow down', 'speak slower', 'talk slower', 'too fast', 'decrease speed'],
    },
  };

  /// Parse speech text into a VoiceCommand using enhanced keyword matching
  VoiceCommand parseIntent(String text) {
    final normalized = text.toLowerCase().trim();
    
    if (normalized.isEmpty) {
      return VoiceCommand.unknown(text);
    }

    // Pre-process: remove common filler words
    final cleaned = _removeFillerWords(normalized);
    
    // Try settings first (more specific patterns)
    final settingCommand = _matchSetting(cleaned, text);
    if (settingCommand != null) return settingCommand;

    // Try actions (specific action triggers)
    final actionCommand = _matchAction(cleaned, text);
    if (actionCommand != null) return actionCommand;

    // Try navigation (screen navigation)
    final navCommand = _matchNavigation(cleaned, text);
    if (navCommand != null) return navCommand;

    // Try fuzzy matching for close matches
    final fuzzyCommand = _fuzzyMatch(cleaned, text);
    if (fuzzyCommand != null) return fuzzyCommand;

    // No match found
    return VoiceCommand.unknown(text);
  }

  /// Remove common filler words that don't add meaning
  String _removeFillerWords(String text) {
    final fillerWords = {
      'please', 'can you', 'could you', 'would you', 'hey', 'um', 'uh', 'like', 
      'actually', 'really', 'just', 'maybe', 'perhaps', 'i want to', 'i need to',
      'can i', 'could i', 'i would like to', 'let me', 'help me'
    };
    
    String result = text;
    for (final filler in fillerWords) {
      result = result.replaceAll(filler, '');
    }
    
    // Clean up extra spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    return result;
  }

  /// Fuzzy matching for close keyword matches
  VoiceCommand? _fuzzyMatch(String normalized, String original) {
    // Try partial word matching for longer phrases
    final words = normalized.split(' ');
    
    // Check if any word closely matches a keyword
    for (final word in words) {
      if (word.length < 3) continue; // Skip very short words
      
      // Check navigation patterns
      for (final entry in _navigationPatterns.entries) {
        for (final keyword in entry.value) {
          if (_isFuzzyMatch(word, keyword)) {
            final response = _getNavigationResponse(entry.key);
            return VoiceCommand(
              intent: VoiceIntent.navigation,
              target: entry.key,
              confidence: 0.7, // Lower confidence for fuzzy matches
              response: response,
              originalText: original,
            );
          }
        }
      }
    }
    
    return null;
  }

  /// Check if two strings are fuzzy matches (similar but not exact)
  bool _isFuzzyMatch(String a, String b) {
    // Simple fuzzy matching: check if one contains the other or they're very similar
    if (a.contains(b) || b.contains(a)) return true;
    
    // Check Levenshtein distance for close matches
    final distance = _levenshteinDistance(a, b);
    final maxLength = math.max(a.length, b.length);
    final similarity = 1.0 - (distance / maxLength);
    
    return similarity > 0.7; // 70% similarity threshold
  }

  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = math.min(
          math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
          matrix[i - 1][j - 1] + cost,
        );
      }
    }

    return matrix[a.length][b.length];
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
