import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  /// Generates a short, spoken-style description of the scene
  /// using a Prompt A–style template.
  Future<String> generateAIText(List<String> labels) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'API key not found. Please set OPENAI_API_KEY in your .env file.';
    }

    // Build the Prompt A–style instruction with the detected labels.
    final detectedList =
        labels.isEmpty ? 'none' : labels.toSet().join(', '); // de-duplicate

    final prompt = '''
You are an AI visual assistant for blind and low-vision users. Your tone is calm, clear, friendly, concise, and helpful.
You will receive a list of detected objects from the camera right now.

Detected objects: $detectedList

Rules:
- Describe the scene naturally, as if speaking to the user.
- Focus on what is most important/relevant for navigation and understanding the environment.
- Mention approximate positions only if confident (e.g., "in front of you", "to your left").
- Do not guess distances or make up things not in the list.
- Keep the response short (1–2 sentences), easy to understand when spoken.
- If nothing important is detected, say something reassuring like "Nothing notable in front of you right now."
- Never mention technical terms like "ML Kit" or "object detection".
- Do NOT ask the user to request more details, more help, or navigation help.
- Never use phrases like "let me know if you need more details" or "let me know if you want help".

Generate a spoken description right now.
''';

    const url = 'https://api.openai.com/v1/chat/completions';
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode(<String, Object>{
      'model': 'gpt-4.1-mini',
      'messages': <Map<String, String>>[
        <String, String>{
          'role': 'system',
          'content':
              'You are an AI visual assistant for blind and low-vision users. Speak clearly, calmly, and concisely.',
        },
        <String, String>{
          'role': 'user',
          'content': prompt,
        },
      ],
      'max_tokens': 100,
      'temperature': 0.7,
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      // Helpful debug output in the console so you can see exact errors
      // from the OpenAI API (including 429 rate-limit details).
      // You can remove these prints later if you want.
      // ignore: avoid_print
      print('OpenAI status: ${response.statusCode}');
      // ignore: avoid_print
      print('OpenAI body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          return 'No description generated.';
        }
        final message = (choices.first as Map<String, dynamic>)['message']
            as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        if (content == null || content.trim().isEmpty) {
          return 'No description generated.';
        }
        return content.trim();
      }

      // Try to surface a human-friendly explanation from the error response.
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        final error = errorJson['error'] as Map<String, dynamic>?;
        final message = error?['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return 'Failed to generate description (${response.statusCode}): $message';
        }
      } catch (_) {
        // If parsing fails, just fall back to generic text.
      }

      return 'Failed to generate description (${response.statusCode}).';
    } catch (e) {
      return 'Error generating description: $e';
    }
  }

  /// Returns a rich, spoken-style colour description for accessibility.
  /// Falls back to [colorName] if the API key is missing or the request fails.
  Future<String> describeColor({
    required String colorName,
    required String hex,
  }) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return colorName;
    }

    final prompt = '''
The user is blind or has low vision. They pointed their phone camera at something and the detected colour is "$colorName" (hex $hex).

Give a single, natural-sounding sentence that:
- Names the colour in plain language.
- Adds a brief, vivid comparison so the user can imagine it (e.g. "like a clear summer sky" or "similar to dark chocolate").
- Is concise — no more than 15 words.
- Does NOT start with "The colour is" or "This is".
''';

    const url = 'https://api.openai.com/v1/chat/completions';
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode(<String, Object>{
      'model': 'gpt-4.1-mini',
      'messages': <Map<String, String>>[
        <String, String>{
          'role': 'system',
          'content':
              'You are a concise colour-description assistant for blind users. '
              'Respond with exactly one short sentence.',
        },
        <String, String>{
          'role': 'user',
          'content': prompt,
        },
      ],
      'max_tokens': 40,
      'temperature': 0.7,
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = (choices.first as Map<String, dynamic>)['message']
              as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      }
      return colorName;
    } catch (_) {
      return colorName;
    }
  }
}