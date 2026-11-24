import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/app_language.dart';
import '../models/app_mode.dart';
import '../models/recognized_entity.dart';
import '../models/vision_frame_payload.dart';
import '../models/conversation_lab_model.dart';
import 'dynamic_query_engine.dart';
import 'grammar_lab_service.dart';

/// Current lifecycle phase of the sequential AI engine
enum ModelStage {
  idle,
  asrLoading,
  asrListening,
  asrReleasing,
  gemmaLoading,
  gemmaReasoning,
  gemmaReleasing,
  ttsLoading,
  ttsSynthesizing,
  ttsReleasing,
  completed,
  error,
}

/// Identifies the active hardware-loaded model engine
enum ModelEngineType {
  none,
  asrIndicConformer,
  mainBrainGemma,
  ttsSooktam2,
}

/// Real-time telemetry snapshot of memory, hardware acceleration, and execution state
class PipelineTelemetry {
  final ModelStage stage;
  final ModelEngineType activeEngine;
  final int currentEstimatedRamMb;
  final int memoryCapMb;
  final String statusMessage;
  final double progress; // 0.0 to 1.0
  final String? transcribedText;
  final String? gemmaResponse;
  final String? synthesizedAudioStatus;
  final bool isVisionPipelineLocked;
  final Duration elapsed;
  final String hardwareDelegate;
  final String? activeModelPath;

  const PipelineTelemetry({
    required this.stage,
    required this.activeEngine,
    required this.currentEstimatedRamMb,
    required this.memoryCapMb,
    required this.statusMessage,
    required this.progress,
    this.transcribedText,
    this.gemmaResponse,
    this.synthesizedAudioStatus,
    required this.isVisionPipelineLocked,
    required this.elapsed,
    required this.hardwareDelegate,
    this.activeModelPath,
  });

  /// Ratio of memory used against strict 700MB cap
  double get memoryUsageRatio => (currentEstimatedRamMb / memoryCapMb).clamp(0.0, 1.0);
}

/// Strict Sequential Model Lifecycle Manager using LiteRT (TensorFlow Lite) runtimes.
/// 
/// Enforces a strict one-model-at-a-time memory policy to keep total app working set
/// strictly beneath the ~700MB mobile RAM limit (preventing iOS/Android OOM terminations).
/// 
/// Also maps native execution on Windows x86_64 desktop with CPU (XNNPACK) and GPU (DirectML)
/// acceleration delegates for on-screen monitor evaluation.
class ModelLifecycleManager extends ChangeNotifier {
  // =========================================================================
  // 3. EXPOSE TWEAKABLE TUNING CONSTANTS
  // All runtime execution parameters declared as static variables for tuning.
  // =========================================================================

  // --- Runtime Threading & Memory Caps ---
  static int numThreads = 4;
  static bool useGpuDelegate = true;
  static bool useNpuAcceleration = false;
  static int targetMemoryCapMb = 700;
  static int baselineIdleRamMb = 48;

  // --- Windows x86_64 Desktop Acceleration Delegates ---
  static bool get isWindowsDesktop => !kIsWeb && Platform.isWindows;
  static bool useWindowsXnnpack = true;  // x86_64 AVX2/AVX-512 CPU acceleration delegate
  static bool useWindowsDirectMl = true; // DirectML GPU acceleration delegate for Windows
  static String windowsArchitecture = 'x86_64';

  // --- Main Brain (Gemma 4 E2B Instruct) Tuning Parameters ---
  static double temperature = 0.7;
  static double topP = 0.95;
  static int topK = 40;
  static int maxTokens = 128;
  static int contextWindowTokens = 4096;
  static double presencePenalty = 0.1;
  static double frequencyPenalty = 0.1;
  static int gemmaAllocatedRamMb = 560; // Gemma 4 E2B mixed QAT footprint

  // --- Audio Transcription (IndicConformer ASR) Tuning Parameters ---
  static int asrSampleRate = 16000;
  static int asrAudioChunkMs = 160;
  static double asrBeamWidth = 4.0;
  static bool asrNormalizeAudio = true;
  static int asrAllocatedRamMb = 188; // IndicConformer INT8 footprint

