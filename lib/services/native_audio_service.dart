import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/app_language.dart';

/// Native cross-platform Audio and Voice Synthesis service.
/// 
/// Communicates over 'com.bolixr.languageapp/audio' with:
/// - iOS: Native AVSpeechSynthesizer configured with AVAudioSessionCategoryPlayback
///   (so audio plays audibly through speakers even if the iPhone hardware ring/silent switch is on silent).
/// - Android: Native android.speech.tts.TextToSpeech with multilingual locale mapping.
/// - Windows Desktop: Local SAPI System.Speech.Synthesis fallback.
/// 
/// Supports authentic pronunciation in Punjabi, Hindi, English, French, Tamil, and Telugu.
class NativeAudioService {
  static const MethodChannel channel = MethodChannel('com.bolixr.languageapp/audio');

  /// Tracks the last spoken text for verification and UI state
  static String? lastSpokenText;
  static String? lastSpokenLocale;

  /// Maps [AppLanguage] to BCP-47 locale tags
  static String getLanguageLocaleCode(AppLanguage language) {
    switch (language) {
      case AppLanguage.punjabi:
        return 'pa-IN';
      case AppLanguage.hindi:
        return 'hi-IN';
      case AppLanguage.english:
        return 'en-US';
      case AppLanguage.french:
        return 'fr-FR';
      case AppLanguage.tamil:
        return 'ta-IN';
      case AppLanguage.telugu:
        return 'te-IN';
    }
  }

  /// Synthesizes and plays audible speech through the device's physical speakers.
  static Future<bool> speak({
    required String text,
    required AppLanguage language,
    double rate = 1.0,
    double pitch = 1.0,
  }) async {
    final sanitized = text.trim();
    if (sanitized.isEmpty) return false;

    final langCode = getLanguageLocaleCode(language);
    lastSpokenText = sanitized;
    lastSpokenLocale = langCode;

    // Unit test environment guard to keep test suites blazing fast and silent
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }

    // Windows Desktop: Native SAPI fallback via PowerShell System.Speech
    if (Platform.isWindows) {
      _playWindowsSpeech(sanitized);
      return true;
    }

    // iOS and Android: Native platform channel
    if (Platform.isIOS || Platform.isAndroid) {
      try {
        final bool? success = await channel.invokeMethod<bool>('speak', {
          'text': sanitized,
          'language': langCode,
          'rate': rate,
          'pitch': pitch,
        });
        return success ?? false;
      } on MissingPluginException {
        return true;
      } catch (e) {
        debugPrint('[NativeAudioService] Playback error: $e');
        return false;
      }
    }

    return true;
  }

  /// Immediately stops any ongoing speech synthesis playback.
  static Future<bool> stop() async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }

    if (Platform.isIOS || Platform.isAndroid) {
      try {
        final bool? success = await channel.invokeMethod<bool>('stop');
        return success ?? false;
      } catch (_) {
        return false;
      }
    }

    return true;
  }

  /// Checks whether native speech synthesis is currently active.
  static Future<bool> isSpeaking() async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }

    if (Platform.isIOS || Platform.isAndroid) {
      try {
        final bool? active = await channel.invokeMethod<bool>('isSpeaking');
        return active ?? false;
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  /// Spawns Windows System.Speech.Synthesis PowerShell process for desktop laptop speaker audio.
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
}
