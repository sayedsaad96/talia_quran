package com.example.talia_quran.prayer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/** Shared Arabic display names for the canonical prayer keys. */
object PrayerNames {
    private val AR = mapOf(
        "fajr" to "الفجر",
        "dhuhr" to "الظهر",
        "asr" to "العصر",
        "maghrib" to "المغرب",
        "isha" to "العشاء",
    )

    fun arabic(key: String): String = AR[key] ?: key
}

/**
 * Builds the "prayer time has come" notification on the dedicated V2
 * channel. Deliberately carries NO adhan clip: the adhan is owned audio
 * playback (AdhanPlaybackService), not a channel sound.
 */
object PrayerNotificationFactory {
    const val CHANNEL_ID = "talia_prayer_events_v2"
    private const val TAG = "PrayerV2"

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "مواقيت الصلاة",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "تنبيه دخول وقت الصلاة"
            // No sound set: the channel must never own the adhan audio.
        }
        manager.createNotificationChannel(channel)
    }

    fun prayerTimeNotification(context: Context, event: PrayerEventData): Notification {
        ensureChannel(context)
        val prayerName = PrayerNames.arabic(event.prayerKey)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        return builder
            .setContentTitle("حان الآن وقت صلاة $prayerName")
            .setSmallIcon(context.applicationInfo.icon)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setContentIntent(buildContentIntent(context, event))
            .build()
    }

    /** Body tap → app home (launch intent). */
    private fun buildContentIntent(context: Context, event: PrayerEventData): PendingIntent {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent().setClassName(context, "com.example.talia_quran.MainActivity")
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return PendingIntent.getActivity(
            context,
            event.requestCode,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** Posts the notification; failures are logged, never thrown. */
    fun post(context: Context, event: PrayerEventData): Boolean {
        return try {
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(event.requestCode, prayerTimeNotification(context, event))
            Log.d(TAG, "posted notification event=${event.eventId} id=${event.requestCode}")
            true
        } catch (error: Exception) {
            Log.w(TAG, "failed to post prayer notification", error)
            false
        }
    }
}