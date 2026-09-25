package com.example.talia_quran.prayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** JVM unit tests for the Stage 6 adhan playback policy pieces. */
class AdhanPlaybackPolicyTest {
    @Test
    fun `default profile resolves to the bundled adhan clip`() {
        assertEquals("adhan", AdhanClipResolver.rawResourceName("default", "maghrib"))
    }

    @Test
    fun `fajr resolves to the default clip until a licensed fajr asset exists`() {
        assertEquals(
            AdhanClipResolver.rawResourceName("default", "fajr"),
            AdhanClipResolver.rawResourceName("default", "maghrib"),
        )
    }

    @Test
    fun `unknown or null profiles fall back to the bundled clip`() {
        assertEquals("adhan", AdhanClipResolver.rawResourceName("muezzin_x", "isha"))
        assertEquals("adhan", AdhanClipResolver.rawResourceName(null, "isha"))
    }

    @Test
    fun `stop action is recognized`() {
        assertTrue(AdhanPlaybackService.isStopAction(AdhanPlaybackService.ACTION_STOP))
        assertFalse(AdhanPlaybackService.isStopAction(AdhanPlaybackService.ACTION_START))
        assertFalse(AdhanPlaybackService.isStopAction(null))
        assertFalse(AdhanPlaybackService.isStopAction("something.else"))
    }

    @Test
    fun `start and stop actions are distinct`() {
        assertNotEquals(
            AdhanPlaybackService.ACTION_START,
            AdhanPlaybackService.ACTION_STOP,
        )
    }

    @Test
    fun `media notification id stays outside every frozen alarm namespace`() {
        val id = AdhanPlaybackService.MEDIA_NOTIFICATION_ID
        assertTrue(id !in 2000..2039)
        assertTrue(id !in 2100..2134)
        assertTrue(id !in 2200..2499)
    }
}