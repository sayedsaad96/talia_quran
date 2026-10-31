package com.talia.quran.widget

enum class WidgetSize { SMALL, MEDIUM, LARGE }

/**
 * Small keeps the next prayer, medium adds the summary lines, and large adds
 * the wird range, progress and action.
 *
 * The minimums are the Android 12 [android.util.SizeF] cutoffs. On a typical
 * portrait grid `(73n − 16) × (118m − 16)` that is a 2×1 prayer strip, a 4×2
 * summary (about 276×220), and a 4×3 wird card (about 276×338). A launcher
 * that has not reported a size stays on the summary.
 */
object WidgetLayoutPolicy {
    const val SMALL_MIN_WIDTH = 110
    // Leave room for padding and a single line at moderately enlarged font sizes.
    const val SMALL_MIN_HEIGHT = 72
    const val MEDIUM_MIN_WIDTH = 203
    const val MEDIUM_MIN_HEIGHT = 110
    const val LARGE_MIN_WIDTH = 250
    const val LARGE_MIN_HEIGHT = 280

    fun span(
        minWidth: Int,
        maxWidth: Int,
        minHeight: Int,
        maxHeight: Int,
        portrait: Boolean,
    ): Pair<Int, Int> {
        val width = if (portrait) minWidth else maxWidth
        val height = if (portrait) maxHeight else minHeight
        return width to height
    }

    fun sizeFor(widthDp: Int, heightDp: Int): WidgetSize = when {
        widthDp <= 0 || heightDp <= 0 -> WidgetSize.MEDIUM
        widthDp >= LARGE_MIN_WIDTH && heightDp >= LARGE_MIN_HEIGHT -> WidgetSize.LARGE
        widthDp >= MEDIUM_MIN_WIDTH && heightDp >= MEDIUM_MIN_HEIGHT -> WidgetSize.MEDIUM
        else -> WidgetSize.SMALL
    }

    fun apply(rows: WidgetRows, size: WidgetSize): WidgetRows {
        if (rows.stale) return rows
        val sized = when (size) {
            WidgetSize.SMALL -> {
                val prayer = rows.prayerLine
                val review = if (prayer == null) rows.reviewLine else null
                val wird = if (prayer == null && review == null) rows.wirdLine else null
                rows.copy(
                    prayerLine = prayer,
                    reviewLine = review,
                    wirdLine = wird,
                    wirdRange = null,
                    wirdDone = null,
                    wirdTotal = null,
                    showWirdAction = false,
                )
            }
            WidgetSize.MEDIUM -> rows.copy(
                wirdRange = null,
                wirdDone = null,
                wirdTotal = null,
                showWirdAction = false,
            )
            WidgetSize.LARGE -> rows
        }
        val blank = sized.prayerLine == null &&
            sized.reviewLine == null &&
            sized.wirdLine == null
        return sized.copy(empty = blank)
    }
}
