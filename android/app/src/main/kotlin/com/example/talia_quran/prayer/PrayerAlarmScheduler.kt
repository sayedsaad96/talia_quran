package com.example.talia_quran.prayer

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/** Outcome of a scheduling round-trip, mirrored back to Dart. */
data class PrayerScheduleOutcome(
    val success: Boolean,
    val scheduledCount: Int,
    val exactAllowed: Boolean,
    val error: String? = null,
)

/**
 * Owns the native prayer alarms (V2 §11). Responsibilities ONLY:
 *
 *   PrayerEventData → PendingIntent → AlarmManager
 *
 * Exact when permitted (setExactAndAllowWhileIdle), inexact fallback
 * (setAndAllowWhileIdle) otherwise — a denied exact permission must never
 * break prayer delivery. Cancel-first: [scheduleEvents] always cancels all
 * previously tracked alarms first, so an occurrence can never hold a stale
 * AND a fresh alarm at the same time (golden rule).
 */
object PrayerAlarmScheduler {
    private const val TAG = "PrayerV2"
    private const val STORE_PREFS = "talia_prayer_v2_alarms"
    private const val STORE_KEY_EVENTS = "scheduled_events"

    fun scheduleEvents(context: Context, events: List<PrayerEventData>): PrayerScheduleOutcome {
        return try {
            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                    ?: return PrayerScheduleOutcome(false, 0, false, "alarm manager unavailable")
            val exactAllowed = canScheduleExact(alarmManager)
            cancelAll(context, alarmManager)
            val stored = HashSet<String>()
            for (event in events) {
                armAlarm(alarmManager, context, event, exactAllowed)
                stored.add(PrayerEventCodec.encode(event))
                Log.d(TAG, "scheduled event=${event.eventId} code=${event.requestCode} exact=$exactAllowed")
            }
            persist(context, stored)
            PrayerScheduleOutcome(true, events.size, exactAllowed)
        } catch (error: Exception) {
            Log.w(TAG, "scheduleEvents failed", error)
            PrayerScheduleOutcome(false, 0, false, error.message ?: "scheduling failed")
        }
    }

    /** Whether exact alarms are currently permitted for this app. */
    fun canScheduleExact(context: Context): Boolean {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return false
        return canScheduleExact(alarmManager)
    }

    private fun canScheduleExact(alarmManager: AlarmManager): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    private fun buildPendingIntent(context: Context, event: PrayerEventData): PendingIntent {
        val intent = Intent(context, PrayerAlarmReceiver::class.java)
        PrayerEventCodec.toIntentExtras(intent, event)
        return PendingIntent.getBroadcast(
            context,
            event.requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * Pure recovery plan (V2 §30): decode the persisted events and keep only
     * the future ones, ordered by trigger time. JVM-testable — no Android
     * types involved.
     */
    fun rearmPlan(
        encodedEvents: Collection<String>,
        nowMillis: Long,
    ): List<PrayerEventData> {
        val plan = ArrayList<PrayerEventData>()
        for (encoded in encodedEvents) {
            val event = PrayerEventCodec.decode(encoded) ?: continue
            // Already-fired or stale occurrences are dropped; the next Dart
            // refresh rebuilds the rolling window.
            if (event.scheduledAtUtcMillis <= nowMillis) continue
            plan.add(event)
        }
        plan.sortBy { it.scheduledAtUtcMillis }
        return plan
    }

    /**
     * Re-arms every stored future event after a reboot, device time change
     * or timezone change. Deliberately native-only: it reads the persisted
     * absolute-time events, re-anchors them to (possibly corrected) wall
     * clock, drops stale occurrences, and never starts the Flutter engine
     * nor computes prayer times.
     *
     * @return the number of alarms re-armed.
     */
    fun rearmFromStore(context: Context): Int {
        return try {
            val alarmManager =
                context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                    ?: return 0
            val now = System.currentTimeMillis()
            val plan = rearmPlan(loadStored(context), now)
            val exactAllowed = canScheduleExact(alarmManager)
            for (event in plan) {
                armAlarm(alarmManager, context, event, exactAllowed)
            }
            persist(context, HashSet(plan.map { PrayerEventCodec.encode(it) }))
            Log.d(TAG, "rearmed ${plan.size} native prayer alarms")
            plan.size
        } catch (error: Exception) {
            Log.w(TAG, "rearm failed", error)
            0
        }
    }

    private fun armAlarm(
        alarmManager: AlarmManager,
        context: Context,
        event: PrayerEventData,
        exactAllowed: Boolean,
    ) {
        val pendingIntent = buildPendingIntent(context, event)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (exactAllowed) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    event.scheduledAtUtcMillis,
                    pendingIntent,
                )
            } else {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    event.scheduledAtUtcMillis,
                    pendingIntent,
                )
            }
        } else {
            @Suppress("DEPRECATION")
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                event.scheduledAtUtcMillis,
                pendingIntent,
            )
        }
    }

    /** Cancels every tracked native prayer alarm. */
    fun cancelAll(context: Context) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        cancelAll(context, alarmManager)
    }

    /** Cancels a single occurrence and removes it from the tracked store. */
    fun cancelEvent(context: Context, event: PrayerEventData) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        cancelAlarm(context, alarmManager, event)
        val remaining = loadStored(context).filterNot { encoded ->
            PrayerEventCodec.decode(encoded)?.eventId == event.eventId
        }
        persist(context, HashSet(remaining))
    }

    private fun cancelAll(context: Context, alarmManager: AlarmManager) {
        for (encoded in loadStored(context)) {
            val event = PrayerEventCodec.decode(encoded) ?: continue
            cancelAlarm(context, alarmManager, event)
        }
        persist(context, emptySet())
    }

    private fun cancelAlarm(context: Context, alarmManager: AlarmManager, event: PrayerEventData) {
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            event.requestCode,
            Intent(context, PrayerAlarmReceiver::class.java),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        pendingIntent?.cancel()
        Log.d(TAG, "cancelled event=${event.eventId} code=${event.requestCode}")
    }

    private fun loadStored(context: Context): Set<String> {
        return try {
            val prefs = context.getSharedPreferences(STORE_PREFS, Context.MODE_PRIVATE)
            HashSet(prefs.getStringSet(STORE_KEY_EVENTS, emptySet()) ?: emptySet())
        } catch (error: Exception) {
            Log.w(TAG, "failed to read scheduled-events store", error)
            emptySet()
        }
    }

    private fun persist(context: Context, events: Set<String>) {
        try {
            val prefs = context.getSharedPreferences(STORE_PREFS, Context.MODE_PRIVATE)
            prefs.edit().putStringSet(STORE_KEY_EVENTS, events).apply()
        } catch (error: Exception) {
            Log.w(TAG, "failed to persist scheduled-events store", error)
        }
    }
}