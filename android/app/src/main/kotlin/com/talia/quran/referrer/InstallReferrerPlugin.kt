package com.talia.quran.referrer

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/** Passes through an invitation referrer for Dart to validate again. */
class InstallReferrerPlugin(context: Context, messenger: BinaryMessenger) {
    private val appContext = context.applicationContext
    private val handler = Handler(Looper.getMainLooper())

    init {
        MethodChannel(messenger, "talia/install_referrer").setMethodCallHandler { call, result ->
            if (call.method == "getReferrer") readReferrer(result) else result.notImplemented()
        }
    }

    private fun readReferrer(result: MethodChannel.Result) {
        val client = InstallReferrerClient.newBuilder(appContext).build()
        val completed = AtomicBoolean(false)
        val timeout = Runnable { finish(client, completed, result, null) }
        handler.postDelayed(timeout, 3000)
        try {
            client.startConnection(object : InstallReferrerStateListener {
                override fun onInstallReferrerSetupFinished(responseCode: Int) {
                    if (responseCode != InstallReferrerClient.InstallReferrerResponse.OK) {
                        handler.post {
                            handler.removeCallbacks(timeout)
                            finish(client, completed, result, null)
                        }
                        return
                    }
                    // A Binder read must not stall the main-thread timeout.
                    Thread {
                        if (completed.get()) return@Thread
                        val referrer = try {
                            client.installReferrer.installReferrer.takeIf {
                                InstallReferrerParser.parse(it) != null
                            }
                        } catch (_: Exception) { null }
                        handler.post {
                            handler.removeCallbacks(timeout)
                            finish(client, completed, result, referrer)
                        }
                    }.start()
                }

                override fun onInstallReferrerServiceDisconnected() {
                    handler.post {
                        handler.removeCallbacks(timeout)
                        finish(client, completed, result, null)
                    }
                }
            })
        } catch (_: Exception) {
            handler.removeCallbacks(timeout)
            finish(client, completed, result, null)
        }
    }

    private fun finish(
        client: InstallReferrerClient,
        completed: AtomicBoolean,
        result: MethodChannel.Result,
        value: String?,
    ) {
        if (!completed.compareAndSet(false, true)) return
        try { client.endConnection() } catch (_: Exception) { }
        result.success(value)
    }
}