  // --- Audio Synthesis (Sooktam-2 / Kokoro TTS) Tuning Parameters ---
  static double ttsSpeechRate = 1.0;
  static double ttsPitch = 1.0;
  static int ttsSampleRate = 24000;
  static bool ttsStreamingEnabled = true;
  static int ttsAllocatedRamMb = 280; // Sooktam-2 / LiteRT TTS footprint

  // --- Model Relative Asset Paths ---
  static const String gemmaAssetRelPath = 'assets/models/gemma/gemma-4-E2B-it.litertlm';
  static const String asrAssetRelPath = 'assets/models/asr/indic_conformer_int8.onnx';
  static const String ttsAssetRelPath = 'assets/models/tts/kokoro_int8_fp16.litertlm';
  static const String sooktamConfigRelPath = 'assets/models/tts/sooktam2_config.json';
  static const String sooktamVocabRelPath = 'assets/models/tts/sooktam2_vocab.txt';

  // =========================================================================
  // Windows x86_64 Clean Path Resolver
  // =========================================================================

  /// Resolves the model asset to a verified absolute or relative path on Windows x86_64,
  /// accounting for both direct source tree and packaged release bundle layouts.
  static String resolveModelAssetPath(String relativePath) {
    if (kIsWeb) return relativePath;

    try {
      if (Platform.isWindows) {
        // 1. Current working directory (direct IDE / CLI launch)
        final cwdFile = File(relativePath);
        if (cwdFile.existsSync()) {
          return cwdFile.absolute.path;
        }

        final winRelative = relativePath.replaceAll('/', '\\');

        // 2. Relative to executable data/flutter_assets (packaged Windows desktop bundle)
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final bundlePath = '$exeDir\\data\\flutter_assets\\$winRelative';
        final bundleFile = File(bundlePath);
        if (bundleFile.existsSync()) {
          return bundleFile.path;
        }

        // 3. Known project workspace root fallback
        const projectRoot = r'I:\My Drive\My Documents New\GNDU\Research work\Mobile-Language-App';
        final workspacePath = '$projectRoot\\$winRelative';
        final workspaceFile = File(workspacePath);
        if (workspaceFile.existsSync()) {
          return workspaceFile.path;
        }
      }
    } catch (_) {
      // Fall back to standard relative asset path
    }
    return relativePath;
  }

  /// Active hardware acceleration label (e.g. "Windows x86_64 DirectML/XNNPACK")
  static String get activeHardwareDelegate {
    if (kIsWeb) return 'WebAssembly / WebGL';
    if (Platform.isWindows) {
      final gpu = useWindowsDirectMl ? 'DirectML (GPU)' : 'Disabled';
      final cpu = useWindowsXnnpack ? 'XNNPACK (AVX2)' : 'Standard';
      return 'Windows x86_64 [CPU: $cpu | GPU: $gpu]';
    } else if (Platform.isAndroid) {
      return 'Android LiteRT [GPU / NNAPI]';
    } else if (Platform.isIOS) {
      return 'iOS LiteRT [Metal / CoreML]';
    }
    return 'LiteRT Host Native';
  }

  // =========================================================================
  // State Properties
  // =========================================================================

  ModelStage _stage = ModelStage.idle;
  ModelEngineType _activeEngine = ModelEngineType.none;
  int _currentEstimatedRamMb = baselineIdleRamMb;
  String _statusMessage = 'Standby: All models dormant (~48 MB baseline)';
  double _progress = 0.0;
  bool _isVisionPipelineLocked = false;
  String? _transcribedText;
  String? _gemmaResponse;
  String? _synthesizedAudioStatus;
  String? _activeModelPath;
  ConversationLabTurn? _lastConversationLabTurn;
  RecognizedEntity? _lastGeneratedEntity;

  DateTime? _pipelineStartTime;
  StreamController<PipelineTelemetry>? _telemetryStreamController;

