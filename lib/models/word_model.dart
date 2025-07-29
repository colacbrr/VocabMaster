// lib/models/word_model.dart
import 'package:hive/hive.dart';

part 'word_model.g.dart';

@HiveType(typeId: 1)
class WordModel extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String word;
  
  @HiveField(2)
  String definition;
  
  @HiveField(3)
  String example;
  
  @HiveField(4)
  String partOfSpeech;
  
  @HiveField(5)
  DateTime learnedAt;
  
  @HiveField(6)
  int reviewCount;
  
  @HiveField(7)
  double masteryLevel;
  
  @HiveField(8)
  DateTime nextReview;
  
  @HiveField(9)
  bool isFavorite;
  
  @HiveField(10)
  DateTime lastSynced;
  
  @HiveField(11)
  String userId;

  WordModel({
    required this.id,
    required this.word,
    required this.definition,
    required this.example,
    required this.partOfSpeech,
    required this.learnedAt,
    this.reviewCount = 0,
    this.masteryLevel = 0.0,
    required this.nextReview,
    this.isFavorite = false,
    required this.lastSynced,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'definition': definition,
      'example': example,
      'partOfSpeech': partOfSpeech,
      'learnedAt': learnedAt.toIso8601String(),
      'reviewCount': reviewCount,
      'masteryLevel': masteryLevel,
      'nextReview': nextReview.toIso8601String(),
      'isFavorite': isFavorite,
      'lastSynced': lastSynced.toIso8601String(),
      'userId': userId,
    };
  }

  factory WordModel.fromMap(Map<String, dynamic> map) {
    return WordModel(
      id: map['id'] ?? '',
      word: map['word'] ?? '',
      definition: map['definition'] ?? '',
      example: map['example'] ?? '',
      partOfSpeech: map['partOfSpeech'] ?? '',
      learnedAt: DateTime.parse(map['learnedAt'] ?? DateTime.now().toIso8601String()),
      reviewCount: map['reviewCount'] ?? 0,
      masteryLevel: (map['masteryLevel'] ?? 0.0).toDouble(),
      nextReview: DateTime.parse(map['nextReview'] ?? DateTime.now().toIso8601String()),
      isFavorite: map['isFavorite'] ?? false,
      lastSynced: DateTime.parse(map['lastSynced'] ?? DateTime.now().toIso8601String()),
      userId: map['userId'] ?? '',
    );
  }

  WordModel copyWith({
    String? word,
    String? definition,
    String? example,
    String? partOfSpeech,
    DateTime? learnedAt,
    int? reviewCount,
    double? masteryLevel,
    DateTime? nextReview,
    bool? isFavorite,
    DateTime? lastSynced,
  }) {
    return WordModel(
      id: id,
      word: word ?? this.word,
      definition: definition ?? this.definition,
      example: example ?? this.example,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      learnedAt: learnedAt ?? this.learnedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      nextReview: nextReview ?? this.nextReview,
      isFavorite: isFavorite ?? this.isFavorite,
      lastSynced: lastSynced ?? this.lastSynced,
      userId: userId,
    );
  }
}