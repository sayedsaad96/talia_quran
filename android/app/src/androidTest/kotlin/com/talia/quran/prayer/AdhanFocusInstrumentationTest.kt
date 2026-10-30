package com.talia.quran.prayer

import android.media.AudioManager
import android.media.MediaPlayer
import android.test.AndroidTestCase

/** Exercises the service's real focus callback against a playing bundled clip. */
@Suppress("DEPRECATION")
class AdhanFocusInstrumentationTest : AndroidTestCase() {
    fun testFocusChangesDoNotStopOrPausePlayback() {
        val service = AdhanPlaybackService()
        val clip = context.resources.getIdentifier("adhan", "raw", context.packageName)
        assertTrue("Bundled adhan is missing", clip != 0)
        val player = MediaPlayer.create(context, clip)
        assertNotNull("Could not prepare bundled adhan", player)
        val activePlayer = requireNotNull(player)
        val playerField = AdhanPlaybackService::class.java.getDeclaredField("player")
        val listenerField = AdhanPlaybackService::class.java.getDeclaredField("focusListener")
        playerField.isAccessible = true
        listenerField.isAccessible = true
        playerField.set(service, activePlayer)
        val listener = listenerField.get(service) as AudioManager.OnAudioFocusChangeListener

        try {
            activePlayer.start()
            for (change in listOf(
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK,
                AudioManager.AUDIOFOCUS_GAIN,
                AudioManager.AUDIOFOCUS_LOSS,
            )) {
                listener.onAudioFocusChange(change)
                assertTrue("Playback stopped or paused after focus change $change", activePlayer.isPlaying)
            }
        } finally {
            activePlayer.release()
        }
    }
}
