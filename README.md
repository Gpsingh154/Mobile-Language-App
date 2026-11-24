# Mobile Language App: Model Asset Architecture

This repository hosts the on-device AI/ML model assets for the local-first multilingual language learning and reasoning mobile application.

## 1. Directory Structure

```
Mobile-Language-App/
├── assets/
│   └── models/
│       ├── gemma/
│       │   ├── gemma-4-E2B-it.litertlm      # Main Brain: Native LiteRT-LM binary (2.46 GB)
│       │   ├── chat_template.jinja          # Chat template for instruction & conversational formatting
│       │   └── metadata.json                # Gemma model specs, context limits, & runtime config
│       ├── asr/
│       │   ├── indic_conformer_int8.onnx    # ASR: INT8 Quantized IndicConformer model (187.85 MB)
│       │   ├── tokens.txt                   # Multilingual CTC token vocabulary
│       │   ├── config.json                  # Model hyperparameter & feature extraction config
│       │   └── metadata.json                # ASR metadata, sampling rates, & language support
│       └── tts/
│           ├── kokoro_int8_fp16.litertlm    # TTS On-Device Engine: LiteRT-LM audio synthesizer (281.13 MB)
│           ├── sooktam2_config.json         # Sooktam-2 model architecture configuration
│           ├── sooktam2_vocab.txt           # Sooktam-2 CLS Indic phonetic vocabulary
│           ├── reference.wav                # Reference conditioning voice sample
│           └── metadata.json                # Audio synthesis specifications & language codes
├── pubspec.yaml                             # Flutter packaging manifest linking local model assets
└── README.md
```

## 2. Model Specifications & Deployment Rationale

### Main Brain: Gemma 4 E2B Instruct
* **Target Repository**: [`litert-community/gemma-4-E2B-it-litert-lm`](https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm)
* **Deployed File**: `gemma-4-E2B-it.litertlm` (2,588,147,712 bytes)
* **Format**: Native LiteRT-LM (`.litertlm`) compiled for Google LiteRT / Flutter Edge AI runtime.
* **Quantization**: Mixture of 2-bit, 4-bit, and 8-bit Quantization Aware Training (QAT).
* **Working Memory**: ~800 MB active RAM footprint with memory-mapped weights.

