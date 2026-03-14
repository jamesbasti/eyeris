// lib/services/voice/natural_voice_service.dart
//
// Natural voice service using ElevenLabs API
// Provides high-quality, natural-sounding voices for accessibility
// Free tier available with generous limits

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/api_config.dart';

class NaturalVoiceService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  
  /// Speaks text using ElevenLabs natural voice API
  /// Downloads and plays natural voice audio
  static Future<void> speakWithNaturalVoice(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    try {
      // Get available voices
      final voicesResponse = await http.get(
        Uri.parse('${ApiConfig.elevenLabsBaseUrl}/voices'),
        headers: {
          'xi-api-key': ApiConfig.elevenLabsApiKey,
        },
      );

      if (voicesResponse.statusCode != 200) {
        developer.log('Failed to get voices: ${voicesResponse.statusCode}');
        return;
      }

      final voicesData = jsonDecode(voicesResponse.body);
      final voices = voicesData['voices'] as List;
      
      // Choose a good voice for accessibility
      String selectedVoiceId = ApiConfig.defaultVoiceId;
      for (var voice in voices) {
        if (voice['name'].toString().toLowerCase().contains('rachel') ||
            voice['name'].toString().toLowerCase().contains('sam') ||
            voice['name'].toString().toLowerCase().contains('domi')) {
          selectedVoiceId = voice['voice_id'];
          break;
        }
      }

      // Generate speech
      final speechResponse = await http.post(
        Uri.parse('${ApiConfig.elevenLabsBaseUrl}/text-to-speech/$selectedVoiceId'),
        headers: {
          'xi-api-key': ApiConfig.elevenLabsApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': ApiConfig.voiceStability,
            'similarity_boost': ApiConfig.voiceSimilarityBoost,
            'style': 0.0,
            'use_speaker_boost': true,
          },
        }),
      );

      if (speechResponse.statusCode == 200) {
        // Save audio to temporary file
        final tempDir = await getTemporaryDirectory();
        final audioFile = File('${tempDir.path}/natural_voice.mp3');
        await audioFile.writeAsBytes(speechResponse.bodyBytes);
        
        // Play the audio file
        await _audioPlayer.play(DeviceFileSource(audioFile.path));
      } else {
        developer.log('ElevenLabs API error: ${speechResponse.statusCode}');
        developer.log('Response body: ${speechResponse.body}');
      }
    } catch (e) {
      developer.log('Natural voice error: $e');
    }
  }

  /// Stops any playing audio
  static Future<void> stop() async {
    await _audioPlayer.stop();
  }

  /// Checks if ElevenLabs API key is configured
  static bool isApiKeyConfigured() {
    return ApiConfig.isElevenLabsConfigured;
  }

  /// Gets list of available voices
  static Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.elevenLabsBaseUrl}/voices'),
        headers: {
          'xi-api-key': ApiConfig.elevenLabsApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['voices']);
      }
      return [];
    } catch (e) {
      developer.log('Error getting voices: $e');
      return [];
    }
  }
}
