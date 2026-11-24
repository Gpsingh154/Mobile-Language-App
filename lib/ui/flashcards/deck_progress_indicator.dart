import 'package:flutter/material.dart';
import '../../models/vocabulary_item.dart';
import '../../utils/theme.dart';

/// Progress overview widget displaying the distribution of deck mastery levels.
class DeckProgressIndicator extends StatelessWidget {
  const DeckProgressIndicator({
    super.key,
    required this.cards,
  });

  final List<VocabularyItem> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = cards.length;
    final learningCount = cards.where((c) => c.masteryLevel == MasteryLevel.learning).length;
    final familiarCount = cards.where((c) => c.masteryLevel == MasteryLevel.familiar).length;
    final masteredCount = cards.where((c) => c.masteryLevel == MasteryLevel.mastered).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DECK MASTERY ($total CARDS)',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppTheme.textMuted,
              ),
            ),
            Row(
              children: [
                _StatusDot(color: Colors.redAccent, label: '$learningCount New'),
                const SizedBox(width: 8),
                _StatusDot(color: AppTheme.explorationAmber, label: '$familiarCount Learning'),
                const SizedBox(width: 8),
                _StatusDot(color: AppTheme.learningEmerald, label: '$masteredCount Mastered'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Stacked progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                if (learningCount > 0)
                  Expanded(
                    flex: learningCount,
                    child: Container(color: Colors.redAccent.withOpacity(0.8)),
                  ),
                if (familiarCount > 0)
                  Expanded(
                    flex: familiarCount,
                    child: Container(color: AppTheme.explorationAmber),
                  ),
                if (masteredCount > 0)
                  Expanded(
                    flex: masteredCount,
                    child: Container(color: AppTheme.learningEmerald),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
