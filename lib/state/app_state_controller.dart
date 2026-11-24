import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/app_language.dart';
import '../models/app_mode.dart';
import '../models/conversation_lab_model.dart';
import '../models/recognized_entity.dart';
import '../models/vision_frame_payload.dart';
import '../models/vocabulary_item.dart';
import '../services/audio_capture_service.dart';
import '../services/model_lifecycle_manager.dart';
import '../services/on_demand_vision_router.dart';
import '../utils/mock_detection_data.dart';

/// 3-way input toggle modes corresponding to the photograph
enum InputMode {
  image,
  audio,
  text,
}

/// Central state controller managing language selections, mode derivation,
/// real-time camera recognition entities, dynamic flashcard review deck,
/// on-demand single frame vision router, 16kHz mono audio mic channel,
/// and backend ModelLifecycleManager hardware execution.
class AppStateController extends ChangeNotifier {
  AppStateController({
    AppLanguage initialInputLanguage = AppLanguage.punjabi,
    AppLanguage initialOutputLanguage = AppLanguage.english,
  })  : _inputLanguage = initialInputLanguage,
        _outputLanguage = initialOutputLanguage,
        lifecycleManager = ModelLifecycleManager(),
        visionRouter = OnDemandVisionRouter(),
        audioService = AudioCaptureService() {
    _detectedEntities = MockDetectionData.getEntities();
    if (_detectedEntities.isNotEmpty) {
      _activeEntity = _detectedEntities.first;
    }
    _seedInitialFlashcards();

    // Propagate lifecycle manager, vision router & audio service updates to UI
    lifecycleManager.addListener(_onServiceChanged);
    visionRouter.addListener(_onServiceChanged);
    audioService.addListener(_onServiceChanged);
  }

  /// Backend Model Lifecycle Manager enforcing <700MB sequential memory limits
  final ModelLifecycleManager lifecycleManager;

  /// Event-driven single-frame vision router decoupling camera from continuous AI
  final OnDemandVisionRouter visionRouter;

  /// Embedded 16kHz mono audio recording channel
  final AudioCaptureService audioService;

  void _onServiceChanged() {
    notifyListeners();
  }

  // --- Navigation & View Target State ---
  int _activeTabIndex = 0; // 0: Camera, 1: Vocabulary, 2: Study (Conversation Lab)
  InputMode _activeInputMode = InputMode.audio;
  bool _isConversationLabActive = false;

  int get activeTabIndex => _activeTabIndex;
  InputMode get activeInputMode => _activeInputMode;
  bool get isConversationLabActive => _isConversationLabActive;

  void setActiveTab(int index) {
    if (_activeTabIndex != index) {
      _activeTabIndex = index;
      if (index == 2) {
        _isConversationLabActive = true;
      } else {
        _isConversationLabActive = false;
      }
      notifyListeners();
    }
  }

  void setInputMode(InputMode mode) {
    if (_activeInputMode != mode) {
      _activeInputMode = mode;
      notifyListeners();
    }
  }

  void toggleConversationLab([bool? active]) {
    _isConversationLabActive = active ?? !_isConversationLabActive;
    if (_isConversationLabActive) {
      _activeTabIndex = 2;
    }
    notifyListeners();
  }

  // --- Assistant Message & Audio Playback ---
  String _assistantMessage = 'Hi there! What are you looking to learn about today?';
  String get assistantMessage => _assistantMessage;
  RecognizedEntity? _activeVocabResult;
  RecognizedEntity? get activeVocabResult => _activeVocabResult;

  void setAssistantMessage(String message) {
    _assistantMessage = message;
    notifyListeners();
  }

  void clearActiveVocabResult() {
    _activeVocabResult = null;
    notifyListeners();
  }

  void setActiveVocabResult(RecognizedEntity? entity) {
    _activeVocabResult = entity;
    notifyListeners();
  }

