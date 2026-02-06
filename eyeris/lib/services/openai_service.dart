import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  Future<String> generateAIText(List<String> labels) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      return 'API key not found';
    }

    final prompt = 'Describe the following objects in the environment: ${labels.join(", ")}';
    const url = 'https://api.openai.com/v1/completions';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      'model': 'text-davinci-003',
      'prompt': prompt,
      'max_tokens': 100,
      'temperature': 0.7,
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['text'].trim();
      } else {
        return 'Failed to generate text: ${response.body}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}