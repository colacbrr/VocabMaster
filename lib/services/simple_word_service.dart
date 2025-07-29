// lib/services/simple_word_service.dart
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/word_model.dart';

class SimpleWordService {
  final Uuid _uuid = const Uuid();
  
  // High-quality vocabulary words for learning
  final List<Map<String, String>> _words = [
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
    {
      'word': 'Paradigm',
      'definition': 'A typical example or pattern of something; a model.',
      'example': 'The new teaching method represents a paradigm shift in education.',
      'partOfSpeech': 'noun'
    },
    {
      'word': 'Synthesis',
      'definition': 'The combination of ideas to form a theory or system.',
      'example': 'Her book is a brilliant synthesis of psychology and philosophy.',
      'partOfSpeech': 'noun'
    },
    {
      'word': 'Intricate',
      'definition': 'Very complicated or detailed.',
      'example': 'The watch mechanism was incredibly intricate and beautiful.',
      'partOfSpeech': 'adjective'
    },
    {
      'word': 'Paradox',
      'definition': 'A seemingly absurd or contradictory statement that may be true.',
      'example': 'It\'s a paradox that the busiest people often have the most time.',
      'partOfSpeech': 'noun'
    },
    {
      'word': 'Aesthetic',
      'definition': 'Concerned with beauty or the appreciation of beauty.',
      'example': 'The building\'s aesthetic appeal attracted many visitors.',
      'partOfSpeech': 'adjective'
    },
  ];

  WordModel getRandomWord(String userId) {
    final random = Random();
    final wordData = _words[random.nextInt(_words.length)];
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

  Future<List<WordModel>> getMultipleWords(String userId, int count) async {
    final words = <WordModel>[];
    final usedIndices = <int>{};
    final random = Random();
    
    // Get unique words
    while (words.length < count && usedIndices.length < _words.length) {
      final index = random.nextInt(_words.length);
      if (!usedIndices.contains(index)) {
        usedIndices.add(index);
        final wordData = _words[index];
        final now = DateTime.now();
        
        words.add(WordModel(
          id: _uuid.v4(),
          word: wordData['word']!,
          definition: wordData['definition']!,
          example: wordData['example']!,
          partOfSpeech: wordData['partOfSpeech']!,
          learnedAt: now,
          nextReview: now.add(const Duration(days: 1)),
          lastSynced: now,
          userId: userId,
        ));
      }
    }
    
    // Add a small delay to simulate loading
    await Future.delayed(const Duration(milliseconds: 500));
    
    return words;
  }
}