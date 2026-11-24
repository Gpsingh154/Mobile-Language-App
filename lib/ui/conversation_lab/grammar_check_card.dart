import 'package:flutter/material.dart';
import '../../models/conversation_lab_model.dart';

class GrammarCheckCard extends StatelessWidget {
  const GrammarCheckCard({
    super.key,
    required this.result,
  });

  final GrammarCheckResult result;

  @override
  Widget build(BuildContext context) {
    final hasErrors = result.hasErrors;
    final accentColor = hasErrors ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xEE1A2230),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasErrors ? Icons.spellcheck_rounded : Icons.verified_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Grammar Check',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasErrors ? 'Corrections Needed' : 'Grammar Perfect (100%)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Annotated Text
          if (result.annotatedText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x660B0E14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                result.annotatedText,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // List of Correction Notes
          if (result.correctionNotes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'No grammatical flaws detected in this utterance. Syntax and concord are well-formed.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                  height: 1.35,
                ),
              ),
            )
          else
            ...result.correctionNotes.map((note) => _buildNoteItem(note, accentColor)),
        ],
      ),
    );
  }

  Widget _buildNoteItem(GrammarCorrectionNote note, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x40101520),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Original with strikethrough
              Text(
                note.originalSegment,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Color(0xFFEF4444),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white54),
              ),
              // Corrected segment
              Text(
                note.correctedSegment,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  note.ruleType,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.explanation,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
