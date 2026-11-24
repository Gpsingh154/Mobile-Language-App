/// Supported regional languages for the multi-platform language learning application.
/// Covers regional Indian languages: Punjabi, Hindi, Tamil, Telugu, and English.
enum AppLanguage {
  punjabi(
    code: 'pa',
    name: 'Punjabi',
    nativeName: 'ਪੰਜਾਬੀ',
    script: 'Gurmukhi',
    flagEmoji: '🇮🇳',
    regionName: 'Punjab',
  ),
  hindi(
    code: 'hi',
    name: 'Hindi',
    nativeName: 'हिन्दी',
    script: 'Devanagari',
    flagEmoji: '🇮🇳',
    regionName: 'Northern / Central India',
  ),
  tamil(
    code: 'ta',
    name: 'Tamil',
    nativeName: 'தமிழ்',
    script: 'Tamil',
    flagEmoji: '🇮🇳',
    regionName: 'Tamil Nadu',
  ),
  telugu(
    code: 'te',
    name: 'Telugu',
    nativeName: 'తెలుగు',
    script: 'Telugu',
    flagEmoji: '🇮🇳',
    regionName: 'Andhra Pradesh & Telangana',
  ),
  english(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    script: 'Latin',
    flagEmoji: '🌐',
    regionName: 'Global / Indian English',
  ),
  french(
    code: 'fr',
    name: 'French',
    nativeName: 'Français',
    script: 'Latin',
    flagEmoji: '🇫🇷',
    regionName: 'France / Global',
  );

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.script,
    required this.flagEmoji,
    required this.regionName,
  });

  final String code;
  final String name;
  final String nativeName;
  final String script;
  final String flagEmoji;
  final String regionName;

  /// Full label for dropdown display (e.g. "ਪੰਜਾਬੀ (Punjabi)")
  String get fullDisplayName => '$nativeName ($name)';

  /// Compact badge string (e.g. "PA · ਪੰਜਾਬੀ")
  String get badgeString => '${code.toUpperCase()} · $nativeName';

  /// Helper to lookup language by ISO code
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code.toLowerCase() == code.toLowerCase(),
      orElse: () => AppLanguage.english,
    );
  }
}
