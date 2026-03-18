import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  /// Generates an enhanced AI description of the scene with context awareness
  Future<String> generateAIText(List<String> labels, {bool isTorchOn = false}) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'API key not found. Please set OPENAI_API_KEY in your .env file.';
    }

    // Build enhanced prompt with context
    final detectedList =
        labels.isEmpty ? 'none' : labels.toSet().join(', '); // de-duplicate
    
    final currentTime = DateTime.now();
    final hour = currentTime.hour;
    final timeContext = hour >= 6 && hour < 18 ? 'daytime' : 
                       hour >= 18 && hour < 22 ? 'evening' : 'night';
    final lightingContext = isTorchOn ? 'with flashlight on' : 'in ambient lighting';

    final prompt = '''
You are an AI visual assistant for blind and low-vision users. Your tone is calm, clear, friendly, and helpful.

Current context: $timeContext, $lightingContext
Detected objects: $detectedList

Enhanced Guidelines:
1. Create a vivid but concise mental picture (1-2 sentences)
2. Infer the most likely scene type (indoor/outdoor, room type, street, etc.)
3. Describe spatial relationships and layout when evident
4. Mention important objects for navigation/safety
5. Note potential obstacles or points of interest
6. Consider the time of day in your description
7. If torch is on, assume low light conditions
8. Group related objects naturally (e.g., "kitchen counter with appliances")
9. Use directional language sparingly and only when confident
10. If nothing significant is detected, provide a reassuring context
11. Never use phrases like "feel free to ask", "let me know", or offer additional help

Examples:
- "You're in what appears to be a kitchen with a counter and appliances to your right"
- "A street scene with buildings and what looks like a sidewalk in front of you"
- "An indoor space with a table and chairs, possibly a dining area"

Generate a helpful, natural description right now.
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

  /// Returns a rich, spoken-style description for multiple detected colours.
  /// Includes spatial context (positions) and percentages for accessibility.
  /// Falls back to a simple description if the API key is missing or request fails.
  Future<String> describeColors({
    required String dominantColor,
    required String dominantHex,
    required double dominantPercentage,
    required List<(String name, String hex, double percentage, String position)> secondaryColors,
  }) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    
    // Build fallback description
    final fallback = _buildFallbackDescription(
      dominantColor, dominantPercentage, secondaryColors);
    
    if (apiKey == null || apiKey.isEmpty) {
      return fallback;
    }

    // Build color info for prompt
    final colorInfo = StringBuffer();
    colorInfo.writeln('Dominant colour: $dominantColor ($dominantHex) - ${dominantPercentage.round()}% of the view');
    
    if (secondaryColors.isNotEmpty) {
      colorInfo.writeln('Secondary colours:');
      for (final (name, hex, pct, pos) in secondaryColors) {
        colorInfo.writeln('  - $name ($hex): ${pct.round()}%, located at $pos');
      }
    }

    final prompt = '''
The user is blind or has low vision. They pointed their phone camera at something and detected these colours:

$colorInfo

Generate a natural, spoken description that:
- Describes the overall colour composition in plain language
- If multiple colours, describe the pattern or relationship (e.g., "striped", "checkered", "gradient", "with accents")
- Adds a brief, vivid comparison when helpful (e.g., "like a sunset", "similar to a coffee with cream")
- Mentions spatial relationships if relevant (e.g., "blue on top, white below")
- Is concise — no more than 20 words
- Does NOT start with "The colour is" or "This is" or "I see"
- Sounds natural when spoken aloud
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
              'Describe colour combinations naturally and vividly. '
              'Respond with exactly one short sentence.',
        },
        <String, String>{
          'role': 'user',
          'content': prompt,
        },
      ],
      'max_tokens': 60,
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
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// Builds a fallback description when AI is unavailable
  String _buildFallbackDescription(
    String dominantColor,
    double dominantPercentage,
    List<(String name, String hex, double percentage, String position)> secondaryColors,
  ) {
    if (secondaryColors.isEmpty) {
      return dominantColor;
    }
    
    if (dominantPercentage >= 80) {
      // Mostly one color
      final accent = secondaryColors.first.$1;
      return 'Mostly $dominantColor with a touch of $accent';
    } else if (dominantPercentage >= 60) {
      // Dominant with accents
      final accents = secondaryColors.map((c) => c.$1).join(' and ');
      return '$dominantColor with $accents accents';
    } else {
      // Mixed colors
      final others = secondaryColors.map((c) => c.$1).join(', ');
      return '$dominantColor and $others';
    }
  }

  /// Analyzes an image using OpenAI Vision API for rich scene description
  Future<String> analyzeImage(File imageFile, {bool isTorchOn = false}) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'API key not found. Please set OPENAI_API_KEY in your .env file.';
    }

    try {
      // Read image file and convert to base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      // Get image format
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = extension == 'jpg' || extension == 'jpeg' 
          ? 'image/jpeg' 
          : extension == 'png' 
              ? 'image/png' 
              : 'image/jpeg'; // default to jpeg

      final currentTime = DateTime.now();
      final hour = currentTime.hour;
      final timeContext = hour >= 6 && hour < 18 ? 'daytime' : 
                         hour >= 18 && hour < 22 ? 'evening' : 'night';
      final lightingContext = isTorchOn ? 'with flashlight on' : 'in ambient lighting';

      final prompt = '''
You are an AI visual assistant for blind and low-vision users. Your tone is calm, clear, friendly, and helpful.

Current context: $timeContext, $lightingContext

Analyze this image and provide a vivid, concise description of what the user is seeing right now.

Enhanced Guidelines:
1. Create a vivid but concise mental picture (1-2 sentences)
2. Infer the most likely scene type (indoor/outdoor, room type, street, etc.)
3. Describe spatial relationships and layout when evident
4. Mention important objects for navigation/safety
5. Note potential obstacles or points of interest
6. Consider the time of day in your description
7. If torch is on, assume low light conditions
8. Group related objects naturally (e.g., "kitchen counter with appliances")
9. Use directional language sparingly and only when confident
10. If nothing significant is detected, provide a reassuring context
11. Never use phrases like "feel free to ask", "let me know", or offer additional help

Examples:
- "You're in what appears to be a kitchen with a counter and appliances to your right"
- "A street scene with buildings and what looks like a sidewalk in front of you"
- "An indoor space with a table and chairs, possibly a dining area"

Generate a helpful, natural description right now.
''';

      const url = 'https://api.openai.com/v1/chat/completions';
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };
      
      final body = jsonEncode(<String, Object>{
        'model': 'gpt-4o', // Using GPT-4o for vision capabilities
        'messages': <Map<String, dynamic>>[
          <String, dynamic>{
            'role': 'system',
            'content': 'You are an AI visual assistant for blind and low-vision users. Speak clearly, calmly, and concisely.',
          },
          <String, dynamic>{
            'role': 'user',
            'content': <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'text',
                'text': prompt,
              },
              <String, dynamic>{
                'type': 'image_url',
                'image_url': <String, String>{
                  'url': 'data:$mimeType;base64,$base64Image',
                },
              },
            ],
          },
        ],
        'max_tokens': 150,
        'temperature': 0.7,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      // Debug output
      // ignore: avoid_print
      print('OpenAI Vision status: ${response.statusCode}');
      
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
          return 'Failed to analyze image (${response.statusCode}): $message';
        }
      } catch (_) {
        // If parsing fails, just fall back to generic text.
      }

      return 'Failed to analyze image (${response.statusCode}).';
    } catch (e) {
      return 'Error analyzing image: $e';
    }
  }
}