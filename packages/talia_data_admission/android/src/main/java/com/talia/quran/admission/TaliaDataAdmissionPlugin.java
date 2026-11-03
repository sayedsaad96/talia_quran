package com.talia.quran.admission;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.util.UUID;

/** Per-engine channel; detach never releases permits because callbacks may outlive it. */
public final class TaliaDataAdmissionPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private final String engineId = UUID.randomUUID().toString();
    private MethodChannel channel;
    private File lockFile;

    @Override public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        try {
            File directory = binding.getApplicationContext().getNoBackupFilesDir();
            lockFile = directory == null ? null : new File(directory, "talia_data_admission.lock");
        } catch (RuntimeException e) {
            lockFile = null;
        }
        channel = new MethodChannel(binding.getBinaryMessenger(), "talia/data_admission");
        channel.setMethodCallHandler(this);
    }
    @Override public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }
    @Override public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            switch (call.method) {
                case "acquire": result.success(AdmissionBroker.acquire(lockFile, engineId, call.argument("mode"))); break;
                case "validate": result.success(AdmissionBroker.validate(call.argument("token"), engineId)); break;
                case "release": result.success(AdmissionBroker.release(call.argument("token"), engineId)); break;
                default: result.notImplemented();
            }
        } catch (RuntimeException e) {
            result.error("admission_failed", "Data admission unavailable", null);
        }
    }
}
