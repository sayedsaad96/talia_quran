package com.example.talia_quran.prayer

/**
 * MethodChannel contract for the Talia prayer delivery pipeline (V2).
 *
 * MUST stay in sync with the Dart side:
 *   lib/core/prayer_delivery/android_prayer_delivery_scheduler.dart
 * (PrayerDeliveryContract + PrayerScheduledEvent.toMap keys)
 */
object PrayerAlarmContract {
    const val CHANNEL_NAME = "talia/prayer_delivery"

    // Operations.
    const val METHOD_SCHEDULE_EVENTS = "scheduleEvents"
    const val METHOD_CANCEL_ALL = "cancelAll"
    const val METHOD_CANCEL_EVENT = "cancelEvent"
    const val METHOD_CAN_SCHEDULE_EXACT = "canScheduleExact"

    // Request keys (mirror PrayerScheduledEvent.toMap).
    const val KEY_EVENTS = "events"
    const val KEY_EVENT = "event"
    const val KEY_EVENT_ID = "eventId"
    const val KEY_PRAYER_KEY = "prayerKey"
    const val KEY_SCHEDULED_AT_UTC = "scheduledAtUtc"
    const val KEY_LOCAL_PRAYER_TIME = "localPrayerTime"
    const val KEY_TIMEZONE_ID = "timezoneId"
    const val KEY_NOTIFICATION_ENABLED = "notificationEnabled"
    const val KEY_ADHAN_ENABLED = "adhanEnabled"
    const val KEY_SOUND_PROFILE = "soundProfile"
    const val KEY_PAYLOAD = "payload"

    // Result keys (mirror PrayerDeliveryResult parsing).
    const val KEY_SUCCESS = "success"
    const val KEY_SCHEDULED_COUNT = "scheduledCount"
    const val KEY_EXACT_ALLOWED = "exactAllowed"
    const val KEY_CAN_SCHEDULE_EXACT = "canScheduleExact"
    const val KEY_ERROR = "error"
}