package com.example.talia_quran.prayer

import android.content.Intent
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.net.URLDecoder
import java.net.URLEncoder

/**
 * Encoding/decoding of [PrayerEventData] between the transports it crosses:
 * the MethodChannel map (from Dart), intent extras (scheduler → receiver)
 * and the persisted scheduled-events store (cancel/recovery). The persisted
 * form is URL-encoded pipe-delimited so it stays testable on the plain JVM.
 */
object PrayerEventCodec {
    private const val FIELD_SEPARATOR = "|"

    /** Parses one event map as delivered by Dart. Returns null on bad data. */
    fun fromChannelMap(raw: Any?): PrayerEventData? {
        val map = raw as? Map<*, *> ?: return null
        val eventId = map[PrayerAlarmContract.KEY_EVENT_ID] as? String ?: return null
        val prayerKey = map[PrayerAlarmContract.KEY_PRAYER_KEY] as? String ?: return null
        val scheduledAt = map[PrayerAlarmContract.KEY_SCHEDULED_AT_UTC] as? String ?: return null
        val millis = parseIsoUtcMillis(scheduledAt) ?: return null
        @Suppress("UNCHECKED_CAST")
        val rawPayload = (map[PrayerAlarmContract.KEY_PAYLOAD] as? Map<String, String>) ?: emptyMap()
        return PrayerEventData(
            eventId = eventId,
            prayerKey = prayerKey,
            scheduledAtUtcMillis = millis,
            localPrayerTime = (map[PrayerAlarmContract.KEY_LOCAL_PRAYER_TIME] as? String) ?: "",
            timezoneId = (map[PrayerAlarmContract.KEY_TIMEZONE_ID] as? String) ?: "",
            notificationEnabled = (map[PrayerAlarmContract.KEY_NOTIFICATION_ENABLED] as? Boolean) ?: true,
            adhanEnabled = (map[PrayerAlarmContract.KEY_ADHAN_ENABLED] as? Boolean) ?: false,
            soundProfile = (map[PrayerAlarmContract.KEY_SOUND_PROFILE] as? String) ?: "default",
            payload = rawPayload,
        )
    }

    /** ISO-8601 UTC instant ("...Z"); tolerates a missing Z suffix. */
    fun parseIsoUtcMillis(iso: String): Long? {
        return try {
            Instant.parse(
                if (iso.endsWith("Z") || iso.endsWith("z")) iso else "${iso}Z",
            ).toEpochMilli()
        } catch (_: Exception) {
            null
        }
    }

    fun toExtrasMap(event: PrayerEventData): Map<String, Any> = mapOf(
        PrayerAlarmContract.KEY_EVENT_ID to event.eventId,
        PrayerAlarmContract.KEY_PRAYER_KEY to event.prayerKey,
        PrayerAlarmContract.KEY_SCHEDULED_AT_UTC to event.scheduledAtUtcMillis,
        PrayerAlarmContract.KEY_LOCAL_PRAYER_TIME to event.localPrayerTime,
        PrayerAlarmContract.KEY_TIMEZONE_ID to event.timezoneId,
        PrayerAlarmContract.KEY_NOTIFICATION_ENABLED to event.notificationEnabled,
        PrayerAlarmContract.KEY_ADHAN_ENABLED to event.adhanEnabled,
        PrayerAlarmContract.KEY_SOUND_PROFILE to event.soundProfile,
    )

    fun fromExtrasMap(extras: Map<String, Any?>): PrayerEventData? {
        val eventId = extras[PrayerAlarmContract.KEY_EVENT_ID] as? String ?: return null
        val prayerKey = extras[PrayerAlarmContract.KEY_PRAYER_KEY] as? String ?: return null
        val millis = (extras[PrayerAlarmContract.KEY_SCHEDULED_AT_UTC] as? Number)?.toLong()
            ?: return null
        return PrayerEventData(
            eventId = eventId,
            prayerKey = prayerKey,
            scheduledAtUtcMillis = millis,
            localPrayerTime = (extras[PrayerAlarmContract.KEY_LOCAL_PRAYER_TIME] as? String) ?: "",
            timezoneId = (extras[PrayerAlarmContract.KEY_TIMEZONE_ID] as? String) ?: "",
            notificationEnabled =
                (extras[PrayerAlarmContract.KEY_NOTIFICATION_ENABLED] as? Boolean) ?: true,
            adhanEnabled = (extras[PrayerAlarmContract.KEY_ADHAN_ENABLED] as? Boolean) ?: false,
            soundProfile = (extras[PrayerAlarmContract.KEY_SOUND_PROFILE] as? String) ?: "default",
            payload = emptyMap(),
        )
    }

