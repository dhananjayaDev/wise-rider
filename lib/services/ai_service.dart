
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<String> getTripAdvice(String start, String end, String duration, String weather) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null) return "AI Configuration Error: Missing API Key.";

    final prompt = "Motorcycle trip from $start to $end ($duration). Weather report: $weather. Based on this, provide 3 critical safety tips. If a specific location has rain/bad weather, mention it by name. Keep tips concise (under 15 words). Bullet points only.";

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'openai/gpt-oss-120b', 
          'messages': [
            {'role': 'user', 'content': prompt}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
// print('AI Error: ${response.body}');
        return "Advice currently unavailable (API Error).";
      }
    } catch (e) {
// print('AI Exception: $e');
      return "Advice currently unavailable.";
    }
  }
}
