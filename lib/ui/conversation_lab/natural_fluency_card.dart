import 'package:flutter/material.dart';
import '../../models/conversation_lab_model.dart';
import '../../state/app_state_controller.dart';

class NaturalFluencyCard extends StatelessWidget {
  const NaturalFluencyCard({
    super.key,
    required this.suggestion,
    required this.controller,
  });

  final NaturalFluencySuggestion suggestion;
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF38BDF8); // Sky blue

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
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Natural Fluency Suggestion',
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
                  suggestion.registerTag,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Idiomatic phrasing box + Audio button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x660B0E14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NATIVE IDIOMATIC PHRASING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion.idiomaticVersion,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.volume_up_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5B9E),
                    foregroundColor: Colors.white,
                  ),
                  tooltip: 'Listen to native pronunciation',
                  onPressed: () {
                    controller.playAssistantAudio(suggestion.idiomaticVersion);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Nuance explanation
          Text(
            suggestion.nuanceExplanation,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF94A3B8),
              height: 1.35,
            ),
          ),

          // Alternatives
          if (suggestion.alternativeExpressions.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'ALTERNATIVE LOCAL EXPRESSIONS:',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestion.alternativeExpressions.map((alt) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    '• "$alt"',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
