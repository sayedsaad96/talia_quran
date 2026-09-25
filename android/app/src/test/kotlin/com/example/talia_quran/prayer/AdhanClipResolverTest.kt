package com.example.talia_quran.prayer

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Unit tests for the muezzin sound-profile → raw-clip mapping.
 *
 * Golden rule: an unknown/missing profile MUST degrade to the bundled
 * default clip — a bad preference value can never break adhan delivery.
 */
class AdhanClipResolverTest {

    @Test
    fun `null and empty profiles resolve to the default clip`() {
        assertEquals("adhan", AdhanClipResolver.rawResourceName(null, "fajr"))
        assertEquals("adhan", AdhanClipResolver.rawResourceName("", "dhuhr"))
        assertEquals("adhan", AdhanClipResolver.rawResourceName("  ", "asr"))
        assertEquals("adhan", AdhanClipResolver.rawResourceName("default", "maghrib"))
    }

    @Test
    fun `every bundled muezzin maps to its raw clip`() {
        assertEquals("adhan_makkah", AdhanClipResolver.rawResourceName("makkah", "dhuhr"))
        assertEquals("adhan_abdulbasit", AdhanClipResolver.rawResourceName("abdulbasit", "isha"))
        assertEquals("adhan_qatami", AdhanClipResolver.rawResourceName("qatami", "asr"))
        assertEquals("adhan_suraihi", AdhanClipResolver.rawResourceName("suraihi", "maghrib"))
    }

    @Test
    fun `unknown profile falls back to the default clip`() {
        assertEquals("adhan", AdhanClipResolver.rawResourceName("not_a_muezzin", "dhuhr"))
        assertEquals("adhan", AdhanClipResolver.rawResourceName("adhan_makkah", "dhuhr"))
        assertEquals("adhan", AdhanClipResolver.rawResourceName("../etc/passwd", "isha"))
    }

    @Test
    fun `fajr override applies only to fajr`() {
        assertEquals(
            "adhan_afasy_fajr",
            AdhanClipResolver.rawResourceName("fajr:afasy_fajr", "fajr"),
        )
        // Same override on non-fajr prayers keeps the default clip.
        assertEquals("adhan", AdhanClipResolver.rawResourceName("fajr:afasy_fajr", "dhuhr"))
        assertEquals("adhan", AdhanClipResolver.rawResourceName("fajr:afasy_fajr", "isha"))
    }

    @Test
    fun `fajr override supports regular muezzins too`() {
        assertEquals(
            "adhan_makkah",
            AdhanClipResolver.rawResourceName("fajr:makkah", "fajr"),
        )
    }

    @Test
    fun `malformed fajr override degrades to the default clip`() {
        assertEquals("adhan", AdhanClipResolver.rawResourceName("fajr:", "fajr"))
        assertEquals("adhan", AdhanClipResolver.rawResourceName("fajr:default", "fajr"))
        assertEquals("adhan", AdhanClipResolver.rawResourceName("fajr:unknown", "fajr"))
    }

    @Test
    fun `fajr-optimized profile is directly selectable as general`() {
        // Choosing the Afasy fajr recording as the general muezzin is legal:
        // it then plays for every prayer.
        assertEquals(
            "adhan_afasy_fajr",
            AdhanClipResolver.rawResourceName("afasy_fajr", "dhuhr"),
        )
    }
}
