import 'package:flutter/material.dart';
import '../../models/recognized_entity.dart';
import '../../state/app_state_controller.dart';

/// Modal bottom sheet displaying dynamic vocabulary extracted from the
/// on-demand single frame camera capture or user text/audio query, matching
/// the exact layout shown in the mobile screen recording.
class VocabFoundSheet extends StatefulWidget {
  const VocabFoundSheet({
    super.key,
    required this.controller,
    required this.entity,
    required this.onClose,
  });

  final AppStateController controller;
  final RecognizedEntity entity;
  final VoidCallback onClose;

  @override
  State<VocabFoundSheet> createState() => _VocabFoundSheetState();
}

class _VocabFoundSheetState extends State<VocabFoundSheet> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final entity = widget.entity;
    final src = controller.inputLanguage;
    final dst = controller.outputLanguage;
    final learning = entity.getLearning(src, dst);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E242E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header with title and close X
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 28), // balance X
              const Text(
                'Vocab found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 24),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Vocab Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131821),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                // Top section: Thumbnail + Word + Translation + Speaker
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Captured image thumbnail with edit badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C3545),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _buildThumbnail(controller),
                          ),
                        ),
                        // Pencil edit badge
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: Color(0xFF1E242E),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Target word & English meaning
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            learning.targetTerm,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            learning.sourceTerm,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (learning.targetPhonetic.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              learning.targetPhonetic,
                              style: const TextStyle(
                                color: Color(0xFF64B5F6),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Speaker audio button
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        controller.playAssistantAudio(learning.targetTerm);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Example Sentence Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E242E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              learning.targetExampleSentence,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              learning.sourceExampleSentence,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_outlined, color: Colors.white70, size: 18),
                        onPressed: () {
                          controller.playAssistantAudio(learning.targetExampleSentence);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Save to Vocab Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaved ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(_isSaved ? Icons.check_rounded : Icons.bookmark_border_rounded, size: 18),
                    label: Text(
                      _isSaved ? 'Saved to Vocab' : 'Save to Vocab',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      final added = controller.addActiveEntityToFlashcards(entity);
                      setState(() {
                        _isSaved = added || _isSaved;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            added
                                ? 'Added "${learning.targetTerm}" to Vocabulary Deck!'
                                : 'Already saved in your Vocabulary deck.',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF1565C0),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Bottom Action Row: Ask a follow up + Keyboard icon
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81D4FA),
                      foregroundColor: const Color(0xFF0D47A1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.mic, size: 20),
                    label: const Text(
                      'Ask a follow up',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      widget.onClose();
                      controller.setInputMode(InputMode.audio);
                      controller.startAudioRecording();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.keyboard_outlined, color: Colors.white, size: 22),
                  onPressed: () {
                    widget.onClose();
                    controller.setInputMode(InputMode.text);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 4. "Ask about something else"
          TextButton(
            onPressed: widget.onClose,
            child: const Text(
              'Ask about something else',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(AppStateController controller) {
    final payload = controller.visionRouter.lastCapturedPayload;
    if (payload != null && payload.frameBytes.isNotEmpty) {
      try {
        return Image.memory(
          payload.frameBytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackThumbnail(),
        );
      } catch (_) {
        return _fallbackThumbnail();
      }
    }
    return _fallbackThumbnail();
  }

  Widget _fallbackThumbnail() {
    return Container(
      color: const Color(0xFF1B2330),
      child: const Center(
        child: Icon(
          Icons.camera_alt_rounded,
          color: Colors.white38,
          size: 32,
        ),
      ),
    );
  }
}
