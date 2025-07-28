// lib/words_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class WordsApiService {
  static const _baseUrl = 'https://wordsapiv1.p.rapidapi.com/words';
  static const _apiKey = '3caf06bd92msh3d19c14b6ffe394p1d76aejsnc7fbd4fa36ef'; // Înlocuiește cu cheia ta reală
  static const _headers = {
    'X-RapidAPI-Key': _apiKey,
    'X-RapidAPI-Host': 'wordsapiv1.p.rapidapi.com',
  };

  static Future<Map<String, dynamic>?> fetchWordData(String word) async {
    final url = Uri.parse('$_baseUrl/$word');

    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('❌ Error: ${response.statusCode}');
      return null;
    }
  }
}
