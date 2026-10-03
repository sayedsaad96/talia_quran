package com.example.talia_quran.prayer

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileOutputStream

/**
 * Bridges "preview this muezzin clip" from the Flutter settings UI to the
 * platform players. Preview is a foreground UI action, so it never touches
 * the prayer delivery pipeline: no alarms, no notifications, no reschedule.
 *
 * - Android: copies the bundled raw clip into a cache file and returns a
 *   `content://` URI (FileProvider) for just_audio's lockCaching/audio
 *   source. Raw resource URIs are not reliably supported by ExoPlayer, the
 *   cache copy is cheap (clips are ~1 MB) and always works.
 * - iOS: returns the bundle file name (`<clip>.caf`) resolved from the
 *   main bundle by the Dart side via rootBundle.
 */
object AdhanPreviewBridge {
    private const val AUTHORITY = "com.example.talia_quran.fileprovider"
    private const val CACHE_DIR = "adhan_preview"

    /** Returns a playable URI/source for the given resolved clip name. */
    fun previewSource(context: Context, clip: String): String {
        val resId = context.resources.getIdentifier(clip, "raw", context.packageName)
        if (resId == 0) return ""
        return try {
            val dir = File(context.cacheDir, CACHE_DIR).apply { mkdirs() }
            val outFile = File(dir, "$clip.mp3")
            if (!outFile.exists() || outFile.length() == 0L) {
                context.resources.openRawResource(resId).use { input ->
                    FileOutputStream(outFile).use { output -> input.copyTo(output) }
                }
            }
            FileProvider.getUriForFile(context, AUTHORITY, outFile).toString()
        } catch (_: Exception) {
            // Fallback: bundled-resource URI (works on most devices).
            Uri.parse("android.resource://${context.packageName}/raw/$clip").toString()
        }
    }

    /** Deletes the preview cache (called on channel setup / cleanup). */
    fun clearCache(context: Context) {
        runCatching { File(context.cacheDir, CACHE_DIR).deleteRecursively() }
    }
}
