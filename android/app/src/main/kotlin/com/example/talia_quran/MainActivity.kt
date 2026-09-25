package com.example.talia_quran

import android.media.AudioManager
import android.media.MediaPlayer
import com.example.talia_quran.prayer.AdhanClipResolver
import com.example.talia_quran.prayer.AdhanPreviewBridge
import com.example.talia_quran.prayer.PrayerDeliveryChannelHandler
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var previewPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Prayer V2 delivery: AlarmManager-backed scheduling (stage 4).
        // Dormant until Dart flips prayer_delivery_version to 2 (stage 7).
        PrayerDeliveryChannelHandler.register(this, flutterEngine.dartExecutor.binaryMessenger)
        registerAdhanPreviewChannel(flutterEngine.dartExecutor.binaryMessenger)
    }

    /**
     * Muezzin preview channel: lets the settings UI play a short sample of
     * each bundled adhan clip BEFORE the user commits to a choice. Pure UI
     * affordance — never touches alarms, notifications or scheduling.
     */
    private fun registerAdhanPreviewChannel(messenger: io.flutter.plugin.common.BinaryMessenger) {
        MethodChannel(messenger, "talia/adhan_preview").setMethodCallHandler { call, result ->
            when (call.method) {
                "resolveClipSource" -> {
                    val profile = call.argument<String>("soundProfile") ?: "default"
                    val clip = AdhanClipResolver.rawResourceName(profile, "fajr")
                    val resId = resources.getIdentifier(clip, "raw", packageName)
                    if (resId == 0) {
                        result.success(null)
                    } else {
                        result.success(AdhanPreviewBridge.previewSource(this, clip))
                    }
                }
                "previewStart" -> {
                    val profile = call.argument<String>("soundProfile") ?: "default"
                    val clip = AdhanClipResolver.rawResourceName(profile, "fajr")
                    val resId = resources.getIdentifier(clip, "raw", packageName)
                    if (resId == 0) {
                        result.success(false)
                    } else {
                        result.success(startPreview(resId))
                    }
                }
                "previewStop" -> {
                    stopPreview()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    @Synchronized
    private fun startPreview(resId: Int): Boolean {
        return try {
            stopPreview()
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            val player = MediaPlayer.create(this, resId) ?: return false
            player.setOnCompletionListener {
                it.release()
                if (previewPlayer === it) previewPlayer = null
            }
            player.setOnErrorListener { p, _, _ ->
                p.release()
                if (previewPlayer === p) previewPlayer = null
                true
            }
            player.start()
            previewPlayer = player
            // Respect the media volume the user already set.
            audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun stopPreview() {
        try {
            previewPlayer?.let { p ->
                p.stop()
                p.release()
            }
        } catch (_: Exception) {
        }
        previewPlayer = null
    }

    override fun onDestroy() {
        stopPreview()
        super.onDestroy()
    }
}