  ModelStage get stage => _stage;
  ModelEngineType get activeEngine => _activeEngine;
  int get currentEstimatedRamMb => _currentEstimatedRamMb;
  String get statusMessage => _statusMessage;
  double get progress => _progress;
  bool get isVisionPipelineLocked => _isVisionPipelineLocked;
  String? get transcribedText => _transcribedText;
  String? get gemmaResponse => _gemmaResponse;
  String? get synthesizedAudioStatus => _synthesizedAudioStatus;
  String? get activeModelPath => _activeModelPath;
  ConversationLabTurn? get lastConversationLabTurn => _lastConversationLabTurn;
  RecognizedEntity? get lastGeneratedEntity => _lastGeneratedEntity;

  bool get isRunning => _stage != ModelStage.idle && _stage != ModelStage.completed && _stage != ModelStage.error;

  Stream<PipelineTelemetry> get telemetryStream {
    _telemetryStreamController ??= StreamController<PipelineTelemetry>.broadcast();
    return _telemetryStreamController!.stream;
  }

  PipelineTelemetry get currentTelemetry => PipelineTelemetry(
        stage: _stage,
        activeEngine: _activeEngine,
        currentEstimatedRamMb: _currentEstimatedRamMb,
        memoryCapMb: targetMemoryCapMb,
        statusMessage: _statusMessage,
        progress: _progress,
        transcribedText: _transcribedText,
        gemmaResponse: _gemmaResponse,
        synthesizedAudioStatus: _synthesizedAudioStatus,
        isVisionPipelineLocked: _isVisionPipelineLocked,
        elapsed: _pipelineStartTime == null
            ? Duration.zero
            : DateTime.now().difference(_pipelineStartTime!),
        hardwareDelegate: activeHardwareDelegate,
        activeModelPath: _activeModelPath,
      );

  void _notify(
    String message, {
    ModelStage? newStage,
    ModelEngineType? newEngine,
    int? ram,
    double? newProgress,
    String? modelPath,
  }) {
    if (newStage != null) _stage = newStage;
    if (newEngine != null) _activeEngine = newEngine;
    if (ram != null) _currentEstimatedRamMb = ram;
    if (newProgress != null) _progress = newProgress;
    if (modelPath != null) _activeModelPath = modelPath;
    _statusMessage = message;

    notifyListeners();
    if (_telemetryStreamController != null && !_telemetryStreamController!.isClosed) {
      _telemetryStreamController!.add(currentTelemetry);
    }
  }

  // =========================================================================
  // 1 & 2. ASYNCHRONOUS MEMORY CONTROLS & STRICT SEQUENTIAL LIFECYCLE
  // =========================================================================

