// lib/services/voice/natural_voice_service.dart
//
// Natural voice service using ElevenLabs API
// Provides high-quality, natural-sounding voices for accessibility
// Free tier available with generous limits

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/api_config.dart';

class NaturalVoiceService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Rachel voice ID from ElevenLabs pre-made voices
  static const String _rachelVoiceId = '21m00Tcm4TlvDq8ikWAM';

  /// Speaks text using ElevenLabs natural voice API.
  /// Throws on failure so callers can fall back to device TTS.
  static Future<void> speakWithNaturalVoice(String text) async {
    if (text.trim().isEmpty) return;

    // Generate speech — 15s timeout on the HTTP call only
    final speechResponse = await http
        .post(
          Uri.parse('${ApiConfig.elevenLabsBaseUrl}/text-to-speech/$_rachelVoiceId'),
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
        )
        .timeout(const Duration(seconds: 15));

    if (speechResponse.statusCode != 200) {
      throw Exception('ElevenLabs error ${speechResponse.statusCode}: ${speechResponse.body}');
    }

    developer.log('ElevenLabs: audio received (${speechResponse.bodyBytes.length} bytes), playing...');

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final audioFile = File('${tempDir.path}/natural_voice.mp3');
    await audioFile.writeAsBytes(speechResponse.bodyBytes);

    // Use a Completer so both natural completion and manual stop resolve it
    final completer = Completer<void>();
    final completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      developer.log('ElevenLabs: playback completed naturally');
      if (!completer.isCompleted) completer.complete();
    });
    final stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped && !completer.isCompleted) {
        developer.log('ElevenLabs: playback stopped');
        completer.complete();
      }
    });

    try {
      await _audioPlayer.play(DeviceFileSource(audioFile.path));
      await completer.future; // wait for completion or stop — no timeout here
    } finally {
      await completeSub.cancel();
      await stateSub.cancel();
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
