import 'package:flutter/material.dart';
import 'app_language.dart';

/// The two primary functional modes of the application, derived dynamically
/// from the relationship between the selected Input and Output languages.
enum AppMode {
  /// Triggered when `inputLanguage == outputLanguage`.
  /// Presents in-depth monolingual explanations, contextual nuance, taxonomy,
  /// and cultural descriptions of identified objects or text in that language.
  exploration,

  /// Triggered when `inputLanguage != outputLanguage`.
  /// Presents cross-lingual translations, phonetic transcriptions, grammatical
  /// breakdowns, and morphological structure.
  learning;

  /// Derive active mode from input and output language configuration.
  static AppMode derive({
    required AppLanguage inputLanguage,
    required AppLanguage outputLanguage,
  }) {
    if (inputLanguage == outputLanguage) {
      return AppMode.exploration;
    } else {
      return AppMode.learning;
    }
  }

  /// Whether current mode is Exploration Mode
  bool get isExploration => this == AppMode.exploration;

  /// Whether current mode is Learning Mode
  bool get isLearning => this == AppMode.learning;

  /// User-facing mode label
  String get title {
    switch (this) {
      case AppMode.exploration:
        return 'Exploration Mode';
      case AppMode.learning:
        return 'Learning Mode';
    }
  }

  /// Short subtitle describing active behavior
  String get subtitle {
    switch (this) {
      case AppMode.exploration:
        return 'Monolingual Deep-Dive & Cultural Insights';
      case AppMode.learning:
        return 'Bilingual Translation & Grammatical Breakdown';
    }
  }

  /// Primary theme accent color for the mode badge and HUD accents
  Color get accentColor {
    switch (this) {
      case AppMode.exploration:
        return const Color(0xFFF59E0B); // Amber / Gold
      case AppMode.learning:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  /// Secondary badge color
  Color get badgeBgColor {
    switch (this) {
      case AppMode.exploration:
        return const Color(0x33F59E0B);
      case AppMode.learning:
        return const Color(0x3310B981);
    }
  }

  /// Icon representing the mode
  IconData get icon {
    switch (this) {
      case AppMode.exploration:
        return Icons.travel_explore_rounded;
      case AppMode.learning:
        return Icons.auto_stories_rounded;
    }
  }
}