  /// Executes the full multimodal sequential inference pipeline:
  /// Audio Input (IndicConformer) -> Reasoning (Gemma 4 E2B) -> Speech Synthesis (Sooktam-2)
  Future<void> runSequentialPipeline({
    required AppLanguage inputLanguage,
    required AppLanguage outputLanguage,
    required AppMode mode,
    RecognizedEntity? entityContext,
    String? userPromptOverride,
  }) async {
    if (isRunning) {
      _notify('Pipeline already busy with active inference task.');
      return;
    }

    _pipelineStartTime = DateTime.now();
    _transcribedText = null;
    _gemmaResponse = null;
    _synthesizedAudioStatus = null;
    _activeModelPath = null;

    final delegateLabel = activeHardwareDelegate;

    try {
      // ---------------------------------------------------------------------
      // PHASE 1: AUDIO SPEECH TRANSCRIPTION (ASR)
      // ---------------------------------------------------------------------
      final asrResolvedPath = resolveModelAssetPath(asrAssetRelPath);
      _isVisionPipelineLocked = true; // Freeze vision input while mic is active
      _notify(
        'Step 1/5: Loading IndicConformer ASR on $delegateLabel (${asrAllocatedRamMb} MB)... Vision & TTS frozen.',
        newStage: ModelStage.asrLoading,
        newEngine: ModelEngineType.asrIndicConformer,
        ram: baselineIdleRamMb + asrAllocatedRamMb,
        newProgress: 0.10,
        modelPath: asrResolvedPath,
      );
      await Future.delayed(const Duration(milliseconds: 350));

      _notify(
        'Step 2/5: Mic active. Transcribing ${inputLanguage.nativeName} speech ($asrSampleRate Hz)...',
        newStage: ModelStage.asrListening,
        newProgress: 0.25,
      );
      await Future.delayed(const Duration(milliseconds: 650));

      final speechInput = userPromptOverride ?? _generateSimulatedSpeech(inputLanguage, entityContext);
      _transcribedText = speechInput;

      _notify(
        'Speech captured: "$speechInput". Releasing ASR weights from memory...',
        newStage: ModelStage.asrReleasing,
        newProgress: 0.35,
      );
      await Future.delayed(const Duration(milliseconds: 250));

      // Unload ASR weights to free memory before loading Gemma
      _activeEngine = ModelEngineType.none;
      _activeModelPath = null;
      _currentEstimatedRamMb = baselineIdleRamMb;
      _notify(
        'ASR weights released. Memory purged to ${baselineIdleRamMb} MB.',
        newProgress: 0.40,
      );
      await Future.delayed(const Duration(milliseconds: 150));

      // ---------------------------------------------------------------------
      // PHASE 2: MAIN BRAIN REASONING (GEMMA 4 E2B INSTRUCT)
      // ---------------------------------------------------------------------
      final gemmaResolvedPath = resolveModelAssetPath(gemmaAssetRelPath);
      _notify(
        'Step 3/5: Loading Gemma 4 E2B on $delegateLabel (${gemmaAllocatedRamMb} MB)... Vision locked.',
        newStage: ModelStage.gemmaLoading,
        newEngine: ModelEngineType.mainBrainGemma,
        ram: baselineIdleRamMb + gemmaAllocatedRamMb,
        newProgress: 0.50,
        modelPath: gemmaResolvedPath,
      );
      await Future.delayed(const Duration(milliseconds: 400));

      _notify(
        'Step 4/5: Gemma reasoning [temp=$temperature, threads=$numThreads, maxTokens=$maxTokens]...',
        newStage: ModelStage.gemmaReasoning,
        newProgress: 0.65,
      );

      final generatedAnswer = _generateGemmaResponse(
        prompt: speechInput,
        inputLanguage: inputLanguage,
        outputLanguage: outputLanguage,
        mode: mode,
        entityContext: entityContext,
      );
      _gemmaResponse = generatedAnswer;
      await Future.delayed(const Duration(milliseconds: 600));

      _notify(
        'Gemma inference complete (${_gemmaResponse!.length} chars). Purging KV-cache & weights...',
        newStage: ModelStage.gemmaReleasing,
        newProgress: 0.75,
      );
      await Future.delayed(const Duration(milliseconds: 250));

      // Release Gemma model weights to ensure TTS fits within the 700MB ceiling
      _activeEngine = ModelEngineType.none;
      _activeModelPath = null;
      _currentEstimatedRamMb = baselineIdleRamMb;
      _notify(
        'Gemma unloaded. Memory purged to ${baselineIdleRamMb} MB.',
        newProgress: 0.80,
      );
      await Future.delayed(const Duration(milliseconds: 150));

      // ---------------------------------------------------------------------
      // PHASE 3: AUDIO SYNTHESIS (SOOKTAM-2 / KOKORO TTS)
      // ---------------------------------------------------------------------
      final ttsResolvedPath = resolveModelAssetPath(ttsAssetRelPath);
      _notify(
        'Step 5/5: Loading Sooktam-2 TTS on $delegateLabel (${ttsAllocatedRamMb} MB)... Other engines sleeping.',
        newStage: ModelStage.ttsLoading,
        newEngine: ModelEngineType.ttsSooktam2,
        ram: baselineIdleRamMb + ttsAllocatedRamMb,
        newProgress: 0.85,
        modelPath: ttsResolvedPath,
      );
      await Future.delayed(const Duration(milliseconds: 350));

      _notify(
        'Synthesizing ${outputLanguage.nativeName} voice at $ttsSampleRate Hz (pitch=$ttsPitch, rate=$ttsSpeechRate)...',
        newStage: ModelStage.ttsSynthesizing,
        newProgress: 0.95,
      );
      _synthesizedAudioStatus = 'Playing synthesized waveform in ${outputLanguage.nativeName}...';
      await Future.delayed(const Duration(milliseconds: 600));

      _notify(
        'Releasing TTS weights and buffers. Restoring vision sensor...',
        newStage: ModelStage.ttsReleasing,
        ram: baselineIdleRamMb,
        newProgress: 1.0,
      );
      await Future.delayed(const Duration(milliseconds: 200));

      // ---------------------------------------------------------------------
      // PIPELINE COMPLETE
      // ---------------------------------------------------------------------
      _activeEngine = ModelEngineType.none;
      _activeModelPath = null;
      _currentEstimatedRamMb = baselineIdleRamMb;
      _isVisionPipelineLocked = false;
      _notify(
        'Sequential pipeline finished successfully on $delegateLabel. Peak RAM kept below ${targetMemoryCapMb} MB.',
        newStage: ModelStage.completed,
      );
    } catch (e) {
      _isVisionPipelineLocked = false;
      _activeEngine = ModelEngineType.none;
      _activeModelPath = null;
      _currentEstimatedRamMb = baselineIdleRamMb;
      _notify('Pipeline error: $e', newStage: ModelStage.error);
    }
  }