  Future<void> playAssistantAudio([String? textOverride]) async {
    final text = textOverride ?? _assistantMessage;
    await lifecycleManager.synthesizeSpeechOnly(
      text: text,
      language: _outputLanguage,
    );
  }

  // --- Supernova-Style Conversation Lab History ---
  final List<ConversationLabTurn> _conversationLabHistory = [];
  List<ConversationLabTurn> get conversationLabHistory => List.unmodifiable(_conversationLabHistory);

  ConversationLabTurn? get currentLabTurn =>
      _conversationLabHistory.isNotEmpty ? _conversationLabHistory.first : null;

  /// Sends a free-form message in Conversation Lab Mode (English-to-English or Punjabi-to-English)
  Future<ConversationLabTurn> sendConversationLabMessage({
    required String message,
    CapturedFramePayload? visualFrame,
  }) async {
    final turn = await lifecycleManager.runConversationLabInference(
      userUtterance: message,
      sourceLanguage: _inputLanguage,
      targetLanguage: _outputLanguage,
      visualFrame: visualFrame,
    );
    _conversationLabHistory.insert(0, turn);
    _assistantMessage = turn.tutorContinuity.coachReply;
    notifyListeners();
    return turn;
  }

  // --- On-Demand Event Triggers ---
  bool _isAudioProcessing = false;

  /// 1. Voice Input Trigger: Finishes 16kHz audio capture, routes directly to
  /// 'indic_conformer_int8.onnx', captures exactly ONE static frame, and passes payload to Gemma-4-E2B-it.
  Future<void> startAudioRecording() async {
    if (_isAudioProcessing || audioService.isTranscribing) return;
    audioService.startRecording();
  }

  Future<void> stopAudioRecordingAndProcess({Uint8List? cameraBuffer}) async {
    if (_isAudioProcessing) return;
    _isAudioProcessing = true;
    try {
      final transcribedText = await audioService.stopRecordingAndTranscribe(
        language: _inputLanguage,
      );

      if (transcribedText.isEmpty) return;

      // Capture exactly ONE static frame from camera buffer
      final framePayload = await visionRouter.captureFromVoice(
        voiceTranscript: transcribedText,
        cameraBuffer: cameraBuffer,
      );

      if (_isConversationLabActive || _activeTabIndex == 2) {
        await sendConversationLabMessage(
          message: transcribedText,
          visualFrame: framePayload,
        );
      } else {
        // Standard Buddy / Learning analysis
        final answer = await lifecycleManager.runOnDemandVisionInference(
          framePayload: framePayload,
          inputLanguage: _inputLanguage,
          outputLanguage: _outputLanguage,
          mode: currentMode,
          entityContext: _activeEntity,
          promptOverride: transcribedText,
        );
        _assistantMessage = answer;
        _activeVocabResult = lifecycleManager.lastGeneratedEntity ?? _activeEntity;
        notifyListeners();
      }
    } finally {
      _isAudioProcessing = false;
    }
  }

  /// 2. Text Input Trigger: User submits a text query, capturing exactly ONE static frame.
  Future<void> submitTextQuery(String queryText, {Uint8List? cameraBuffer}) async {
    if (queryText.trim().isEmpty) return;

    final framePayload = await visionRouter.captureFromText(
      textQuery: queryText,
      cameraBuffer: cameraBuffer,
    );

    if (_isConversationLabActive || _activeTabIndex == 2) {
      await sendConversationLabMessage(
        message: queryText,
        visualFrame: framePayload,
      );
    } else {
      final answer = await lifecycleManager.runOnDemandVisionInference(
        framePayload: framePayload,
        inputLanguage: _inputLanguage,
        outputLanguage: _outputLanguage,
        mode: currentMode,
        entityContext: _activeEntity,
        promptOverride: queryText,
      );
      _assistantMessage = answer;
      _activeVocabResult = lifecycleManager.lastGeneratedEntity ?? _activeEntity;
      notifyListeners();
    }
  }

