package com.talia.quran.prayer

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

/** Registers prayer delivery for every Flutter engine, including WorkManager. */
class TaliaPrayerDeliveryPlugin : FlutterPlugin {
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = PrayerDeliveryChannelHandler.register(
            binding.applicationContext,
            binding.binaryMessenger,
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }
}
