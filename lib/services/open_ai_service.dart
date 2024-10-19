import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String _apiKey = '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'; // Remember to keep your API key secure

  Future<List<String>> getSortedEventIds({
    required Map<String, dynamic> user,
    required List<Map<String, dynamic>> events,
  }) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final body = jsonEncode({
      "model": "gpt-4",
      "messages": [
        {
          "role": "system",
          "content": "You are an assistant that helps users find events based on their interests."
        },
        {
          "role": "user",
          "content": _generatePrompt(user, events)
        }
      ],
      "max_tokens": 200,
      "temperature": 0.7,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final assistantMessage = responseData['choices'][0]['message']['content'];
      return _extractEventIds(assistantMessage);
    } else {
      print('OpenAI API Error: ${response.body}');
      throw Exception('Failed to fetch sorted event IDs');
    }
  }

  String _generatePrompt(Map<String, dynamic> user, List<Map<String, dynamic>> events) {
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
Please return nothing but a JSON array of the event IDs in the order of most relevant to least relevant based on the user's interests. Do not include any other information in the response. Not even an explanation. Do not start with "based on the users..." or anything like that. Just the JSON array. Thank you. Just go straight into the json array. Otherwise it will break my api.
''';


    return prompt;
  }

  List<String> _extractEventIds(String textResponse) {
    try {
      // Parse the textResponse as JSON
      List<dynamic> eventIds = jsonDecode(textResponse);
      return eventIds.cast<String>();
    } catch (e) {
      print('Error parsing response: $e');
      throw Exception('Failed to parse event IDs from OpenAI response');
    }
  }
}
