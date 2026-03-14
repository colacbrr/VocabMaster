import '../models/word_model.dart';

List<WordModel> filterWords(List<WordModel> words, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return List<WordModel>.from(words);
  }

  return words.where((word) {
    return word.word.toLowerCase().contains(normalizedQuery) ||
        word.definition.toLowerCase().contains(normalizedQuery);
  }).toList();
}
