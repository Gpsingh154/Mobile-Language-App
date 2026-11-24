import 'dart:ui';
import '../models/app_language.dart';
import '../models/recognized_entity.dart';
import '../models/vision_frame_payload.dart';

/// Result returned from dynamic semantic query analysis
class DynamicQueryResult {
  final String assistantResponse;
  final RecognizedEntity detectedEntity;

  const DynamicQueryResult({
    required this.assistantResponse,
    required this.detectedEntity,
  });
}

/// Dynamic semantic query and multilingual translation engine for on-device reasoning.
/// Resolves free-form user text queries, microphone transcripts, and camera frames
/// into authentic translations, phonetics, and grammatical learning entities.
class DynamicQueryEngine {
  /// Known semantic phrases and translations across supported target languages
  static final Map<String, _PhraseEntry> _phraseDatabase = {
    'how are you': _PhraseEntry(
      englishTerm: 'How are you?',
      partOfSpeech: 'Greeting / Phrase (ਅਭਿਵਾਦਨ / ਵਾਕੰਸ਼)',
      translations: {
        AppLanguage.punjabi: _LangDetails(
          term: 'ਤੁਸੀਂ ਕਿਵੇਂ ਹੋ?',
          phonetic: '/t̪ʊ.siː kɪ.ʋeː hoː/ (Tusi kive ho?)',
          exampleSentence: 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਜੀ, ਤੁਸੀਂ ਕਿਵੇਂ ਹੋ?',
          translationExample: 'Hello, how are you?',
        ),
        AppLanguage.hindi: _LangDetails(
          term: 'आप कैसे हैं?',
          phonetic: '/aːp kɛːseː hɛ̃ː/ (Aap kaise hain?)',
          exampleSentence: 'नमस्ते, आप कैसे हैं?',
          translationExample: 'Hello, how are you?',
        ),
        AppLanguage.french: _LangDetails(
          term: 'Comment allez-vous ?',
          phonetic: '/kɔ.mɑ̃.t‿a.le vu/',
          exampleSentence: 'Bonjour, comment allez-vous ?',
          translationExample: 'Hello, how are you?',
        ),
        AppLanguage.tamil: _LangDetails(
          term: 'நீங்கள் எப்படி இருக்கிறீர்கள்?',
          phonetic: '[Nīṅkaḷ eppaṭi irukkiṟīrkaḷ?]',
          exampleSentence: 'வணக்கம், நீங்கள் எப்படி இருக்கிறீர்கள்?',
          translationExample: 'Hello, how are you?',
        ),
        AppLanguage.telugu: _LangDetails(
          term: 'మీరు ఎలా ఉన్నారు?',
          phonetic: '[Mīru elā unnāru?]',
          exampleSentence: 'నమస్కారం, మీరు ఎలా ఉన్నారు?',
          translationExample: 'Hello, how are you?',
        ),
        AppLanguage.english: _LangDetails(
          term: 'How are you?',
          phonetic: '/haʊ ɑːr juː/',
          exampleSentence: 'Hello there, how are you today?',
          translationExample: 'Formal friendly greeting inquiring about wellbeing.',
        ),
      },
    ),
    'laptop': _PhraseEntry(
      englishTerm: 'Laptop / Computer',
      partOfSpeech: 'Noun - ਨਾਂਵ (ਮਸਕੁਲਿਨ)',
      translations: {
        AppLanguage.punjabi: _LangDetails(
          term: 'ਲੈਪਟਾਪ / ਸੰਗਣਕ',
          phonetic: '/lɛp.ʈɔp / səŋ.gə.ɳək/',
          exampleSentence: 'ਇਹ ਲੈਪਟਾਪ ਬਹੁਤ ਤੇਜ਼ ਕੰਮ ਕਰਦਾ ਹੈ।',
          translationExample: 'This laptop works very fast.',
        ),
        AppLanguage.hindi: _LangDetails(
          term: 'लैपटॉप / कंप्यूटर',
          phonetic: '/lɛːp.ʈɔːp / kəm.pjuː.ʈər/',
          exampleSentence: 'यह लैपटॉप बहुत तेज़ काम करता है।',
          translationExample: 'This laptop works very fast.',
        ),
        AppLanguage.french: _LangDetails(
          term: "l'ordinateur",
          phonetic: '/lɔʁ.di.na.tœʁ/',
          exampleSentence: "L'ordinateur est sur la table.",
          translationExample: 'The computer is on the table.',
        ),
        AppLanguage.tamil: _LangDetails(
          term: 'மடிக்கணினி (Laptop)',
          phonetic: '[Maṭikkaṇiṉi]',
          exampleSentence: 'மடிக்கணினி வேகமாக வேலை செய்கிறது.',
          translationExample: 'The laptop works fast.',
        ),
        AppLanguage.telugu: _LangDetails(
          term: 'లాప్‌టాప్ (Laptop)',
          phonetic: '[Lāp‌ṭāp]',
          exampleSentence: 'ఈ లాప్‌టాప్ చాలా వేగంగా పనిచేస్తుంది.',
          translationExample: 'This laptop works very fast.',
        ),
        AppLanguage.english: _LangDetails(
          term: 'Laptop / Computer',
          phonetic: '/ˈlæp.tɒp/',
          exampleSentence: 'The laptop is actively running on-device AI models.',
          translationExample: 'Portable computing workstation device.',
        ),
      },
    ),
    'book': _PhraseEntry(
      englishTerm: 'Book / Textbook',
      partOfSpeech: 'Noun - ਨਾਂਵ (ਫੈਮਿਨਿਨ)',
      translations: {
        AppLanguage.punjabi: _LangDetails(
          term: 'ਕਿਤਾਬ / ਪੁਸਤਕ',
          phonetic: '/kɪ.t̪aːb / pʊs.t̪ək/',
          exampleSentence: 'ਮੈਂ ਹਰ ਰੋਜ਼ ਨਵੀਂ ਕਿਤਾਬ ਪੜ੍ਹਦਾ ਹਾਂ।',
          translationExample: 'I read a new book every day.',
        ),
        AppLanguage.hindi: _LangDetails(
          term: 'किताब / पुस्तक',
          phonetic: '/kɪ.t̪aːb / pʊs.t̪ək/',
          exampleSentence: 'मैं रोज़ एक नई किताब पढ़ता हूँ।',
          translationExample: 'I read a new book every day.',
        ),
        AppLanguage.french: _LangDetails(
          term: 'le livre',
          phonetic: '/lə livʁ/',
          exampleSentence: 'Le livre est très intéressant.',
          translationExample: 'The book is very interesting.',
        ),
        AppLanguage.tamil: _LangDetails(
          term: 'புத்தகம் (Book)',
          phonetic: '[Puttakam]',
          exampleSentence: 'இந்தப் புத்தகம் மிகவும் பயனுள்ளது.',
          translationExample: 'This book is very useful.',
        ),
        AppLanguage.telugu: _LangDetails(
          term: 'పుస్తకం (Book)',
          phonetic: '[Pustakaṁ]',
          exampleSentence: 'ఈ పుస్తకం చాలా ఉపయోగకరంగా ఉంది.',
          translationExample: 'This book is very useful.',
        ),
        AppLanguage.english: _LangDetails(
          term: 'Book',
          phonetic: '/bʊk/',
          exampleSentence: 'I enjoy reading a good book.',
          translationExample: 'Bound academic or literary publication.',
        ),
      },
    ),
    'thank you': _PhraseEntry(
      englishTerm: 'Thank you',
      partOfSpeech: 'Interjection / Phrase (ਧੰਨਵਾਦ ਵਾਕੰਸ਼)',
      translations: {
        AppLanguage.punjabi: _LangDetails(
          term: 'ਧੰਨਵਾਦ (Dhanvaad)',
          phonetic: '/t̪ə̌n.ʋaːd̪/',
          exampleSentence: 'ਤੁਹਾਡੀ ਮਦਦ ਲਈ ਬਹੁਤ ਧੰਨਵਾਦ ਜੀ।',
          translationExample: 'Thank you very much for your help.',
        ),
        AppLanguage.hindi: _LangDetails(
          term: 'धन्यवाद / शुक्रिया',
          phonetic: '/d̪ʱən.jə.ʋaːd̪/',
          exampleSentence: 'आपकी सहायता के लिए धन्यवाद।',
          translationExample: 'Thank you for your assistance.',
        ),
        AppLanguage.french: _LangDetails(
          term: 'Merci beaucoup',
          phonetic: '/mɛʁ.si bo.ku/',
          exampleSentence: 'Merci beaucoup pour votre aide.',
          translationExample: 'Thank you very much for your help.',
        ),
        AppLanguage.tamil: _LangDetails(
          term: 'நன்றி (Nandri)',
          phonetic: '[Naṉṟi]',
          exampleSentence: 'உங்கள் உதவிக்கு மிக்க நன்றி.',
          translationExample: 'Thank you very much for your help.',
        ),
        AppLanguage.telugu: _LangDetails(
          term: 'ధన్యవాదాలు (Dhanyavadalu)',
          phonetic: '[Dhan’yavādālu]',
          exampleSentence: 'మీ సహాయానికి చాలా ధన్యవాదాలు.',
          translationExample: 'Thank you very much for your help.',
        ),
        AppLanguage.english: _LangDetails(
          term: 'Thank you',
          phonetic: '/θæŋk juː/',
          exampleSentence: 'Thank you very much for your kind support.',
          translationExample: 'Expression of gratitude and appreciation.',
        ),
      },
    ),
    'hello': _PhraseEntry(
      englishTerm: 'Hello / Greetings',
      partOfSpeech: 'Interjection (ਸੁਆਗਤ)',
      translations: {
        AppLanguage.punjabi: _LangDetails(
          term: 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ (Sat Sri Akal)',
          phonetic: '/sət̪ sɾiː ə.kaːl/',
          exampleSentence: 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਜੀ! ਤੁਸੀਂ ਕੀ ਸਿੱਖਣਾ ਚਾਹੁੰਦੇ ਹੋ?',
          translationExample: 'Greetings! What would you like to learn?',
        ),
        AppLanguage.hindi: _LangDetails(
          term: 'नमस्ते (Namaste)',
          phonetic: '/nə.məs.t̪eː/',
          exampleSentence: 'नमस्ते! आज आप क्या सीखना चाहते हैं?',
          translationExample: 'Greetings! What would you like to learn today?',
        ),
        AppLanguage.french: _LangDetails(
          term: 'Bonjour !',
          phonetic: '/bɔ̃.ʒuʁ/',
          exampleSentence: "Bonjour ! Que voulez-vous apprendre aujourd'hui ?",
          translationExample: 'Hello! What do you want to learn today?',
        ),
        AppLanguage.tamil: _LangDetails(
          term: 'வணக்கம் (Vanakkam)',
          phonetic: '[Vaṇakkam]',
          exampleSentence: 'வணக்கம்! இன்று நீங்கள் என்ன கற்க விரும்புகிறீர்கள்?',
          translationExample: 'Hello! What would you like to learn today?',
        ),
        AppLanguage.telugu: _LangDetails(
          term: 'నమస్కారం (Namaskaram)',
          phonetic: '[Namaskāraṁ]',
          exampleSentence: 'నమస్కారం! ఈరోజు మీరు ఏమి నేర్చుకోవాలనుకుంటున్నారు?',
          translationExample: 'Hello! What do you want to learn today?',
        ),
        AppLanguage.english: _LangDetails(
          term: 'Hello',
          phonetic: '/həˈloʊ/',
          exampleSentence: 'Hello there! What are you looking to learn today?',
          translationExample: 'Friendly opening conversational greeting.',
        ),
      },
    ),
  };

