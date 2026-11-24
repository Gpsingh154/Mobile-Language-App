import 'package:flutter/material.dart';
import '../../state/app_state_controller.dart';
import '../flashcards/deck_progress_indicator.dart';
import '../flashcards/flashcard_card_widget.dart';

class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({
    super.key,
    required this.controller,
  });

  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final deck = controller.flashcardDeck;
    final currentCard = controller.currentCard;

    return Scaffold(
      backgroundColor: const Color(0xFF090D14),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0D121C),
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                    onPressed: () => controller.setActiveTab(0),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Vocabulary & AI Flashcards',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${deck.length} Items',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: deck.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.style_outlined, size: 56, color: Colors.grey.shade600),
                          const SizedBox(height: 12),
                          const Text(
                            'Your review deck is currently empty.',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Active Camera Entity'),
                            onPressed: () {
                              controller.addActiveEntityToFlashcards();
                            },
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        DeckProgressIndicator(cards: deck),
                        const SizedBox(height: 16),
                        if (currentCard != null)
                          FlashcardCardWidget(
                            item: currentCard,
                            onMasterySelected: (level) {
                              controller.updateCardMastery(currentCard.id, level);
                            },
                            onDelete: () {
                              controller.removeCard(currentCard.id);
                            },
                          ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filled(
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: controller.previousCard,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Card ${controller.currentCardIndex + 1} of ${deck.length}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(width: 16),
                            IconButton.filled(
                              icon: const Icon(Icons.arrow_forward_rounded),
                              onPressed: controller.nextCard,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
