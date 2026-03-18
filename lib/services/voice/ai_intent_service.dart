// lib/services/voice/ai_intent_service.dart
//
// AI-powered intent recognition using OpenAI GPT.
// Understands natural language and maps to app commands.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:eyeris/models/voice_command.dart';

/// AI-powered intent recognition using OpenAI
class AIIntentService {
  AIIntentService._();
  static final AIIntentService instance = AIIntentService._();

  static const String _systemPrompt = '''
You are a voice command interpreter for Eyeris, an accessibility app for blind and low-vision users.

Parse the user's spoken command and return ONLY valid JSON (no markdown, no explanation):
{
  "intent": "navigation" | "action" | "setting" | "unknown",
  "target": "<target name>",
  "parameters": {},
  "confidence": 0.0-1.0,
  "response": "<brief confirmation to speak aloud>"
}

Available targets:
- Navigation: read, colorDetect, sceneDescribe, communicate, back, home
- Actions: detectColor, readText, describeScene
- Settings: torch (parameters: {"state": "on" or "off"}), speechRate (parameters: {"direction": "increase" or "decrease"})

Enhanced understanding guidelines:
1. Handle natural language variations and conversational speech
2. Recognize context clues (e.g., "it's dark" → torch on)
3. Understand indirect requests (e.g., "I need to see this" → scene describe)
4. Filter out filler words and politeness expressions
5. Handle partial words and mispronunciations
6. Consider the user's likely intent based on accessibility needs

Examples:
- "scan this document" → {"intent": "navigation", "target": "read", "parameters": {}, "confidence": 0.95, "response": "Opening Read screen"}
- "what color is this" → {"intent": "navigation", "target": "colorDetect", "parameters": {}, "confidence": 0.95, "response": "Opening Color Detect"}
- "it's too dark" → {"intent": "setting", "target": "torch", "parameters": {"state": "on"}, "confidence": 0.85, "response": "Turning torch on"}
- "what am I looking at" → {"intent": "navigation", "target": "sceneDescribe", "parameters": {}, "confidence": 0.9, "response": "Opening Scene Describe"}
- "can you help me see what's around" → {"intent": "navigation", "target": "sceneDescribe", "parameters": {}, "confidence": 0.9, "response": "Opening Scene Describe"}
- "I need to read this text" → {"intent": "navigation", "target": "read", "parameters": {}, "confidence": 0.95, "response": "Opening Read screen"}
- "please tell me the color" → {"intent": "navigation", "target": "colorDetect", "parameters": {}, "confidence": 0.9, "response": "Opening Color Detect"}
- "go back" → {"intent": "navigation", "target": "back", "parameters": {}, "confidence": 1.0, "response": "Going back"}
- "speak slower" → {"intent": "setting", "target": "speechRate", "parameters": {"direction": "decrease"}, "confidence": 0.95, "response": "Speaking slower"}
- "can you turn on the light" → {"intent": "setting", "target": "torch", "parameters": {"state": "on"}, "confidence": 0.85, "response": "Turning torch on"}
- "I need help" → {"intent": "navigation", "target": "communicate", "parameters": {}, "confidence": 0.9, "response": "Opening Communicate"}

If the command is unclear or unrelated to app functions, return:
{"intent": "unknown", "target": "", "parameters": {}, "confidence": 0.0, "response": "I didn't understand that command."}
''';

  /// Parse speech text into a VoiceCommand using OpenAI
  Future<VoiceCommand> parseIntent(String text) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('AIIntent: API key not configured');
      return VoiceCommand.unknown(text);
    }

    if (text.trim().isEmpty) {
      return VoiceCommand.unknown(text);
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': 'User command: "$text"'},
          ],
          'max_tokens': 150,
          'temperature': 0.3,
        }),
      ).timeout(const Duration(milliseconds: 2500));

      if (response.statusCode != 200) {
        debugPrint('AIIntent: API error ${response.statusCode}');
        return VoiceCommand.unknown(text);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      
      if (choices == null || choices.isEmpty) {
        return VoiceCommand.unknown(text);
      }

      final message = choices.first['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null || content.isEmpty) {
        return VoiceCommand.unknown(text);
      }

      // Parse the JSON response
      return _parseJsonResponse(content, text);
    } catch (e) {
      debugPrint('AIIntent: error — $e');
      return VoiceCommand.unknown(text);
    }
  }

  VoiceCommand _parseJsonResponse(String content, String originalText) {
    try {
      // Clean up the response (remove markdown code blocks if present)
      String jsonStr = content.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'^```json?\n?'), '');
        jsonStr = jsonStr.replaceAll(RegExp(r'\n?```$'), '');
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      final intentStr = json['intent'] as String? ?? 'unknown';
      final target = json['target'] as String? ?? '';
      final parameters = json['parameters'] as Map<String, dynamic>? ?? {};
      final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;
      final response = json['response'] as String? ?? '';

      VoiceIntent intent;
      switch (intentStr) {
        case 'navigation':
          intent = VoiceIntent.navigation;
          break;
        case 'action':
          intent = VoiceIntent.action;
          break;
        case 'setting':
          intent = VoiceIntent.setting;
          break;
        default:
          intent = VoiceIntent.unknown;
      }

      return VoiceCommand(
        intent: intent,
        target: target,
        parameters: parameters,
        confidence: confidence,
        response: response,
        originalText: originalText,
      );
    } catch (e) {
      debugPrint('AIIntent: JSON parse error — $e');
      debugPrint('AIIntent: raw content — $content');
      return VoiceCommand.unknown(originalText);
    }
  }

  /// Check if the API key is configured
  bool get isConfigured {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    return apiKey != null && apiKey.isNotEmpty;
  }
}
