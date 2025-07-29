// lib/screens/vocab_learning_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word_model.dart';
import '../models/user_model.dart';
import '../services/enhanced_word_service.dart';
import '../services/hive_service.dart';

class VocabLearningScreen extends StatefulWidget {
  final UserProfile user;

  const VocabLearningScreen({super.key, required this.user});

  @override
  State<VocabLearningScreen> createState() => _VocabLearningScreenState();
}

class _VocabLearningScreenState extends State<VocabLearningScreen> {
  final EnhancedWordService _wordService = EnhancedWordService();
  final HiveService _hiveService = HiveService();
  final FlutterTts _flutterTts = FlutterTts();
  
  List<WordModel> _sessionWords = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showDefinition = false;
  int _wordsLearned = 0;
  bool _isSpeaking = false;
  Set<String> _learnedWordIds = {}; // Track which words were actually learned
  String _selectedDifficulty = 'intermediate';

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadWords();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    
    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
      print('TTS Error: $msg');
    });
  }

  Future<void> _speakWord() async {
    if (_sessionWords.isNotEmpty && _currentIndex < _sessionWords.length) {
      final currentWord = _sessionWords[_currentIndex];
      await _flutterTts.speak(currentWord.word);
    }
  }

  Future<void> _speakDefinition() async {
    if (_sessionWords.isNotEmpty && _currentIndex < _sessionWords.length) {
      final currentWord = _sessionWords[_currentIndex];
      await _flutterTts.speak("${currentWord.word}. ${currentWord.definition}");
    }
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    
    try {
      final words = await _wordService.getMultipleWords(
        widget.user.uid, 
        5, 
        difficulty: _selectedDifficulty,
      );
      setState(() {
        _sessionWords = words;
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading words: $e');
      setState(() => _isLoading = false);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading words: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleDefinition() {
    setState(() {
      _showDefinition = !_showDefinition;
    });
  }

  void _markAsLearned() async {
    if (_currentIndex < _sessionWords.length) {
      final currentWord = _sessionWords[_currentIndex];
      
      // Only award XP if this word hasn't been learned in this session
      if (!_learnedWordIds.contains(currentWord.id)) {
        _learnedWordIds.add(currentWord.id);
        
        // Save word to local storage
        await _hiveService.saveWord(currentWord);
        
        // Update user stats properly
        final currentProfile = _hiveService.getUserProfile();
        if (currentProfile != null) {
          final updatedUser = currentProfile.copyWith(
            totalWordsLearned: currentProfile.totalWordsLearned + 1,
            xpPoints: currentProfile.xpPoints + 10,
            lastStudySession: DateTime.now(),
          );
          await _hiveService.saveUserProfile(updatedUser);
        }
        
        setState(() {
          _wordsLearned++;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Learned "${currentWord.word}" (+10 XP)'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Already learned "${currentWord.word}" in this session'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      _nextWord();
    }
  }

  void _nextWord() {
    if (_currentIndex < _sessionWords.length - 1) {
      setState(() {
        _currentIndex++;
        _showDefinition = false;
      });
    } else {
      _showSessionComplete();
    }
  }

  void _previousWord() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showDefinition = false;
      });
    }
  }

  void _toggleFavorite() async {
    if (_currentIndex < _sessionWords.length) {
      final currentWord = _sessionWords[_currentIndex];
      final updatedWord = currentWord.copyWith(isFavorite: !currentWord.isFavorite);
      
      setState(() {
        _sessionWords[_currentIndex] = updatedWord;
      });
      
      await _hiveService.saveWord(updatedWord);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedWord.isFavorite ? 'Added to favorites!' : 'Removed from favorites'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showSessionComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.orange),
            SizedBox(width: 8),
            Text('Session Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Great job! You learned $_wordsLearned new words in this session.'),
            const SizedBox(height: 8),
            Text('You earned ${_wordsLearned * 10} XP points!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🎯 Tip: Review your favorites regularly to improve retention!',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to main screen with refresh flag
            },
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _startNewSession(); // Start another session
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Learn More'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _startNewSession() {
    setState(() {
      _learnedWordIds.clear();
      _wordsLearned = 0;
      _currentIndex = 0;
      _showDefinition = false;
    });
    _loadWords();
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _toggleDefinition();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextWord();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previousWord();
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _markAsLearned();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return true to indicate data should be refreshed
        Navigator.pop(context, true);
        return false;
      },
      child: RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: _handleKeyPress,
      child: Scaffold(
        backgroundColor: Colors.deepPurple.shade50,
        appBar: AppBar(
          title: const Text('Learning Session'),
          backgroundColor: Colors.deepPurple.shade100,
          elevation: 0,
          actions: [
            // Difficulty selector
            PopupMenuButton<String>(
              icon: Icon(Icons.tune, color: Colors.deepPurple.shade800),
              tooltip: 'Difficulty: $_selectedDifficulty',
              onSelected: (difficulty) {
                setState(() => _selectedDifficulty = difficulty);
                _startNewSession();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'beginner',
                  child: Row(
                    children: [
                      Icon(Icons.star, 
                           color: _selectedDifficulty == 'beginner' ? Colors.green : Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Beginner'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'intermediate',
                  child: Row(
                    children: [
                      Icon(Icons.star_half, 
                           color: _selectedDifficulty == 'intermediate' ? Colors.orange : Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Intermediate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'advanced',
                  child: Row(
                    children: [
                      Icon(Icons.star_border, 
                           color: _selectedDifficulty == 'advanced' ? Colors.red : Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Advanced'),
                    ],
                  ),
                ),
              ],
            ),
            if (_sessionWords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${_currentIndex + 1}/${_sessionWords.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading vocabulary words...'),
                  ],
                ),
              )
            : _sessionWords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Failed to load words'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadWords,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: _toggleDefinition,
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! > 0) {
                          _previousWord();
                        } else {
                          _nextWord();
                        }
                      }
                    },
                    child: Column(
                      children: [
                        // Progress indicator
                        if (_sessionWords.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: LinearProgressIndicator(
                              value: (_currentIndex + 1) / _sessionWords.length,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade400),
                            ),
                          ),
                        
                        // Main word card
                        Expanded(
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                key: ValueKey(_currentIndex),
                                margin: const EdgeInsets.all(24),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.deepPurple.shade100,
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: _buildWordCard(),
                              ),
                            ),
                          ),
                        ),
                        
                        // Action buttons
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    onPressed: _currentIndex > 0 ? _previousWord : null,
                                    icon: const Icon(Icons.arrow_back),
                                    iconSize: 32,
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _toggleDefinition,
                                    icon: Icon(_showDefinition ? Icons.visibility_off : Icons.visibility),
                                    label: Text(_showDefinition ? 'Hide' : 'Reveal'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _toggleFavorite,
                                    icon: Icon(
                                      _sessionWords.isNotEmpty && _sessionWords[_currentIndex].isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: _sessionWords.isNotEmpty && _sessionWords[_currentIndex].isFavorite
                                          ? Colors.red
                                          : null,
                                    ),
                                    iconSize: 32,
                                  ),
                                  IconButton(
                                    onPressed: _nextWord,
                                    icon: const Icon(Icons.arrow_forward),
                                    iconSize: 32,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _markAsLearned,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Mark as Learned (+10 XP)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Keyboard shortcuts hint
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Shortcuts: Space (reveal), ← → (navigate), Enter (learned)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    ),
    );
  }

  Widget _buildWordCard() {
    if (_sessionWords.isEmpty) return const SizedBox();
    
    final currentWord = _sessionWords[_currentIndex];
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Word
        Text(
          currentWord.word,
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Part of speech
        if (currentWord.partOfSpeech.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '(${currentWord.partOfSpeech})',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
        
        const SizedBox(height: 24),
        
        // Definition (hidden by default)
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _showDefinition ? null : 0,
          child: _showDefinition
              ? Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  currentWord.definition,
                                  style: const TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                onPressed: _isSpeaking ? null : _speakDefinition,
                                icon: _isSpeaking 
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.volume_up),
                                iconSize: 20,
                                tooltip: 'Hear word and definition',
                              ),
                            ],
                          ),
                          if (currentWord.example.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              '"${currentWord.example}"',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                )
              : null,
        ),
        
        // Tap hint
        if (!_showDefinition) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '👆 Tap to reveal definition',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ],
    );
  }
}