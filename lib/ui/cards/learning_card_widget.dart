import 'package:flutter/material.dart';
import '../../models/app_language.dart';
import '../../models/recognized_entity.dart';
import '../../state/app_state_controller.dart';
import '../../utils/theme.dart';

/// Card widget displayed in Learning Mode (`Input Language != Output Language`).
/// Reveals bilingual translation pairs, phonetic scripts (IPA/transliteration),
/// and detailed grammatical breakdowns.
class LearningCardWidget extends StatelessWidget {
  const LearningCardWidget({
    super.key,
    required this.entity,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.controller,
  });

  final RecognizedEntity entity;
  final AppLanguage sourceLanguage;
  final AppLanguage targetLanguage;
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final learning = entity.getLearning(sourceLanguage, targetLanguage);
    const accent = AppTheme.learningEmerald;

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
          // Header: Mode Tag & Directional Language Indicator
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
                      Icons.auto_stories_rounded,
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'LEARNING · ${sourceLanguage.code.toUpperCase()} ➔ ${targetLanguage.code.toUpperCase()}',
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
              // Confidence Badge
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

          const SizedBox(height: 14),

          // Bilingual Translation Hero Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF141C26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                // Source Side
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sourceLanguage.nativeName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        learning.sourceTerm,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        learning.sourcePhonetic,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: accent.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow divider
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: accent,
                  ),
                ),

                const SizedBox(width: 12),

                // Target Side
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetLanguage.nativeName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        learning.targetTerm,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: accent,
                        ),
                      ),
                      Text(
                        learning.targetPhonetic,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Grammatical Breakdown Section Header
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, size: 15, color: accent),
              const SizedBox(width: 6),
              const Text(
                'GRAMMATICAL BREAKDOWN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: accent,
                ),
              ),
              const Spacer(),
              Text(
                learning.partOfSpeech,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Grammatical Components Grid Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: learning.grammarComponents.map((comp) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF161F2C),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11),
                    children: [
                      TextSpan(
                        text: '${comp.label}: ',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: comp.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Example Sentence Pair
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sourceLanguage.code.toUpperCase(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        learning.sourceExampleSentence,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        targetLanguage.code.toUpperCase(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: accent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        learning.targetExampleSentence,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons: Pronounce & Save to Deck
          Row(
            children: [
              // Pronunciation Audio Button (Connected to LiteRT Sooktam-2 TTS Engine)
              OutlinedButton.icon(
                onPressed: () {
                  controller.triggerSpeechSynthesis(learning.targetTerm, targetLanguage);
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
                              color: added ? accent : AppTheme.explorationAmber,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              added
                                  ? 'Added "${learning.targetTerm}" to Flashcard Deck!'
                                  : '"${learning.targetTerm}" is already in your Flashcards.',
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
