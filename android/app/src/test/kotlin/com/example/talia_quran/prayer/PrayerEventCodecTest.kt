package com.example.talia_quran.prayer

import android.content.Intent
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** JVM unit tests for PrayerEventData parsing/encoding (V2 §37). */
class PrayerEventCodecTest {
    private fun event() = PrayerEventData(
        eventId = "2026-09-21_fajr",
        prayerKey = "fajr",
        scheduledAtUtcMillis = 1_789_938_720_000L, // 2026-09-20T21:12:00Z
        localPrayerTime = "00:12",
        timezoneId = "Africa/Cairo",
        notificationEnabled = true,
        adhanEnabled = true,
        soundProfile = "default",
        payload = mapOf("source" to "test"),
    )

    private fun channelMap(): Map<String, Any?> = mapOf(
        "eventId" to "2026-09-21_fajr",
        "prayerKey" to "fajr",
        "scheduledAtUtc" to "2026-09-20T21:12:00.000Z",
        "localPrayerTime" to "00:12",
        "timezoneId" to "Africa/Cairo",
        "notificationEnabled" to true,
        "adhanEnabled" to true,
        "soundProfile" to "default",
        "payload" to mapOf("source" to "test"),
    )

    @Test
    fun `parses a Dart channel map with all fields`() {
        val event = PrayerEventCodec.fromChannelMap(channelMap())
        assertTrue(event != null)
        assertEquals("2026-09-21_fajr", event!!.eventId)
        assertEquals("fajr", event.prayerKey)
        assertEquals(1_789_938_720_000L, event.scheduledAtUtcMillis)
        assertEquals("Africa/Cairo", event.timezoneId)
        assertTrue(event.notificationEnabled)
        assertTrue(event.adhanEnabled)
        assertEquals(mapOf("source" to "test"), event.payload)
    }

    @Test
    fun `tolerates a timestamp without the Z suffix`() {
        val map = channelMap().toMutableMap()
        map["scheduledAtUtc"] = "2026-09-20T21:12:00"
        val event = PrayerEventCodec.fromChannelMap(map)
        assertEquals(1_789_938_720_000L, event!!.scheduledAtUtcMillis)
    }

    @Test
    fun `applies documented defaults for missing flags`() {
        val map = channelMap().toMutableMap()
        map.remove("notificationEnabled")
        map.remove("adhanEnabled")
        map.remove("soundProfile")
        map.remove("payload")
        val event = PrayerEventCodec.fromChannelMap(map)
        assertTrue(event!!.notificationEnabled)
        assertFalse(event.adhanEnabled)
        assertEquals("default", event.soundProfile)
        assertEquals(emptyMap<String, String>(), event.payload)
    }

    @Test
    fun `returns null for malformed maps`() {
        assertNull(PrayerEventCodec.fromChannelMap(null))
        assertNull(PrayerEventCodec.fromChannelMap(mapOf<String, Any?>()))
        assertNull(
            PrayerEventCodec.fromChannelMap(
                mapOf<String, Any?>("eventId" to "x", "prayerKey" to "fajr"),
            ),
        )
    }

    @Test
    fun `encode-decode round-trips every field`() {
        val decoded = PrayerEventCodec.decode(PrayerEventCodec.encode(event()))
        assertEquals(event(), decoded)
    }

    @Test
    fun `encode-decode round-trips arabic and special characters`() {
        val event = event().copy(
            localPrayerTime = "05:03",
            payload = mapOf("مفتاح" to "قيمة|مع فاصل"),
        )
        val decoded = PrayerEventCodec.decode(PrayerEventCodec.encode(event))
        assertEquals(event, decoded)
    }

    @Test
    fun `extras map round-trip`() {
        val extras = PrayerEventCodec.toExtrasMap(event())
        val restored = PrayerEventCodec.fromExtrasMap(extras)
        assertTrue(restored != null)
        assertEquals(event().copy(payload = emptyMap()), restored)
    }

    @Test
    fun `extras map rejects missing timestamp`() {
        val extras = PrayerEventCodec.toExtrasMap(event())
            .toMutableMap()
            .apply { remove(PrayerAlarmContract.KEY_SCHEDULED_AT_UTC) }
        assertNull(PrayerEventCodec.fromExtrasMap(extras))
    }

    @Test
    fun `requestCode matches Dart formula`() {
        val event = event()
        assertEquals(
            PrayerAlarmIdentity.requestCodeForEvent(event),
            event.requestCode,
        )
    }
}