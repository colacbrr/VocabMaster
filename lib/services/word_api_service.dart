import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/word_model.dart';

class WordApiService {
  static const String _baseUrl = 'https://wordsapiv1.p.rapidapi.com/words/';
  static const String _apiKey = '3caf06bd92msh3d19c14b6ffe394p1d76aejsnc7fbd4fa36ef'; // Replace with your actual key
  static const String _apiHost = 'wordsapiv1.p.rapidapi.com';
  
  final Uuid _uuid = const Uuid();

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<WordModel?> fetchRandomWord(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?random=true'),
        headers: {
          'X-RapidAPI-Key': _apiKey,
          'X-RapidAPI-Host': _apiHost,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'];
        
        if (results != null && results.isNotEmpty) {
          final firstResult = results[0];
          if (firstResult['definition'] != null) {
            String def = _capitalize(firstResult['definition'].toString().trim());
            if (!def.endsWith('.')) def += '.';
            
            final now = DateTime.now();
            return WordModel(
              id: _uuid.v4(),
              word: _capitalize(data['word'] ?? ''),
              definition: def,
              example: (firstResult['examples'] != null && firstResult['examples'].isNotEmpty)
                  ? _capitalize(firstResult['examples'][0].toString().trim())
                  : '',
              partOfSpeech: firstResult['partOfSpeech'] ?? '',
              learnedAt: now,
              nextReview: now.add(const Duration(days: 1)), // Next review in 1 day
              lastSynced: now,
              userId: userId,
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching word: $e');
    }
    return null;
  }

  Future<List<WordModel>> fetchMultipleWords(String userId, int count) async {
    final words = <WordModel>[];
    int attempts = 0;
    final maxAttempts = count * 3; // Allow some failures

    while (words.length < count && attempts < maxAttempts) {
      attempts++;
      final word = await fetchRandomWord(userId);
      if (word != null) {
        // Check for duplicates
        if (!words.any((w) => w.word.toLowerCase() == word.word.toLowerCase())) {
          words.add(word);
        }
      }
      
      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return words;
  }
}