### Audio Transcription (ASR): IndicConformer Multilingual
* **Target Repositories**: [`ai4bharat/indic-conformer-600m-multilingual`](https://huggingface.co/ai4bharat/indic-conformer-600m-multilingual) / [`AI4Bharat/IndicConformerASR`](https://github.com/AI4Bharat/IndicConformerASR)
* **Deployed Source**: [`meetsync/indic-conformer-onnx-sherpa`](https://huggingface.co/meetsync/indic-conformer-onnx-sherpa)
* **Deployed File**: `indic_conformer_int8.onnx` (196,977,855 bytes)
* **Format**: INT8 Quantized ONNX for `sherpa-onnx` / `onnxruntime_flutter`.
* **Fallback Rationale**: The base Hugging Face repository is gated (`gated: auto`, HTTP 401 Unauthorized without user token) and consists of unquantized FP32 weights (>2.4 GB). The INT8 quantized ONNX export preserves the exact 600M IndicConformer multilingual architecture in an optimized 188 MB package suitable for zero-latency, local-first mobile inference.
* **Supported Languages**: Hindi (`hi`), Punjabi (`pa`), English (`en`), Bengali (`bn`), Gujarati (`gu`), Kannada (`kn`), Malayalam (`ml`), Marathi (`mr`), Odia (`or`), Tamil (`ta`), Telugu (`te`), Urdu (`ur`).

### Audio Synthesis (TTS): Sooktam-2 & Kokoro LiteRT
* **Target Repository**: [`bharatgenai/sooktam2`](https://huggingface.co/bharatgenai/sooktam2)
* **Deployed Files**:
  * Sooktam-2 Manifest: `sooktam2_config.json`, `sooktam2_vocab.txt`, `reference.wav`
  * Mobile Engine: `kokoro_int8_fp16.litertlm` (294,783,298 bytes) from [`litert-community/Kokoro-82M`](https://huggingface.co/litert-community/Kokoro-82M)
* **Format**: LiteRT-LM (`.litertlm`) / TFLite.
* **Fallback Rationale**: Base Sooktam-2 weights (`model_1250000.pt`) are 5.13 GB PyTorch server-side weights requiring full CUDA/PyTorch runtime, unsuitable for mobile on-device execution. The app packages Sooktam-2's vocabulary and voice reference assets while deploying the LiteRT-LM INT8-quantized synthesizer matching the Gemma LiteRT runtime for instant offline voice generation.

## 3. Flutter Packaging Configuration

All asset paths are declared in [`pubspec.yaml`](./pubspec.yaml) under the `flutter.assets` section:
- Directory packages: `assets/models/gemma/`, `assets/models/asr/`, `assets/models/tts/`
- Explicit binary references for each model file, token dictionary, and configuration JSON.

---

## 4. Phase 2: Multi-Platform UI Layout & State Flows

The Phase 2 Flutter implementation provides a cross-platform (iOS/Android) camera HUD and state engine:

### Component Architecture

```
lib/
├── main.dart                                # Application entrypoint & edge-to-edge system chrome
├── models/
│   ├── app_language.dart                    # Regional choices: Punjabi, Hindi, Tamil, Telugu, English
│   ├── app_mode.dart                        # AppMode: Exploration vs Learning mode triggers
│   ├── recognized_entity.dart               # Vision detection model & localized data
│   └── vocabulary_item.dart                 # AI Flashcard item with mastery tracking
├── state/
│   └── app_state_controller.dart            # ChangeNotifier reactive state controller
├── ui/
│   ├── camera/
│   │   ├── camera_overlay_screen.dart       # Master HUD layout container
│   │   ├── camera_viewfinder_widget.dart    # Viewfinder, object sensors, & HUD controls
│   │   └── scan_reticle_painter.dart        # CustomPainter for target brackets & scanline
│   ├── controls/
│   │   ├── language_selector_bar.dart       # Accessible top bar with swap & mode badge
│   │   └── language_dropdown_widget.dart    # Prominent dropdown with native scripts
│   ├── cards/
│   │   ├── mode_card_container.dart         # Animated switcher between modes
│   │   ├── exploration_card_widget.dart     # Monolingual deep-dive & cultural insights
│   │   └── learning_card_widget.dart        # Bilingual translations, phonetics & grammar
│   └── flashcards/
│       ├── flashcard_review_deck.dart       # Inline expandable bottom review deck
│       ├── flashcard_card_widget.dart       # 3D interactive flip card (Front/Back)
│       └── deck_progress_indicator.dart     # Mastery distribution progress bar
└── utils/
    ├── mock_detection_data.dart             # Seeded authentic Indic cultural entities
    └── theme.dart                           # Dark-mode camera overlay design tokens
```

### Functional State Rules

1. **Exploration Mode** (`Input Language == Output Language`):
   - Example: `Punjabi` -> `Punjabi`
   - UI presents `ExplorationCardWidget` with monolingual detailed definitions, cultural nuances (e.g. folk history, regional significance), etymology, synonyms, and local TTS audio.
2. **Learning Mode** (`Input Language != Output Language`):
   - Example: `Punjabi` -> `English` or `Hindi` -> `Tamil`
   - UI presents `LearningCardWidget` with source-to-target translation hero, phonetic script (IPA / Gurmukhi / Devanagari transliterations), morphological grammar breakdown (Part of speech, gender, number, stem root, inflections), bilingual example sentences, and audio triggers.
3. **Local AI Flashcard System**:
   - Inline review deck docked at the bottom of the viewfinder.
   - Saves dynamic vocabulary with "Save to Flashcards" action.
   - 3D perspective flip card revealing grammar components and mastery rating buttons (`Need Practice`, `Familiar`, `Mastered`).

---

## 5. Phase 3: Model Lifecycle Manager & Memory Controls

Mobile operating systems enforce strict per-application RAM ceilings. To guarantee zero Out-of-Memory (OOM) crashes on iOS and Android devices, **[`ModelLifecycleManager`](./lib/services/model_lifecycle_manager.dart)** enforces a strict sequential execution sequence:

```
[Standby ~48MB] ──► 1. Load ASR (IndicConformer ~188MB) ──► Transcribe Audio ──► Unload ASR
                       (Vision & TTS Frozen)
                                                                             │
[Standby ~48MB] ◄── 3. Unload TTS ◄── Play Audio ◄── 2. Load TTS (Sooktam-2 ~280MB) ◄──┘
                                                       (Gemma & ASR Dormant)
                                                                 ▲
                                                                 │
                       Load Gemma 4 E2B (~560MB) ──► Reason ──► Unload Gemma
                       (Vision Pipeline Strictly Locked)
```

### Static Optimization Tuning Constants

Configured as static variables at the top of `model_lifecycle_manager.dart`:
```dart
// Runtime Threading & Hardware Acceleration
static int numThreads = 4;
static bool useGpuDelegate = true;
static bool useNpuAcceleration = false;
static int targetMemoryCapMb = 700;

// Main Brain (Gemma 4 E2B Instruct)
static double temperature = 0.7;
static double topP = 0.95;
static int topK = 40;
static int maxTokens = 128;
static int contextWindowTokens = 4096;

// ASR (IndicConformer)
static int asrSampleRate = 16000;
static int asrAudioChunkMs = 160;
static double asrBeamWidth = 4.0;

// Audio Synthesis (Sooktam-2 / Kokoro TTS)
static double ttsSpeechRate = 1.0;
static double ttsPitch = 1.0;
static int ttsSampleRate = 24000;
```

### Compilation Assembly & UI Interaction

- **Try It Interactive Trigger**: Embedded within **[`PipelineStatusHud`](./lib/ui/controls/pipeline_status_hud.dart)** on the camera overlay. Pressing "Try it" executes the full 5-step sequential pipeline with real-time memory meters and phase logs.
- **Card Audio Synthesis**: Tapping "Audio" on either Exploration or Learning cards triggers single-phase TTS execution (`synthesizeSpeechOnly`), keeping Gemma and ASR sleeping and releasing RAM back to ~48MB immediately upon completion.

---

## 6. Local SDK Ingestion & Environment Scripts

To operate without modifying global Windows system PATH variables, the Flutter SDK is self-contained within the project root:

```
Mobile-Language-App/
├── .tools/
│   └── flutter/                     # Isolated local Flutter SDK (v3.50.1 stable)
│       └── bin/
│           ├── flutter.bat          # Local Flutter CLI binary
│           └── dart.bat             # Local Dart SDK (v3.14.0)
├── run_app.ps1                      # PowerShell local process bridge
└── setup_env.bat                    # CMD environment setter script
```

### Running Commands via the Local Process Bridge

```powershell
# Check environment health & dependencies
.\run_app.ps1 doctor -v

# List connected devices (including USB-connected hardware)
.\run_app.ps1 devices

# Execute full unit & widget test suite
.\run_app.ps1 test

# Launch application on connected target
.\run_app.ps1 run
```

---

## 7. Native Windows Desktop Target & Hardware Acceleration

The project includes full native compilation assets for **Windows 11 / 10 x86_64** desktop execution, enabling interactive on-screen evaluation of the camera overlay viewfinder, language state toggles, and sequential AI pipelines without requiring a physical phone tethered at all times.

### Platform Runner Architecture

```
windows/
├── CMakeLists.txt                    # Top-level CMake build script with Flutter integration
├── runner/
│   ├── main.cpp                      # Native Win32 application entry point
│   ├── flutter_window.h / .cpp       # Win32 Flutter engine host window
│   ├── win32_window.h / .cpp         # Custom Win32 message loop & DPI handler
│   ├── Runner.rc / resource.h        # Windows application icons and version resources
│   └── utils.h / .cpp                # Win32 string/error converters
```

### Windows x86_64 Acceleration Delegates

LiteRT and ONNX inference are mapped to native Windows x86_64 acceleration delegates inside [`ModelLifecycleManager`](./lib/services/model_lifecycle_manager.dart):

* **CPU Delegate**: **XNNPACK** with AVX2 / AVX-512 SIMD vectorization (`ModelLifecycleManager.useWindowsXnnpack = true`).
* **GPU Delegate**: **DirectML** (DirectX 12 Machine Learning) GPU delegate (`ModelLifecycleManager.useWindowsDirectMl = true`).
* **Asset Path Resolution**: `ModelLifecycleManager.resolveModelAssetPath()` dynamically discovers asset binaries across both developer workspace trees (`Directory.current`) and packaged production layouts (`$exeDir\data\flutter_assets\`).

### Compiling and Running on Windows Desktop

```powershell
# Compile debug/release Windows desktop binary
.\run_app.ps1 build windows --debug

# Interactively launch and debug on your monitor screen (with hot reload enabled)
.\run_app.ps1 run -d windows

# Or launch the compiled native binary directly
.\build\windows\x64\runner\Release\mobile_language_app.exe
```

### On-Screen Monitor Evaluation Features

1. **Simulated Viewfinder & Reticle**: Displays the active scan reticle with pulsing corner brackets, cyan target grid, and live detection boxes for authentic Indic cultural items (Harmandir Sahib model, Phulkari dupatta, Punjabi jutti).
2. **Language Switching**: Top bar selectors toggle seamlessly between Punjabi, Hindi, Tamil, Telugu, and English.
   - Matching languages trigger **Exploration Mode** (etymology, cultural notes, monolingual definitions).
   - Differing languages trigger **Learning Mode** (Gurmukhi/Devanagari phonetics, morphological breakdown, bilingual sentences).
3. **Hardware & Memory HUD**: Live status HUD reports active delegate string (`Windows x86_64 [CPU: XNNPACK (AVX2) | GPU: DirectML (GPU)]`), active model binary location, and real-time RAM meter pinned strictly under the 700MB ceiling.
4. **"Try it" Button**: Triggers the 5-step sequential execution cycle (Mic/ASR -> Gemma 4 E2B Instruct -> Sooktam-2 TTS), cleanly verifying sequential loading and unloading on your local Windows PC.




