package com.talia.quran.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.After
import org.junit.Before
import org.junit.Test
import java.util.TimeZone

class WidgetSnapshotFormatterTest {
    private val nowMillis = 0L
    private val labels = WidgetSnapshotLabels(
        prayerNames = mapOf("fajr" to "Fajr", "dhuhr" to "Dhuhr", "asr" to "Asr", "maghrib" to "Maghrib", "isha" to "Isha"),
        reviewLine = { count -> "$count reviews due" },
        wirdLine = { name, done, total -> "$name · $done/$total pages" },
    )
    private val arabicLabels = WidgetSnapshotLabels(
        prayerNames = mapOf("fajr" to "الفجر"),
        reviewLine = { count -> "$count مراجعات مستحقة" },
        wirdLine = { name, done, total -> "$name · $done/$total" },
    )
    private lateinit var originalTimeZone: TimeZone

    @Before
    fun useUtc() {
        originalTimeZone = TimeZone.getDefault()
        TimeZone.setDefault(TimeZone.getTimeZone("UTC"))
    }

    @After
    fun restoreTimeZone() {
        TimeZone.setDefault(originalTimeZone)
    }

    @Test
    fun `null corrupt and unknown schema snapshots are empty`() {
        assertTrue(WidgetSnapshotFormatter.format(null, labels, false, nowMillis).empty)
        assertTrue(WidgetSnapshotFormatter.format("{", labels, false, nowMillis).empty)
        assertTrue(
            WidgetSnapshotFormatter
                .format("""{"schemaVersion":2}""", labels, false, nowMillis)
                .empty,
        )
    }

    @Test
    fun `arabic prayer line uses a canonical name and Arabic Indic time`() {
        val rows = WidgetSnapshotFormatter.format(
            """{
              "schemaVersion":1,
              "isEmpty":false,
              "nextPrayerKey":"fajr",
              "nextPrayerAt":18180000
            }""".trimIndent(),
            arabicLabels,
            true,
            nowMillis,
        )

        assertEquals("الفجر · ٠٥:٠٣", rows.prayerLine)
        assertFalse(rows.empty)
    }

    @Test
    fun `zero due reviews are hidden`() {
        val rows = WidgetSnapshotFormatter.format(
            """{"schemaVersion":1,"isEmpty":false,"dueReviewCount":0}""",
            labels,
            false,
            nowMillis,
        )

        assertNull(rows.reviewLine)
    }

    @Test
    fun `malformed fields invalid bounds and expired prayer do not render`() {
        val rows = WidgetSnapshotFormatter.format(
            """{
              "schemaVersion":1,
              "isEmpty":false,
              "nextPrayerKey":"sunrise",
              "nextPrayerAt":-1,
              "dueReviewCount":"4",
              "wirdFromPage":0,
              "wirdToPage":605,
              "wirdDonePages":9,
              "wirdSurahName":42
            }""".trimIndent(),
            labels,
            false,
            nowMillis,
        )

        assertTrue(rows.empty)
        assertNull(rows.prayerLine)
        assertNull(rows.reviewLine)
        assertNull(rows.wirdLine)
    }

    @Test
    fun `fractional and overflowing numeric values are rejected`() {
        val fractionalSchema = WidgetSnapshotFormatter.format(
            """{"schemaVersion":1.5,"dueReviewCount":2}""",
            labels,
            false,
            nowMillis,
        )
        val invalidCounts = WidgetSnapshotFormatter.format(
            """{"schemaVersion":1,"dueReviewCount":4294967297,"wirdFromPage":2.5}""",
            labels,
            false,
            nowMillis,
        )
        val fractionalTimestamp = WidgetSnapshotFormatter.format(
            """{"schemaVersion":1,"nextPrayerKey":"fajr","nextPrayerAt":18180000.5}""",
            labels,
            false,
            nowMillis,
        )

        assertTrue(fractionalSchema.empty)
        assertNull(invalidCounts.reviewLine)
        assertNull(invalidCounts.wirdLine)
        assertNull(fractionalTimestamp.prayerLine)
    }

    @Test
    fun `valid rows retain only safe snapshot display values`() {
        val rows = WidgetSnapshotFormatter.format(
            """{
              "schemaVersion":1,
              "isEmpty":false,
              "nextPrayerKey":"dhuhr",
              "nextPrayerAt":28800000,
              "dueReviewCount":2,
              "wirdFromPage":10,
              "wirdToPage":12,
              "wirdDonePages":9,
              "wirdSurahName":"الفاتحة"
            }""".trimIndent(),
            labels,
            false,
            nowMillis,
        )

        assertEquals("Dhuhr · 08:00", rows.prayerLine)
        assertTrue(rows.reviewLine!!.contains("2"))
        assertTrue(rows.wirdLine!!.contains("الفاتحة"))
        assertTrue(rows.wirdLine!!.contains("3/3"))
        assertFalse(rows.empty)
    }

    @Test
    fun `prayer time uses the configured city offset instead of device time`() {
        val rows = WidgetSnapshotFormatter.format(
            """{
              "schemaVersion":1,
              "isEmpty":false,
              "nextPrayerKey":"fajr",
              "nextPrayerAt":21600000,
              "nextPrayerOffsetMinutes":120
            }""".trimIndent(),
            labels,
            false,
            nowMillis,
        )

        assertEquals("Fajr · 08:00", rows.prayerLine)
    }

    @Test
    fun `expired snapshot hides every row`() {
        val rows = WidgetSnapshotFormatter.format(
            """{
              "schemaVersion":1,
              "isEmpty":false,
              "expiresAt":0,
              "nextPrayerKey":"fajr",
              "nextPrayerAt":18180000,
              "dueReviewCount":2,
              "wirdFromPage":10,
              "wirdToPage":12,
              "wirdDonePages":1,
              "wirdSurahName":"الفاتحة"
            }""".trimIndent(),
            labels,
            false,
            nowMillis,
        )

        assertTrue(rows.empty)
        assertNull(rows.prayerLine)
        assertNull(rows.reviewLine)
        assertNull(rows.wirdLine)
    }

    @Test
    fun `formatter renders only labels supplied by its native caller`() {
        val customLabels = WidgetSnapshotLabels(
            prayerNames = mapOf("fajr" to "Morning prayer"),
            reviewLine = { count -> "Review $count" },
            wirdLine = { name, done, total -> "$name [$done/$total]" },
        )

        val rows = WidgetSnapshotFormatter.format(
            """{"schemaVersion":1,"nextPrayerKey":"fajr","nextPrayerAt":18180000}""",
            customLabels,
            false,
            nowMillis,
        )

        assertEquals("Morning prayer · 05:03", rows.prayerLine)
    }
}