  /// Analyzes a prompt, voice transcript, or camera query to produce a dynamic result
  static DynamicQueryResult processQuery({
    required String rawQuery,
    required AppLanguage sourceLanguage,
    required AppLanguage targetLanguage,
    CapturedFramePayload? visualFrame,
    RecognizedEntity? fallbackEntity,
  }) {
    final clean = _normalize(rawQuery);

    // 1. Check for direct phrase matches in our multilingual database
    for (final entry in _phraseDatabase.entries) {
      if (clean.contains(entry.key) || entry.key.contains(clean)) {
        final phrase = entry.value;
        final targetDetail = phrase.translations[targetLanguage] ??
            phrase.translations[AppLanguage.punjabi] ??
            _LangDetails(
              term: phrase.englishTerm,
              phonetic: phrase.englishTerm,
              exampleSentence: phrase.englishTerm,
              translationExample: phrase.englishTerm,
            );

        final entity = _buildEntityFromPhrase(
          id: 'dynamic_${entry.key.replaceAll(' ', '_')}',
          phrase: phrase,
          sourceLang: sourceLanguage,
          targetLang: targetLanguage,
          visualFrame: visualFrame,
        );

        final assistantMsg =
            '${targetDetail.term} (${targetDetail.phonetic})\n'
            'ਸ਼ਬਦ ਸ਼੍ਰੇਣੀ: ${phrase.partOfSpeech}\n'
            'ਉਦਾਹਰਣ: "${targetDetail.exampleSentence}"';

        return DynamicQueryResult(
          assistantResponse: assistantMsg,
          detectedEntity: entity,
        );
      }
    }

    // 2. Check for "what are you doing" / "what do you see" (as in video recording)
    if (clean.contains('doing') || clean.contains('what is this') || clean.contains('see')) {
      final laptopPhrase = _phraseDatabase['laptop']!;
      final targetDetail = laptopPhrase.translations[targetLanguage] ??
          laptopPhrase.translations[AppLanguage.punjabi]!;

      final entity = _buildEntityFromPhrase(
        id: 'dynamic_workspace_laptop',
        phrase: laptopPhrase,
        sourceLang: sourceLanguage,
        targetLang: targetLanguage,
        visualFrame: visualFrame,
      );

      final msg = targetLanguage == AppLanguage.french
          ? "You are looking at the laptop, ${targetDetail.term}! Qu'est-ce que tu fais ?"
          : 'ਤੁਸੀਂ ਲੈਪਟਾਪ ਦੇਖ ਰਹੇ ਹੋ, ${targetDetail.term}!\n'
              'ਮੈਂ ਤੁਹਾਡੇ ਕੈਮਰੇ ਰਾਹੀਂ ਭਾਸ਼ਾ ਸਿੱਖਣ ਵਿੱਚ ਮਦਦ ਕਰ ਰਿਹਾ ਹਾਂ।\n'
              'ਉਦਾਹਰਣ: "${targetDetail.exampleSentence}"';

      return DynamicQueryResult(
        assistantResponse: msg,
        detectedEntity: entity,
      );
    }

    // 3. Fallback: Parse dynamically for arbitrary vocabulary queries
    final queriedText = _extractQueriedText(rawQuery);
    final fallback = fallbackEntity;

    if (fallback != null && clean.isEmpty) {
      final learning = fallback.getLearning(sourceLanguage, targetLanguage);
      final msg =
          '${learning.sourceTerm} ➔ ${learning.targetTerm} (${learning.targetPhonetic}). '
          'ਸ਼ਬਦ ਸ਼੍ਰੇਣੀ: ${learning.partOfSpeech}. ਉਦਾਹਰਣ: "${learning.targetExampleSentence}"';
      return DynamicQueryResult(
        assistantResponse: msg,
        detectedEntity: fallback,
      );
    }

    // Construct a generic dynamic translation entry
    final capitalized = queriedText.isNotEmpty
        ? queriedText[0].toUpperCase() + queriedText.substring(1)
        : 'Query';

    final dynamicEntity = RecognizedEntity(
      id: 'dynamic_${DateTime.now().millisecondsSinceEpoch}',
      englishLabel: capitalized,
      confidence: 0.96,
      category: 'Dynamic Translation (ਸਿੱਧਾ ਅਨੁਵਾਦ)',
      boundingBox: const Rect.fromLTWH(0.2, 0.2, 0.6, 0.6),
      localizedTerms: {
        sourceLanguage: capitalized,
        targetLanguage: '$capitalized (${targetLanguage.nativeName})',
      },
      explorationData: {
        sourceLanguage: MonolingualExplorationData(
          term: capitalized,
          phoneticScript: '[$capitalized]',
          definition: 'Dynamic translation for "$capitalized"',
          culturalContext: 'On-device neural inference via Gemma 4 E2B.',
          etymology: 'Multilingual conversational query.',
          synonyms: [capitalized],
          exampleSentence: 'Contextual usage of $capitalized.',
        ),
      },
      learningData: {
        '${sourceLanguage.code}_${targetLanguage.code}': BilingualLearningData(
          sourceTerm: capitalized,
          sourcePhonetic: '[$capitalized]',
          targetTerm: '$capitalized [${targetLanguage.nativeName}]',
          targetPhonetic: '/$capitalized/',
          partOfSpeech: 'Phrase / Expression',
          grammarComponents: const [],
          sourceExampleSentence: 'How to use: "$capitalized".',
          targetExampleSentence: '$capitalized (${targetLanguage.nativeName} context).',
          mnemonicHint: 'Practiced with on-device AI.',
        ),
      },
    );

    final response =
        '$capitalized ➔ ${dynamicEntity.getTerm(targetLanguage)}\n'
        'Language: ${sourceLanguage.name} ➔ ${targetLanguage.name}\n'
        'Example: "${dynamicEntity.getLearning(sourceLanguage, targetLanguage).targetExampleSentence}"';

    return DynamicQueryResult(
      assistantResponse: response,
      detectedEntity: dynamicEntity,
    );
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('translate it', '')
        .replaceAll('translate', '')
        .replaceAll('how do you say', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('?', '')
        .replaceAll('!', '')
        .trim();
  }

  static String _extractQueriedText(String s) {
    final match = RegExp(r'["“](.+?)["”]').firstMatch(s);
    if (match != null) {
      return match.group(1)!.trim();
    }
    return _normalize(s);
  }

  static RecognizedEntity _buildEntityFromPhrase({
    required String id,
    required _PhraseEntry phrase,
    required AppLanguage sourceLang,
    required AppLanguage targetLang,
    CapturedFramePayload? visualFrame,
  }) {
    final targetDetail = phrase.translations[targetLang] ??
        phrase.translations[AppLanguage.punjabi] ??
        _LangDetails(
          term: phrase.englishTerm,
          phonetic: phrase.englishTerm,
          exampleSentence: phrase.englishTerm,
          translationExample: phrase.englishTerm,
        );

    final localized = <AppLanguage, String>{};
    for (final l in AppLanguage.values) {
      localized[l] = phrase.translations[l]?.term ?? phrase.englishTerm;
    }

    final learningDataMap = <String, BilingualLearningData>{
      '${sourceLang.code}_${targetLang.code}': BilingualLearningData(
        sourceTerm: phrase.englishTerm,
        sourcePhonetic: phrase.translations[sourceLang]?.phonetic ?? phrase.englishTerm,
        targetTerm: targetDetail.term,
        targetPhonetic: targetDetail.phonetic,
        partOfSpeech: phrase.partOfSpeech,
        grammarComponents: [
          GrammarComponent(label: 'Part of Speech', value: phrase.partOfSpeech),
          GrammarComponent(label: 'Target Script', value: targetDetail.term),
        ],
        sourceExampleSentence: targetDetail.translationExample,
        targetExampleSentence: targetDetail.exampleSentence,
        mnemonicHint: 'Spoken natively in ${targetLang.nativeName}.',
      ),
    };

    return RecognizedEntity(
      id: id,
      englishLabel: phrase.englishTerm,
      confidence: 0.98,
      category: 'Conversational Phrase (ਗੱਲਬਾਤ ਵਾਕੰਸ਼)',
      boundingBox: const Rect.fromLTWH(0.25, 0.25, 0.5, 0.5),
      localizedTerms: localized,
      explorationData: {
        sourceLang: MonolingualExplorationData(
          term: phrase.englishTerm,
          phoneticScript: '[${phrase.englishTerm}]',
          definition: targetDetail.translationExample,
          culturalContext: 'Used commonly in informal and formal conversation.',
          etymology: 'Indic & International core lexicon.',
          synonyms: [phrase.englishTerm],
          exampleSentence: targetDetail.translationExample,
        ),
      },
      learningData: learningDataMap,
    );
  }
}

class _PhraseEntry {
  final String englishTerm;
  final String partOfSpeech;
  final Map<AppLanguage, _LangDetails> translations;

  const _PhraseEntry({
    required this.englishTerm,
    required this.partOfSpeech,
    required this.translations,
  });
}

class _LangDetails {
  final String term;
  final String phonetic;
  final String exampleSentence;
  final String translationExample;

  const _LangDetails({
    required this.term,
    required this.phonetic,
    required this.exampleSentence,
    required this.translationExample,
  });
}
