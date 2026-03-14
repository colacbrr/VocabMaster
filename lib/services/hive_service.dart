// lib/services/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/word_model.dart';

class HiveService {
  static const String _userProfileBox = 'userProfile';
  static const String _wordsBox = 'words';
  static const String _settingsBox = 'settings';

  static Future<void> initHive() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(WordModelAdapter());
    }
    
    // Open boxes
    if (!Hive.isBoxOpen(_userProfileBox)) {
      await Hive.openBox<UserProfile>(_userProfileBox);
    }
    if (!Hive.isBoxOpen(_wordsBox)) {
      await Hive.openBox<WordModel>(_wordsBox);
    }
    if (!Hive.isBoxOpen(_settingsBox)) {
      await Hive.openBox(_settingsBox);
    }
  }

  // User Profile Operations
  Future<void> saveUserProfile(UserProfile profile) async {
    final box = Hive.box<UserProfile>(_userProfileBox);
    await box.put('currentUser', profile);
  }

  UserProfile? getUserProfile() {
    final box = Hive.box<UserProfile>(_userProfileBox);
    return box.get('currentUser');
  }

  Future<void> clearUserProfile() async {
    final box = Hive.box<UserProfile>(_userProfileBox);
    await box.clear();
  }

  // Words Operations
  Future<void> saveWord(WordModel word) async {
    final box = Hive.box<WordModel>(_wordsBox);
    await box.put(word.id, word);
  }

  List<WordModel> getAllWords() {
    final box = Hive.box<WordModel>(_wordsBox);
    return box.values.toList();
  }

  WordModel? getWord(String id) {
    final box = Hive.box<WordModel>(_wordsBox);
    return box.get(id);
  }

  Future<void> deleteWord(String id) async {
    final box = Hive.box<WordModel>(_wordsBox);
    await box.delete(id);
  }

  List<WordModel> getFavoriteWords() {
    final box = Hive.box<WordModel>(_wordsBox);
    return box.values.where((word) => word.isFavorite).toList();
  }

  // Settings Operations
  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  T? getSetting<T>(String key) {
    final box = Hive.box(_settingsBox);
    return box.get(key) as T?;
  }

  // Clear all data
  Future<void> clearAllData() async {
    await Hive.box<UserProfile>(_userProfileBox).clear();
    await Hive.box<WordModel>(_wordsBox).clear();
    await Hive.box(_settingsBox).clear();
  }

  Future<void> clearStudyData() async {
    await Hive.box<WordModel>(_wordsBox).clear();
  }
}
