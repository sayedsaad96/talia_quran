package com.example.talia_quran.prayer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Recovery receiver (V2 §30 + Gate H): re-arms the stored native prayer
 * alarms after events that invalidate or clear them:
 *
 *   - BOOT_COMPLETED / MY_PACKAGE_REPLACED / quick-boot: AlarmManager
 *     alarms are cleared on reboot; the persisted events restore them.
 *   - TIME_SET (device time change) / TIMEZONE_CHANGED: stored
 *     absolute-time events are re-anchored to the (possibly corrected)
 *     wall clock and stale occurrences dropped, so recovery never waits
 *     for the next 6-hour Workmanager refresh.
 *
 * Deliberately native-only: no Flutter engine start, no prayer-time
 * computation — the persisted events created by the Dart side are simply
 * re-armed. The next Dart refresh performs the full 7-day rebuild.
 */
class PrayerRecoveryReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action !in SUPPORTED_ACTIONS) return
        val rearmed = PrayerAlarmScheduler.rearmFromStore(context.applicationContext)
        Log.d(TAG, "recovery after $action: rearmed=$rearmed native prayer alarms")
    }

    companion object {
        private const val TAG = "PrayerV2"
        val SUPPORTED_ACTIONS = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED, // "android.intent.action.TIME_SET"
            "android.intent.action.TIMEZONE_CHANGED",
            "com.htc.intent.action.QUICKBOOT_POWERON",
        )
    }
}