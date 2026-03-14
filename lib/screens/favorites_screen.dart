// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word_model.dart';
import '../models/user_model.dart';
import '../services/hive_service.dart';
import '../utils/word_filters.dart';

class FavoritesScreen extends StatefulWidget {
  final UserProfile user;

  const FavoritesScreen({super.key, required this.user});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final HiveService _hiveService = HiveService();
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _searchController = TextEditingController();
  
  List<WordModel> _allFavorites = [];
  List<WordModel> _filteredFavorites = [];
  bool _isLoading = true;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadFavorites();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _searchController.dispose();
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
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    
    try {
      final favorites = _hiveService.getFavoriteWords();
      setState(() {
        _allFavorites = favorites;
        _filteredFavorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterFavorites(String query) {
    setState(() {
      _filteredFavorites = filterWords(_allFavorites, query);
    });
  }

  Future<void> _speakWord(WordModel word) async {
    await _flutterTts.speak("${word.word}. ${word.definition}");
  }

  Future<void> _removeFavorite(WordModel word) async {
    final updatedWord = word.copyWith(isFavorite: false);
    await _hiveService.saveWord(updatedWord);
    
    setState(() {
      _allFavorites.removeWhere((w) => w.id == word.id);
      _filteredFavorites.removeWhere((w) => w.id == word.id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${word.word}" from favorites'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _undoRemoveFavorite(updatedWord),
        ),
      ),
    );
  }

  Future<void> _undoRemoveFavorite(WordModel word) async {
    final restoredWord = word.copyWith(isFavorite: true);
    await _hiveService.saveWord(restoredWord);
    await _loadFavorites();
  }

  void _showWordDetails(WordModel word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                word.word,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade800,
                ),
              ),
            ),
            IconButton(
              onPressed: _isSpeaking ? null : () => _speakWord(word),
              icon: _isSpeaking 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.volume_up),
              tooltip: 'Hear word and definition',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (word.partOfSpeech.isNotEmpty) ...[
              Text(
                'Part of Speech: ${word.partOfSpeech}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Definition:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(word.definition),
            if (word.example.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Example:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '"${word.example}"',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Added: ${_formatDate(word.learnedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _removeFavorite(word);
            },
            icon: const Icon(Icons.favorite, color: Colors.red),
            label: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: Colors.deepPurple.shade100,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${_filteredFavorites.length} words',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade100,
            child: TextField(
              controller: _searchController,
              onChanged: _filterFavorites,
              decoration: InputDecoration(
                hintText: 'Search favorites...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterFavorites('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading favorites...'),
                      ],
                    ),
                  )
                : _filteredFavorites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _allFavorites.isEmpty ? Icons.favorite_border : Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _allFavorites.isEmpty 
                                  ? 'No favorites yet'
                                  : 'No words found',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _allFavorites.isEmpty
                                  ? 'Start learning and add words to your favorites!'
                                  : 'Try a different search term',
                              style: TextStyle(color: Colors.grey.shade500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredFavorites.length,
                        itemBuilder: (context, index) {
                          final word = _filteredFavorites[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showWordDetails(word),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              word.word,
                                              style: GoogleFonts.playfairDisplay(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepPurple.shade800,
                                              ),
                                            ),
                                            if (word.partOfSpeech.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                '(${word.partOfSpeech})',
                                                style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Text(
                                              word.definition,
                                              style: const TextStyle(fontSize: 14),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                            onPressed: _isSpeaking ? null : () => _speakWord(word),
                                            icon: _isSpeaking 
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : const Icon(Icons.volume_up),
                                            tooltip: 'Hear word and definition',
                                          ),
                                          IconButton(
                                            onPressed: () => _removeFavorite(word),
                                            icon: const Icon(Icons.favorite, color: Colors.red),
                                            tooltip: 'Remove from favorites',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
