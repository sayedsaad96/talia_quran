package com.talia.quran.widget

import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.SimpleTimeZone

data class WidgetRows(
    val prayerLine: String?,
    val reviewLine: String?,
    val wirdLine: String?,
    val empty: Boolean,
    // An adult with nothing to show, as opposed to a cleared or expired widget.
    val adultNoData: Boolean = false,
    // The precomputed window has ended. Distinct from a widget that was never filled.
    val stale: Boolean = false,
    val wirdRange: String? = null,
    val wirdDone: Int? = null,
    val wirdTotal: Int? = null,
    val showWirdAction: Boolean = false,
    // `wird` opens the reading position; `khatmah-setup` opens plan setup.
    val wirdDestination: String = "wird",
)

data class WidgetSnapshotLabels(
    val prayerNames: Map<String, String>,
    val reviewLine: (Int) -> String,
    val wirdLine: (String, Int, Int) -> String,
    val reviewsDone: String = "Reviews done",
    val noKhatmahPlan: String = "No khatmah plan",
    val prayerUnset: String = "Set prayer times",
    val wirdRange: (Int, Int) -> String = { from, to -> "$from–$to" },
)

object WidgetSnapshotFormatter {
    private const val schemaVersion = 1
    private const val maxUpcoming = 12
    private val fardPrayerKeys = setOf("fajr", "dhuhr", "asr", "maghrib", "isha")
    // Copied from SurahNames.arabic. The Dart contract test keeps this exact
    // native allow-list aligned with the canonical source of truth.
    private val canonicalSurahNames = setOf(
        "الفاتحة", "البقرة", "آل عمران", "النساء", "المائدة", "الأنعام", "الأعراف", "الأنفال", "التوبة", "يونس",
        "هود", "يوسف", "الرعد", "إبراهيم", "الحجر", "النحل", "الإسراء", "الكهف", "مريم", "طه", "الأنبياء", "الحج",
        "المؤمنون", "النور", "الفرقان", "الشعراء", "النمل", "القصص", "العنكبوت", "الروم", "لقمان", "السجدة", "الأحزاب",
        "سبأ", "فاطر", "يس", "الصافات", "ص", "الزمر", "غافر", "فصلت", "الشورى", "الزخرف", "الدخان", "الجاثية", "الأحقاف",
        "محمد", "الفتح", "الحجرات", "ق", "الذاريات", "الطور", "النجم", "القمر", "الرحمن", "الواقعة", "الحديد", "المجادلة",
        "الحشر", "الممتحنة", "الصف", "الجمعة", "المنافقون", "التغابن", "الطلاق", "التحريم", "الملك", "القلم", "الحاقة",
        "المعارج", "نوح", "الجن", "المزمل", "المدثر", "القيامة", "الإنسان", "المرسلات", "النبأ", "النازعات", "عبس", "التكوير",
        "الانفطار", "المطففين", "الانشقاق", "البروج", "الطارق", "الأعلى", "الغاشية", "الفجر", "البلد", "الشمس", "الليل",
        "الضحى", "الشرح", "التين", "العلق", "القدر", "البينة", "الزلزلة", "العاديات", "القارعة", "التكاثر", "العصر", "الهمزة",
        "الفيل", "قريش", "الماعون", "الكوثر", "الكافرون", "النصر", "المسد", "الإخلاص", "الفلق", "الناس",
    )

