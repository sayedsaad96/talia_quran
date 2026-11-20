package com.talia.quran.prayer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.os.Build
import android.test.AndroidTestCase

/** Requires notification permission on Android 13+ and an emulator or device. */
@Suppress("DEPRECATION")
class PrayerNotificationInstrumentationTest : AndroidTestCase() {
    private val manager get() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val event = PrayerEventData("test-prayer", "fajr", 1700000000000L, "05:00", "UTC", true, true, "default", emptyMap())

    override fun tearDown() {
        context.stopService(Intent(context, AdhanPlaybackService::class.java))
        manager.cancel(2500)
        manager.cancel(2200)
        manager.cancel(2201)
        super.tearDown()
    }

    fun testReceiverKeepsFallbackAndCleansOnlyHistoricalPrayerAlerts() {
        PrayerNotificationFactory.ensureChannel(context)
        val otherChannel = "prayer_test_other"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(otherChannel, "Test", NotificationManager.IMPORTANCE_LOW))
        }
        val other = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(context, otherChannel) else Notification.Builder(context)
        manager.notify(2200, PrayerNotificationFactory.prayerTimeNotification(context, event))
        manager.notify(2201, other.setSmallIcon(com.talia.quran.prayer.R.drawable.ic_notification).build())
        waitFor { manager.activeNotifications.any { it.id == 2200 } && manager.activeNotifications.any { it.id == 2201 } }
        val denied = object : ContextWrapper(context) {
            override fun startForegroundService(service: Intent): ComponentName? = throw SecurityException("test denial")
            override fun startService(service: Intent): ComponentName? = throw SecurityException("test denial")
        }
        val alarm = Intent().also { PrayerEventCodec.toIntentExtras(it, event) }
        PrayerAlarmReceiver().onReceive(denied, alarm)
        waitFor { active() != null && manager.activeNotifications.none { it.id == 2200 } }
        val active = manager.activeNotifications.associateBy { it.id }
        assertNotNull(active[2500])
        assertNull(active[2200])
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) assertNotNull(active[2201])
        assertEquals(event.eventId, active[2500]!!.notification.extras.getString(PrayerAlarmContract.KEY_EVENT_ID))
    }

    fun testForegroundPromotionAndStopLeaveOneDismissibleAlert() {
        PrayerNotificationFactory.post(context, event)
        val start = Intent(context, AdhanPlaybackService::class.java).setAction(AdhanPlaybackService.ACTION_START)
        PrayerEventCodec.toIntentExtras(start, event)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) context.startForegroundService(start) else context.startService(start)
        waitFor { active()?.notification?.actions?.isNotEmpty() == true }
        assertEquals(1, nativeDisplayCount())
        context.startService(Intent(context, AdhanPlaybackService::class.java).setAction(AdhanPlaybackService.ACTION_STOP))
        waitFor { active()?.notification?.let { it.actions.isNullOrEmpty() } == true }
        assertNotNull(active())
        assertEquals(0, active()!!.notification.flags and Notification.FLAG_ONGOING_EVENT)
    }

    fun testOlderPlaybackCannotRestoreOverNewerPrayer() {
        val newer = event.copy(eventId = "newer-prayer", prayerKey = "dhuhr")
        PrayerNotificationFactory.post(context, newer)
        waitFor { active()?.notification?.extras?.getString(PrayerAlarmContract.KEY_EVENT_ID) == newer.eventId }
        PrayerNotificationFactory.restoreIfOwned(context, event)
        Thread.sleep(500) // Allow an erroneously enqueued update to reach NotificationManager.
        assertEquals(newer.eventId, active()!!.notification.extras.getString(PrayerAlarmContract.KEY_EVENT_ID))
    }

    fun testDifferentPrayerEventsUseOneDisplaySlot() {
        PrayerNotificationFactory.post(context, event)
        waitFor { active()?.notification?.extras?.getString(PrayerAlarmContract.KEY_EVENT_ID) == event.eventId }
        val newer = event.copy(eventId = "another-prayer", prayerKey = "dhuhr")
        PrayerNotificationFactory.post(context, newer)
        waitFor { active()?.notification?.extras?.getString(PrayerAlarmContract.KEY_EVENT_ID) == newer.eventId }
        assertEquals(1, nativeDisplayCount())
    }

    private fun active() = manager.activeNotifications.firstOrNull { it.id == 2500 }
    private fun nativeDisplayCount() = manager.activeNotifications.count {
        it.id == 2500 || (it.id in 2200..2499 &&
            (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || it.notification.channelId == PrayerNotificationFactory.CHANNEL_ID))
    }
    private fun waitFor(condition: () -> Boolean) {
        val until = System.currentTimeMillis() + 10000
        while (!condition() && System.currentTimeMillis() < until) Thread.sleep(50)
        assertTrue("Notification state did not arrive", condition())
    }
}
