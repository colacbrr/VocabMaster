// PART 1 of 3

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VocabMaster',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
        textTheme: GoogleFonts.montserratTextTheme(
          ThemeData.light().textTheme.apply(
            bodyColor: Colors.black,
            displayColor: Colors.black,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.montserratTextTheme(
          ThemeData.dark().textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const VocabScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WordData {
  final String word;
  final String definition;
  final String example;
  final String partOfSpeech;
  final DateTime lastSeen;
  final int reviewCount;
  final double difficulty;
  final bool isFavorite;

  WordData({
    required this.word,
    required this.definition,
    required this.example,
    required this.partOfSpeech,
    required this.lastSeen,
    this.reviewCount = 0,
    this.difficulty = 1.0,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'definition': definition,
        'example': example,
        'partOfSpeech': partOfSpeech,
        'lastSeen': lastSeen.millisecondsSinceEpoch,
        'reviewCount': reviewCount,
        'difficulty': difficulty,
        'isFavorite': isFavorite,
      };

  factory WordData.fromJson(Map<String, dynamic> json) => WordData(
        word: json['word'] ?? '',
        definition: json['definition'] ?? '',
        example: json['example'] ?? '',
        partOfSpeech: json['partOfSpeech'] ?? '',
        lastSeen: DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] ?? 0),
        reviewCount: json['reviewCount'] ?? 0,
        difficulty: (json['difficulty'] ?? 1.0).toDouble(),
        isFavorite: json['isFavorite'] ?? false,
      );

  WordData copyWith({
    String? word,
    String? definition,
    String? example,
    String? partOfSpeech,
    DateTime? lastSeen,
    int? reviewCount,
    double? difficulty,
    bool? isFavorite,
  }) =>
      WordData(
        word: word ?? this.word,
        definition: definition ?? this.definition,
        example: example ?? this.example,
        partOfSpeech: partOfSpeech ?? this.partOfSpeech,
        lastSeen: lastSeen ?? this.lastSeen,
        reviewCount: reviewCount ?? this.reviewCount,
        difficulty: difficulty ?? this.difficulty,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}

// Type "continue" for PART 2
class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  List<dynamic> _voices = [];
  String? _selectedVoice;
  double _speechRate = 0.45;

  List<WordData> _allWords = [];
  WordData? _currentWord;
  int _currentStreak = 0;
  int _todayCount = 0;
  int _totalWordsRead = 0;
  int _currentScore = 0;
  int _level = 1;
  String _difficulty = 'mixed';
  bool _isLoading = false;

  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOut,
    );
    _loadVoices();
    _loadSettings();
    _loadWords();
    _loadProgress();
  }

  Future<void> _loadVoices() async {
    final voices = await _flutterTts.getVoices;
    setState(() => _voices = voices);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedVoice = prefs.getString('selectedVoice');
      _speechRate = prefs.getDouble('speechRate') ?? 0.45;
      _difficulty = prefs.getString('difficulty') ?? 'mixed';
    });
  }

  Future<void> _loadWords() async {
    final prefs = await SharedPreferences.getInstance();
    final wordsJson = prefs.getString('allWords');
    if (wordsJson != null) {
      final List<dynamic> wordsList = json.decode(wordsJson);
      _allWords = wordsList.map((w) => WordData.fromJson(w)).toList();
    }
    if (_allWords.isEmpty) {
      await _prefetchWords(10);
    } else {
      _selectNextWord();
    }
  }

  Future<void> _prefetchWords(int count) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    int fetched = 0;
    int attempts = 0;
    const int maxAttempts = 20;

    while (fetched < count && attempts < maxAttempts) {
      attempts++;
      final word = await _fetchNewWord();
      if (word != null && !_allWords.any((w) => w.word == word.word)) {
        _allWords.add(word);
        fetched++;
      }
    }

    await _saveWords();
    setState(() => _isLoading = false);
  }

  Future<void> _saveWords() async {
    final prefs = await SharedPreferences.getInstance();
    final wordsJson = json.encode(_allWords.map((w) => w.toJson()).toList());
    await prefs.setString('allWords', wordsJson);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _totalWordsRead = prefs.getInt('totalWordsRead') ?? 0;
    _currentScore = prefs.getInt('currentScore') ?? 0;
    _level = (_currentScore ~/ 100) + 1;
  }

  Future<WordData?> _fetchNewWord() async {
    try {
      final response = await http.get(
        Uri.parse('https://wordsapiv1.p.rapidapi.com/words/?random=true'),
        headers: {
          'X-RapidAPI-Key': 'YOUR_API_KEY',
          'X-RapidAPI-Host': 'wordsapiv1.p.rapidapi.com',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'];
        if (results != null && results.isNotEmpty) {
          final result = results[0];
          String word = data['word'] ?? '';
          String definition = result['definition'] ?? '';
          String partOfSpeech = result['partOfSpeech'] ?? '';
          String example = (result['examples'] != null && result['examples'].isNotEmpty)
              ? result['examples'][0]
              : '';

          word = _capitalize(word);
          definition = _capitalize(definition);
          if (!definition.endsWith('.')) definition += '.';
          example = _capitalize(example);

          return WordData(
            word: word,
            definition: definition,
            example: example,
            partOfSpeech: partOfSpeech,
            lastSeen: DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching word: $e');
    }
    return null;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  void _selectNextWord() {
    if (_allWords.isEmpty) return;
    final index = Random().nextInt(_allWords.length);
    _currentWord = _allWords[index];
    _cardController.reset();
    _cardController.forward();
    setState(() {});
  }

  // Continue to PART 3 next
  void _markWordReviewed({required bool wasEasy}) {
    if (_currentWord == null) return;

    final now = DateTime.now();
    final newDifficulty = wasEasy
        ? (_currentWord!.difficulty * 0.8).clamp(0.3, 3.0)
        : (_currentWord!.difficulty * 1.2).clamp(0.3, 3.0);

    final updatedWord = _currentWord!.copyWith(
      lastSeen: now,
      reviewCount: _currentWord!.reviewCount + 1,
      difficulty: newDifficulty,
    );

    final index = _allWords.indexWhere((w) => w.word == _currentWord!.word);
    if (index != -1) _allWords[index] = updatedWord;

    _currentScore += wasEasy ? 15 : 5;
    _totalWordsRead++;
    _todayCount++;
    _currentStreak++;

    _level = (_currentScore ~/ 100) + 1;
    _saveWords();
    _saveProgress();

    if (_allWords.length < 30) {
      _prefetchWords(5);
    }

    _selectNextWord();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalWordsRead', _totalWordsRead);
    await prefs.setInt('currentScore', _currentScore);
    await prefs.setInt('currentStreak', _currentStreak);
  }

  Future<void> _speak(String text) async {
    if (_selectedVoice != null) {
      await _flutterTts.setVoice({'name': _selectedVoice!, 'locale': 'en-US'});
    }
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.speak(text);
  }

  void _toggleFavorite() {
    if (_currentWord == null) return;

    final updated = _currentWord!.copyWith(isFavorite: !_currentWord!.isFavorite);
    final index = _allWords.indexWhere((w) => w.word == updated.word);
    if (index != -1) _allWords[index] = updated;

    setState(() => _currentWord = updated);
    _saveWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VocabMaster'),
        actions: [
          IconButton(
            icon: Icon(
              _currentWord?.isFavorite ?? false ? Icons.favorite : Icons.favorite_border,
              color: Colors.redAccent,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: _currentWord == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: AnimatedBuilder(
                animation: _cardAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardAnimation.value,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentWord!.word,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentWord!.partOfSpeech.isNotEmpty)
                              Text(
                                '(${_currentWord!.partOfSpeech})',
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                            const SizedBox(height: 20),
                            Text(
                              _currentWord!.definition,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 12),
                            if (_currentWord!.example.isNotEmpty)
                              Text(
                                '"${_currentWord!.example}"',
                                style: const TextStyle(fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _speak('${_currentWord!.word}. ${_currentWord!.definition}'),
                                  icon: const Icon(Icons.volume_up),
                                  label: const Text("Listen"),
                                ),
                                ElevatedButton(
                                  onPressed: () => _markWordReviewed(wasEasy: true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: const Text("Easy 😊"),
                                ),
                                ElevatedButton(
                                  onPressed: () => _markWordReviewed(wasEasy: false),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  child: const Text("Hard 😰"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }
}