  /// 3. Image Gallery Trigger: User selects a photo from the local gallery.
  Future<void> selectGalleryPhoto(String imageName, {Uint8List? imageBytes}) async {
    final framePayload = await visionRouter.captureFromGallery(
      galleryImageName: imageName,
      galleryImageBytes: imageBytes,
    );

    if (_isConversationLabActive || _activeTabIndex == 2) {
      await sendConversationLabMessage(
        message: 'Analyze local gallery image: "$imageName".',
        visualFrame: framePayload,
      );
    } else {
      final answer = await lifecycleManager.runOnDemandVisionInference(
        framePayload: framePayload,
        inputLanguage: _inputLanguage,
        outputLanguage: _outputLanguage,
        mode: currentMode,
        entityContext: _activeEntity,
        promptOverride: 'Analyze local gallery image: "$imageName". Provide language insights in ${_outputLanguage.name}.',
      );
      _assistantMessage = answer;
      _activeVocabResult = lifecycleManager.lastGeneratedEntity ?? _activeEntity;
      notifyListeners();
    }
  }

  // --- Language & Mode State ---
  AppLanguage _inputLanguage;
  AppLanguage _outputLanguage;

  AppLanguage get inputLanguage => _inputLanguage;
  AppLanguage get outputLanguage => _outputLanguage;

  /// Derived mode: Exploration when Input == Output, Learning when Input != Output.
  AppMode get currentMode => AppMode.derive(
        inputLanguage: _inputLanguage,
        outputLanguage: _outputLanguage,
      );

  void setInputLanguage(AppLanguage language) {
    if (_inputLanguage != language) {
      _inputLanguage = language;
      notifyListeners();
    }
  }

  void setOutputLanguage(AppLanguage language) {
    if (_outputLanguage != language) {
      _outputLanguage = language;
      notifyListeners();
    }
  }

  /// Swap input and output languages easily
  void swapLanguages() {
    final temp = _inputLanguage;
    _inputLanguage = _outputLanguage;
    _outputLanguage = temp;
    notifyListeners();
  }

  // --- Camera Vision Detection State ---
  List<RecognizedEntity> _detectedEntities = [];
  RecognizedEntity? _activeEntity;
  bool _isScanning = true;

  List<RecognizedEntity> get detectedEntities => _detectedEntities;
  RecognizedEntity? get activeEntity => _activeEntity;
  
  /// Vision is automatically locked when the backend manager is processing ASR/Gemma/TTS
  bool get isScanning => _isScanning && !lifecycleManager.isVisionPipelineLocked;

  void toggleScanning() {
    _isScanning = !_isScanning;
    notifyListeners();
  }

  void selectEntity(RecognizedEntity entity) {
    _activeEntity = entity;
    notifyListeners();
  }

  void cycleNextEntity() {
    if (_detectedEntities.isEmpty) return;
    final currentIndex = _detectedEntities.indexOf(_activeEntity!);
    final nextIndex = (currentIndex + 1) % _detectedEntities.length;
    _activeEntity = _detectedEntities[nextIndex];
    notifyListeners();
  }

  // --- Model Execution & Assembly Triggers ---

  /// Executes the full sequential pipeline: ASR -> Gemma 4 E2B -> Sooktam-2 TTS
  Future<void> triggerLiveInferencePipeline({String? promptOverride}) async {
    await lifecycleManager.runSequentialPipeline(
      inputLanguage: _inputLanguage,
      outputLanguage: _outputLanguage,
      mode: currentMode,
      entityContext: _activeEntity,
      userPromptOverride: promptOverride,
    );
  }

  /// Plays synthesized speech using Sooktam-2 / LiteRT TTS
  Future<void> triggerSpeechSynthesis(String text, AppLanguage language) async {
    await lifecycleManager.synthesizeSpeechOnly(text: text, language: language);
  }

  // --- Dynamic Flashcard System State ---
  final List<VocabularyItem> _flashcardDeck = [];
  bool _isFlashcardDeckExpanded = false;
  int _currentCardIndex = 0;

