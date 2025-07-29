import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word_model.dart';

class WordCard extends StatelessWidget {
  final WordModel word;
  final VoidCallback onSpeak;
  final VoidCallback onToggleFavorite;
  final List<dynamic> voices;
  final String? selectedVoice;
  final Function(String?) onVoiceChanged;

  const WordCard({
    super.key,
    required this.word,
    required this.onSpeak,
    required this.onToggleFavorite,
    required this.voices,
    required this.selectedVoice,
    required this.onVoiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Word
          Text(
            word.word,
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade800,
            ),
          ),
          
          // Part of Speech
          if (word.partOfSpeech.isNotEmpty)
            Text(
              '(${word.partOfSpeech})',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          const SizedBox(height: 12),
          
          // Definition
          Text(
            word.definition,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          
          // Example
          if (word.example.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${word.example}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onSpeak,
                icon: const Icon(Icons.volume_up),
                label: const Text('Hear'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  word.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: word.isFavorite ? Colors.red : null,
                ),
                onPressed: onToggleFavorite,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Voice Selector
          DropdownButton<String>(
            value: selectedVoice,
            hint: const Text('Choose voice'),
            isExpanded: true,
            items: voices.map<DropdownMenuItem<String>>((v) {
              final voice = (v as Map).cast<String, dynamic>();
              return DropdownMenuItem<String>(
                value: voice['name'],
                child: Text(voice['name']),
              );
            }).toList(),
            onChanged: onVoiceChanged,
          ),
          
          // Word Stats
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                icon: Icons.visibility,
                label: 'Reviews',
                value: word.reviewCount.toString(),
              ),
              _StatChip(
                icon: Icons.trending_up,
                label: 'Mastery',
                value: '${(word.masteryLevel * 100).toInt()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.deepPurple.shade600),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.deepPurple.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}