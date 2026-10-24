package com.talia.quran

import android.content.ComponentName
import android.content.pm.PackageManager
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.StatFs
import android.media.MediaPlayer
import com.talia.quran.prayer.AdhanClipResolver
import com.talia.quran.prayer.AdhanPreviewBridge
import com.talia.quran.widget.TaliaHomeWidgetProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var previewPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerAdhanPreviewChannel(flutterEngine.dartExecutor.binaryMessenger)
        registerHomeWidgetComponentChannel(flutterEngine.dartExecutor.binaryMessenger)
        registerDeviceResourcesChannel(flutterEngine.dartExecutor.binaryMessenger)
    }

    /**
     * Read-only probes for recitation downloads: free space in the app's files
     * directory (where downloads are stored) and whether the active network is
     * unmetered. Answers null when the device cannot tell.
     */
    private fun registerDeviceResourcesChannel(messenger: io.flutter.plugin.common.BinaryMessenger) {
        MethodChannel(messenger, "talia/device_resources").setMethodCallHandler { call, result ->
            when (call.method) {
                "freeBytes" -> result.success(
                    try {
                        StatFs(filesDir.absolutePath).availableBytes
                    } catch (e: Exception) {
                        null
                    },
                )
                "isUnmeteredNetwork" -> result.success(
                    try {
                        val manager = getSystemService(ConnectivityManager::class.java)
                        val capabilities = manager?.getNetworkCapabilities(manager.activeNetwork)
                        capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
                    } catch (e: Exception) {
                        null
                    },
                )
                else -> result.notImplemented()
            }
        }
    }

    /**
     * The widget receiver ships disabled in the manifest and is only offered
     * to the user while its feature flag is on. Pure component toggle: it never
     * reads or writes widget data.
     */
    private fun registerHomeWidgetComponentChannel(messenger: io.flutter.plugin.common.BinaryMessenger) {
        MethodChannel(messenger, "talia/home_widget_component").setMethodCallHandler { call, result ->
            when (call.method) {
                "setProviderEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled")
                    if (enabled == null) {
                        result.error("bad_args", "enabled is required", null)
                    } else {
                        try {
                            packageManager.setComponentEnabledSetting(
                                ComponentName(this, TaliaHomeWidgetProvider::class.java),
                                if (enabled) {
                                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                                } else {
                                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                                },
                                PackageManager.DONT_KILL_APP,
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("component_failed", e.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
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