    fun toIntentExtras(intent: Intent, event: PrayerEventData) {
        val extras = toExtrasMap(event)
        intent
            .putExtra(PrayerAlarmContract.KEY_EVENT_ID, extras[PrayerAlarmContract.KEY_EVENT_ID] as String)
            .putExtra(PrayerAlarmContract.KEY_PRAYER_KEY, extras[PrayerAlarmContract.KEY_PRAYER_KEY] as String)
            .putExtra(PrayerAlarmContract.KEY_SCHEDULED_AT_UTC, event.scheduledAtUtcMillis)
            .putExtra(PrayerAlarmContract.KEY_LOCAL_PRAYER_TIME, event.localPrayerTime)
            .putExtra(PrayerAlarmContract.KEY_TIMEZONE_ID, event.timezoneId)
            .putExtra(PrayerAlarmContract.KEY_NOTIFICATION_ENABLED, event.notificationEnabled)
            .putExtra(PrayerAlarmContract.KEY_ADHAN_ENABLED, event.adhanEnabled)
            .putExtra(PrayerAlarmContract.KEY_SOUND_PROFILE, event.soundProfile)
    }

    fun fromIntentExtras(intent: Intent): PrayerEventData? {
        val extras = intent.extras ?: return null
        val map = HashMap<String, Any?>()
        for (key in extras.keySet()) {
            map[key] = extras.get(key)
        }
        return fromExtrasMap(map)
    }

    /** Persisted-store encoding (URL-encoded pipe-delimited fields). */
    fun encode(event: PrayerEventData): String {
        val payloadText = event.payload.entries.joinToString(",") { "${it.key}=${it.value}" }
        return listOf(
            event.eventId,
            event.prayerKey,
            event.scheduledAtUtcMillis.toString(),
            event.localPrayerTime,
            event.timezoneId,
            event.notificationEnabled.toString(),
            event.adhanEnabled.toString(),
            event.soundProfile,
            payloadText,
        ).joinToString(FIELD_SEPARATOR) { URLEncoder.encode(it, Charsets.UTF_8.name()) }
    }

    fun decode(encoded: String): PrayerEventData? {
        val fields = encoded.split(FIELD_SEPARATOR).map { URLDecoder.decode(it, Charsets.UTF_8.name()) }
        if (fields.size < 9) return null
        val millis = fields[2].toLongOrNull() ?: return null
        val payload: Map<String, String> = if (fields[8].isEmpty()) {
            emptyMap()
        } else {
            fields[8].split(",").mapNotNull { entry ->
                val separator = entry.indexOf('=')
                if (separator <= 0) null else entry.substring(0, separator) to entry.substring(separator + 1)
            }.toMap()
        }
        return PrayerEventData(
            eventId = fields[0],
            prayerKey = fields[1],
            scheduledAtUtcMillis = millis,
            localPrayerTime = fields[3],
            timezoneId = fields[4],
            notificationEnabled = fields[5].toBoolean(),
            adhanEnabled = fields[6].toBoolean(),
            soundProfile = fields[7],
            payload = payload,
        )
    }
}

/**
 * One planned prayer occurrence pushed from Flutter. Native code NEVER
 * computes prayer times — it only executes what it is given.
 */
data class PrayerEventData(
    val eventId: String,
    val prayerKey: String,
    val scheduledAtUtcMillis: Long,
    val localPrayerTime: String,
    val timezoneId: String,
    val notificationEnabled: Boolean,
    val adhanEnabled: Boolean,
    val soundProfile: String,
    val payload: Map<String, String>,
) {
    /** Deterministic alarm/notification id for this occurrence. */
    val requestCode: Int
        get() = PrayerAlarmIdentity.requestCodeForEvent(this)
}

/**
 * Deterministic alarm identity. MUST match
 * `PrayerAlarmIdentity` in lib/core/prayer_delivery/prayer_scheduled_event.dart.
 *
 * Frozen namespaces: 2000-2039 legacy FLN, 2100-2134 companion,
 * 2200-2499 native V2 prayer alarms.
 */
object PrayerAlarmIdentity {
    const val RANGE_START = 2200
    const val RANGE_END = 2499
    const val DAY_BUCKETS = 60L
    val PRAYER_ORDER = listOf("fajr", "dhuhr", "asr", "maghrib", "isha")

    fun requestCodeFor(epochDayUtc: Long, prayerKey: String): Int {
        val daySlot = Math.floorMod(epochDayUtc, DAY_BUCKETS)
        return RANGE_START + (daySlot * PRAYER_ORDER.size).toInt() + prayerIndex(prayerKey)
    }

    fun requestCodeFor(date: LocalDate, prayerKey: String): Int =
        requestCodeFor(date.toEpochDay(), prayerKey)

    fun requestCodeForEvent(event: PrayerEventData): Int =
        requestCodeFor(
            Instant.ofEpochMilli(event.scheduledAtUtcMillis)
                .atZone(ZoneOffset.UTC).toLocalDate().toEpochDay(),
            event.prayerKey,
        )

    fun prayerIndex(prayerKey: String): Int {
        val index = PRAYER_ORDER.indexOf(prayerKey)
        if (index >= 0) return index
        return Math.floorMod(prayerKey.hashCode(), PRAYER_ORDER.size)
    }
}