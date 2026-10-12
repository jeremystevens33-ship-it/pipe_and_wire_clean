package com.example.pipe_and_wire_clean

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer

class MainActivity : FlutterActivity() {
    private var recognizer: SpeechRecognizer? = null
    private var pending: MethodChannel.Result? = null
    private var speechPauseMillis: Int? = null
    private var speechChannel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    private val timeout = Runnable { finish(error = "Speech timed out. Try again or type your material.") }

    private fun onDeviceAvailable(): Boolean = Build.VERSION.SDK_INT >= 31 &&
        SpeechRecognizer.isOnDeviceRecognitionAvailable(this)

    private fun available(): Boolean = onDeviceAvailable() || SpeechRecognizer.isRecognitionAvailable(this)

    private fun speechStatus(): Map<String, Any> = mapOf(
        "available" to available(),
        "mode" to if (onDeviceAvailable()) "on_device" else if (available()) "phone_service" else "unavailable",
        "message" to if (onDeviceAvailable()) "On-device voice: no internet needed."
            else if (available()) "Phone voice service: offline preferred; it may need a connection."
            else "No speech service is available. Enable a speech recognition service in phone settings, or use app typing.",
        "androidVersion" to Build.VERSION.RELEASE
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pipe_and_wire/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val text = call.argument<String>("text")
                val title = call.argument<String>("title") ?: "Share"
                if (text.isNullOrBlank()) {
                    result.error("empty", "There is no list to share.", null)
                    return@setMethodCallHandler
                }
                try {
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                        putExtra(Intent.EXTRA_SUBJECT, title)
                    }
                    startActivity(Intent.createChooser(send, title))
                    // Opening the chooser does not imply delivery.
                    result.success(null)
                } catch (_: Exception) {
                    result.error("share", "Could not open sharing. Please try again.", null)
                }
            }
        speechChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pipe_and_wire/offline_speech")
        speechChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "available" -> result.success(available())
                    "status" -> result.success(speechStatus())
                    "listen" -> {
                        if (pending != null) {
                            result.error("busy", "Microphone is already listening.", null)
                        } else if (!available()) {
                            result.error("unavailable", "No phone speech service is available. You can use app typing instead.", null)
                        } else {
                            pending = result
                            speechPauseMillis = call.argument<Number>("pauseMillis")?.toInt()?.coerceIn(1000, 5000)
                            if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                                requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 4301)
                            } else startSpeech()
                        }
                    }
                    "stop" -> {
                        if (recognizer == null && pending != null) finish(error = "Recording stopped before it began.")
                        else recognizer?.stopListening()
                        result.success(null)
                    }
                    "cancel" -> { finish(error = "Listening cancelled."); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 4301 && pending != null) {
            if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) startSpeech()
            else finish(error = "Microphone permission was denied. You can type instead.")
        }
    }

    private fun startSpeech(preferOffline: Boolean = true) {
        if (pending == null) return
        try {
            // Prefer guaranteed local speech. Older phones can use their own
            // speech service without opening a keyboard. Its mode is shown in UI.
            val local = onDeviceAvailable()
            val currentRecognizer = if (local && Build.VERSION.SDK_INT >= 31)
                SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
            else SpeechRecognizer.createSpeechRecognizer(this)
            recognizer = currentRecognizer
            currentRecognizer.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {}
                override fun onPartialResults(partialResults: Bundle?) {
                    if (recognizer !== currentRecognizer || pending == null) return
                    val text = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                    if (!text.isNullOrBlank()) speechChannel?.invokeMethod("partial", text)
                }
                override fun onEvent(eventType: Int, params: Bundle?) {}
                override fun onResults(results: Bundle?) {
                    if (recognizer !== currentRecognizer || pending == null) return
                    val text = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                    if (text.isNullOrBlank()) finish(error = "No words recognized. Try again or type instead.")
                    else finish(text = text)
                }
                override fun onError(error: Int) {
                    if (recognizer !== currentRecognizer || pending == null) return
                    val languageUnavailable = error == SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED ||
                        error == SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE
                    if (!local && preferOffline && languageUnavailable) {
                        // A keyboard's dictation service can work even when its
                        // offline English pack is missing. Retry once with the
                        // service's default language and normal network policy.
                        val request = pending
                        recognizer = null
                        handler.removeCallbacks(timeout)
                        currentRecognizer.cancel()
                        currentRecognizer.destroy()
                        handler.postDelayed({
                            if (pending === request && pending != null && recognizer == null) startSpeech(false)
                        }, 250)
                        return
                    }
                    val message = when (error) {
                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Microphone permission is required. You can type instead."
                        SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED, SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE ->
                            if (local) "Offline English speech is unavailable. Check your phone's speech language downloads, or type instead."
                            else "The phone speech language is unavailable. Check the speech service's language settings, or use app typing."
                        SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No words recognized. Try again or type instead."
                        SpeechRecognizer.ERROR_NETWORK, SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "The phone speech service needs a connection right now. Retry with reception, or use app typing."
                        else -> "Speech could not finish ($error). Try again or type instead."
                    }
                    finish(error = message)
                }
            })
            currentRecognizer.startListening(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                if (preferOffline) putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, preferOffline)
                speechPauseMillis?.let {
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, it.toLong())
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, it.toLong())
                }
            })
            handler.postDelayed(timeout, if (speechPauseMillis != null) 45000L else 20000L)
        } catch (_: Exception) {
            finish(error = "The phone speech service could not start. Try again or use app typing.")
        }
    }

    private fun finish(text: String? = null, error: String? = null) {
        val result = pending
        pending = null
        handler.removeCallbacks(timeout)
        val oldRecognizer = recognizer
        recognizer = null
        oldRecognizer?.cancel()
        oldRecognizer?.destroy()
        if (text != null) result?.success(text)
        else result?.error("speech", error ?: "Listening cancelled.", null)
    }

    override fun onStop() {
        finish(error = "Listening stopped when the app left the screen.")
        super.onStop()
    }

    override fun onDestroy() { finish(error = "Listening cancelled."); super.onDestroy() }
}
