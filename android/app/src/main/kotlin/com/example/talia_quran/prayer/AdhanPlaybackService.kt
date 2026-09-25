package com.example.talia_quran.prayer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.util.Log

/**
 * Owns full Adhan audio playback (V2 §15). Responsibilities ONLY:
 *
 *   1. Read prayer/sound profile from the intent extras.
 *   2. Request audio focus (USAGE_MEDIA + CONTENT_TYPE_SPEECH).
 *   3. Show a foreground media notification (low-importance channel) with
 *      a "إيقاف الأذان" stop action.
 *   4. Play the bundled adhan clip via MediaPlayer.
 *   5. Handle the stop action (user button or audio-focus loss).
 *   6. Release the player, abandon focus, stop the foreground service.
 *
 * Never computes prayer times, never touches Flutter. No full-screen
 * intent, no forcing the user to open Talia.
 */
class AdhanPlaybackService : Service() {
    companion object {
        const val ACTION_START = "com.example.talia_quran.prayer.action.START_ADHAN"
        const val ACTION_STOP = "com.example.talia_quran.prayer.action.STOP_ADHAN"
        const val EXTRA_PRAYER_KEY = "prayerKey"
        const val EXTRA_LOCAL_PRAYER_TIME = "localPrayerTime"
        const val EXTRA_SOUND_PROFILE = "soundProfile"

        /** Low-importance channel: the media notification must not make sound. */
        const val CHANNEL_ID = "talia_adhan_playback"

        /** Media-notification id, outside every frozen alarm namespace (2200–2499). */
        const val MEDIA_NOTIFICATION_ID = 2500
        private const val STOP_REQUEST_CODE = 2500
        private const val TAG = "PrayerV2"

        fun isStopAction(action: String?): Boolean = action == ACTION_STOP
    }

    private var player: MediaPlayer? = null
    private var audioManager: AudioManager? = null
    private var focusRequest: AudioFocusRequest? = null
    private var ducked = false
    private var pausedByFocus = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (isStopAction(intent?.action)) {
            Log.d(TAG, "stop_action received")
            stopPlayback()
            return START_NOT_STICKY
        }
        val prayerKey = intent?.getStringExtra(EXTRA_PRAYER_KEY) ?: "prayer"
        val soundProfile = intent?.getStringExtra(EXTRA_SOUND_PROFILE) ?: "default"
        startForegroundCompat(buildMediaNotification(prayerKey))
        Log.d(TAG, "focus_requested profile=$soundProfile")
        if (!requestAudioFocus()) {
            Log.w(TAG, "audio focus denied; skipping adhan playback")
            stopPlayback()
            return START_NOT_STICKY
        }
        startPlayback(soundProfile)
        return START_NOT_STICKY
    }

    private fun startPlayback(soundProfile: String) {
        try {
            val clip = AdhanClipResolver.rawResourceName(soundProfile, "")
            val resId = resources.getIdentifier(clip, "raw", packageName)
            if (resId == 0) {
                Log.w(TAG, "bundled clip '$clip' not found")
                stopPlayback()
                return
            }
            val mediaPlayer = MediaPlayer()
            mediaPlayer.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build(),
            )
            mediaPlayer.setDataSource(this, Uri.parse("android.resource://$packageName/raw/$clip"))
            mediaPlayer.setOnCompletionListener {
                Log.d(TAG, "playback_completed")
                stopPlayback()
            }
            mediaPlayer.setOnErrorListener { _, what, extra ->
                Log.w(TAG, "playback error what=$what extra=$extra")
                stopPlayback()
                true
            }
            mediaPlayer.prepare()
            mediaPlayer.start()
            player = mediaPlayer
            Log.d(TAG, "playback_started clip=$clip")
        } catch (error: Exception) {
            Log.w(TAG, "failed to start playback", error)
            stopPlayback()
        }
    }

    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            AudioManager.AUDIOFOCUS_LOSS -> {
                Log.d(TAG, "focus_lost")
                stopPlayback()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                pausedByFocus = true
                try {
                    player?.pause()
                } catch (_: Exception) {
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                ducked = true
                try {
                    player?.setVolume(0.2f, 0.2f)
                } catch (_: Exception) {
                }
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                try {
                    if (ducked) {
                        ducked = false
                        player?.setVolume(1.0f, 1.0f)
                    }
                    if (pausedByFocus) {
                        pausedByFocus = false
                        player?.start()
                    }
                } catch (_: Exception) {
                }
            }
        }
    }

    private fun requestAudioFocus(): Boolean {
        audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
            .build()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attrs)
                .setOnAudioFocusChangeListener(focusListener)
                .build()
            focusRequest = request
            audioManager!!.requestAudioFocus(request) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            @Suppress("DEPRECATION")
            audioManager!!.requestAudioFocus(
                focusListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN,
            ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    private fun abandonAudioFocus() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                focusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
                focusRequest = null
            } else {
                @Suppress("DEPRECATION")
                audioManager?.abandonAudioFocus(focusListener)
            }
        } catch (error: Exception) {
            Log.w(TAG, "failed to abandon audio focus", error)
        }
    }

    private fun stopPlayback() {
        try {
            player?.let { if (it.isPlaying) it.stop() }
        } catch (_: Exception) {
        }
        try {
            player?.release()
        } catch (_: Exception) {
        }
        player = null
        abandonAudioFocus()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
        Log.d(TAG, "service_stopped")
    }

    private fun startForegroundCompat(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                MEDIA_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(MEDIA_NOTIFICATION_ID, notification)
        }
    }

    private fun buildMediaNotification(prayerKey: String): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "الأذان",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply { description = "تشغيل الأذان مع إمكانية الإيقاف" },
            )
        }
        val stopIntent = PendingIntent.getService(
            this,
            STOP_REQUEST_CODE,
            Intent(this, AdhanPlaybackService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val launch = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent().setClassName(this, "com.example.talia_quran.MainActivity")
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val contentIntent = PendingIntent.getActivity(
            this,
            MEDIA_NOTIFICATION_ID,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle("صلاة ${PrayerNames.arabic(prayerKey)}")
            .setContentText("الأذان الآن")
            .setSmallIcon(applicationInfo.icon)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_TRANSPORT)
            .setContentIntent(contentIntent)
            .addAction(0, "إيقاف الأذان", stopIntent)
            .build()
    }
}