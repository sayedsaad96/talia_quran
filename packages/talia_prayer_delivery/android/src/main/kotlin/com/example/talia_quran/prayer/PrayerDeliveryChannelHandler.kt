package com.example.talia_quran.prayer

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Registers the `talia/prayer_delivery` MethodChannel on the Flutter engine
 * and dispatches the four delivery operations to [PrayerAlarmScheduler].
 *
 * Failure policy: platform failures are returned as `success: false` maps
 * (never thrown), so the Dart migration flow can keep the legacy path.
 */
object PrayerDeliveryChannelHandler {
    private const val TAG = "PrayerV2"

    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, PrayerAlarmContract.CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                onMethodCall(context.applicationContext, call, result)
            }
    }

    private fun onMethodCall(
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            PrayerAlarmContract.METHOD_SCHEDULE_EVENTS -> handleScheduleEvents(context, call, result)
            PrayerAlarmContract.METHOD_CANCEL_ALL -> {
                PrayerAlarmScheduler.cancelAll(context)
                result.success(null)
            }
            PrayerAlarmContract.METHOD_CANCEL_EVENT -> handleCancelEvent(context, call, result)
            PrayerAlarmContract.METHOD_CAN_SCHEDULE_EXACT -> result.success(
                mapOf(
                    PrayerAlarmContract.KEY_CAN_SCHEDULE_EXACT to
                        PrayerAlarmScheduler.canScheduleExact(context),
                ),
            )
            else -> result.notImplemented()
        }
    }

    private fun handleScheduleEvents(
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val arguments = call.arguments as? Map<*, *>
        @Suppress("UNCHECKED_CAST")
        val rawEvents = arguments?.get(PrayerAlarmContract.KEY_EVENTS) as? List<Any?> ?: emptyList()
        val events = rawEvents.mapNotNull { PrayerEventCodec.fromChannelMap(it) }
        if (events.size != rawEvents.size) {
            Log.w(TAG, "scheduleEvents: ${rawEvents.size - events.size} unparseable event(s)")
            result.success(
                mapOf(
                    PrayerAlarmContract.KEY_SUCCESS to false,
                    PrayerAlarmContract.KEY_SCHEDULED_COUNT to 0,
                    PrayerAlarmContract.KEY_ERROR to "one or more events were unparseable",
                ),
            )
            return
        }
        val outcome = PrayerAlarmScheduler.scheduleEvents(context, events)
        result.success(
            mapOf(
                PrayerAlarmContract.KEY_SUCCESS to outcome.success,
                PrayerAlarmContract.KEY_SCHEDULED_COUNT to outcome.scheduledCount,
                PrayerAlarmContract.KEY_EXACT_ALLOWED to outcome.exactAllowed,
                PrayerAlarmContract.KEY_ERROR to outcome.error,
            ),
        )
    }

    private fun handleCancelEvent(
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val arguments = call.arguments as? Map<*, *>
        val event = PrayerEventCodec.fromChannelMap(arguments?.get(PrayerAlarmContract.KEY_EVENT))
        if (event == null) {
            result.error("invalid_event", "unparseable event payload", null)
            return
        }
        PrayerAlarmScheduler.cancelEvent(context, event)
        result.success(null)
    }
}