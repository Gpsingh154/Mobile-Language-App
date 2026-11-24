import 'package:flutter/material.dart';
import '../../models/app_language.dart';
import '../../models/vision_frame_payload.dart';
import '../../services/model_lifecycle_manager.dart';
import '../../state/app_state_controller.dart';
import '../conversation_lab/conversation_lab_screen.dart';
import '../vocabulary/vocabulary_screen.dart';
import 'gallery_picker_sheet.dart';
import 'model_info_dialog.dart';
import 'vocab_found_sheet.dart';

/// The core cross-platform camera overlay screen replicating the exact photograph layout:
/// - Top header with `< BoliXR Companion` and model selector pill `Gemma-4-E2B-it`
/// - Assistant message card with mode badges `Buddy`, language pair `English -> Punjabi / French`,
///   engine status indicators `PocketTTS / Sooktam-2` & `Parakeet / IndicConformer ASR`, play button `▶`
/// - Floating translation FAB `文A`
/// - Central circular microphone button with white ring, subtitle "Tap the mic to ask a question"
/// - 3-way input toggle pill `Image` | `Audio` | `Text`
/// - Bottom navigation bar: `Camera` | `Vocabulary` | `Study`
/// - Features an On-Demand Event-Driven Vision Router (continuous AI camera stream decoupled).
class CameraOverlayScreen extends StatelessWidget {
  const CameraOverlayScreen({
    super.key,
    required this.controller,
  });

  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        // Tab 1: Vocabulary & AI Flashcards
        if (controller.activeTabIndex == 1) {
          return VocabularyScreen(controller: controller);
        }

        // Tab 2: Supernova-Style Conversation Lab Mode
        if (controller.activeTabIndex == 2 || controller.isConversationLabActive) {
          return ConversationLabScreen(
            controller: controller,
            onBack: () => controller.setActiveTab(0),
          );
        }

        // Tab 0: Primary Camera Overlay Screen matching the reference photograph
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Clean Cinematic Camera Viewfinder Background
              _buildCleanCameraViewport(context),

              // 2. On-Demand Decoupled Camera Pipeline Indicator (Zero Continuous Processing)
              _buildLowPowerIdleTag(),

              // 3. Single Frame Capture Snapshot Flash Overlay
              if (controller.visionRouter.powerState == CameraPowerState.capturingSingleFrame ||
                  controller.visionRouter.powerState == CameraPowerState.frameCaptured)
                _buildFrameCaptureFlashIndicator(),

