import 'package:flutter/material.dart';
import '../../models/app_language.dart';
import '../../models/conversation_lab_model.dart';
import '../../state/app_state_controller.dart';
import 'grammar_check_card.dart';
import 'natural_fluency_card.dart';
import 'tutor_continuity_card.dart';

/// Dedicated 'Conversation Lab Mode' view target.
/// Enables free conversational exchange (English-to-English or Punjabi-to-English)
/// and presents the interactive split-view interface tracking:
/// - 'Grammar Check'
/// - 'Natural Fluency Suggestion'
/// - 'Tutor Continuity Response'
class ConversationLabScreen extends StatefulWidget {
  const ConversationLabScreen({
    super.key,
    required this.controller,
    this.onBack,
  });

  final AppStateController controller;
  final VoidCallback? onBack;

  @override
  State<ConversationLabScreen> createState() => _ConversationLabScreenState();
}

class _ConversationLabScreenState extends State<ConversationLabScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late final TabController _splitTabController;

  @override
  void initState() {
    super.initState();
    _splitTabController = TabController(length: 3, vsync: this);

    // Seed initial turn if empty after frame renders so user immediately sees split-view
    if (widget.controller.conversationLabHistory.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.controller.conversationLabHistory.isEmpty) {
          widget.controller.sendConversationLabMessage(
            message: widget.controller.inputLanguage == AppLanguage.punjabi
                ? 'ਮੈਂ ਇਹ ਕਿਤਾਬ ਪੜ੍ਹਦਾ ਚਾਹੁੰਦੀ ਹਾਂ।'
                : 'I wants to reading this chapter.',
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _splitTabController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    widget.controller.submitTextQuery(text);
  }

  void _handleVoiceToggle() async {
    final audio = widget.controller.audioService;
    if (audio.isTranscribing) return;
    if (audio.isRecording) {
      await widget.controller.stopAudioRecordingAndProcess();
    } else {
      await widget.controller.startAudioRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final currentTurn = controller.currentLabTurn;
    final isPunjabi = controller.inputLanguage == AppLanguage.punjabi;

    return Scaffold(
      backgroundColor: const Color(0xFF090D14),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar
            _buildHeader(context, isPunjabi),

            // 2. Main Content Split View
            Expanded(
              child: currentTurn == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        // User Utterance Bubble + Visual Context Chip
                        _buildUserUtteranceCard(currentTurn),

                        const SizedBox(height: 12),

                        // Interactive Split-View Category Selector Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A26),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: TabBar(
                            controller: _splitTabController,
                            indicatorColor: Colors.transparent,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                            ),
                            labelColor: const Color(0xFF38BDF8),
                            unselectedLabelColor: const Color(0xFF94A3B8),
                            labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            tabs: const [
                              Tab(text: 'Grammar Check'),
                              Tab(text: 'Natural Fluency'),
                              Tab(text: 'Tutor Continuity'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Split-View Tracked Panels
                        SizedBox(
                          height: 380,
                          child: TabBarView(
                            controller: _splitTabController,
                            children: [
                              SingleChildScrollView(
                                child: GrammarCheckCard(result: currentTurn.grammarCheck),
                              ),
                              SingleChildScrollView(
                                child: NaturalFluencyCard(
                                  suggestion: currentTurn.fluencySuggestion,
                                  controller: controller,
                                ),
                              ),
                              SingleChildScrollView(
                                child: TutorContinuityCard(
                                  response: currentTurn.tutorContinuity,
                                  controller: controller,
                                  onSelectFollowUp: (q) {
                                    controller.submitTextQuery(q);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),

            // 3. Lower Conversational Input Strip
            _buildInputBar(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isPunjabi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0D121C),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                widget.controller.setActiveTab(0);
              }
            },
          ),
          const SizedBox(width: 4),

          // Title & Supernova Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded, size: 18, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    const Text(
                      'Conversation Lab',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SUPERNOVA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Gemma-4-E2B-it · IndicConformer ASR',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),

          // Language Pair Switcher: English-to-English or Punjabi-to-English
          InkWell(
            onTap: () {
              if (isPunjabi) {
                widget.controller.setInputLanguage(AppLanguage.english);
                widget.controller.setOutputLanguage(AppLanguage.english);
              } else {
                widget.controller.setInputLanguage(AppLanguage.punjabi);
                widget.controller.setOutputLanguage(AppLanguage.english);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync_alt_rounded, size: 14, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 4),
                  Text(
                    isPunjabi ? 'Punjabi ⇄ Eng' : 'English ⇄ Eng',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserUtteranceCard(ConversationLabTurn turn) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF3B82F6),
                child: const Icon(Icons.person, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'You (${turn.userLanguage.nativeName})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF93C5FD),
                ),
              ),
              const Spacer(),
              if (turn.visionContextFrame != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x3310B981),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_rounded, size: 10, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        '1x Frame (${turn.visionContextFrame!.label})',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            turn.userMessage,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(AppStateController controller) {
    final audio = controller.audioService;
    final isRecording = audio.isRecording;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0D121C),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Voice recording FAB (supporting tap and hold)
          GestureDetector(
            onTap: _handleVoiceToggle,
            onLongPressStart: (_) async {
              final audio = widget.controller.audioService;
              if (!audio.isRecording && !audio.isTranscribing) {
                await widget.controller.startAudioRecording();
              }
            },
            onLongPressEnd: (_) async {
              final audio = widget.controller.audioService;
              if (audio.isRecording) {
                await widget.controller.stopAudioRecordingAndProcess();
              }
            },
            onLongPressCancel: () {
              widget.controller.audioService.cancelRecording();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isRecording ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isRecording ? Colors.white : const Color(0xFF38BDF8),
                  width: 2,
                ),
                boxShadow: [
                  if (isRecording)
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.5),
                      blurRadius: 10,
                    ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Text query field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161E2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: isRecording
                      ? 'Listening on 16kHz mono channel...'
                      : 'Type a sentence to evaluate grammar...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Color(0xFF38BDF8), size: 22),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}
