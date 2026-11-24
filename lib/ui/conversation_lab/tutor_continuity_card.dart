import 'package:flutter/material.dart';
import '../../models/conversation_lab_model.dart';
import '../../state/app_state_controller.dart';

class TutorContinuityCard extends StatelessWidget {
  const TutorContinuityCard({
    super.key,
    required this.response,
    required this.controller,
    required this.onSelectFollowUp,
  });

  final TutorContinuityResponse response;
  final AppStateController controller;
  final ValueChanged<String> onSelectFollowUp;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFA855F7); // Purple / Violet coach accent

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
                  Icons.psychology_alt_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tutor Continuity Response',
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
                child: const Text(
                  'Virtual Coach',
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

          // Virtual coach response text + audio synthesis button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x660B0E14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    response.coachReply,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5B9E),
                    foregroundColor: Colors.white,
                  ),
                  tooltip: 'Listen to coach reply',
                  onPressed: () {
                    controller.playAssistantAudio(response.coachAudioText);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Follow-up conversation starters
          if (response.followUpQuestions.isNotEmpty) ...[
            const Text(
              'KEEP THE CONVERSATION FLOWING (TAP TO REPLY):',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: response.followUpQuestions.map((q) {
                return InkWell(
                  onTap: () => onSelectFollowUp(q),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 13, color: accentColor),
                        const SizedBox(width: 5),
                        Text(
                          q,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
