import 'package:flutter/material.dart';

/// Design tokens and styling for the camera overlay and multi-platform HUD.
class AppTheme {
  static const Color background = Color(0xFF0A0E14);
  static const Color surfaceDark = Color(0xE6121820);
  static const Color surfaceCard = Color(0xF2182230);
  static const Color cardBorder = Color(0x2EFFFFFF);

  // Mode Accents
  static const Color explorationAmber = Color(0xFFF59E0B);
  static const Color explorationGlow = Color(0x40F59E0B);
  static const Color learningEmerald = Color(0xFF10B981);
  static const Color learningGlow = Color(0x4010B981);

  // Reticle HUD Colors
  static const Color hudCyan = Color(0xFF00E5FF);
  static const Color hudGrid = Color(0x1A00E5FF);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: learningEmerald,
      colorScheme: const ColorScheme.dark(
        primary: learningEmerald,
        secondary: explorationAmber,
        surface: surfaceDark,
      ),
      fontFamily: 'Roboto',
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
    );
  }
}