    fun format(
        json: String?,
        labels: WidgetSnapshotLabels,
        arabic: Boolean,
        nowMillis: Long,
    ): WidgetRows {
        val objectValue = parse(json) ?: return emptyRows()
        if (integer(objectValue, "schemaVersion") != schemaVersion) return emptyRows()
        if (isExpired(objectValue, nowMillis)) return emptyRows(stale = true)
        val dayEnded = hasDayEnded(objectValue, nowMillis)
        val daySlice = if (dayEnded) objectValue.optJSONObject("nextDay") else objectValue
        if (objectValue.optBoolean("isEmpty", false) && daySlice == null) {
            return if (objectValue.optBoolean("adultNoData", false)) {
                WidgetRows(null, null, null, true, adultNoData = true)
            } else {
                emptyRows()
            }
        }
        val showPrayer = sectionVisible(objectValue, "showPrayer")
        val showReviews = sectionVisible(objectValue, "showReviews")
        val showWird = sectionVisible(objectValue, "showWird")
        val prayer = if (showPrayer) {
            prayerLine(objectValue, labels, arabic, nowMillis)
                ?: if (objectValue.optBoolean("prayerUnset", false)) labels.prayerUnset else null
        } else {
            null
        }
        val review = if (daySlice != null && showReviews) {
            reviewLine(daySlice, objectValue, labels, arabic, nowMillis)
        } else {
            null
        }
        val wird = if (daySlice != null && showWird) {
            wirdPresentation(daySlice, labels, arabic)
        } else {
            null
        }
        val blank = prayer == null && review == null && wird?.line == null
        if (blank && objectValue.optBoolean("isEmpty", false)) {
            return if (objectValue.optBoolean("adultNoData", false)) {
                WidgetRows(null, null, null, true, adultNoData = true)
            } else {
                emptyRows()
            }
        }
        return WidgetRows(
            prayer,
            review,
            wird?.line,
            blank,
            // Hiding every section is a choice, not a missing snapshot.
            adultNoData = blank && !showPrayer && !showReviews && !showWird,
            wirdRange = wird?.range,
            wirdDone = wird?.done,
            wirdTotal = wird?.total,
            showWirdAction = wird?.action == true,
            wirdDestination = wird?.destination ?: "wird",
        )
    }

    private fun parse(json: String?): JSONObject? = try {
        if (json.isNullOrBlank()) null else JSONObject(json)
    } catch (_: Exception) {
        null
    }

    /** App language the snapshot was written for (`ar` or `en`); null means use the device. */
    fun language(json: String?): String? {
        val value = parse(json)?.optString("locale")
        return value?.takeIf { it == "ar" || it == "en" }
    }

    /**
     * The first allow-listed prayer still in the future at draw time, chosen
     * from the upcoming list and the legacy next-prayer fields.
     */
    internal fun nextPrayer(objectValue: JSONObject, nowMillis: Long): Triple<String, Long, Int>? {
        val defaultOffset = integer(objectValue, "nextPrayerOffsetMinutes") ?: 0
        val candidates = mutableListOf<Triple<String, Long, Int>>()
        val key = objectValue.optString("nextPrayerKey")
        val at = long(objectValue, "nextPrayerAt")
        if (key in fardPrayerKeys && at != null) candidates.add(Triple(key, at, defaultOffset))
        val list = objectValue.optJSONArray("upcomingPrayers")
        if (list != null) {
            for (index in 0 until minOf(list.length(), maxUpcoming)) {
                val entry = list.optJSONObject(index) ?: continue
                val entryKey = entry.optString("key")
                val entryAt = long(entry, "at")
                if (entryKey !in fardPrayerKeys || entryAt == null) continue
                candidates.add(Triple(entryKey, entryAt, integer(entry, "offsetMinutes") ?: defaultOffset))
            }
        }
        return candidates
            .filter { it.second > nowMillis && it.third in -14 * 60..14 * 60 }
            .minByOrNull { it.second }
    }

    private fun prayerLine(
        objectValue: JSONObject,
        labels: WidgetSnapshotLabels,
        arabic: Boolean,
        nowMillis: Long,
    ): String? {
        val (key, at, offset) = nextPrayer(objectValue, nowMillis) ?: return null
        val name = labels.prayerNames[key] ?: return null
        return "$name · ${formatTime(at, offset, arabic)}"
    }

    private fun sectionVisible(objectValue: JSONObject, key: String) =
        objectValue.optBoolean(key, true)

