import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, AVSpeechSynthesizerDelegate {
  private let permissionsChannelName = "com.bolixr.languageapp/permissions"
  private let audioChannelName = "com.bolixr.languageapp/audio"

  private var speechSynthesizer = AVSpeechSynthesizer()
  private var isConfigured = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let registrar = self.registrar(forPlugin: "BoliXRNative") {
      setupChannels(messenger: registrar.messenger())
    } else if let controller = window?.rootViewController as? FlutterViewController {
      setupChannels(messenger: controller.binaryMessenger)
    }

    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BoliXRNative") {
      setupChannels(messenger: registrar.messenger())
    }
  }

  private func setupChannels(messenger: FlutterBinaryMessenger) {
    guard !isConfigured else { return }
    isConfigured = true

    speechSynthesizer.delegate = self
    configureAudioSession()

    // 1. Permissions Platform Channel
    let permissionsChannel = FlutterMethodChannel(name: permissionsChannelName, binaryMessenger: messenger)
    permissionsChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handlePermissionsCall(call: call, result: result)
    }

    // 2. Audio & Speech Synthesis Platform Channel
    let audioChannel = FlutterMethodChannel(name: audioChannelName, binaryMessenger: messenger)
    audioChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleAudioCall(call: call, result: result)
    }
  }

  private func configureAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      print("[BoliXR Audio] Error activating AVAudioSession: \(error)")
    }
  }

  private func handlePermissionsCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "checkPermission":
      guard let args = call.arguments as? [String: Any],
            let type = args["type"] as? String else {
        result("granted")
        return
      }
      if type == "camera" {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized: result("granted")
        case .notDetermined: result("notDetermined")
        case .denied: result("denied")
        case .restricted: result("restricted")
        @unknown default: result("denied")
        }
      } else if type == "microphone" {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized: result("granted")
        case .notDetermined: result("notDetermined")
        case .denied: result("denied")
        case .restricted: result("restricted")
        @unknown default: result("denied")
        }
      } else {
        result("granted")
      }

    case "requestPermission":
      guard let args = call.arguments as? [String: Any],
            let type = args["type"] as? String else {
        result(true)
        return
      }
      if type == "camera" {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
          AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { result(granted) }
          }
        } else {
          result(status == .authorized)
        }
      } else if type == "microphone" {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .notDetermined {
          AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async { result(granted) }
          }
        } else {
          result(status == .authorized)
        }
      } else {
        result(true)
      }

    case "openAppSettings":
      if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:]) { success in
          result(success)
        }
      } else {
        result(false)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleAudioCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "speak":
      guard let args = call.arguments as? [String: Any],
            let text = args["text"] as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        result(false)
        return
      }
      let langCode = (args["language"] as? String) ?? "en-US"
      let rate = (args["rate"] as? Double) ?? 1.0
      let pitch = (args["pitch"] as? Double) ?? 1.0

      // Configure audio session with .playback category so it sounds through physical speakers
      // even if the iPhone silent switch is set to mute.
      configureAudioSession()

      let utterance = AVSpeechUtterance(string: text)
      if let voice = resolveVoice(for: langCode) {
        utterance.voice = voice
      }
      let clampedRate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, Float(rate) * AVSpeechUtteranceDefaultSpeechRate))
      utterance.rate = clampedRate
      utterance.pitchMultiplier = max(0.5, min(2.0, Float(pitch)))

      if speechSynthesizer.isSpeaking {
        speechSynthesizer.stopSpeaking(at: .immediate)
        // Reset synthesizer instance to prevent iOS radar bug where back-to-back utterances are dropped
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer.delegate = self
      }
      speechSynthesizer.speak(utterance)
      result(true)

    case "stop":
      if speechSynthesizer.isSpeaking {
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer.delegate = self
      }
      result(true)

    case "isSpeaking":
      result(speechSynthesizer.isSpeaking)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func resolveVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
    let voices = AVSpeechSynthesisVoice.speechVoices()

    // 1. Exact match in installed speech voices (e.g., pa-IN, hi-IN, fr-FR, ta-IN, te-IN, en-US)
    if let exactVoice = voices.first(where: { $0.language.caseInsensitiveCompare(languageCode) == .orderedSame }) {
      return exactVoice
    }

    // 2. Exact match via system initializer IF available in installed voices
    if let systemVoice = AVSpeechSynthesisVoice(language: languageCode),
       voices.contains(where: { $0.identifier == systemVoice.identifier }) {
      return systemVoice
    }

    // 3. Prefix match in installed voices (e.g. "pa", "hi", "fr", "ta", "te")
    let prefix = languageCode.split(separator: "-").first.map(String.init) ?? languageCode
    if let prefixVoice = voices.first(where: { $0.language.lowercased().hasPrefix(prefix.lowercased()) }) {
      return prefixVoice
    }

    // 4. Fallback to Hindi for Indian locales (-IN) if regional voice (pa, ta, te) is uninstalled
    if languageCode.hasSuffix("-IN") || languageCode.hasPrefix("pa") || languageCode.hasPrefix("ta") || languageCode.hasPrefix("te") {
      if let hindiVoice = voices.first(where: { $0.language.lowercased().hasPrefix("hi") }) ?? AVSpeechSynthesisVoice(language: "hi-IN") {
        return hindiVoice
      }
    }

    // 5. Fallback to system requested voice as last attempt
    if let fallback = AVSpeechSynthesisVoice(language: languageCode) {
      return fallback
    }

    // 6. Guaranteed audible voice: English
    return voices.first(where: { $0.language.lowercased().hasPrefix("en") }) ?? AVSpeechSynthesisVoice(language: "en-US")
  }
}