              // 4. Main Foreground UI Layer
              SafeArea(
                child: Column(
                  children: [
                    // Top App Header
                    _buildTopHeader(context),

                    const SizedBox(height: 10),

                    // Floating Assistant Message Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildAssistantCard(context),
                    ),

                    // Translation FAB (文A) on the right below card
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 18, top: 12),
                        child: _buildTranslationFab(context),
                      ),
                    ),

                    const Spacer(),

                    // Central Interaction Control (Mic FAB / Text Input / Gallery Launcher)
                    _buildCenterInputControl(context),

                    const SizedBox(height: 14),

                    // Subtitle Prompt
                    _buildSubtitlePrompt(),

                    const SizedBox(height: 16),

                    // 3-Way Input Toggle Pill: Image | Audio | Text
                    _buildInputTogglePill(),

                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // 5. "Vocab found" dynamic bottom sheet modal (matching video recording)
              if (controller.activeVocabResult != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VocabFoundSheet(
                    controller: controller,
                    entity: controller.activeVocabResult!,
                    onClose: () => controller.clearActiveVocabResult(),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  // =========================================================================
  // 1. TOP HEADER: `< XR Language Teacher` + Model Pill + History
  // =========================================================================

  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button `<`
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
            tooltip: 'Back',
            onPressed: () {
              // Return to Camera default state
              controller.setActiveTab(0);
            },
          ),

          // Center: Title + Model Pill
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title: Graduation icon + "BoliXR Companion" in green
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.school_rounded,
                    color: Color(0xFF34C759),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'BoliXR Companion',
                    style: TextStyle(
                      color: Color(0xFF34C759),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Model Selector Pill: Gemma-4-E2B-it
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => ModelInfoDialog(controller: controller),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222834),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Green circular download / chip icon
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0x3334C759),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 12,
                          color: Color(0xFF34C759),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Gemma-4-E2B-it',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // History Button
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 24, color: Colors.white),
            tooltip: 'History & Telemetry',
            onPressed: () {
              _showHistorySheet(context);
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. ASSISTANT MESSAGE CARD (Badges, Status Dots, Message & Play Button)
  // =========================================================================

  Widget _buildAssistantCard(BuildContext context) {
    final inputLang = controller.inputLanguage;
    final outputLang = controller.outputLanguage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xEE161F2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode Badges sitting inside top-left of the card
          Row(
            children: [
              // "Buddy" Pill
              GestureDetector(
                onTap: () {
                  _showModeSwitchDialog(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Buddy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Language Pair Pill (e.g. English -> French / Punjabi)
              GestureDetector(
                onTap: () {
                  _showLanguagePicker(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${inputLang.name} → ${outputLang.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Top Status Row: Green Dot PocketTTS / Sooktam-2 & Green Dot Parakeet / IndicConformer ASR
          Row(
            children: [
              _buildEngineStatusDot('PocketTTS / Sooktam-2'),
              const SizedBox(width: 14),
              _buildEngineStatusDot('Parakeet / IndicConformer ASR'),
            ],
          ),
          const SizedBox(height: 12),

          // Message Text + Play Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  controller.assistantMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Play Button (Dark Blue Circle with White Triangle / Stop Square)
              GestureDetector(
                onTap: () {
                  controller.playAssistantAudio();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F5B9E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F5B9E).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      controller.lifecycleManager.stage == ModelStage.ttsSynthesizing ||
                              controller.lifecycleManager.stage == ModelStage.ttsLoading
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngineStatusDot(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF34C759),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD1D5DB),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 3. FLOATING TRANSLATION FAB (`文A`)
  // =========================================================================

  Widget _buildTranslationFab(BuildContext context) {
    return Tooltip(
      message: 'Swap languages & quick translation',
      child: GestureDetector(
        onTap: () {
          controller.swapLanguages();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Swapped languages: ${controller.inputLanguage.name} → ${controller.outputLanguage.name}',
              ),
              duration: const Duration(seconds: 1),
              backgroundColor: const Color(0xFF1E293B),
            ),
          );
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF262C38),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.translate_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 4. SUBTITLE PROMPT & CENTRAL INTERACTION CONTROL
  // =========================================================================

  Widget _buildSubtitlePrompt() {
    final audio = controller.audioService;
    final vision = controller.visionRouter;

    String text = 'Tap the mic to ask a question';
    if (audio.isRecording) {
      text = 'Listening on 16kHz mono channel... (Tap to stop)';
    } else if (audio.isTranscribing) {
      text = 'Transcribing with indic_conformer_int8.onnx...';
    } else if (vision.powerState == CameraPowerState.capturingSingleFrame) {
      text = 'Capturing 1x isolated frame for Gemma-4-E2B-it...';
    } else if (controller.activeInputMode == InputMode.text) {
      text = 'Type your question to trigger 1x static frame capture';
    } else if (controller.activeInputMode == InputMode.image) {
      text = 'Select a photo from local gallery to analyze';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterInputControl(BuildContext context) {
    switch (controller.activeInputMode) {
      case InputMode.audio:
        return _buildMicFab();
      case InputMode.text:
        return _buildTextInputField();
      case InputMode.image:
        return _buildGalleryPickerLauncher(context);
    }
  }

  /// Feature 2: Dedicated Microphone Floating Action Button with distinct white ring border
  Widget _buildMicFab() {
    final audio = controller.audioService;
    final isRecording = audio.isRecording;
    final isTranscribing = audio.isTranscribing;

    return GestureDetector(
      onTap: () async {
        if (isTranscribing) return;
        if (isRecording) {
          await controller.stopAudioRecordingAndProcess();
        } else {
          await controller.startAudioRecording();
        }
      },
      onLongPressStart: (_) async {
        if (isTranscribing || isRecording) return;
        await controller.startAudioRecording();
      },
      onLongPressEnd: (_) async {
        if (isRecording) {
          await controller.stopAudioRecordingAndProcess();
        }
      },
      onLongPressCancel: () {
        if (isRecording) {
          controller.audioService.cancelRecording();
        }
      },
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: isRecording
              ? const Color(0xFFEF4444)
              : isTranscribing
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF8AB4F8),
          shape: BoxShape.circle,
          // Distinct crisp white circular ring border matching photograph
          border: Border.all(
            color: Colors.white,
            width: 4.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (isRecording
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF8AB4F8))
                  .withOpacity(0.5),
              blurRadius: 18,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isTranscribing
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: isRecording ? Colors.white : const Color(0xFF102766),
                  size: 34,
                ),
        ),
      ),
    );
  }

  /// Feature 1 (Event 2): Text query input that captures 1 frame upon submit
  Widget _buildTextInputField() {
    final textController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xEE161F2C),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white24, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask Gemma about this page...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  border: InputBorder.none,
                ),
                onSubmitted: (val) {
                  controller.submitTextQuery(val);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF709BF5), size: 22),
              onPressed: () {
                controller.submitTextQuery(textController.text);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Feature 1 (Event 3): Image Gallery input launcher
  Widget _buildGalleryPickerLauncher(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
        ),
        elevation: 6,
      ),
      icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF38BDF8)),
      label: const Text(
        'Browse Local Gallery Photos',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => GalleryPickerSheet(controller: controller),
        );
      },
    );
  }

  // =========================================================================
  // 5. 3-WAY INPUT TOGGLE PILL (`Image` | `Audio` | `Text`)
  // =========================================================================

  Widget _buildInputTogglePill() {
    final activeMode = controller.activeInputMode;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2028),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleSegment(
            title: 'Image',
            isActive: activeMode == InputMode.image,
            onTap: () => controller.setInputMode(InputMode.image),
          ),
          _buildToggleSegment(
            title: 'Audio',
            isActive: activeMode == InputMode.audio,
            onTap: () => controller.setInputMode(InputMode.audio),
          ),
          _buildToggleSegment(
            title: 'Text',
            isActive: activeMode == InputMode.text,
            onTap: () => controller.setInputMode(InputMode.text),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSegment({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.black : const Color(0xFF94A3B8),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 6. BOTTOM NAVIGATION BAR (`Camera` | `Vocabulary` | `Study`)
  // =========================================================================

  Widget _buildBottomNavigationBar() {
    final activeTab = controller.activeTabIndex;

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.camera_alt_rounded,
            label: 'Camera',
            isActive: activeTab == 0,
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.menu_book_rounded,
            label: 'Vocabulary',
            isActive: activeTab == 1,
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.school_rounded,
            label: 'Study',
            isActive: activeTab == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () => controller.setActiveTab(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill highlight around icon when active
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF165C9E) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isActive ? const Color(0xFF76C1FF) : const Color(0xFF8E9BAE),
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF76C1FF) : const Color(0xFF8E9BAE),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 7. ON-DEMAND LOW-POWER HUD & FRAME CAPTURE FLASH INDICATORS
  // =========================================================================

  Widget _buildLowPowerIdleTag() {
    return Positioned(
      bottom: 84,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'On-Demand Vision Router: Idle (Continuous AI decoupled)',
              style: TextStyle(fontSize: 9.5, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrameCaptureFlashIndicator() {
    return Positioned(
      top: 140,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xEB10B981),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.camera_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '1x Static Frame Captured (${controller.visionRouter.lastCapturedPayload?.label ?? "Buffer"}) → Routing to Gemma-4-E2B-it',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 8. DIALOGS & ACTION SHEETS
  // =========================================================================

  void _showModeSwitchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131A26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Operating Mode',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.smart_toy_rounded, color: Color(0xFF1565C0)),
                title: const Text('Buddy Mode (Photograph View)', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Live camera viewfinder & interactive multimodal tutor', style: TextStyle(color: Colors.white60, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  controller.setActiveTab(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.psychology_rounded, color: Color(0xFF38BDF8)),
                title: const Text('Conversation Lab Mode (Supernova)', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Grammar Check, Natural Fluency, & Continuity split-view', style: TextStyle(color: Colors.white60, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  controller.setActiveTab(2);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131A26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure Language Pair',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _langChoiceChip(context, 'English → French (Photograph default)', AppLanguage.english, AppLanguage.french),
                  _langChoiceChip(context, 'English → Punjabi', AppLanguage.english, AppLanguage.punjabi),
                  _langChoiceChip(context, 'Punjabi → English', AppLanguage.punjabi, AppLanguage.english),
                  _langChoiceChip(context, 'English → Hindi', AppLanguage.english, AppLanguage.hindi),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _langChoiceChip(BuildContext context, String label, AppLanguage inL, AppLanguage outL) {
    return ActionChip(
      backgroundColor: const Color(0xFF1E293B),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      onPressed: () {
        controller.setInputLanguage(inL);
        controller.setOutputLanguage(outL);
        Navigator.pop(context);
      },
    );
  }

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131A26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('On-Demand Frame & Reasoning History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Total On-Demand Frames Processed: ${controller.visionRouter.onDemandFrameCount}',
                style: const TextStyle(color: Color(0xFF34C759), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                'Continuous Frame Inferences: ${controller.visionRouter.continuousFramesRendered} (0 = perfectly decoupled)',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (controller.visionRouter.lastCapturedPayload != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Last Payload: ${controller.visionRouter.lastCapturedPayload!.triggerDescription}\nTimestamp: ${controller.visionRouter.lastCapturedPayload!.timestamp}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // Clean Camera Viewfinder Viewport (Decoupled from continuous AI rendering)
  // =========================================================================

  Widget _buildCleanCameraViewport(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.25,
          colors: [
            Color(0xFF222C3A),
            Color(0xFF131922),
            Color(0xFF090D14),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Optical focus reticle
          Center(
            child: Opacity(
              opacity: 0.10,
              child: const Icon(
                Icons.center_focus_weak_rounded,
                size: 260,
                color: Colors.white,
              ),
            ),
          ),
          // Rule of thirds camera framing grid
          CustomPaint(
            painter: _CameraGridPainter(),
          ),
        ],
      ),
    );
  }
}

class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical rule of thirds
    final w1 = size.width / 3;
    final w2 = size.width * 2 / 3;
    canvas.drawLine(Offset(w1, 0), Offset(w1, size.height), paint);
    canvas.drawLine(Offset(w2, 0), Offset(w2, size.height), paint);

    // Horizontal rule of thirds
    final h1 = size.height / 3;
    final h2 = size.height * 2 / 3;
    canvas.drawLine(Offset(0, h1), Offset(size.width, h1), paint);
    canvas.drawLine(Offset(0, h2), Offset(size.width, h2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
