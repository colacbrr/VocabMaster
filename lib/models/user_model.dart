// lib/models/user_model.dart
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String uid;
  
  @HiveField(1)
  String displayName;
  
  @HiveField(2)
  String email;
  
  @HiveField(3)
  String? photoURL;
  
  @HiveField(4)
  DateTime createdAt;
  
  @HiveField(5)
  int totalWordsLearned;
  
  @HiveField(6)
  int streakDays;
  
  @HiveField(7)
  int dailyGoal;
  
  @HiveField(8)
  Map<String, int> categoryProgress;
  
  @HiveField(9)
  List<String> achievements;
  
  @HiveField(10)
  DateTime lastStudySession;
  
  @HiveField(11)
  int xpPoints;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.createdAt,
    this.totalWordsLearned = 0,
    this.streakDays = 0,
    this.dailyGoal = 10,
    this.categoryProgress = const {},
    this.achievements = const [],
    required this.lastStudySession,
    this.xpPoints = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'totalWordsLearned': totalWordsLearned,
      'streakDays': streakDays,
      'dailyGoal': dailyGoal,
      'categoryProgress': categoryProgress,
      'achievements': achievements,
      'lastStudySession': lastStudySession.toIso8601String(),
      'xpPoints': xpPoints,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoURL: map['photoURL'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      totalWordsLearned: map['totalWordsLearned'] ?? 0,
      streakDays: map['streakDays'] ?? 0,
      dailyGoal: map['dailyGoal'] ?? 10,
      categoryProgress: Map<String, int>.from(map['categoryProgress'] ?? {}),
      achievements: List<String>.from(map['achievements'] ?? []),
      lastStudySession: DateTime.parse(map['lastStudySession'] ?? DateTime.now().toIso8601String()),
      xpPoints: map['xpPoints'] ?? 0,
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    int? totalWordsLearned,
    int? streakDays,
    int? dailyGoal,
    Map<String, int>? categoryProgress,
    List<String>? achievements,
    DateTime? lastStudySession,
    int? xpPoints,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      streakDays: streakDays ?? this.streakDays,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      achievements: achievements ?? this.achievements,
      lastStudySession: lastStudySession ?? this.lastStudySession,
      xpPoints: xpPoints ?? this.xpPoints,
    );
  }
}