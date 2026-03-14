// lib/services/vision/text_enhancement_service.dart
//
// Text enhancement service using OpenAI API
// Improves OCR results by correcting spelling, grammar, and formatting
// Used after initial text recognition for better readability

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class TextEnhancementService {
  
  /// Enhances OCR text using OpenAI API
  /// Returns improved text with better spelling, grammar, and formatting
  static Future<String> enhanceText(String ocrText) async {
    if (ocrText.trim().isEmpty) {
      return ocrText;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.openaiChatEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openaiApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''You are an expert text correction AI specializing in OCR text improvement. Your task is to transform messy OCR text into perfectly readable, grammatically correct, and contextually accurate text.

## CORRECTION PRIORITIES:
1. **Grammar Perfection**: Fix all grammar errors, verb tenses, sentence structure
2. **Context Validation**: Ensure words make sense in context (e.g., "warning" not "warming")
3. **Spelling Correction**: Fix all spelling mistakes completely
4. **OCR Error Fixing**: Correct character confusions (0→O, 1→l, 5→S, 8→B, rn→m, vv→w)
5. **Semantic Coherence**: Ensure the text makes logical sense
6. **Proper Formatting**: Fix punctuation, capitalization, spacing

## CONTEXTUAL INTELLIGENCE:
- Analyze surrounding words to determine correct meaning
- Validate word choices against context (e.g., weather vs warning)
- Ensure proper terminology for the subject matter
- Fix broken sentences and add missing words
- Maintain original meaning while improving clarity

## EXAMPLES:
- "The warming system was activated" → "The warning system was activated"
- "Warming about the storm" → "Warning about the storm"
- "The weather is warming" → "The weather is warming" (correct in weather context)
- "Computer stldies class" → "Computer studies class"
- "Please be carefu1 with the equipment" → "Please be careful with the equipment"

## OUTPUT REQUIREMENTS:
- Return ONLY the perfectly corrected text
- No explanations, notes, or commentary
- Perfect grammar, spelling, and context
- Natural, readable formatting
- Maintain original meaning and structure

Analyze the full context and ensure every word is contextually appropriate.'''
            },
            {
              'role': 'user',
              'content': 'Please enhance this OCR text with expert-level correction: "$ocrText"\n\nFocus on:\n1. Grammar perfection and sentence structure\n2. Context validation (ensure words make sense in context)\n3. Spelling correction and OCR error fixing\n4. Semantic coherence and logical flow\n5. Proper punctuation and formatting\n\nAnalyze the full context to distinguish between similar words (e.g., warning vs warming, weather vs whether) and choose the correct one based on meaning. Return ONLY the perfectly corrected text.'
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final enhancedText = data['choices'][0]['message']['content'] as String;
        return enhancedText.trim();
      } else {
        developer.log('OpenAI API error: ${response.statusCode}');
        return ocrText;
      }
    } catch (e) {
      developer.log('Text enhancement error: $e');
      return ocrText;
    }
  }

  /// Checks if API key is configured
  static bool isApiKeyConfigured() {
    return ApiConfig.isOpenaiConfigured;
  }

  /// Fallback enhancement without API (basic text cleaning)
  static String basicEnhancement(String text) {
    if (text.trim().isEmpty) return text;
    
    String enhanced = text
      .replaceAll(RegExp(r'(?<![0-9])0(?![0-9])'), 'O')
      .replaceAll(RegExp(r'(?<![A-Z])1(?![0-9])'), 'l')
      .replaceAll(RegExp(r'(?<![0-9])5(?![0-9])'), 'S')
      .replaceAll(RegExp(r'(?<![0-9])8(?![0-9])'), 'B')
      .replaceAll('rn', 'm')
      .replaceAll('vv', 'w')
      .replaceAll('UNlVERSlTY', 'UNIVERSITY')
      .replaceAll('Stldes', 'Studies')
      .replaceAll('ENR0LLED', 'ENROLLED')
      .replaceAll('C0MPUTER', 'COMPUTER')
      .replaceAll('SEMESTER', 'SEMESTER')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
    
    // Capitalize first letter
    if (enhanced.isNotEmpty) {
      enhanced = enhanced[0].toUpperCase() + enhanced.substring(1);
    }
    
    return enhanced;
  }
}