    private fun reviewLine(
        objectValue: JSONObject,
        snapshot: JSONObject,
        labels: WidgetSnapshotLabels,
        arabic: Boolean,
        nowMillis: Long,
    ): String? {
        var count = integer(objectValue, "dueReviewCount")
        val transitions = snapshot.optJSONArray("reviewCounts")
        var latest = Long.MIN_VALUE
        if (transitions != null) {
            for (index in 0 until transitions.length()) {
                val entry = transitions.optJSONObject(index) ?: continue
                val at = long(entry, "at") ?: continue
                val value = integer(entry, "count") ?: continue
                if (at <= nowMillis && at >= latest && value >= 0) {
                    latest = at
                    count = value
                }
            }
        }
        if (count != null && count > 0) {
            val line = labels.reviewLine(count)
            return if (arabic) digits(line) else line
        }
        return if (objectValue.optBoolean("reviewsSettled", false)) labels.reviewsDone else null
    }

    private data class WirdPresentation(
        val line: String,
        val range: String?,
        val done: Int?,
        val total: Int?,
        val action: Boolean,
        val destination: String,
    )

    private fun wirdPresentation(
        objectValue: JSONObject,
        labels: WidgetSnapshotLabels,
        arabic: Boolean,
    ): WirdPresentation? {
        val from = integer(objectValue, "wirdFromPage")
        val to = integer(objectValue, "wirdToPage")
        val done = integer(objectValue, "wirdDonePages")
        val name = objectValue.optString("wirdSurahName").takeIf { it in canonicalSurahNames }
        if (from != null && to != null && done != null && name != null &&
            from in 1..604 && to in from..604 && done >= 0
        ) {
            val total = to - from + 1
            val shownDone = minOf(done, total)
            val line = labels.wirdLine(name, shownDone, total)
            val range = labels.wirdRange(from, to)
            return WirdPresentation(
                line = if (arabic) digits(line) else line,
                range = if (arabic) digits(range) else range,
                done = shownDone,
                total = total,
                action = shownDone < total,
                destination = "wird",
            )
        }
        return if (objectValue.optBoolean("noKhatmahPlan", false)) {
            WirdPresentation(labels.noKhatmahPlan, null, null, null, false, "khatmah-setup")
        } else {
            null
        }
    }

    private fun formatTime(millis: Long, offsetMinutes: Int, arabic: Boolean): String {
        val formatter = SimpleDateFormat("HH:mm", Locale.US).apply {
            timeZone = SimpleTimeZone(offsetMinutes * 60_000, "widget")
        }
        val time = formatter.format(Date(millis))
        return if (arabic) digits(time) else time
    }

    private fun digits(value: Any): String = value.toString().map { char ->
        if (char in '0'..'9') ('٠'.code + char.digitToInt()).toChar() else char
    }.joinToString("")

    private fun integer(objectValue: JSONObject, key: String): Int? {
        val value = objectValue.opt(key)
        return when (value) {
            is Int -> value
            is Long -> value.takeIf { it in Int.MIN_VALUE..Int.MAX_VALUE }?.toInt()
            else -> null
        }
    }

    private fun long(objectValue: JSONObject, key: String): Long? = when (val value = objectValue.opt(key)) {
        is Int -> value.toLong()
        is Long -> value
        else -> null
    }

    private fun isExpired(objectValue: JSONObject, nowMillis: Long): Boolean {
        if (!objectValue.has("expiresAt")) return false
        val expiresAt = long(objectValue, "expiresAt") ?: return true
        return expiresAt <= nowMillis
    }

    // Snapshots written before dayEndsAt existed have no day end.
    private fun hasDayEnded(objectValue: JSONObject, nowMillis: Long): Boolean {
        if (!objectValue.has("dayEndsAt")) return false
        val dayEndsAt = long(objectValue, "dayEndsAt") ?: return true
        return nowMillis >= dayEndsAt
    }

    private fun emptyRows(stale: Boolean = false) =
        WidgetRows(null, null, null, true, stale = stale)
}
