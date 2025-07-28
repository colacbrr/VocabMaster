import 'dart:convert';
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
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      home: const VocabScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  List<dynamic> _voices = [];
  String? _selectedVoice;

  final List<Map<String, dynamic>> _history = [];
  int _currentIndex = -1;
  bool _isFavorite = false;
  List<Map<String, dynamic>> _favorites = [];

  String _word = '';
  String _definition = '';
  String _example = '';
  String _partOfSpeech = '';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVoices();
    _loadSelectedVoice();
    _loadFavorites();
    _prefetchWords(5);
  }

  Future<void> _loadVoices() async {
    final voices = await _flutterTts.getVoices;
    setState(() => _voices = voices);
  }

  Future<void> _loadSelectedVoice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selectedVoice = prefs.getString('selectedVoice'));
  }

  Future<void> _saveSelectedVoice(String voice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedVoice', voice);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getString('favorites');
    if (favs != null) {
      _favorites = List<Map<String, dynamic>>.from(json.decode(favs));
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorites', json.encode(_favorites));
  }

  Future<void> _prefetchWords(int count) async {
    if (_isLoading) return;
    _isLoading = true;

    int fetched = 0;
    while (fetched < count) {
      final word = await _fetchNewWord();
      if (word != null) {
        _history.add(word);
        fetched++;
      }
    }

    if (_currentIndex == -1 && _history.isNotEmpty) {
      _showWordAtIndex(0);
    }

    _isLoading = false;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<Map<String, dynamic>?> _fetchNewWord() async {
    try {
      final response = await http.get(
        Uri.parse('https://wordsapiv1.p.rapidapi.com/words/?random=true'),
        headers: {
          'X-RapidAPI-Key': '3caf06bd92msh3d19c14b6ffe394p1d76aejsnc7fbd4fa36ef',
          'X-RapidAPI-Host': 'wordsapiv1.p.rapidapi.com',
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
            return {
              'word': _capitalize(data['word'] ?? ''),
              'definition': def,
              'example': (firstResult['examples'] != null && firstResult['examples'].isNotEmpty)
                  ? _capitalize(firstResult['examples'][0].toString().trim())
                  : '',
              'pos': firstResult['partOfSpeech'] ?? ''
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    return null;
  }

  void _showWordAtIndex(int index) {
    final wordData = _history[index];
    setState(() {
      _word = wordData['word'];
      _definition = wordData['definition'];
      _example = wordData['example'];
      _partOfSpeech = wordData['pos'];
      _currentIndex = index;
      _isFavorite = _favorites.any((item) => item['word'] == _word);
    });
  }

  Future<void> _speak(String word, String definition) async {
    if (_selectedVoice != null) {
      await _flutterTts.setVoice({'name': _selectedVoice!, 'locale': 'en-US'});
    }
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.1);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.speak(word);
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.speak(definition);
  }

  void _toggleFavorite() {
    final current = {
      'word': _word,
      'definition': _definition,
      'example': _example,
      'pos': _partOfSpeech
    };
    setState(() {
      if (_isFavorite) {
        _favorites.removeWhere((item) => item['word'] == _word);
      } else {
        _favorites.add(current);
      }
      _isFavorite = !_isFavorite;
    });
    _saveFavorites();
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_currentIndex + 1 < _history.length) {
          _showWordAtIndex(_currentIndex + 1);
        } else {
          _prefetchWords(5);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_currentIndex > 0) {
          _showWordAtIndex(_currentIndex - 1);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('VocabMaster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FavoritesPage(favorites: _favorites)),
            ),
          )
        ],
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKey: _handleKey,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! > 0) {
                if (_currentIndex > 0) {
                  _showWordAtIndex(_currentIndex - 1);
                }
              } else {
                if (_currentIndex + 1 < _history.length) {
                  _showWordAtIndex(_currentIndex + 1);
                } else {
                  _prefetchWords(5);
                }
              }
            }
          },
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey(_word),
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.deepPurple.shade100, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _word,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                    Text('($_partOfSpeech)', style: const TextStyle(fontStyle: FontStyle.italic)),
                    const SizedBox(height: 12),
                    Text(_definition, textAlign: TextAlign.center),
                    if (_example.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('"$_example"', style: const TextStyle(color: Colors.grey)),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _speak(_word, _definition),
                          icon: const Icon(Icons.volume_up),
                          label: const Text('Hear'),
                        ),
                        IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : null,
                          ),
                          onPressed: _toggleFavorite,
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButton<String>(
                      value: _selectedVoice,
                      hint: const Text('Choose voice'),
                      items: _voices.map<DropdownMenuItem<String>>((v) {
                        final voice = (v as Map).cast<String, dynamic>();
                        return DropdownMenuItem<String>(
                          value: voice['name'],
                          child: Text(voice['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedVoice = value);
                        if (value != null) _saveSelectedVoice(value);
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  final List<Map<String, dynamic>> favorites;
  const FavoritesPage({super.key, required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (_, i) {
          final item = favorites[i];
          return ListTile(
            title: Text(item['word']),
            subtitle: Text(item['definition']),
            trailing: Text(item['pos'] ?? ''),
          );
        },
      ),
    );
  }
}
