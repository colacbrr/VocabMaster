// lib/services/word_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/word_model.dart';
import 'api_config.dart';

class WordService {
  final Uuid _uuid = const Uuid();
  
  // Fallback word list for when API is not available
  final List<Map<String, String>> _fallbackWords = [
    {
      'word': 'Serendipity',
      'definition': 'The occurrence of events by chance in a happy or beneficial way.',
      'example': 'It was pure serendipity that led me to find this amazing book.',
      'partOfSpeech': 'noun'
    },
    {
      'word': 'Ephemeral',
      'definition': 'Lasting for a very short time.',
      'example': 'The beauty of cherry blossoms is ephemeral, lasting only a few weeks.',
      'partOfSpeech': 'adjective'
    },
    {
      'word': 'Ubiquitous',
      'definition': 'Present, appearing, or found everywhere.',
      'example': 'Smartphones have become ubiquitous in modern society.',
      'partOfSpeech': 'adjective'
    },
    {
      'word': 'Perspicacious',
      'definition': 'Having a ready insight into and understanding of things.',
      'example': 'Her perspicacious analysis of the market trends impressed everyone.',
      'partOfSpeech': 'adjective'
    },
    {
      'word': 'Mellifluous',
      'definition': 'Sweet or musical; pleasant to hear.',
      'example': 'The singer\'s mellifluous voice captivated the entire audience.',
      'partOfSpeech': 'adjective'
    },
    {
      'word': 'Eloquent',
      'definition': 'Fluent or persuasive in speaking or writing.',
      'example': 'The politician gave an eloquent speech about environmental protection.',
      'partOfSpeech': 'adjective'
    },
    {
      'word': 'Benevolent',
      'definition': 'Well meaning and kindly.',
      'example': 'The benevolent king was loved by all his subjects.',
      'partOfSpeech': 'adjective'
    },
    {
      'word': 'Comprehensive',
      'definition': 'Complete and including everything that is necessary.',
      'example': 'The teacher provided a comprehensive review before the exam.',
      'partOfSpeech': 'adjective'
    },
    {
      'word': 'Resilient',
      'definition': 'Able to withstand or recover quickly from difficult conditions.',
      'example': 'The resilient community rebuilt after the natural disaster.',
      'partOfSpeech': 'adjective'
    },
    {
      'word': 'Innovative',
      'definition': 'Featuring new methods; advanced and original.',
      'example': 'The company\'s innovative approach revolutionized the industry.',
      'partOfSpeech': 'adjective'
    },
  ];

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<WordModel?> fetchRandomWord(String userId) async {
    // For now, let's use fallback words directly since API key isn't set
    // Later you can get a RapidAPI key and use the API
    return _getFallbackWord(userId);
  }

  Future<WordModel?> _fetchFromAPI(String userId) async {
    if (!ApiConfig.hasRapidApiKey) {
      return null;
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.wordsApiBaseUrl}?random=true'),
      headers: {
        'X-RapidAPI-Key': ApiConfig.rapidApiKey,
        'X-RapidAPI-Host': ApiConfig.wordsApiHost,
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
            nextReview: now.add(const Duration(days: 1)),
            lastSynced: now,
            userId: userId,
          );
        }
      }
    }
    return null;
  }

  WordModel _getFallbackWord(String userId) {
    final random = Random();
    final wordData = _fallbackWords[random.nextInt(_fallbackWords.length)];
    final now = DateTime.now();
    
    return WordModel(
      id: _uuid.v4(),
      word: wordData['word']!,
      definition: wordData['definition']!,
      example: wordData['example']!,
      partOfSpeech: wordData['partOfSpeech']!,
      learnedAt: now,
      nextReview: now.add(const Duration(days: 1)),
      lastSynced: now,
      userId: userId,
    );
  }

  Future<List<WordModel>> fetchMultipleWords(String userId, int count) async {
    final words = <WordModel>[];
    final usedWords = <String>{};
    
    for (int i = 0; i < count; i++) {
      try {
        WordModel? word;
        int attempts = 0;
        
        // Try to get a unique word
        while (attempts < 5) {
          word = await fetchRandomWord(userId);
          if (word != null && !usedWords.contains(word.word.toLowerCase())) {
            usedWords.add(word.word.toLowerCase());
            words.add(word);
            break;
          }
          attempts++;
        }
        
        // If we couldn't get a unique word, just add any word
        if (word != null && words.length < count) {
          words.add(word);
        }
      } catch (e) {
        print('Error fetching word $i: $e');
        // Continue to next word
      }
      
      // Small delay between requests
      if (i < count - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    // If we got no words, return at least one fallback word
    if (words.isEmpty) {
      words.add(_getFallbackWord(userId));
    }
    
    return words;
  }
}
