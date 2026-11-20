package com.talia.quran.prayer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import com.talia.quran.prayer.R

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
    const val NOTIFICATION_ID = 2500
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

    fun prayerTimeNotification(context: Context, event: PrayerEventData, silent: Boolean = false): Notification {
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
            .setSmallIcon(R.drawable.ic_notification)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setOnlyAlertOnce(silent)
            .addExtras(Bundle().apply { putString(PrayerAlarmContract.KEY_EVENT_ID, event.eventId) })
            .setContentIntent(buildContentIntent(context, event))
            .build()
    }

    /** Body tap → app home (launch intent). */
    private fun buildContentIntent(context: Context, event: PrayerEventData): PendingIntent {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent().setClassName(context, "com.talia.quran.MainActivity")
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
            clearHistoricalAlerts(manager)
            val active = activePrayer(manager)
            // A repeated alarm must not replace live playback controls.
            if (active != null && active.extras.getString(PrayerAlarmContract.KEY_EVENT_ID) == event.eventId &&
                !active.actions.isNullOrEmpty()) return true
            manager.notify(NOTIFICATION_ID, prayerTimeNotification(context, event))
            Log.d(TAG, "posted notification event=${event.eventId} id=$NOTIFICATION_ID")
            true
        } catch (error: Exception) {
            Log.w(TAG, "failed to post prayer notification", error)
            false
        }
    }

    private fun clearHistoricalAlerts(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        for (entry in manager.activeNotifications) {
            if (entry.tag != null || entry.id !in PrayerAlarmIdentity.RANGE_START..PrayerAlarmIdentity.RANGE_END) continue
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && entry.notification.channelId != CHANNEL_ID) continue
            manager.cancel(entry.id)
        }
    }

    private fun activePrayer(manager: NotificationManager): Notification? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return null
        return manager.activeNotifications.firstOrNull { it.tag == null && it.id == NOTIFICATION_ID }?.notification
    }

    fun restoreIfOwned(context: Context, event: PrayerEventData) {
        try {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            // Before API 23 there is no active-notification ownership query.
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                activePrayer(manager)?.extras?.getString(PrayerAlarmContract.KEY_EVENT_ID) == event.eventId) {
                manager.notify(NOTIFICATION_ID, prayerTimeNotification(context, event, silent = true))
            }
        } catch (error: Exception) {
            Log.w(TAG, "failed to restore prayer notification", error)
        }
    }
}
