import 'dart:convert';
import 'app_language.dart';
import 'vision_frame_payload.dart';

/// Individual granular correction note inside the 'Grammar Check' result
class GrammarCorrectionNote {
  final String originalSegment;
  final String correctedSegment;
  final String explanation;
  final String ruleType; // e.g. "Subject-Verb Concord", "Gurmukhi Gender Agreement", "Preposition"

  const GrammarCorrectionNote({
    required this.originalSegment,
    required this.correctedSegment,
    required this.explanation,
    required this.ruleType,
  });

  Map<String, dynamic> toJson() => {
        'original_segment': originalSegment,
        'corrected_segment': correctedSegment,
        'explanation': explanation,
        'rule_type': ruleType,
      };

  factory GrammarCorrectionNote.fromJson(Map<String, dynamic> json) =>
      GrammarCorrectionNote(
        originalSegment: json['original_segment'] as String? ?? '',
        correctedSegment: json['corrected_segment'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        ruleType: json['rule_type'] as String? ?? 'General Grammar',
      );
}

/// 1. 'Grammar Check': Real-time error highlight and correction notes
class GrammarCheckResult {
  final bool hasErrors;
  final String annotatedText;
  final List<GrammarCorrectionNote> correctionNotes;
  final double score;

  const GrammarCheckResult({
    required this.hasErrors,
    required this.annotatedText,
    required this.correctionNotes,
    this.score = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'has_errors': hasErrors,
        'annotated_text': annotatedText,
        'correction_notes': correctionNotes.map((n) => n.toJson()).toList(),
        'score': score,
      };

  factory GrammarCheckResult.fromJson(Map<String, dynamic> json) {
    final notesList = (json['correction_notes'] as List<dynamic>? ?? [])
        .map((e) => GrammarCorrectionNote.fromJson(e as Map<String, dynamic>))
        .toList();
    return GrammarCheckResult(
      hasErrors: json['has_errors'] as bool? ?? false,
      annotatedText: json['annotated_text'] as String? ?? '',
      correctionNotes: notesList,
      score: (json['score'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// 2. 'Natural Fluency Suggestion': Rephrasing tips to match local native idiomatic speech
class NaturalFluencySuggestion {
  final String idiomaticVersion;
  final String nuanceExplanation;
  final String registerTag; // e.g. "Native Colloquial", "Majha Idiom", "Casual Conversational"
  final List<String> alternativeExpressions;

  const NaturalFluencySuggestion({
    required this.idiomaticVersion,
    required this.nuanceExplanation,
    required this.registerTag,
    this.alternativeExpressions = const [],
  });

  Map<String, dynamic> toJson() => {
        'idiomatic_version': idiomaticVersion,
        'nuance_explanation': nuanceExplanation,
        'register_tag': registerTag,
        'alternative_expressions': alternativeExpressions,
      };

  factory NaturalFluencySuggestion.fromJson(Map<String, dynamic> json) =>
      NaturalFluencySuggestion(
        idiomaticVersion: json['idiomatic_version'] as String? ?? '',
        nuanceExplanation: json['nuance_explanation'] as String? ?? '',
        registerTag: json['register_tag'] as String? ?? 'Native Idiom',
        alternativeExpressions: (json['alternative_expressions'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// 3. 'Tutor Continuity Response': A constructive reply statement from virtual coach
class TutorContinuityResponse {
  final String coachReply;
  final String coachAudioText;
  final List<String> followUpQuestions;
  final String encouragementNote;

  const TutorContinuityResponse({
    required this.coachReply,
    required this.coachAudioText,
    required this.followUpQuestions,
    required this.encouragementNote,
  });

  Map<String, dynamic> toJson() => {
        'coach_reply': coachReply,
        'coach_audio_text': coachAudioText,
        'follow_up_questions': followUpQuestions,
        'encouragement_note': encouragementNote,
      };

  factory TutorContinuityResponse.fromJson(Map<String, dynamic> json) =>
      TutorContinuityResponse(
        coachReply: json['coach_reply'] as String? ?? '',
        coachAudioText: json['coach_audio_text'] as String? ?? '',
        followUpQuestions: (json['follow_up_questions'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        encouragementNote: json['encouragement_note'] as String? ?? 'Keep going!',
      );
}

/// Complete interactive turn tracking all 3 split-view targets from Gemma-4-E2B-it
class ConversationLabTurn {
  final String id;
  final String userMessage;
  final AppLanguage userLanguage;
  final AppLanguage targetLanguage;
  final DateTime timestamp;
  final GrammarCheckResult grammarCheck;
  final NaturalFluencySuggestion fluencySuggestion;
  final TutorContinuityResponse tutorContinuity;
  final CapturedFramePayload? visionContextFrame;

  const ConversationLabTurn({
    required this.id,
    required this.userMessage,
    required this.userLanguage,
    required this.targetLanguage,
    required this.timestamp,
    required this.grammarCheck,
    required this.fluencySuggestion,
    required this.tutorContinuity,
    this.visionContextFrame,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_message': userMessage,
        'user_language': userLanguage.code,
        'target_language': targetLanguage.code,
        'timestamp': timestamp.toIso8601String(),
        'grammar_check': grammarCheck.toJson(),
        'natural_fluency_suggestion': fluencySuggestion.toJson(),
        'tutor_continuity_response': tutorContinuity.toJson(),
        'has_vision_frame': visionContextFrame != null,
      };

  factory ConversationLabTurn.fromJson(
    Map<String, dynamic> json, {
    CapturedFramePayload? frame,
  }) =>
      ConversationLabTurn(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userMessage: json['user_message'] as String? ?? '',
        userLanguage: AppLanguage.fromCode(json['user_language'] as String? ?? 'en'),
        targetLanguage: AppLanguage.fromCode(json['target_language'] as String? ?? 'en'),
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        grammarCheck: json['grammar_check'] != null
            ? GrammarCheckResult.fromJson(json['grammar_check'] as Map<String, dynamic>)
            : const GrammarCheckResult(
                hasErrors: false,
                annotatedText: '',
                correctionNotes: [],
              ),
        fluencySuggestion: json['natural_fluency_suggestion'] != null
            ? NaturalFluencySuggestion.fromJson(
                json['natural_fluency_suggestion'] as Map<String, dynamic>)
            : const NaturalFluencySuggestion(
                idiomaticVersion: '',
                nuanceExplanation: '',
                registerTag: 'Standard',
              ),
        tutorContinuity: json['tutor_continuity_response'] != null
            ? TutorContinuityResponse.fromJson(
                json['tutor_continuity_response'] as Map<String, dynamic>)
            : const TutorContinuityResponse(
                coachReply: 'Interesting point! Tell me more.',
                coachAudioText: 'Interesting point! Tell me more.',
                followUpQuestions: [],
                encouragementNote: 'Good job!',
              ),
        visionContextFrame: frame,
      );

  String toFormattedPromptResponseJson() {
    return jsonEncode(toJson());
  }
}