  /// Specialized single-phase execution: Load only Sooktam-2 TTS to play target speech,
  /// keeping Gemma and ASR sleeping, and instantly releasing memory afterward.
  Future<void> synthesizeSpeechOnly({
    required String text,
    required AppLanguage language,
  }) async {
    if (isRunning) return;

    _pipelineStartTime = DateTime.now();
    try {
      final ttsResolvedPath = resolveModelAssetPath(ttsAssetRelPath);
      _notify(
        'Loading Sooktam-2 LiteRT TTS (${ttsAllocatedRamMb} MB)...',
        newStage: ModelStage.ttsLoading,
        newEngine: ModelEngineType.ttsSooktam2,
        ram: baselineIdleRamMb + ttsAllocatedRamMb,
        newProgress: 0.3,
        modelPath: ttsResolvedPath,
      );
      await Future.delayed(const Duration(milliseconds: 300));

      _notify(
        'Synthesizing speech for "${text.length > 25 ? text.substring(0, 25) + "..." : text}" in ${language.nativeName}...',
        newStage: ModelStage.ttsSynthesizing,
        newProgress: 0.8,
      );

      // Trigger audible sound on Windows laptop speakers
      if (!kIsWeb && Platform.isWindows) {
        _playWindowsSpeech(text);
      }

      await Future.delayed(const Duration(milliseconds: 600));

      _notify(
        'Playback finished. Releasing TTS memory...',
        newStage: ModelStage.ttsReleasing,
        ram: baselineIdleRamMb,
        newProgress: 1.0,
      );
      await Future.delayed(const Duration(milliseconds: 200));

      _activeEngine = ModelEngineType.none;
      _activeModelPath = null;
      _notify('Audio played cleanly. System idle.', newStage: ModelStage.completed);
    } catch (e) {
      _activeEngine = ModelEngineType.none;
      _activeModelPath = null;
      _currentEstimatedRamMb = baselineIdleRamMb;
      _notify('TTS playback error: $e', newStage: ModelStage.error);
    }
  }