  List<VocabularyItem> get flashcardDeck => List.unmodifiable(_flashcardDeck);
  bool get isFlashcardDeckExpanded => _isFlashcardDeckExpanded;
  int get currentCardIndex => _currentCardIndex;

  VocabularyItem? get currentCard {
    if (_flashcardDeck.isEmpty || _currentCardIndex >= _flashcardDeck.length) {
      return null;
    }
    return _flashcardDeck[_currentCardIndex];
  }

  void toggleFlashcardDeck() {
    _isFlashcardDeckExpanded = !_isFlashcardDeckExpanded;
    notifyListeners();
  }

  void setFlashcardDeckExpanded(bool expanded) {
    _isFlashcardDeckExpanded = expanded;
    notifyListeners();
  }

  /// Adds the currently active entity to the dynamic Flashcard review deck
  bool addActiveEntityToFlashcards([RecognizedEntity? targetEntity]) {
    final entityToSave = targetEntity ?? _activeVocabResult ?? _activeEntity;
    if (entityToSave == null) return false;

    final sourceTerm = entityToSave.getTerm(_inputLanguage);
    final exists = _flashcardDeck.any((item) =>
        item.sourceTerm == sourceTerm &&
        item.sourceLanguage == _inputLanguage &&
        item.targetLanguage == _outputLanguage);

    if (exists) {
      return false; // Already present
    }

    final VocabularyItem newItem;
    if (currentMode.isLearning) {
      newItem = VocabularyItem.fromLearning(
        entity: entityToSave,
        sourceLang: _inputLanguage,
        targetLang: _outputLanguage,
      );
    } else {
      newItem = VocabularyItem.fromExploration(
        entity: entityToSave,
        language: _inputLanguage,
      );
    }

    _flashcardDeck.insert(0, newItem);
    _currentCardIndex = 0;
    notifyListeners();
    return true;
  }

  void updateCardMastery(String cardId, MasteryLevel level) {
    final index = _flashcardDeck.indexWhere((c) => c.id == cardId);
    if (index != -1) {
      _flashcardDeck[index].masteryLevel = level;
      _flashcardDeck[index].reviewCount += 1;
      notifyListeners();
    }
  }

  void flipCurrentCard() {
    final card = currentCard;
    if (card != null) {
      card.isFlipped = !card.isFlipped;
      notifyListeners();
    }
  }

  void nextCard() {
    if (_flashcardDeck.isEmpty) return;
    _currentCardIndex = (_currentCardIndex + 1) % _flashcardDeck.length;
    currentCard?.isFlipped = false;
    notifyListeners();
  }

  void previousCard() {
    if (_flashcardDeck.isEmpty) return;
    _currentCardIndex = (_currentCardIndex - 1 + _flashcardDeck.length) % _flashcardDeck.length;
    currentCard?.isFlipped = false;
    notifyListeners();
  }

  void removeCard(String cardId) {
    _flashcardDeck.removeWhere((c) => c.id == cardId);
    if (_currentCardIndex >= _flashcardDeck.length) {
      _currentCardIndex = _flashcardDeck.isEmpty ? 0 : _flashcardDeck.length - 1;
    }
    notifyListeners();
  }

  void _seedInitialFlashcards() {
    if (_detectedEntities.isNotEmpty) {
      final seed = VocabularyItem.fromLearning(
        entity: _detectedEntities.first,
        sourceLang: AppLanguage.punjabi,
        targetLang: AppLanguage.english,
      );
      _flashcardDeck.add(seed);
    }
  }

  @override
  void dispose() {
    lifecycleManager.removeListener(_onServiceChanged);
    visionRouter.removeListener(_onServiceChanged);
    audioService.removeListener(_onServiceChanged);
    lifecycleManager.dispose();
    visionRouter.dispose();
    audioService.dispose();
    super.dispose();
  }
}
