import 'package:flutter/material.dart';
import 'app_language.dart';

/// Represents a single grammatical component in the breakdown
class GrammarComponent {
  final String label;
  final String value;
  final String? note;

  const GrammarComponent({
    required this.label,
    required this.value,
    this.note,
  });
}

/// Rich monolingual data displayed in Exploration Mode (`Input == Output`)
class MonolingualExplorationData {
  final String term;
  final String phoneticScript;
  final String definition;
  final String culturalContext;
  final String etymology;
  final List<String> synonyms;
  final String exampleSentence;

  const MonolingualExplorationData({
    required this.term,
    required this.phoneticScript,
    required this.definition,
    required this.culturalContext,
    required this.etymology,
    required this.synonyms,
    required this.exampleSentence,
  });
}

/// Rich bilingual translation & grammatical breakdown displayed in Learning Mode (`Input != Output`)
class BilingualLearningData {
  final String sourceTerm;
  final String sourcePhonetic;
  final String targetTerm;
  final String targetPhonetic;
  final String partOfSpeech;
  final List<GrammarComponent> grammarComponents;
  final String sourceExampleSentence;
  final String targetExampleSentence;
  final String mnemonicHint;

  const BilingualLearningData({
    required this.sourceTerm,
    required this.sourcePhonetic,
    required this.targetTerm,
    required this.targetPhonetic,
    required this.partOfSpeech,
    required this.grammarComponents,
    required this.sourceExampleSentence,
    required this.targetExampleSentence,
    required this.mnemonicHint,
  });
}

/// An entity or text snippet detected in real-time within the camera viewfinder
class RecognizedEntity {
  final String id;
  final String englishLabel;
  final double confidence;
  final String category;
  final Rect boundingBox; // Normalized 0.0 - 1.0 (left, top, width, height)
  final Map<AppLanguage, String> localizedTerms;
  final Map<AppLanguage, MonolingualExplorationData> explorationData;
  final Map<String, BilingualLearningData> learningData; // key: "${src.code}_${dst.code}"

  const RecognizedEntity({
    required this.id,
    required this.englishLabel,
    required this.confidence,
    required this.category,
    required this.boundingBox,
    required this.localizedTerms,
    required this.explorationData,
    required this.learningData,
  });

  /// Retrieve localized term in given language
  String getTerm(AppLanguage lang) {
    return localizedTerms[lang] ?? englishLabel;
  }

  /// Retrieve monolingual exploration details for Exploration Mode
  MonolingualExplorationData getExploration(AppLanguage lang) {
    if (explorationData.containsKey(lang)) {
      return explorationData[lang]!;
    }
    // Fallback if specific language is missing
    return MonolingualExplorationData(
      term: getTerm(lang),
      phoneticScript: '[${getTerm(lang)}]',
      definition: 'Recognized $englishLabel identified by on-device vision model.',
      culturalContext: 'A key element of daily life and regional heritage.',
      etymology: 'Roots in traditional terminology.',
      synonyms: [englishLabel],
      exampleSentence: 'ਇਹ ਇੱਕ ਉਦਾਹਰਣ ਵਾਕ ਹੈ।',
    );
  }

  /// Retrieve bilingual learning details for Learning Mode
  BilingualLearningData getLearning(AppLanguage src, AppLanguage dst) {
    final key = '${src.code}_${dst.code}';
    if (learningData.containsKey(key)) {
      return learningData[key]!;
    }
    // Dynamic fallback builder
    final srcTerm = getTerm(src);
    final dstTerm = getTerm(dst);
    return BilingualLearningData(
      sourceTerm: srcTerm,
      sourcePhonetic: '[$srcTerm]',
      targetTerm: dstTerm,
      targetPhonetic: '[$dstTerm]',
      partOfSpeech: 'Noun (ਨਾਂਵ / संज्ञा)',
      grammarComponents: [
        const GrammarComponent(label: 'Part of Speech', value: 'Noun'),
        const GrammarComponent(label: 'Gender & Number', value: 'Singular'),
        const GrammarComponent(label: 'Root Stem', value: 'Direct Form'),
      ],
      sourceExampleSentence: '$srcTerm ਇੱਥੇ ਮੌਜੂਦ ਹੈ।',
      targetExampleSentence: '$dstTerm is present here.',
      mnemonicHint: 'Connect the visual form of the object with its phonetic tone.',
    );
  }
}