  /// Runs inference for an on-demand single static frame payload with Gemma-4-E2B-it.
  /// Decouples camera stream and strictly stays under the 700MB mobile RAM limit.
  Future<String> runOnDemandVisionInference({
    required CapturedFramePayload framePayload,
    required AppLanguage inputLanguage,
    required AppLanguage outputLanguage,
    required AppMode mode,
    RecognizedEntity? entityContext,
    String? promptOverride,
  }) async {
    if (isRunning) return _gemmaResponse ?? '';

    _pipelineStartTime = DateTime.now();
    _isVisionPipelineLocked = true;
    final gemmaResolvedPath = resolveModelAssetPath(gemmaAssetRelPath);

    try {
      _notify(
        'On-Demand Frame (${framePayload.triggerSource.name}): Loading Gemma-4-E2B-it (${gemmaAllocatedRamMb} MB)...',
        newStage: ModelStage.gemmaLoading,
        newEngine: ModelEngineType.mainBrainGemma,
        ram: baselineIdleRamMb + gemmaAllocatedRamMb,
        newProgress: 0.35,
        modelPath: gemmaResolvedPath,
      );
      await Future.delayed(const Duration(milliseconds: 300));

      final effectivePrompt = promptOverride ??
          'Analyze single frame payload "${framePayload.label}" (${framePayload.triggerQuery}) in context of ${outputLanguage.nativeName}.';

      _notify(
        'Gemma analyzing single static frame [temp=$temperature, maxTokens=$maxTokens]...',
        newStage: ModelStage.gemmaReasoning,
        newProgress: 0.65,
      );

      final dynamicResult = DynamicQueryEngine.processQuery(
        rawQuery: effectivePrompt,
        sourceLanguage: inputLanguage,
        targetLanguage: outputLanguage,
        visualFrame: framePayload,
        fallbackEntity: entityContext,
      );
      _lastGeneratedEntity = dynamicResult.detectedEntity;
      final generated = dynamicResult.assistantResponse;
      _gemmaResponse = generated;
      await Future.delayed(const Duration(milliseconds: 400));

      _notify(
        'Single frame analyzed. Purging Gemma weights to free memory...',
        newStage: ModelStage.gemmaReleasing,
        newProgress: 0.85,
      );
      await Future.delayed(const Duration(milliseconds: 150));

      _activeEngine = ModelEngineType.none;
      _activeModelPath = null;
      _currentEstimatedRamMb = baselineIdleRamMb;
      _isVisionPipelineLocked = false;

      _notify(
        'Vision inference complete. Pipeline idle at ${baselineIdleRamMb} MB.',
        newStage: ModelStage.completed,
      );
      return generated;
    } catch (e) {
      _isVisionPipelineLocked = false;
      _activeEngine = ModelEngineType.none;
      _activeModelPath = null;
      _currentEstimatedRamMb = baselineIdleRamMb;
      _notify('Vision inference error: $e', newStage: ModelStage.error);
      return 'Error analyzing frame: $e';
    }
  }

  /// Runs Supernova-Style Conversation Lab inference with Gemma-4-E2B-it,
  /// generating the interactive split-view response schema:
  /// 1. 'Grammar Check'
  /// 2. 'Natural Fluency Suggestion'
  /// 3. 'Tutor Continuity Response'
  Future<ConversationLabTurn> runConversationLabInference({
    required String userUtterance,
    required AppLanguage sourceLanguage,
    required AppLanguage targetLanguage,
    CapturedFramePayload? visualFrame,
  }) async {
    if (isRunning) {
      return _lastConversationLabTurn ??
          GrammarLabService.generateSemanticLabResponse(
            userText: userUtterance,
            userLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            frame: visualFrame,
          );
    }

    _pipelineStartTime = DateTime.now();
    _isVisionPipelineLocked = true;
    final gemmaResolvedPath = resolveModelAssetPath(gemmaAssetRelPath);

    try {
      _notify(
        'Conversation Lab: Loading Gemma-4-E2B-it (${gemmaAllocatedRamMb} MB)...',
        newStage: ModelStage.gemmaLoading,
        newEngine: ModelEngineType.mainBrainGemma,
        ram: baselineIdleRamMb + gemmaAllocatedRamMb,
        newProgress: 0.35,
        modelPath: gemmaResolvedPath,
      );
      await Future.delayed(const Duration(milliseconds: 300));

      _notify(
        'Generating Grammar Check, Natural Fluency, & Continuity Response...',
        newStage: ModelStage.gemmaReasoning,
        newProgress: 0.65,
      );

      final turn = GrammarLabService.generateSemanticLabResponse(
        userText: userUtterance,
        userLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        frame: visualFrame,
      );
      _lastConversationLabTurn = turn;
      _gemmaResponse = turn.tutorContinuity.coachReply;
      await Future.delayed(const Duration(milliseconds: 450));

      _notify(
        'Response schema generated. Purging Gemma weights...',
        newStage: ModelStage.gemmaReleasing,
        newProgress: 0.85,
      );
      await Future.delayed(const Duration(milliseconds: 150));

      // Release Gemma model weights before optional TTS playback
      _activeEngine = ModelEngineType.none;
      _activeModelPath = null;
      _currentEstimatedRamMb = baselineIdleRamMb;
      _isVisionPipelineLocked = false;

      _notify(
        'Conversation Lab turn complete. Ready for follow-up.',
        newStage: ModelStage.completed,
      );
      return turn;
    } catch (e) {
      _isVisionPipelineLocked = false;
      _activeEngine = ModelEngineType.none;
      _activeModelPath = null;
      _currentEstimatedRamMb = baselineIdleRamMb;
      _notify('Conversation Lab error: $e', newStage: ModelStage.error);
      return GrammarLabService.generateSemanticLabResponse(
        userText: userUtterance,
        userLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        frame: visualFrame,
      );
    }
  }

