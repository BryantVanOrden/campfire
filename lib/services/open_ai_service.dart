import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey =
      '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'; // Keep your API key secure

  Future<List<String>> getSortedEventIds({
    required Map<String, dynamic> user,
    required List<Map<String, dynamic>> events,
  }) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content":
              "You are an assistant that helps users find events based on their interests."
        },
        {"role": "user", "content": _generatePrompt(user, events)}
      ],
      "max_tokens": 200,
      "temperature": 0.7,
    });

    print('OpenAI Request Body: $body');

    final response = await http.post(url, headers: headers, body: body);

    print('OpenAI Response Status: ${response.statusCode}');
    print('OpenAI Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final assistantMessage = responseData['choices'][0]['message']['content'];
      return _extractEventIds(assistantMessage);
    } else {
      print('OpenAI API Error: ${response.body}');
      throw Exception('Failed to fetch sorted event IDs');
    }
  }

  String _generatePrompt(
      Map<String, dynamic> user, List<Map<String, dynamic>> events) {
    String userInterests = (user['interests'] as List<dynamic>).join('", "');
    String prompt = '''
User Interests: "$userInterests"

Here are some events:
''';

    for (int i = 0; i < events.length; i++) {
      prompt += '''
Event ${i + 1}:
- Event ID: ${events[i]['id']}
- Name: ${events[i]['name']}
- Details: ${events[i]['description']}
''';
    }

    prompt += '''
Please return a JSON array of the event IDs in order from most relevant to least relevant based on the user's interests. Return only the JSON array without any additional text or explanation. And do not use markdown syntax. Use raw text.
''';

    return prompt;
  }

  List<String> _extractEventIds(String textResponse) {
    try {
      List<dynamic> eventIds = jsonDecode(textResponse);
      return eventIds.cast<String>();
    } catch (e) {
      print('Error parsing response: $e');
      print('Response was: $textResponse');
      throw Exception('Failed to parse event IDs from OpenAI response');
    }
  }
}
