import 'dart:typed_data';

/// Trigger sources that kick off the on-demand single frame capture
enum VisionTriggerSource {
  audioVoice,
  textQuery,
  imageGallery,
}

/// Operational power state of the camera pipeline.
/// The pipeline stays strictly in [idleLowPower] until an explicit user event occurs.
enum CameraPowerState {
  idleLowPower,
  capturingSingleFrame,
  frameCaptured,
  error,
}

/// Isolated static frame payload captured on-demand and passed to Gemma-4-E2B-it.
class CapturedFramePayload {
  final String frameId;
  final VisionTriggerSource triggerSource;
  final String triggerQuery;
  final Uint8List frameBytes;
  final DateTime timestamp;
  final int width;
  final int height;
  final String label;
  final String? galleryImageName;

  const CapturedFramePayload({
    required this.frameId,
    required this.triggerSource,
    required this.triggerQuery,
    required this.frameBytes,
    required this.timestamp,
    required this.width,
    required this.height,
    required this.label,
    this.galleryImageName,
  });

  String get triggerDescription {
    switch (triggerSource) {
      case VisionTriggerSource.audioVoice:
        return 'Audio/Voice Input ("$triggerQuery")';
      case VisionTriggerSource.textQuery:
        return 'Text Input ("$triggerQuery")';
      case VisionTriggerSource.imageGallery:
        return 'Image Gallery Input (${galleryImageName ?? "Selected Photo"})';
    }
  }

  int get byteSize => frameBytes.lengthInBytes;
}
