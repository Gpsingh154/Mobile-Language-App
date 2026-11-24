import 'package:flutter/material.dart';
import '../../state/app_state_controller.dart';
import '../../utils/theme.dart';
import 'deck_progress_indicator.dart';
import 'flashcard_card_widget.dart';

/// Inline review deck view component for the local AI-driven Flashcard System.
/// Tracks dynamically captured vocabulary during camera usage sessions without
/// navigating away from the live camera overlay.
class FlashcardReviewDeck extends StatelessWidget {
  const FlashcardReviewDeck({
    super.key,
    required this.controller,
  });

  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final isExpanded = controller.isFlashcardDeckExpanded;
    final deck = controller.flashcardDeck;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: const Color(0xF20F1622),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppTheme.learningEmerald.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle bar & header
          GestureDetector(
            onTap: controller.toggleFlashcardDeck,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                children: [
                  // Little pill handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.learningEmerald.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.style_rounded,
                          size: 18,
                          color: AppTheme.learningEmerald,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI VOCABULARY DECK',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              deck.isEmpty
                                  ? 'No cards collected yet'
                                  : '${deck.length} dynamic session cards ready for review',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Expand / Collapse icon
                      IconButton(
                        icon: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          color: AppTheme.learningEmerald,
                          size: 26,
                        ),
                        onPressed: controller.toggleFlashcardDeck,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Review Card Body
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: deck.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress breakdown bar
                        DeckProgressIndicator(cards: deck),

                        const SizedBox(height: 16),

                        // Active Flashcard
                        FlashcardCardWidget(
                          item: controller.currentCard!,
                          onMasterySelected: (level) {
                            controller.updateCardMastery(controller.currentCard!.id, level);
                          },
                          onDelete: () {
                            controller.removeCard(controller.currentCard!.id);
                          },
                        ),

                        const SizedBox(height: 14),

                        // Deck Carousel Navigation Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous Card Button
                            IconButton.filledTonal(
                              onPressed: controller.previousCard,
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.08),
                                foregroundColor: Colors.white,
                              ),
                            ),

                            // Flip card action button
                            OutlinedButton.icon(
                              onPressed: controller.flipCurrentCard,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.learningEmerald,
                                side: BorderSide(color: AppTheme.learningEmerald.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              icon: const Icon(Icons.flip_rounded, size: 16),
                              label: const Text('Flip Card', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),

                            // Card Index Counter
                            Text(
                              '${controller.currentCardIndex + 1} / ${deck.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),

                            // Next Card Button
                            IconButton.filledTonal(
                              onPressed: controller.nextCard,
                              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.08),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(Icons.inventory_2_outlined, size: 40, color: AppTheme.textMuted),
          SizedBox(height: 10),
          Text(
            'Your review deck is currently empty.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          SizedBox(height: 4),
          Text(
            'Explore with the camera and tap "Save to Flashcards" on any card.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
