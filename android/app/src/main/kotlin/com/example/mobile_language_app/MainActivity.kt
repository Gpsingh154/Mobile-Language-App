package com.example.mobile_language_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.speech.tts.TextToSpeech
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val permissionsChannelName = "com.bolixr.languageapp/permissions"
    private val audioChannelName = "com.bolixr.languageapp/audio"

    private val permissionRequestCode = 1001
    private var pendingPermissionResult: MethodChannel.Result? = null

    private var textToSpeech: TextToSpeech? = null
    private var isTtsInitialized = false
    private var pendingSpeakAction: (() -> Unit)? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        textToSpeech = TextToSpeech(applicationContext, this)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            isTtsInitialized = true
            pendingSpeakAction?.invoke()
            pendingSpeakAction = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Permissions Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, permissionsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPermission" -> {
                        val type = call.argument<String>("type") ?: ""
                        val permission = getManifestPermission(type)
                        if (permission == null) {
                            result.success("granted")
                            return@setMethodCallHandler
                        }
                        val granted = ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
                        if (granted) {
                            result.success("granted")
                        } else {
                            val deniedBefore = ActivityCompat.shouldShowRequestPermissionRationale(this, permission)
                            result.success(if (deniedBefore) "denied" else "notDetermined")
                        }
                    }
                    "requestPermission" -> {
                        val type = call.argument<String>("type") ?: ""
                        val permission = getManifestPermission(type)
                        if (permission == null) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
                            result.success(true)
                        } else {
                            if (pendingPermissionResult != null) {
                                result.success(false)
                                return@setMethodCallHandler
                            }
                            pendingPermissionResult = result
                            ActivityCompat.requestPermissions(this, arrayOf(permission), permissionRequestCode)
                        }
                    }
                    "openAppSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // 2. Audio & TTS Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, audioChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "speak" -> {
                        val text = call.argument<String>("text") ?: ""
                        val langCode = call.argument<String>("language") ?: "en-US"
                        val rate = (call.argument<Double>("rate") ?: 1.0).toFloat()
                        val pitch = (call.argument<Double>("pitch") ?: 1.0).toFloat()

                        if (text.trim().isEmpty()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        val performSpeak = {
                            val tts = textToSpeech
                            if (tts != null && isTtsInitialized) {
                                val locale = getLocaleFromCode(langCode)
                                val avail = tts.isLanguageAvailable(locale)
                                if (avail >= TextToSpeech.LANG_AVAILABLE) {
                                    tts.language = locale
                                } else {
                                    tts.language = Locale.US
                                }
                                tts.setSpeechRate(rate)
                                tts.setPitch(pitch)
                                val speakResult = tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "BoliXR_${System.currentTimeMillis()}")
                                result.success(speakResult == TextToSpeech.SUCCESS)
                            } else {
                                result.success(false)
                            }
                        }

                        if (textToSpeech != null && !isTtsInitialized) {
                            pendingSpeakAction = performSpeak
                        } else {
                            performSpeak()
                        }
                    }
                    "stop" -> {
                        pendingSpeakAction = null
                        textToSpeech?.stop()
                        result.success(true)
                    }
                    "isSpeaking" -> {
                        result.success(textToSpeech?.isSpeaking ?: false)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getManifestPermission(type: String): String? {
        return when (type) {
            "camera" -> Manifest.permission.CAMERA
            "microphone" -> Manifest.permission.RECORD_AUDIO
            else -> null
        }
    }

    private fun getLocaleFromCode(code: String): Locale {
        return when (code) {
            "pa-IN", "pa" -> Locale("pa", "IN")
            "hi-IN", "hi" -> Locale("hi", "IN")
            "en-US", "en" -> Locale.US
            "fr-FR", "fr" -> Locale.FRANCE
            "ta-IN", "ta" -> Locale("ta", "IN")
            "te-IN", "te" -> Locale("te", "IN")
            else -> Locale.US
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == permissionRequestCode) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        super.onDestroy()
    }
}
