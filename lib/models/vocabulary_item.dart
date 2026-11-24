import 'app_language.dart';
import 'recognized_entity.dart';

enum MasteryLevel {
  learning(label: 'Learning', score: 1),
  familiar(label: 'Familiar', score: 2),
  mastered(label: 'Mastered', score: 3);

  const MasteryLevel({required this.label, required this.score});
  final String label;
  final int score;
}

/// Represents an item in the local AI-driven Flashcard review deck,
/// dynamically captured during camera exploration or learning interactions.
class VocabularyItem {
  final String id;
  final String sourceTerm;
  final AppLanguage sourceLanguage;
  final String targetTerm;
  final AppLanguage targetLanguage;
  final String sourcePhonetic;
  final String targetPhonetic;
  final String partOfSpeech;
  final List<GrammarComponent> grammarComponents;
  final String exampleSentence;
  final String culturalNote;
  final DateTime dateAdded;
  MasteryLevel masteryLevel;
  int reviewCount;
  bool isFlipped;

  VocabularyItem({
    required this.id,
    required this.sourceTerm,
    required this.sourceLanguage,
    required this.targetTerm,
    required this.targetLanguage,
    required this.sourcePhonetic,
    required this.targetPhonetic,
    required this.partOfSpeech,
    required this.grammarComponents,
    required this.exampleSentence,
    required this.culturalNote,
    required this.dateAdded,
    this.masteryLevel = MasteryLevel.learning,
    this.reviewCount = 0,
    this.isFlipped = false,
  });

  /// Factory to construct a flashcard directly from a RecognizedEntity in Learning Mode
  factory VocabularyItem.fromLearning({
    required RecognizedEntity entity,
    required AppLanguage sourceLang,
    required AppLanguage targetLang,
  }) {
    final learning = entity.getLearning(sourceLang, targetLang);
    return VocabularyItem(
      id: '${entity.id}_${DateTime.now().millisecondsSinceEpoch}',
      sourceTerm: learning.sourceTerm,
      sourceLanguage: sourceLang,
      targetTerm: learning.targetTerm,
      targetLanguage: targetLang,
      sourcePhonetic: learning.sourcePhonetic,
      targetPhonetic: learning.targetPhonetic,
      partOfSpeech: learning.partOfSpeech,
      grammarComponents: learning.grammarComponents,
      exampleSentence: learning.targetExampleSentence,
      culturalNote: learning.mnemonicHint,
      dateAdded: DateTime.now(),
    );
  }

  /// Factory to construct a flashcard directly from a RecognizedEntity in Exploration Mode
  factory VocabularyItem.fromExploration({
    required RecognizedEntity entity,
    required AppLanguage language,
  }) {
    final exploration = entity.getExploration(language);
    return VocabularyItem(
      id: '${entity.id}_${DateTime.now().millisecondsSinceEpoch}',
      sourceTerm: exploration.term,
      sourceLanguage: language,
      targetTerm: exploration.definition,
      targetLanguage: language,
      sourcePhonetic: exploration.phoneticScript,
      targetPhonetic: '',
      partOfSpeech: 'Contextual Monolingual Term',
      grammarComponents: [
        GrammarComponent(label: 'Etymology', value: exploration.etymology),
        GrammarComponent(label: 'Synonyms', value: exploration.synonyms.join(', ')),
      ],
      exampleSentence: exploration.exampleSentence,
      culturalNote: exploration.culturalContext,
      dateAdded: DateTime.now(),
    );
  }
}
