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
)

data class WidgetSnapshotLabels(
    val prayerNames: Map<String, String>,
    val reviewLine: (Int) -> String,
    val wirdLine: (String, Int, Int) -> String,
)

object WidgetSnapshotFormatter {
    private const val schemaVersion = 1
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
        if (integer(objectValue, "schemaVersion") != schemaVersion || objectValue.optBoolean("isEmpty", false)) {
            return emptyRows()
        }
        if (isExpired(objectValue, nowMillis)) return emptyRows()
        val prayer = prayerLine(objectValue, labels, arabic, nowMillis)
        val review = reviewLine(objectValue, labels, arabic)
        val wird = wirdLine(objectValue, labels, arabic)
        return WidgetRows(prayer, review, wird, prayer == null && review == null && wird == null)
    }

    private fun parse(json: String?): JSONObject? = try {
        if (json.isNullOrBlank()) null else JSONObject(json)
    } catch (_: Exception) {
        null
    }

    private fun prayerLine(
        objectValue: JSONObject,
        labels: WidgetSnapshotLabels,
        arabic: Boolean,
        nowMillis: Long,
    ): String? {
        val key = objectValue.optString("nextPrayerKey")
        if (key !in fardPrayerKeys) return null
        val name = labels.prayerNames[key] ?: return null
        val at = long(objectValue, "nextPrayerAt") ?: return null
        if (at <= nowMillis) return null
        val offset = integer(objectValue, "nextPrayerOffsetMinutes") ?: 0
        if (offset !in -14 * 60..14 * 60) return null
        return "$name · ${formatTime(at, offset, arabic)}"
    }

    private fun reviewLine(
        objectValue: JSONObject,
        labels: WidgetSnapshotLabels,
        arabic: Boolean,
    ): String? {
        val count = integer(objectValue, "dueReviewCount") ?: return null
        if (count <= 0) return null
        val line = labels.reviewLine(count)
        return if (arabic) digits(line) else line
    }

    private fun wirdLine(
        objectValue: JSONObject,
        labels: WidgetSnapshotLabels,
        arabic: Boolean,
    ): String? {
        val from = integer(objectValue, "wirdFromPage") ?: return null
        val to = integer(objectValue, "wirdToPage") ?: return null
        val done = integer(objectValue, "wirdDonePages") ?: return null
        val name = objectValue.optString("wirdSurahName").takeIf { it in canonicalSurahNames }
        if (from !in 1..604 || to !in from..604 || done < 0 || name == null) return null
        val total = to - from + 1
        val line = labels.wirdLine(name, minOf(done, total), total)
        return if (arabic) digits(line) else line
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

    private fun emptyRows() = WidgetRows(null, null, null, true)
}
