import 'package:flutter/material.dart';
import '../../models/app_language.dart';
import '../../models/recognized_entity.dart';
import '../../state/app_state_controller.dart';
import '../../utils/theme.dart';

/// Card widget displayed in Exploration Mode (`Input Language == Output Language`).
/// Presents rich monolingual descriptive explanations, contextual semantics,
/// cultural heritage notes, and vocabulary deep-dive.
class ExplorationCardWidget extends StatelessWidget {
  const ExplorationCardWidget({
    super.key,
    required this.entity,
    required this.language,
    required this.controller,
  });

  final RecognizedEntity entity;
  final AppLanguage language;
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final exploration = entity.getExploration(language);
    const accent = AppTheme.explorationAmber;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Category Tag & Mode Pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.travel_explore_rounded,
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'EXPLORATION · ${language.nativeName.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Confidence Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(entity.confidence * 100).toInt()}% Match',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Main Term & Phonetic Transcription
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  exploration.term,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Text(
                exploration.phoneticScript,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: accent.withOpacity(0.9),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Monolingual Definition Text
          Text(
            exploration.definition,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 14),

          // Cultural Context & Heritage Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cultural Significance',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        exploration.culturalContext,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Synonyms & Etymology Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Etymology Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2330),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Etymology: ${exploration.etymology}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              // Synonyms
              ...exploration.synonyms.map(
                (syn) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$syn',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom Action Bar: Audio TTS & Add to Flashcards
          Row(
            children: [
              // Pronunciation Audio Button (Connected to LiteRT Sooktam-2 TTS Engine)
              OutlinedButton.icon(
                onPressed: () {
                  controller.triggerSpeechSynthesis(exploration.term, language);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.volume_up_rounded, size: 18),
                label: const Text('Audio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(width: 10),

              // Save to Review Deck Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final added = controller.addActiveEntityToFlashcards();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: added ? const Color(0xFF152A20) : const Color(0xFF2D2515),
                        content: Row(
                          children: [
                            Icon(
                              added ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                              color: added ? AppTheme.learningEmerald : accent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              added
                                  ? 'Added "${exploration.term}" to Flashcard Deck!'
                                  : '"${exploration.term}" is already in your Flashcards.',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                  label: const Text(
                    'Save to Flashcards',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
