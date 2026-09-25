package com.example.talia_quran.prayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

/**
 * JVM unit tests for the deterministic prayer alarm identity.
 * Mirrors test/core/prayer_delivery/prayer_scheduled_event_test.dart.
 */
class PrayerAlarmIdentityTest {
    @Test
    fun `request codes stay inside the frozen 2200-2499 V2 namespace`() {
        val base = LocalDate.of(2026, 9, 20)
        for (day in 0 until 90) {
            for (key in PrayerAlarmIdentity.PRAYER_ORDER) {
                val code = PrayerAlarmIdentity.requestCodeFor(base.plusDays(day.toLong()), key)
                assertTrue("day=$day key=$key code=$code", code in 2200..2499)
            }
        }
    }

    @Test
    fun `never collides with legacy FLN or companion namespaces`() {
        val code = PrayerAlarmIdentity.requestCodeFor(LocalDate.of(2026, 9, 20), "isha")
        assertTrue(code !in 2000..2039)
        assertTrue(code !in 2100..2134)
        assertTrue(code >= 2200)
    }

    @Test
    fun `is deterministic for the same occurrence`() {
        val a = PrayerAlarmIdentity.requestCodeFor(LocalDate.of(2026, 9, 21), "maghrib")
        val b = PrayerAlarmIdentity.requestCodeFor(LocalDate.of(2026, 9, 21), "maghrib")
        assertEquals(a, b)
    }

    @Test
    fun `distinct prayers on the same day get distinct codes`() {
        val day = LocalDate.of(2026, 9, 21)
        val codes = PrayerAlarmIdentity.PRAYER_ORDER
            .map { PrayerAlarmIdentity.requestCodeFor(day, it) }
            .toSet()
        assertEquals(PrayerAlarmIdentity.PRAYER_ORDER.size, codes.size)
    }

    @Test
    fun `unknown prayer key still produces a valid in-range code`() {
        val code = PrayerAlarmIdentity.requestCodeFor(LocalDate.of(2026, 9, 21), "taraweeh")
        assertTrue(code in 2200..2499)
    }

    @Test
    fun `matches the Dart identity for a known occurrence`() {
        // 2026-09-21 is UTC epoch day 20717; Dart PrayerAlarmIdentity.
        // requestCodeFor(DateTime.utc(2026, 9, 21), 'fajr') == 2200 + (20717 % 60) * 5.
        val expected = 2200 + (20717 % 60) * 5
        assertEquals(expected, PrayerAlarmIdentity.requestCodeFor(LocalDate.of(2026, 9, 21), "fajr"))
    }
}