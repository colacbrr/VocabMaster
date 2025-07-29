// TODO Implement this library.// lib/services/enhanced_word_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/word_model.dart';

class EnhancedWordService {
  static const String _baseUrl = 'https://wordsapiv1.p.rapidapi.com/words/';
  static const String _apiKey = '3caf06bd92msh3d19c14b6ffe394p1d76aejsnc7fbd4fa36ef'; // Replace with actual key if you have one
  static const String _apiHost = 'wordsapiv1.p.rapidapi.com';
  
  final Uuid _uuid = const Uuid();
  
  // Enhanced vocabulary words organized by difficulty
  final Map<String, List<Map<String, String>>> _wordsByDifficulty = {
    'beginner': [
      {
        'word': 'Amazing',
        'definition': 'Causing wonder or astonishment; remarkable.',
        'example': 'The view from the mountain top was amazing.',
        'partOfSpeech': 'adjective'
      },
      {
        'word': 'Brilliant',
        'definition': 'Exceptionally clever or talented.',
        'example': 'She came up with a brilliant solution to the problem.',
        'partOfSpeech': 'adjective'
      },
      {
        'word': 'Creative',
        'definition': 'Relating to or involving the imagination or original ideas.',
        'example': 'The artist\'s creative approach impressed everyone.',
        'partOfSpeech': 'adjective'
      },
      {
        'word': 'Dedicated',
        'definition': 'Devoted to a task or purpose; having single-minded loyalty.',
        'example': 'She is a dedicated teacher who cares about her students.',
        'partOfSpeech': 'adjective'
      },
      {
        'word': 'Enthusiastic',
        'definition': 'Having or showing intense and eager enjoyment.',
        'example': 'The crowd was enthusiastic about the performance.',
        'partOfSpeech': 'adjective'
      },
    ],
    'intermediate': [
      {
        'word': 'Ambitious',
        'definition': 'Having or showing a strong desire and determination to succeed.',
        'example': 'The ambitious student set high goals for herself.',
        'partOfSpeech': 'adjective'
      },
      {
        'word': 'Coherent',
        'definition': 'Logical and consistent; forming a unified whole.',
        'example': 'The professor gave a coherent explanation of the theory.',
        'partOfSpeech': 'adjective'
      },
      {
        'word': 'Substantial',
        'definition': 'Of considerable importance, size, or worth.',
        'example': 'The company made substantial improvements this year.',
        'partOfSpeech': 'adjective'
      },
      {
        'word': 'Methodology',
        'definition': 'A system of methods used in a particular area of study.',
        'example': 'The research methodology was carefully designed.',
        'partOfSpeech': 'noun'
      },
      {
        'word': 'Analytical',
        'definition': 'Relating to or using analysis or logical reasoning.',
        'example': 'Her analytical skills helped solve the complex problem.',
        'partOfSpeech': 'adjective'
      },
    ],
    'advanced': [
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
        'word': 'Perspicacious',
        'definition': 'Having a ready insight into and understanding of things.',
        'example': 'Her perspicacious analysis of the market trends impressed everyone.',
        'partOfSpeech': 'adjective'
      },
      {
        'word': 'Ubiquitous',
        'definition': 'Present, appearing, or found everywhere.',
        'example': 'Smartphones have become ubiquitous in modern society.',
        'partOfSpeech': 'adjective'
      },
      {
        'word': 'Mellifluous',
        'definition': 'Sweet or musical; pleasant to hear.',
        'example': 'The singer\'s mellifluous voice captivated the entire audience.',
        'partOfSpeech': 'adjective'
      },
    ],
  };

  // Try API first, fallback to local words
  Future<WordModel?> _fetchFromAPI(String userId) async {
    if (_apiKey == 'YOUR_RAPIDAPI_KEY') {
      return null; // Skip API if no key is set
    }

    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}?random=true'),
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
              nextReview: now.add(const Duration(days: 1)),
              lastSynced: now,
              userId: userId,
            );
          }
        }
      }
    } catch (e) {
      print('API Error: $e');
    }
    return null;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  WordModel _getLocalWord(String userId, String difficulty) {
    final words = _wordsByDifficulty[difficulty] ?? _wordsByDifficulty['intermediate']!;
    final random = Random();
    final wordData = words[random.nextInt(words.length)];
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

  Future<WordModel> getRandomWord(String userId, {String difficulty = 'intermediate'}) async {
    // Try API first
    final apiWord = await _fetchFromAPI(userId);
    if (apiWord != null) {
      return apiWord;
    }
    
    // Fallback to local words
    return _getLocalWord(userId, difficulty);
  }

  Future<List<WordModel>> getMultipleWords(String userId, int count, {String difficulty = 'intermediate'}) async {
    final words = <WordModel>[];
    final usedWords = <String>{};
    
    for (int i = 0; i < count; i++) {
      int attempts = 0;
      while (attempts < 3) {
        final word = await getRandomWord(userId, difficulty: difficulty);
        if (!usedWords.contains(word.word.toLowerCase())) {
          usedWords.add(word.word.toLowerCase());
          words.add(word);
          break;
        }
        attempts++;
      }
      
      // Small delay between requests
      if (i < count - 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    
    return words;
  }

  List<String> getDifficultyLevels() {
    return ['beginner', 'intermediate', 'advanced'];
  }
}