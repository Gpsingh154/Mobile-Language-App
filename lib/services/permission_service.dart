import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Supported hardware device permission categories
enum PermissionType {
  camera,
  microphone,
}

/// OS-level authorization states
enum PermissionStatus {
  granted,
  denied,
  notDetermined,
  restricted,
}

/// Native platform permission checking and contextual permission priming service.
/// Communicates directly with iOS (AppDelegate.swift) and Android (MainActivity.kt)
/// over the 'com.bolixr.languageapp/permissions' platform channel without requiring
/// third-party plugins that fail on Windows Google Drive symlinks.
class PermissionService {
  static const MethodChannel _channel = MethodChannel('com.bolixr.languageapp/permissions');

  /// Checks the current permission status for [type].
  static Future<PermissionStatus> checkPermission(PermissionType type) async {
    // In automated widget test environments or desktop, grant immediately
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      return PermissionStatus.granted;
    }

    try {
      final String? result = await _channel.invokeMethod<String>(
        'checkPermission',
        {'type': type.name},
      );
      switch (result) {
        case 'granted':
          return PermissionStatus.granted;
        case 'denied':
          return PermissionStatus.denied;
        case 'restricted':
          return PermissionStatus.restricted;
        case 'notDetermined':
        default:
          return PermissionStatus.notDetermined;
      }
    } on MissingPluginException {
      return PermissionStatus.granted;
    } catch (_) {
      return PermissionStatus.granted;
    }
  }

  /// Triggers the native iOS or Android system permission request dialog for [type].
  static Future<bool> requestPermission(PermissionType type) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      return true;
    }

    try {
      final bool? granted = await _channel.invokeMethod<bool>(
        'requestPermission',
        {'type': type.name},
      );
      return granted ?? false;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens the device App Settings page if permissions were permanently denied.
  static Future<bool> openAppSettings() async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      return false;
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>('openAppSettings');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Contextual permission priming for the Microphone before starting audio recording.
  /// If granted or in test/desktop mode, returns true immediately.
  /// If not determined, triggers the system permission dialog directly.
  /// If denied, presents a contextual dialog allowing the user to open settings.
  static Future<bool> ensureMicrophonePermission(BuildContext context) async {
    final status = await checkPermission(PermissionType.microphone);

    if (status == PermissionStatus.granted) {
      return true;
    }

    if (status == PermissionStatus.notDetermined) {
      final granted = await requestPermission(PermissionType.microphone);
      return granted;
    }

    // Permission previously denied or restricted: show contextual priming dialog
    if (context.mounted) {
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161F2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.white24),
          ),
          title: Row(
            children: const [
              Icon(Icons.mic_none_rounded, color: Color(0xFF34C759), size: 24),
              SizedBox(width: 10),
              Text(
                'Microphone Access',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'BoliXR Companion uses the microphone for real-time multilingual speech recognition (IndicConformer ASR) and interactive pronunciation practice.\n\nPlease enable microphone permissions in your device settings.',
            style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop(false);
                openAppSettings();
              },
              child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return false;
    }

    return false;
  }

  /// Contextual permission priming for the Camera before starting viewfinder or capture.
  static Future<bool> ensureCameraPermission(BuildContext context) async {
    final status = await checkPermission(PermissionType.camera);

    if (status == PermissionStatus.granted) {
      return true;
    }

    if (status == PermissionStatus.notDetermined) {
      final granted = await requestPermission(PermissionType.camera);
      return granted;
    }

    if (context.mounted) {
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161F2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.white24),
          ),
          title: Row(
            children: const [
              Icon(Icons.videocam_outlined, color: Color(0xFF34C759), size: 24),
              SizedBox(width: 10),
              Text(
                'Camera Access',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'BoliXR Companion uses the camera for on-demand visual language entity scanning and vocabulary discovery.\n\nPlease enable camera permissions in your device settings.',
            style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop(false);
                openAppSettings();
              },
              child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return false;
    }

    return false;
  }
}
