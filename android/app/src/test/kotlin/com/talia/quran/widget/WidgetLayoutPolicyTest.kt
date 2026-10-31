package com.talia.quran.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetLayoutPolicyTest {
    private val full = WidgetRows(
        prayerLine = "Fajr",
        reviewLine = "2 reviews due",
        wirdLine = "الفاتحة · 1/3 pages",
        empty = false,
        wirdRange = "10–12",
        wirdDone = 1,
        wirdTotal = 3,
        showWirdAction = true,
    )

    @Test
    fun `size follows the responsive cutoffs and an unknown size stays a summary`() {
        assertEquals(WidgetSize.MEDIUM, WidgetLayoutPolicy.sizeFor(0, 0))
        // 2×1 portrait is about 130×102: prayer only.
        assertEquals(WidgetSize.SMALL, WidgetLayoutPolicy.sizeFor(130, 102))
        // Narrow and tall still has no room for the summary.
        assertEquals(WidgetSize.SMALL, WidgetLayoutPolicy.sizeFor(130, 220))
        // 4×2 portrait is about 276×220: the summary.
        assertEquals(WidgetSize.MEDIUM, WidgetLayoutPolicy.sizeFor(276, 220))
        assertEquals(WidgetSize.MEDIUM, WidgetLayoutPolicy.sizeFor(250, 110))
        // 4×3 portrait is about 276×338: the wird detail.
        assertEquals(WidgetSize.LARGE, WidgetLayoutPolicy.sizeFor(276, 338))
    }

    @Test
    fun `portrait uses the minimum width and the maximum height`() {
        assertEquals(110 to 220, WidgetLayoutPolicy.span(110, 280, 80, 220, true))
        assertEquals(280 to 80, WidgetLayoutPolicy.span(110, 280, 80, 220, false))
    }

    @Test
    fun `small keeps prayer medium keeps the summary and large keeps the wird detail`() {
        val small = WidgetLayoutPolicy.apply(full, WidgetSize.SMALL)
        val medium = WidgetLayoutPolicy.apply(full, WidgetSize.MEDIUM)
        val large = WidgetLayoutPolicy.apply(full, WidgetSize.LARGE)

        assertEquals("Fajr", small.prayerLine)
        assertNull(small.reviewLine)
        assertNull(small.wirdLine)
        assertNull(small.wirdRange)
        assertFalse(small.showWirdAction)

        assertEquals("2 reviews due", medium.reviewLine)
        assertEquals("الفاتحة · 1/3 pages", medium.wirdLine)
        assertNull(medium.wirdRange)
        assertFalse(medium.showWirdAction)

        assertEquals("10–12", large.wirdRange)
        assertTrue(large.showWirdAction)
        assertEquals(1, large.wirdDone)
    }

    @Test
    fun `a small widget without prayer promotes the next visible section`() {
        val reviewsOnly = full.copy(prayerLine = null)
        val shown = WidgetLayoutPolicy.apply(reviewsOnly, WidgetSize.SMALL)

        assertNull(shown.prayerLine)
        assertEquals("2 reviews due", shown.reviewLine)
        assertNull(shown.wirdLine)
    }
}
