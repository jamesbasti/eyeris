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
          'model': ApiConfig.defaultModel,
          'messages': [
            {
              'role': 'system',
              'content': '''You are an advanced text correction and enhancement AI specialized in OCR (Optical Character Recognition) text improvement for accessibility applications. Your task is to transform messy OCR text into perfectly readable, grammatically correct text.

## CORE RESPONSIBILITIES:
1. **Word Prediction**: Predict intended words even when severely misspelled
2. **Contextual Understanding**: Use context to determine correct words
3. **OCR Error Correction**: Fix common OCR character confusions
4. **Grammar & Spelling**: Perfect grammar and spelling
5. **Semantic Coherence**: Ensure text makes logical sense
6. **Structure Preservation**: Maintain original text structure and meaning

## ADVANCED OCR CORRECTION RULES:

### Character Confusions (Fix these automatically):
- 0 → O (in words)
- 1 → l, I (in words)
- 5 → S (in words)
- 8 → B (in words)
- rn → m, m → rn
- vv → w, w → vv
- cl → d, d → cl
- ii → n, n → ii
- l1 → ll, ll → l1

### Word Prediction Examples:
- "UNlVERSlTY" → "UNIVERSITY"
- "Stldes" → "Studies" 
- "ENR0LLED" → "ENROLLED"
- "SEMESTER" → "SEMESTER"
- "C0MPUTER" → "COMPUTER"
- "Bui1cter" → "Butcher" (context-based)
- "SILLIMAN" → "SILLIMAN" (proper noun detection)
- "RACH KOLLYR" → "RACH KELLY" or "RACHEL KELLY"

### Contextual Intelligence:
- Recognize proper nouns (names, places, universities)
- Understand academic/educational context
- Fix broken words based on surrounding text
- Add missing words when context is clear
- Correct numbers and dates appropriately

### Grammar Enhancement:
- Fix all punctuation and spacing
- Ensure proper capitalization
- Correct verb tenses and sentence structure
- Maintain formal/informal tone as appropriate

## PROCESSING APPROACH:
1. Analyze the entire text for context
2. Identify OCR error patterns
3. Predict intended words using context clues
4. Apply grammar and spelling corrections
5. Ensure semantic coherence
6. Preserve original meaning and structure

## OUTPUT REQUIREMENTS:
- Return ONLY the enhanced text
- No explanations, notes, or commentary
- Perfect grammar and spelling
- Natural, readable formatting
- Maintain line breaks for structured text

## EXAMPLE TRANSFORMATIONS:
INPUT: "Bui1cter & Fath RACH KOLLYR. BONGO 21-1415 O SILLIMAN UNIVERSITS ENROLLED 2nd SEMSY 202523 College oft Computer Stldes"
OUTPUT: "Butcher & Faith RACHEL KELLY. BONGO 21-1415 SILLIMAN UNIVERSITY ENROLLED 2nd SEMESTER 2025-2026 College of Computer Studies"

INPUT: "H3llo W0RLD ca1 r3ad q1ick b3tter l3tters"
OUTPUT: "Hello World cat read quick better letters"

INPUT: "Stvdent Name: J0hn D0e Grade: A+ C0vrse: C0mpvter Science"
OUTPUT: "Student Name: John Doe Grade: A+ Course: Computer Science"
            },
            {
              'role': 'user',
              'content': '''Please enhance this OCR text using advanced word prediction and contextual analysis: "$ocrText"

## ENHANCEMENT PRIORITIES:
1. **Word Prediction**: Predict intended words from context, even with severe OCR errors
2. **Character Correction**: Fix all OCR character confusions (0→O, 1→l/I, 5→S, 8→B, rn→m, etc.)
3. **Contextual Analysis**: Use surrounding text to determine correct words
4. **Grammar Perfection**: Fix all grammar, spelling, and punctuation
5. **Semantic Coherence**: Ensure the final text makes perfect sense
6. **Structure Preservation**: Maintain original layout and meaning

## SPECIAL FOCUS:
- Recognize proper nouns (names, universities, places)
- Understand educational/academic context
- Fix broken words intelligently
- Add missing words when context is clear
- Ensure dates and numbers are correct

## EXPECTED OUTPUT:
Perfectly readable, grammatically correct text that maintains the original meaning but fixes all OCR errors and enhances readability.

Return ONLY the enhanced text with no explanations.'''
            }
          ],
          'max_tokens': ApiConfig.defaultMaxTokens,
          'temperature': 0.1, // Low temperature for consistent results
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final enhancedText = data['choices'][0]['message']['content'] as String;
        return enhancedText.trim();
      } else {
        developer.log('OpenAI API error: ${response.statusCode}');
        developer.log('Response body: ${response.body}');
        return ocrText; // Return original text if API fails
      }
    } catch (e) {
      developer.log('Text enhancement error: $e');
      return ocrText; // Return original text if enhancement fails
    }
  }

  /// Checks if API key is configured
  static bool isApiKeyConfigured() {
    return ApiConfig.isOpenaiConfigured;
  }

  /// Fallback enhancement without API (advanced text cleaning)
  static String basicEnhancement(String text) {
    if (text.trim().isEmpty) return text;
    
    // Advanced OCR corrections with context awareness
    String enhanced = text;
    
    // Character confusions (most common OCR errors)
    enhanced = enhanced
      .replaceAll(RegExp(r'(?<![0-9])0(?![0-9])'), 'O') // 0 → O in words
      .replaceAll(RegExp(r'(?<![A-Z])1(?![0-9])'), 'l') // 1 → l in words
      .replaceAll(RegExp(r'(?<![0-9])5(?![0-9])'), 'S') // 5 → S in words  
      .replaceAll(RegExp(r'(?<![0-9])8(?![0-9])'), 'B') // 8 → B in words
      .replaceAll('rn', 'm') // rn → m
      .replaceAll('vv', 'w') // vv → w
      .replaceAll('cl', 'd') // cl → d
      .replaceAll('ii', 'n') // ii → n
      .replaceAll('l1', 'll'); // l1 → ll
    
    // Common word patterns (context-aware replacements)
    final Map<String, String> commonWords = {
      'UNlVERSlTY': 'UNIVERSITY',
      'Stldes': 'Studies',
      'Stvdies': 'Studies',
      'ENR0LLED': 'ENROLLED',
      'C0MPUTER': 'COMPUTER',
      'C0MPvTER': 'COMPUTER',
      'C0MPUTER': 'COMPUTER',
      'SEMESTER': 'SEMESTER',
      'SEMESTAR': 'SEMESTER',
      'SEMESTERS': 'SEMESTERS',
      'C0LLEGE': 'COLLEGE',
      'C0LLEGE': 'COLLEGE',
      'UNIVERSITS': 'UNIVERSITY',
      'UNlVERSITY': 'UNIVERSITY',
      'SCH00L': 'SCHOOL',
      'CLASSES': 'CLASSES',
      'CLASS': 'CLASS',
      'STUDENT': 'STUDENT',
      'STVDENT': 'STUDENT',
      'GRADE': 'GRADE',
      'GRADES': 'GRADES',
      'C0VRSE': 'COURSE',
      'COURSE': 'COURSE',
      'T0PICS': 'TOPICS',
      'T0PICS': 'TOPICS',
      'ASSIGNMENT': 'ASSIGNMENT',
      'ASSIGNMENTS': 'ASSIGNMENTS',
      'PR0JECT': 'PROJECT',
      'PR0JECTS': 'PROJECTS',
      'EXAM': 'EXAM',
      'EXAMS': 'EXAMS',
      'TEST': 'TEST',
      'TESTS': 'TESTS',
      'PAPER': 'PAPER',
      'PAPERS': 'PAPERS',
      'RESEARCH': 'RESEARCH',
      'LAB0RAT0RY': 'LABORATORY',
      'LAB0RATORY': 'LABORATORY',
      'LIBRARY': 'LIBRARY',
      'LIBRARY': 'LIBRARY',
      'FACULTY': 'FACULTY',
      'PR0FESS0R': 'PROFESSOR',
      'PR0FESSOR': 'PROFESSOR',
      'TEACHER': 'TEACHER',
      'TEACHERS': 'TEACHERS',
      'DEPARTMENT': 'DEPARTMENT',
      'DEPARTMENT': 'DEPARTMENT',
      'OFFICE': 'OFFICE',
      'BUILDING': 'BUILDING',
      'BUI1DING': 'BUILDING',
      'R00M': 'ROOM',
      'CLASSR00M': 'CLASSROOM',
      'AUDIT0RIUM': 'AUDITORIUM',
      'GYMNASIUM': 'GYMNASIUM',
      'CAFETERIA': 'CAFETERIA',
      'D0RMIT0RY': 'DORMITORY',
      'CAMPUS': 'CAMPUS',
      'CAMPUSES': 'CAMPUSES',
    };
    
    // Apply common word corrections
    commonWords.forEach((wrong, correct) {
      enhanced = enhanced.replaceAll(wrong, correct);
    });
    
    // Normalize whitespace and line breaks
    enhanced = enhanced
      .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single
      .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Preserve paragraph breaks
      .replaceAll(RegExp(r'\n\s+'), '\n') // Clean line breaks
      .trim();
    
    // Advanced punctuation fixes
    enhanced = enhanced
      .replaceAll(RegExp(r'\s*\.\s*'), '. ') // Period spacing
      .replaceAll(RegExp(r'\s*,\s*'), ', ') // Comma spacing
      .replaceAll(RegExp(r'\s*!\s*'), '! ') // Exclamation spacing
      .replaceAll(RegExp(r'\s*\?\s*'), '? ') // Question spacing
      .replaceAll(RegExp(r'\s*;\s*'), '; ') // Semicolon spacing
      .replaceAll(RegExp(r'\s*:\s*'), ': ') // Colon spacing
      .replaceAll(RegExp(r'(?<!\s)\''), ' \'') // Single quote spacing
      .replaceAll(RegExp(r'\'(?!\s)'), '\' '); // Single quote spacing
    
    // Capitalization fixes
    final sentences = enhanced.split(RegExp(r'(?<=[.!?])\s+'));
    for (int i = 0; i < sentences.length; i++) {
      if (sentences[i].isNotEmpty) {
        // Capitalize first letter of each sentence
        sentences[i] = sentences[i][0].toUpperCase() + sentences[i].substring(1).toLowerCase();
        
        // Capitalize "I" when standalone
        sentences[i] = sentences[i].replaceAll(RegExp(r'\bi\b'), 'I');
        
        // Capitalize common proper nouns (basic detection)
        sentences[i] = sentences[i]
          .replaceAll(RegExp(r'\bmonday\b'), 'Monday')
          .replaceAll(RegExp(r'\btuesday\b'), 'Tuesday')
          .replaceAll(RegExp(r'\bwednesday\b'), 'Wednesday')
          .replaceAll(RegExp(r'\bthursday\b'), 'Thursday')
          .replaceAll(RegExp(r'\bfriday\b'), 'Friday')
          .replaceAll(RegExp(r'\bsaturday\b'), 'Saturday')
          .replaceAll(RegExp(r'\bsunday\b'), 'Sunday')
          .replaceAll(RegExp(r'\bjanuary\b'), 'January')
          .replaceAll(RegExp(r'\bfebruary\b'), 'February')
          .replaceAll(RegExp(r'\bmarch\b'), 'March')
          .replaceAll(RegExp(r'\bapril\b'), 'April')
          .replaceAll(RegExp(r'\bmay\b'), 'May')
          .replaceAll(RegExp(r'\bjune\b'), 'June')
          .replaceAll(RegExp(r'\bjuly\b'), 'July')
          .replaceAll(RegExp(r'\baugust\b'), 'August')
          .replaceAll(RegExp(r'\bseptember\b'), 'September')
          .replaceAll(RegExp(r'\boctober\b'), 'October')
          .replaceAll(RegExp(r'\bnovember\b'), 'November')
          .replaceAll(RegExp(r'\bdecember\b'), 'December');
      }
    }
    
    enhanced = sentences.join(' ');
    
    // Final cleanup
    enhanced = enhanced
      .replaceAll(RegExp(r'\s+'), ' ') // Final whitespace cleanup
      .trim();
    
    return enhanced;
  }
}
