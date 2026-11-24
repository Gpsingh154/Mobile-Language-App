import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_language_app/models/app_language.dart';
import 'package:mobile_language_app/models/app_mode.dart';
import 'package:mobile_language_app/models/vision_frame_payload.dart';
import 'package:mobile_language_app/models/vocabulary_item.dart';
import 'package:mobile_language_app/services/audio_capture_service.dart';
import 'package:mobile_language_app/services/dynamic_query_engine.dart';
import 'package:mobile_language_app/services/grammar_lab_service.dart';
import 'package:mobile_language_app/services/model_lifecycle_manager.dart';
import 'package:mobile_language_app/services/on_demand_vision_router.dart';
import 'package:mobile_language_app/state/app_state_controller.dart';
import 'package:mobile_language_app/ui/camera/camera_overlay_screen.dart';
import 'package:mobile_language_app/ui/camera/vocab_found_sheet.dart';

void main() {
  group('AppStateController & Functional State Toggles Tests', () {
    test('Default mode is Learning Mode when Input != Output (Punjabi -> English)', () {
      final controller = AppStateController(
        initialInputLanguage: AppLanguage.punjabi,
        initialOutputLanguage: AppLanguage.english,
      );

      expect(controller.inputLanguage, AppLanguage.punjabi);
      expect(controller.outputLanguage, AppLanguage.english);
      expect(controller.currentMode, AppMode.learning);
      expect(controller.currentMode.isLearning, isTrue);
      expect(controller.currentMode.isExploration, isFalse);
    });

    test('Trigger Exploration Mode when Input Language == Output Language', () {
      final controller = AppStateController(
        initialInputLanguage: AppLanguage.punjabi,
        initialOutputLanguage: AppLanguage.english,
      );

      // Change Output to Punjabi
      controller.setOutputLanguage(AppLanguage.punjabi);

      expect(controller.inputLanguage, AppLanguage.punjabi);
      expect(controller.outputLanguage, AppLanguage.punjabi);
      expect(controller.currentMode, AppMode.exploration);
      expect(controller.currentMode.isExploration, isTrue);
      expect(controller.currentMode.isLearning, isFalse);
    });

    test('Language swap switches Input and Output correctly', () {
      final controller = AppStateController(
        initialInputLanguage: AppLanguage.punjabi,
        initialOutputLanguage: AppLanguage.hindi,
      );

      expect(controller.currentMode, AppMode.learning);

      // Swap
      controller.swapLanguages();

      expect(controller.inputLanguage, AppLanguage.hindi);
      expect(controller.outputLanguage, AppLanguage.punjabi);
      expect(controller.currentMode, AppMode.learning);
    });

    test('Trigger Exploration Mode across all regional Indian choices', () {
      final controller = AppStateController();

      for (final lang in AppLanguage.values) {
        controller.setInputLanguage(lang);
        controller.setOutputLanguage(lang);
        expect(
          controller.currentMode,
          AppMode.exploration,
          reason: 'Language ${lang.name} as both input and output must trigger Exploration Mode',
        );
      }
    });

    test('Dynamic Flashcard Review Deck additions and mastery updates', () {
      final controller = AppStateController(
        initialInputLanguage: AppLanguage.punjabi,
        initialOutputLanguage: AppLanguage.english,
      );

      final initialCount = controller.flashcardDeck.length;

      // Cycle to second detected entity and add to flashcard deck
      controller.cycleNextEntity();
      final added = controller.addActiveEntityToFlashcards();

      expect(added, isTrue);
      expect(controller.flashcardDeck.length, initialCount + 1);

      final newCard = controller.flashcardDeck.first;
      expect(newCard.sourceLanguage, AppLanguage.punjabi);
      expect(newCard.masteryLevel, MasteryLevel.learning);

      // Update card mastery to 'Mastered'
      controller.updateCardMastery(newCard.id, MasteryLevel.mastered);
      expect(newCard.masteryLevel, MasteryLevel.mastered);
      expect(newCard.reviewCount, 1);
    });

    test('Inline Review Deck toggle controls', () {
      final controller = AppStateController();

      expect(controller.isFlashcardDeckExpanded, isFalse);

      controller.toggleFlashcardDeck();
      expect(controller.isFlashcardDeckExpanded, isTrue);

      controller.toggleFlashcardDeck();
      expect(controller.isFlashcardDeckExpanded, isFalse);
    });
  });

  group('ModelLifecycleManager (Phase 3 Strict Sequential Memory) Tests', () {
    test('Static tuning parameters are properly declared and accessible', () {
      expect(ModelLifecycleManager.numThreads, 4);
      expect(ModelLifecycleManager.temperature, 0.7);
      expect(ModelLifecycleManager.maxTokens, 128);
      expect(ModelLifecycleManager.targetMemoryCapMb, 700);
      expect(ModelLifecycleManager.baselineIdleRamMb, 48);
      expect(ModelLifecycleManager.asrAllocatedRamMb, 188);
      expect(ModelLifecycleManager.gemmaAllocatedRamMb, 560);
      expect(ModelLifecycleManager.ttsAllocatedRamMb, 280);
    });

    test('Strict sequential pipeline keeps RAM under 700MB at every phase', () async {
      final manager = ModelLifecycleManager();
      final recordedRamValues = <int>[];

      manager.addListener(() {
        recordedRamValues.add(manager.currentEstimatedRamMb);
        // Verify invariant: RAM must NEVER exceed 700 MB
        expect(
          manager.currentEstimatedRamMb,
          lessThanOrEqualTo(ModelLifecycleManager.targetMemoryCapMb),
          reason: 'Memory exceeded ${ModelLifecycleManager.targetMemoryCapMb}MB: got ${manager.currentEstimatedRamMb}MB',
        );
      });

      // Run sequential pipeline
      await manager.runSequentialPipeline(
        inputLanguage: AppLanguage.punjabi,
        outputLanguage: AppLanguage.english,
        mode: AppMode.learning,
      );

      expect(manager.stage, ModelStage.completed);
      expect(manager.currentEstimatedRamMb, ModelLifecycleManager.baselineIdleRamMb);
      expect(manager.activeEngine, ModelEngineType.none);
      expect(manager.isVisionPipelineLocked, isFalse);
      expect(manager.transcribedText, isNotNull);
      expect(manager.gemmaResponse, isNotNull);

      // Verify RAM dropped back to baseline
      expect(recordedRamValues.last, ModelLifecycleManager.baselineIdleRamMb);
    });

    test('Standalone Sooktam-2 TTS synthesis loads and unloads cleanly', () async {
      final manager = ModelLifecycleManager();

      await manager.synthesizeSpeechOnly(
        text: 'ਕੁੱਜਾ',
        language: AppLanguage.punjabi,
      );

      expect(manager.stage, ModelStage.completed);
      expect(manager.currentEstimatedRamMb, ModelLifecycleManager.baselineIdleRamMb);
      expect(manager.activeEngine, ModelEngineType.none);
    });

    test('AppStateController ties directly to ModelLifecycleManager triggers', () async {
      final controller = AppStateController();

      expect(controller.lifecycleManager.isRunning, isFalse);

      final pipelineFuture = controller.triggerLiveInferencePipeline(
        promptOverride: 'ਕੁੱਜੇ ਵਿੱਚ ਪਾਣੀ ਠੰਢਾ ਕਿਉਂ ਹੁੰਦਾ ਹੈ?',
      );

      // Pipeline should now be running
      expect(controller.lifecycleManager.isRunning, isTrue);

      await pipelineFuture;

      expect(controller.lifecycleManager.isRunning, isFalse);
      expect(controller.lifecycleManager.transcribedText, 'ਕੁੱਜੇ ਵਿੱਚ ਪਾਣੀ ਠੰਢਾ ਕਿਉਂ ਹੁੰਦਾ ਹੈ?');
      expect(controller.lifecycleManager.gemmaResponse, isNotNull);
    });
  });

  group('Feature 1: On-Demand Event-Driven Vision Router Tests', () {
    test('Camera pipeline is completely decoupled from continuous AI frames and starts in idleLowPower', () {
      final router = OnDemandVisionRouter();

      expect(router.isIdle, isTrue);
      expect(router.powerState, CameraPowerState.idleLowPower);
      expect(router.continuousFramesRendered, 0);
      expect(router.onDemandFrameCount, 0);
      expect(router.lastCapturedPayload, isNull);
    });

    test('Trigger 1: Audio/Voice Input captures exactly ONE static frame and returns to idleLowPower', () async {
      final router = OnDemandVisionRouter();

      final payload = await router.captureFromVoice(
        voiceTranscript: 'ਮੈਨੂੰ ਇਸ ਪੰਨੇ ਬਾਰੇ ਸਮਝਾਓ।',
      );

      expect(payload.triggerSource, VisionTriggerSource.audioVoice);
      expect(payload.triggerQuery, 'ਮੈਨੂੰ ਇਸ ਪੰਨੇ ਬਾਰੇ ਸਮਝਾਓ।');
      expect(payload.frameBytes.isNotEmpty, isTrue);
      expect(router.onDemandFrameCount, 1);
      expect(router.continuousFramesRendered, 0);
      expect(router.powerState, CameraPowerState.idleLowPower);
      expect(router.lastCapturedPayload, isNotNull);
    });

    test('Trigger 2: Text Input query submission captures exactly ONE static frame', () async {
      final router = OnDemandVisionRouter();

      final payload = await router.captureFromText(
        textQuery: 'What is the grammatical root of this word?',
      );

      expect(payload.triggerSource, VisionTriggerSource.textQuery);
      expect(payload.triggerQuery, 'What is the grammatical root of this word?');
      expect(payload.frameBytes.lengthInBytes, greaterThan(0));
      expect(router.onDemandFrameCount, 1);
      expect(router.continuousFramesRendered, 0);
      expect(router.powerState, CameraPowerState.idleLowPower);
    });

    test('Trigger 3: Image Gallery Input pulls selected gallery photo payload', () async {
      final router = OnDemandVisionRouter();

      final payload = await router.captureFromGallery(
        galleryImageName: 'Textbook Page (Linguistics)',
      );

      expect(payload.triggerSource, VisionTriggerSource.imageGallery);
      expect(payload.galleryImageName, 'Textbook Page (Linguistics)');
      expect(payload.frameBytes.isNotEmpty, isTrue);
      expect(router.onDemandFrameCount, 1);
      expect(router.continuousFramesRendered, 0);
      expect(router.powerState, CameraPowerState.idleLowPower);
    });

    test('Sequential events only increment on-demand count and never continuous frames', () async {
      final router = OnDemandVisionRouter();

      await router.captureFromVoice(voiceTranscript: 'Prompt 1');
      await router.captureFromText(textQuery: 'Prompt 2');
      await router.captureFromGallery(galleryImageName: 'Photo 3');

      expect(router.onDemandFrameCount, 3);
      expect(router.continuousFramesRendered, 0);
      expect(router.isIdle, isTrue);
    });
  });

  group('Feature 2: Embedded 16kHz Audio Channel & Mic FAB Tests', () {
    test('Acoustic channel configuration enforces 16kHz mono 16-bit PCM for IndicConformer', () {
      expect(AudioCaptureService.sampleRate, 16000);
      expect(AudioCaptureService.channelCount, 1);
      expect(AudioCaptureService.bitsPerSample, 16);
      expect(AudioCaptureService.asrModelAsset, 'assets/models/asr/indic_conformer_int8.onnx');
    });

    test('Audio capture lifecycle: recording starts oscillating amplitude stream, stop routes to ASR', () async {
      final audio = AudioCaptureService();

      expect(audio.state, AudioCaptureState.idle);
      expect(audio.isRecording, isFalse);

      audio.startRecording();
      expect(audio.state, AudioCaptureState.recording);
      expect(audio.isRecording, isTrue);

      await Future.delayed(const Duration(milliseconds: 180));
      expect(audio.currentAmplitude, greaterThan(0.0));
      expect(audio.waveformSamples.isNotEmpty, isTrue);

      final transcription = await audio.stopRecordingAndTranscribe(
        language: AppLanguage.punjabi,
      );

      expect(audio.state, AudioCaptureState.completed);
      expect(audio.isRecording, isFalse);
      expect(transcription.isNotEmpty, isTrue);
      expect(audio.recordedPcmBytes, isNotNull);
      expect(audio.lastTranscribedText, transcription);

      audio.dispose();
    });

    test('AppStateController audio flow triggers single frame capture and Gemma reasoning', () async {
      final controller = AppStateController();

      expect(controller.visionRouter.onDemandFrameCount, 0);

      await controller.startAudioRecording();
      expect(controller.audioService.isRecording, isTrue);

      await controller.stopAudioRecordingAndProcess();
      expect(controller.audioService.isRecording, isFalse);
      // Verify exactly ONE frame was captured and passed to Gemma
      expect(controller.visionRouter.onDemandFrameCount, 1);
      expect(controller.visionRouter.continuousFramesRendered, 0);
      expect(controller.visionRouter.lastCapturedPayload?.triggerSource, VisionTriggerSource.audioVoice);

      controller.dispose();
    });
  });

  group('Feature 3: Supernova-Style Conversation & Grammar Lab Tests', () {
    test('Gemma backend prompt response schema structures split-view tracking', () {
      final prompt = GrammarLabService.buildGemmaPrompt(
        userText: 'I wants to reading this chapter',
        sourceLanguage: AppLanguage.english,
        targetLanguage: AppLanguage.english,
      );

      expect(prompt, contains('grammar_check'));
      expect(prompt, contains('natural_fluency_suggestion'));
      expect(prompt, contains('tutor_continuity_response'));
      expect(prompt, contains('I wants to reading this chapter'));
    });

    test('English-to-English grammar diagnostics highlight infinitive error and offer native fluency', () {
      final turn = GrammarLabService.generateSemanticLabResponse(
        userText: 'I wants to reading this book',
        userLanguage: AppLanguage.english,
        targetLanguage: AppLanguage.english,
      );

      // 1. Grammar Check
      expect(turn.grammarCheck.hasErrors, isTrue);
      expect(turn.grammarCheck.correctionNotes.isNotEmpty, isTrue);
      expect(turn.grammarCheck.correctionNotes.first.ruleType, 'Infinitive vs Gerund');
      expect(turn.grammarCheck.correctionNotes.first.correctedSegment, 'to read');

      // 2. Natural Fluency Suggestion
      expect(turn.fluencySuggestion.idiomaticVersion, contains('read this book'));
      expect(turn.fluencySuggestion.registerTag, 'Native Colloquial English');
      expect(turn.fluencySuggestion.nuanceExplanation.isNotEmpty, isTrue);

      // 3. Tutor Continuity Response
      expect(turn.tutorContinuity.coachReply.isNotEmpty, isTrue);
      expect(turn.tutorContinuity.followUpQuestions.isNotEmpty, isTrue);
    });

    test('Punjabi-to-English conversational turn tracks Gurmukhi verb syntax and local idioms', () {
      final turn = GrammarLabService.generateSemanticLabResponse(
        userText: 'ਮੈਂ ਇਹ ਕਿਤਾਬ ਪੜ੍ਹਦਾ ਚਾਹੁੰਦੀ ਹਾਂ।',
        userLanguage: AppLanguage.punjabi,
        targetLanguage: AppLanguage.english,
      );

      // 1. Grammar Check
      expect(turn.grammarCheck.hasErrors, isTrue);
      expect(turn.grammarCheck.correctionNotes.first.correctedSegment, 'ਪੜ੍ਹਨਾ ਚਾਹੁੰਦੀ');

      // 2. Natural Fluency Suggestion
      expect(turn.fluencySuggestion.registerTag, contains('ਮਾਝੀ'));
      expect(turn.fluencySuggestion.alternativeExpressions.isNotEmpty, isTrue);

      // 3. Tutor Continuity Response
      expect(turn.tutorContinuity.coachReply.isNotEmpty, isTrue);
      expect(turn.tutorContinuity.followUpQuestions.length, greaterThanOrEqualTo(2));
    });

    test('Visual frame payload is integrated into tutor continuity response context', () async {
      final router = OnDemandVisionRouter();
      final frame = await router.captureFromText(textQuery: 'Check page');

      final turn = GrammarLabService.generateSemanticLabResponse(
        userText: 'Can you analyze this page?',
        userLanguage: AppLanguage.english,
        targetLanguage: AppLanguage.english,
        frame: frame,
      );

      expect(turn.visionContextFrame, isNotNull);
      expect(turn.tutorContinuity.coachReply, contains('captured camera frame'));
    });

    test('AppStateController manages dedicated Conversation Lab Mode turns', () async {
      final controller = AppStateController(
        initialInputLanguage: AppLanguage.english,
        initialOutputLanguage: AppLanguage.english,
      );

      expect(controller.conversationLabHistory.isEmpty, isTrue);

      await controller.sendConversationLabMessage(message: 'She go to the library');

      expect(controller.conversationLabHistory.length, 1);
      final turn = controller.currentLabTurn!;
      expect(turn.userMessage, 'She go to the library');
      expect(turn.grammarCheck.hasErrors, isTrue);
      expect(turn.grammarCheck.correctionNotes.first.correctedSegment, 'goes');
      expect(turn.fluencySuggestion.idiomaticVersion.isNotEmpty, isTrue);
      expect(turn.tutorContinuity.coachReply.isNotEmpty, isTrue);

      controller.dispose();
    });
  });

  group('Photograph UI Layout & Widget Tests', () {
    testWidgets('Renders all photograph UI elements with accurate layout and tags', (tester) async {
      final controller = AppStateController();

      await tester.pumpWidget(
        MaterialApp(
          home: CameraOverlayScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Top Header
      expect(find.text('BoliXR Companion'), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsWidgets);
      expect(find.text('Gemma-4-E2B-it'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);

      // 2. Assistant Message Card
      expect(find.text('Buddy'), findsOneWidget);
      expect(find.text('PocketTTS / Sooktam-2'), findsOneWidget);
      expect(find.text('Parakeet / IndicConformer ASR'), findsOneWidget);
      expect(find.text('Hi there! What are you looking to learn about today?'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // 3. Floating Translation FAB (文A)
      expect(find.byIcon(Icons.translate_rounded), findsOneWidget);

      // 4. Central Circular Mic FAB with Subtitle
      expect(find.text('Tap the mic to ask a question'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

      // 5. 3-Way Input Toggle Pill: Image | Audio | Text
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);

      // 6. Bottom Navigation Bar: Camera | Vocabulary | Study
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Vocabulary'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('3-Way Input toggle switches seamlessly between Audio, Text, and Image modes', (tester) async {
      final controller = AppStateController();

      await tester.pumpWidget(
        MaterialApp(
          home: CameraOverlayScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Default is Audio mode -> Mic FAB visible
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

      // Tap Text toggle
      await tester.tap(find.text('Text'));
      await tester.pumpAndSettle();

      expect(controller.activeInputMode, InputMode.text);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Tap Image toggle
      await tester.tap(find.text('Image'));
      await tester.pumpAndSettle();

      expect(controller.activeInputMode, InputMode.image);
      expect(find.text('Browse Local Gallery Photos'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Bottom Navigation Bar: switching to Study opens dedicated Conversation Lab Mode', (tester) async {
      final controller = AppStateController();

      await tester.pumpWidget(
        MaterialApp(
          home: CameraOverlayScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Study' tab
      await tester.tap(find.text('Study'));
      await tester.pumpAndSettle();

      expect(controller.activeTabIndex, 2);
      expect(controller.isConversationLabActive, isTrue);

      // Verify Conversation Lab split-view tabs & cards are rendered
      expect(find.text('Conversation Lab'), findsOneWidget);
      expect(find.text('SUPERNOVA'), findsOneWidget);
      expect(find.text('Grammar Check'), findsWidgets);
      expect(find.text('Natural Fluency'), findsWidgets);
      expect(find.text('Tutor Continuity'), findsWidgets);

      controller.dispose();
    });

    testWidgets('Bottom Navigation Bar: switching to Vocabulary opens Flashcard deck', (tester) async {
      final controller = AppStateController();

      await tester.pumpWidget(
        MaterialApp(
          home: CameraOverlayScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Vocabulary' tab
      await tester.tap(find.text('Vocabulary'));
      await tester.pumpAndSettle();

      expect(controller.activeTabIndex, 1);
      expect(find.text('Vocabulary & AI Flashcards'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Photograph vertical hierarchy: Mic FAB is above subtitle prompt, and subtitle is above 3-way toggle', (tester) async {
      final controller = AppStateController();

      await tester.pumpWidget(
        MaterialApp(
          home: CameraOverlayScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final micCenter = tester.getCenter(find.byIcon(Icons.mic_rounded));
      final subtitleCenter = tester.getCenter(find.text('Tap the mic to ask a question'));
      final toggleCenter = tester.getCenter(find.text('Audio'));

      // In photograph: Mic FAB is above subtitle, subtitle is above 3-way toggle
      expect(micCenter.dy, lessThan(subtitleCenter.dy));
      expect(subtitleCenter.dy, lessThan(toggleCenter.dy));

      controller.dispose();
    });

    testWidgets('Mic FAB tap-and-hold (Long press) lifecycle triggers recording, transcription, and single frame capture', (tester) async {
      final controller = AppStateController();

      await tester.pumpWidget(
        MaterialApp(
          home: CameraOverlayScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.audioService.isRecording, isFalse);
      expect(controller.visionRouter.onDemandFrameCount, 0);

      // Start long press (hold)
      final micGesture = await tester.startGesture(tester.getCenter(find.byIcon(Icons.mic_rounded)));
      await tester.pump(const Duration(milliseconds: 600)); // Trigger long press

      expect(controller.audioService.isRecording, isTrue);

      // Release hold (long press end)
      await micGesture.up();
      // Pump enough time for ASR (~320ms), Vision (~140ms), and Gemma inference (~850ms)
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(controller.audioService.isRecording, isFalse);
      expect(controller.visionRouter.onDemandFrameCount, 1);
      expect(controller.visionRouter.lastCapturedPayload?.triggerSource, VisionTriggerSource.audioVoice);

      controller.dispose();
    });

    testWidgets('Conversation Lab: Text submission kicks off single-frame vision loop and integrates visual context', (tester) async {
      final controller = AppStateController(
        initialInputLanguage: AppLanguage.english,
        initialOutputLanguage: AppLanguage.english,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CameraOverlayScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Open Conversation Lab via Study tab
      await tester.tap(find.text('Study'));
      // Allow initial seeded turn to finish inference
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      final initialFrameCount = controller.visionRouter.onDemandFrameCount;

      // Enter text into Conversation Lab text field
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, "I didn't went to class");
      await tester.tap(find.byIcon(Icons.send_rounded));
      // Pump for vision capture (~140ms) and conversation lab inference (~900ms)
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify on-demand frame capture was triggered
      expect(controller.visionRouter.onDemandFrameCount, initialFrameCount + 1);
      expect(controller.visionRouter.lastCapturedPayload?.triggerSource, VisionTriggerSource.textQuery);

      // Verify Conversation Lab turn has the grammar check error and visual context
      final latestTurn = controller.currentLabTurn!;
      expect(latestTurn.userMessage, "I didn't went to class");
      expect(latestTurn.grammarCheck.hasErrors, isTrue);
      expect(latestTurn.grammarCheck.correctionNotes.first.correctedSegment, "didn't go");
      expect(latestTurn.visionContextFrame, isNotNull);

      controller.dispose();
    });

    testWidgets('Conversation Lab: Tap-and-hold on mic button records, transcribes, and captures frame', (tester) async {
      final controller = AppStateController(
        initialInputLanguage: AppLanguage.english,
        initialOutputLanguage: AppLanguage.english,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CameraOverlayScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Open Conversation Lab
      await tester.tap(find.text('Study'));
      // Allow initial seeded turn to settle
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      final initialFrameCount = controller.visionRouter.onDemandFrameCount;

      // Locate mic button inside input bar
      final micFinder = find.byIcon(Icons.mic_rounded);
      expect(micFinder, findsOneWidget);

      // Long press (hold)
      final gesture = await tester.startGesture(tester.getCenter(micFinder));
      await tester.pump(const Duration(milliseconds: 600));

      expect(controller.audioService.isRecording, isTrue);

      // Release hold
      await gesture.up();
      // Pump for ASR (~320ms), vision frame capture (~140ms), and conversation lab (~900ms)
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(controller.audioService.isRecording, isFalse);
      expect(controller.visionRouter.onDemandFrameCount, initialFrameCount + 1);
      expect(controller.currentLabTurn?.visionContextFrame, isNotNull);

      controller.dispose();
    });

    test('AudioCaptureService: Concurrent startRecording calls during transcribing are safely rejected', () async {
      final service = AudioCaptureService();

      service.startRecording();
      expect(service.isRecording, isTrue);

      final transcribeFuture = service.stopRecordingAndTranscribe(language: AppLanguage.english);
      expect(service.isTranscribing, isTrue);

      // Attempt to start recording while transcribing
      service.startRecording();
      // Should remain transcribing, NOT reset to recording
      expect(service.isTranscribing, isTrue);
      expect(service.isRecording, isFalse);

      await transcribeFuture;
      expect(service.state, AudioCaptureState.completed);

      service.dispose();
    });

    test('GrammarLabService: Large text truncation prevents memory overflow', () {
      final hugeText = 'A' * 3000;
      final prompt = GrammarLabService.buildGemmaPrompt(
        userText: hugeText,
        sourceLanguage: AppLanguage.english,
        targetLanguage: AppLanguage.english,
      );

      expect(prompt.length, lessThan(3000));
      expect(prompt, contains('[truncated]'));

      final turn = GrammarLabService.generateSemanticLabResponse(
        userText: hugeText,
        userLanguage: AppLanguage.english,
        targetLanguage: AppLanguage.english,
      );
      expect(turn.userMessage.length, lessThanOrEqualTo(1503));
    });

    test('GrammarLabService: Punjabi plural concord rule detects "ਉਹ ਆਉਂਦੇ ਹੈ" and corrects to "ਹਨ"', () {
      final turn = GrammarLabService.generateSemanticLabResponse(
        userText: 'ਉਹ ਹਰ ਰੋਜ਼ ਇੱਥੇ ਆਉਂਦੇ ਹੈ।',
        userLanguage: AppLanguage.punjabi,
        targetLanguage: AppLanguage.english,
      );

      expect(turn.grammarCheck.hasErrors, isTrue);
      expect(turn.grammarCheck.correctionNotes.first.ruleType, 'Subject-Verb Concord');
      expect(turn.grammarCheck.correctionNotes.first.correctedSegment, 'ਆਉਂਦੇ ਹਨ');
      expect(turn.fluencySuggestion.registerTag, contains('ਪੰਜਾਬੀ'));
    });

    test('GrammarLabService: English irregular past tense rule detects "buyed" and corrects to "bought"', () {
      final turn = GrammarLabService.generateSemanticLabResponse(
        userText: 'I buyed a new dictionary yesterday.',
        userLanguage: AppLanguage.english,
        targetLanguage: AppLanguage.english,
      );

      expect(turn.grammarCheck.hasErrors, isTrue);
      expect(turn.grammarCheck.correctionNotes.first.ruleType, 'Irregular Past Tense');
      expect(turn.grammarCheck.correctionNotes.first.correctedSegment, 'bought');
    });
  });

  group('Dynamic Semantic Query Engine & Vocab Found Tests', () {
    test('Dynamic Query: "translate it \'how are you?\'" produces authentic Gurmukhi Punjabi translation and sets activeVocabResult', () async {
      final controller = AppStateController(
        initialInputLanguage: AppLanguage.english,
        initialOutputLanguage: AppLanguage.punjabi,
      );

      expect(controller.activeVocabResult, isNull);

      await controller.submitTextQuery('translate it "how are you?"');

      expect(controller.assistantMessage, contains('ਤੁਸੀਂ ਕਿਵੇਂ ਹੋ?'));
      expect(controller.activeVocabResult, isNotNull);
      final entity = controller.activeVocabResult!;
      final learning = entity.getLearning(AppLanguage.english, AppLanguage.punjabi);
      expect(learning.targetTerm, 'ਤੁਸੀਂ ਕਿਵੇਂ ਹੋ?');
      expect(learning.targetPhonetic, contains('Tusi kive ho'));
      expect(learning.targetExampleSentence, contains('ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ'));
    });

    test('Dynamic Query: "what are you doing" recognizes workspace context and generates bilingual response', () async {
      final controller = AppStateController(
        initialInputLanguage: AppLanguage.english,
        initialOutputLanguage: AppLanguage.punjabi,
      );

      await controller.submitTextQuery('what are you doing');

      expect(controller.assistantMessage, contains('ਲੈਪਟਾਪ'));
      expect(controller.activeVocabResult, isNotNull);
      expect(controller.activeVocabResult!.englishLabel, contains('Laptop'));
    });

    testWidgets('VocabFoundSheet renders correctly and "Save to Vocab" adds dynamic entity to flashcard review deck', (tester) async {
      final controller = AppStateController(
        initialInputLanguage: AppLanguage.english,
        initialOutputLanguage: AppLanguage.punjabi,
      );

      final result = DynamicQueryEngine.processQuery(
        rawQuery: 'translate it "how are you?"',
        sourceLanguage: AppLanguage.english,
        targetLanguage: AppLanguage.punjabi,
      );
      final entity = result.detectedEntity;
      controller.setActiveVocabResult(entity);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VocabFoundSheet(
              controller: controller,
              entity: entity,
              onClose: () => controller.clearActiveVocabResult(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Vocab found'), findsOneWidget);
      expect(find.text('ਤੁਸੀਂ ਕਿਵੇਂ ਹੋ?'), findsOneWidget);
      expect(find.text('Save to Vocab'), findsOneWidget);
      expect(find.text('Ask a follow up'), findsOneWidget);
      expect(find.text('Ask about something else'), findsOneWidget);

      final initialDeckLength = controller.flashcardDeck.length;

      // Tap "Save to Vocab"
      await tester.tap(find.text('Save to Vocab'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.flashcardDeck.length, initialDeckLength + 1);
      expect(controller.flashcardDeck.first.sourceTerm, 'How are you?');
      expect(find.text('Saved to Vocab'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('CameraOverlayScreen renders clean camera viewport and opens VocabFoundSheet on dynamic query', (tester) async {
      final controller = AppStateController(
        initialInputLanguage: AppLanguage.english,
        initialOutputLanguage: AppLanguage.punjabi,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CameraOverlayScreen(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('BoliXR Companion'), findsOneWidget);
      expect(find.text('Vocab found'), findsNothing);

      // Set active vocab result
      final result = DynamicQueryEngine.processQuery(
        rawQuery: 'translate it "how are you?"',
        sourceLanguage: AppLanguage.english,
        targetLanguage: AppLanguage.punjabi,
      );
      controller.setActiveVocabResult(result.detectedEntity);
      await tester.pump(const Duration(milliseconds: 100));

      // Vocab found sheet should now be visible on screen
      expect(find.text('Vocab found'), findsOneWidget);
      expect(find.text('ਤੁਸੀਂ ਕਿਵੇਂ ਹੋ?'), findsOneWidget);

      // Dismiss sheet
      await tester.tap(find.text('Ask about something else'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.activeVocabResult, isNull);
      expect(find.text('Vocab found'), findsNothing);

      controller.dispose();
    });
  });
}
