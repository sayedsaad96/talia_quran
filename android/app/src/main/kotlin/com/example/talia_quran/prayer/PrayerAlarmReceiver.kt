package com.example.talia_quran.prayer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Fires when a scheduled prayer alarm goes off.
 *
 * Contract (V2 §13):
 *   - Reads the event payload ONLY (never computes prayer times).
 *   - Always posts the prayer notification (when enabled).
 *   - When adhan is enabled, starts AdhanPlaybackService (owned playback).
 *   - Never starts the Flutter engine and never depends on the app being
 *     open.
 */
class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val event = PrayerEventCodec.fromIntentExtras(intent)
        if (event == null) {
            Log.w(TAG, "received prayer alarm without a parseable event payload")
            return
        }
        Log.d(
            TAG,
            "received event=${event.eventId} prayer=${event.prayerKey} adhan=${event.adhanEnabled}",
        )
        if (!event.notificationEnabled) {
            Log.d(TAG, "notification disabled for ${event.eventId}; nothing to post")
            return
        }
        PrayerNotificationFactory.post(context, event)
        if (event.adhanEnabled) {
            startAdhanPlayback(context, event)
        }
    }

    /**
     * Stage 6: starts the adhan playback foreground service. Failures are
     * logged, never thrown — the prayer notification has already been
     * posted and must not be lost. Note: on Android 12+, an inexact
     * fallback alarm may not be allowed to start a foreground service from
     * the background; in that case the notification still fires and only
     * the adhan playback is skipped (documented V2 §26 fallback behavior).
     */
    private fun startAdhanPlayback(context: Context, event: PrayerEventData) {
        try {
            val intent = Intent(context, AdhanPlaybackService::class.java)
                .setAction(AdhanPlaybackService.ACTION_START)
                .putExtra(AdhanPlaybackService.EXTRA_PRAYER_KEY, event.prayerKey)
                .putExtra(AdhanPlaybackService.EXTRA_LOCAL_PRAYER_TIME, event.localPrayerTime)
                .putExtra(AdhanPlaybackService.EXTRA_SOUND_PROFILE, event.soundProfile)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        } catch (error: Exception) {
            Log.w(TAG, "failed to start adhan playback service", error)
        }
    }

    private companion object {
        const val TAG = "PrayerV2"
    }
}