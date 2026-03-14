import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/models/word_model.dart';
import 'package:vocabmaster/utils/word_filters.dart';

void main() {
  test('filterWords matches word and definition text', () {
    final words = [
      WordModel(
        id: '1',
        word: 'Serendipity',
        definition: 'A happy accident.',
        example: 'Example',
        partOfSpeech: 'noun',
        learnedAt: DateTime(2024),
        nextReview: DateTime(2024),
        lastSynced: DateTime(2024),
        userId: 'u1',
      ),
      WordModel(
        id: '2',
        word: 'Analytical',
        definition: 'Using logical reasoning.',
        example: 'Example',
        partOfSpeech: 'adjective',
        learnedAt: DateTime(2024),
        nextReview: DateTime(2024),
        lastSynced: DateTime(2024),
        userId: 'u1',
      ),
    ];

    expect(filterWords(words, 'seren').length, 1);
    expect(filterWords(words, 'logical').length, 1);
    expect(filterWords(words, '').length, 2);
  });
}
