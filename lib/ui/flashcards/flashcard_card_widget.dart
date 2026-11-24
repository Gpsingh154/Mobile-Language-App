import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/vocabulary_item.dart';
import '../../utils/theme.dart';

/// Interactive flip card widget supporting 3D perspective rotation,
/// revealing target translations and grammatical breakdowns on tap.
class FlashcardCardWidget extends StatefulWidget {
  const FlashcardCardWidget({
    super.key,
    required this.item,
    required this.onMasterySelected,
    required this.onDelete,
  });

  final VocabularyItem item;
  final ValueChanged<MasteryLevel> onMasterySelected;
  final VoidCallback onDelete;

  @override
  State<FlashcardCardWidget> createState() => _FlashcardCardWidgetState();
}

class _FlashcardCardWidgetState extends State<FlashcardCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );

    if (widget.item.isFlipped) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant FlashcardCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.id != oldWidget.item.id) {
      if (widget.item.isFlipped) {
        _flipController.value = 1.0;
      } else {
        _flipController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_flipController.isCompleted) {
      _flipController.reverse();
      widget.item.isFlipped = false;
    } else {
      _flipController.forward();
      widget.item.isFlipped = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, _) {
          final angle = _flipAnimation.value * math.pi;
          final isUnder = _flipAnimation.value >= 0.5;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015) // 3D Perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isUnder
                ? Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBackCard(),
                  )
                : _buildFrontCard(),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161E2B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.learningEmerald.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Bar: Source Language badge & Mastery tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.learningEmerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.item.sourceLanguage.nativeName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.learningEmerald,
                  ),
                ),
              ),
              Row(
                children: [
                  _MasteryChip(level: widget.item.masteryLevel),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textMuted),
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          // Center: Large Term & Phonetic Transliteration
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(
                  widget.item.sourceTerm,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.sourcePhonetic,
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: AppTheme.learningEmerald,
                  ),
                ),
              ],
            ),
          ),

          // Bottom: Flip hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.touch_app_rounded, size: 14, color: AppTheme.textMuted),
              SizedBox(width: 6),
              Text(
                'Tap to flip for translation & grammar breakdown',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2433),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.explorationAmber.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Target language
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.explorationAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.item.targetLanguage.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.explorationAmber,
                  ),
                ),
              ),
              Text(
                widget.item.partOfSpeech,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Target Term
          Text(
            widget.item.targetTerm,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),

          if (widget.item.targetPhonetic.isNotEmpty)
            Text(
              widget.item.targetPhonetic,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppTheme.explorationAmber,
              ),
            ),

          const SizedBox(height: 10),

          // Grammatical Breakdown Chips
          if (widget.item.grammarComponents.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.item.grammarComponents.map((g) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${g.label}: ${g.value}',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textPrimary),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 10),

          // Example Sentence
          if (widget.item.exampleSentence.isNotEmpty)
            Text(
              'Example: "${widget.item.exampleSentence}"',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),

          const SizedBox(height: 16),

          // Mastery Level Actions
          Row(
            children: [
              _MasteryActionButton(
                label: 'Need Practice',
                color: Colors.redAccent,
                isSelected: widget.item.masteryLevel == MasteryLevel.learning,
                onTap: () => widget.onMasterySelected(MasteryLevel.learning),
              ),
              const SizedBox(width: 8),
              _MasteryActionButton(
                label: 'Familiar',
                color: AppTheme.explorationAmber,
                isSelected: widget.item.masteryLevel == MasteryLevel.familiar,
                onTap: () => widget.onMasterySelected(MasteryLevel.familiar),
              ),
              const SizedBox(width: 8),
              _MasteryActionButton(
                label: 'Mastered',
                color: AppTheme.learningEmerald,
                isSelected: widget.item.masteryLevel == MasteryLevel.mastered,
                onTap: () => widget.onMasterySelected(MasteryLevel.mastered),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MasteryChip extends StatelessWidget {
  const _MasteryChip({required this.level});
  final MasteryLevel level;

  @override
  Widget build(BuildContext context) {
    final color = level == MasteryLevel.mastered
        ? AppTheme.learningEmerald
        : (level == MasteryLevel.familiar ? AppTheme.explorationAmber : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _MasteryActionButton extends StatelessWidget {
  const _MasteryActionButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.25) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.white12,
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
