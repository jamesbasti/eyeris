// lib/config/api_config.dart
//
// API configuration for external services
// Store your API keys here for OpenAI and other services

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // OpenAI API Key
  // Get your key from: https://platform.openai.com/api-keys
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  
  // ElevenLabs API Key (Free natural voices)
  // Get your key from: https://elevenlabs.io/app/settings/api-keys
  // Free tier: 10,000 characters per month
  static String get elevenLabsApiKey => dotenv.env['ELEVENLABS_API_KEY'] ?? '';
  
  // Check if API keys are configured
  static bool get isOpenaiConfigured => openaiApiKey.isNotEmpty;
  static bool get isElevenLabsConfigured => elevenLabsApiKey.isNotEmpty;
  
  // API endpoints
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String openaiChatEndpoint = '$openaiBaseUrl/chat/completions';
  static const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';
  
  // Model settings
  static const String defaultModel = 'gpt-3.5-turbo';
  static const double defaultTemperature = 0.1;
  static const int defaultMaxTokens = 500;
  
  // Voice settings
  static const String defaultVoiceId = 'rachel'; // Natural female voice
  static const double voiceStability = 0.75;
  static const double voiceSimilarityBoost = 0.75;
}