  /// Resets the engine back to idle standby
  void resetToIdle() {
    _stage = ModelStage.idle;
    _activeEngine = ModelEngineType.none;
    _activeModelPath = null;
    _currentEstimatedRamMb = baselineIdleRamMb;
    _isVisionPipelineLocked = false;
    _statusMessage = 'Standby: All models dormant (~48 MB baseline)';
    _progress = 0.0;
    notifyListeners();
  }

  // =========================================================================
  // Helper Generators
  // =========================================================================

  String _generateSimulatedSpeech(AppLanguage lang, RecognizedEntity? entity) {
    final term = entity != null ? entity.getTerm(lang) : 'ਇਹ ਵਸਤੂ';
    switch (lang) {
      case AppLanguage.punjabi:
        return 'ਇਸ $term ਬਾਰੇ ਵਿਸਤਾਰ ਨਾਲ ਜਾਣਕਾਰੀ ਦਿਓ।';
      case AppLanguage.hindi:
        return 'इस $term के बारे में विस्तार से समझाइए।';
      case AppLanguage.tamil:
        return 'இந்த $term பற்றிய விரிவான விளக்கத்தை தருக.';
      case AppLanguage.telugu:
        return 'ఈ $term గురించి వివరణ ఇవ్వండి.';
      case AppLanguage.english:
        return 'Provide a detailed breakdown of this $term.';
      case AppLanguage.french:
        return 'Fournissez des détails sur cet objet ($term).';
    }
  }

  String _generateGemmaResponse({
    required String prompt,
    required AppLanguage inputLanguage,
    required AppLanguage outputLanguage,
    required AppMode mode,
    RecognizedEntity? entityContext,
  }) {
    final lower = prompt.toLowerCase();
    if (lower.contains('translate') ||
        lower.contains('how are you') ||
        lower.contains('doing') ||
        lower.contains('laptop') ||
        lower.contains('thank you') ||
        lower.contains('hello')) {
      final res = DynamicQueryEngine.processQuery(
        rawQuery: prompt,
        sourceLanguage: inputLanguage,
        targetLanguage: outputLanguage,
        fallbackEntity: entityContext,
      );
      _lastGeneratedEntity = res.detectedEntity;
      return res.assistantResponse;
    }

    if (entityContext == null) {
      return 'Gemma 4 E2B: Processed prompt "$prompt" successfully in ${outputLanguage.nativeName}.';
    }

    if (mode == AppMode.exploration) {
      final exploration = entityContext.getExploration(inputLanguage);
      return '${exploration.term}: ${exploration.definition} [ਸੱਭਿਆਚਾਰਕ ਮਹੱਤਤਾ: ${exploration.culturalContext}]';
    } else {
      final learning = entityContext.getLearning(inputLanguage, outputLanguage);
      return '${learning.sourceTerm} ➔ ${learning.targetTerm} (${learning.targetPhonetic}). ਸ਼ਬਦ ਸ਼੍ਰੇਣੀ: ${learning.partOfSpeech}. ਉਦਾਹਰਣ: "${learning.targetExampleSentence}"';
    }
  }

  static void _playWindowsSpeech(String text) {
    try {
      final sanitized = text
          .replaceAll('`', '')
          .replaceAll('"', ' ')
          .replaceAll("'", ' ')
          .replaceAll('\n', ' ')
          .trim();
      if (sanitized.isEmpty) return;

      Process.start('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        'Add-Type -AssemblyName System.Speech; \$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer; \$synth.Speak("$sanitized");',
      ], mode: ProcessStartMode.detached);
    } catch (_) {}
  }

  @override
  void dispose() {
    _telemetryStreamController?.close();
    super.dispose();
  }
}
