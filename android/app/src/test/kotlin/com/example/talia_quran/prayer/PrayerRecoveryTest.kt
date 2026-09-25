package com.example.talia_quran.prayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** JVM unit tests for the Stage 8 recovery plan (§30 / Gate H). */
class PrayerRecoveryTest {
    private fun event(millis: Long, id: String) = PrayerEventData(
        eventId = id,
        prayerKey = "fajr",
        scheduledAtUtcMillis = millis,
        localPrayerTime = "00:12",
        timezoneId = "Africa/Cairo",
        notificationEnabled = true,
        adhanEnabled = false,
        soundProfile = "default",
        payload = emptyMap(),
    )

    @Test
    fun `rearm plan keeps only future events sorted by trigger time`() {
        val now = 1_000_000L
        val encoded = listOf(
            PrayerEventCodec.encode(event(now + 3_000, "e_later")),
            PrayerEventCodec.encode(event(now + 1_000, "e_soon")),
            PrayerEventCodec.encode(event(now - 1_000, "e_past")),
        )

        val plan = PrayerAlarmScheduler.rearmPlan(encoded, now)

        assertEquals(listOf("e_soon", "e_later"), plan.map { it.eventId })
    }

    @Test
    fun `rearm plan drops occurrences exactly at now (stale)`() {
        val now = 1_000_000L
        val plan = PrayerAlarmScheduler.rearmPlan(
            listOf(PrayerEventCodec.encode(event(now, "e_now"))),
            now,
        )

        assertTrue(plan.isEmpty())
    }

    @Test
    fun `rearm plan skips malformed store entries without throwing`() {
        val now = 1_000_000L
        val plan = PrayerAlarmScheduler.rearmPlan(
            listOf("garbage", "", PrayerEventCodec.encode(event(now + 5_000, "e_ok"))),
            now,
        )

        assertEquals(listOf("e_ok"), plan.map { it.eventId })
    }

    @Test
    fun `rearm plan is empty for an empty store`() {
        assertTrue(PrayerAlarmScheduler.rearmPlan(emptyList(), 0L).isEmpty())
    }
}