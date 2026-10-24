import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import '../utils/talia_logger.dart';
import 'home_widget_publisher.dart';

final class PlatformHomeWidgetBridge implements HomeWidgetBridge {
  PlatformHomeWidgetBridge({bool? supported})
    : supported = supported ?? (!kIsWeb && Platform.isAndroid);
  static const provider = 'com.talia.quran.widget.TaliaHomeWidgetProvider';
  static const _componentChannel = MethodChannel('talia/home_widget_component');
  final bool supported;

  @override
  Future<void> save(String key, String? json) async {
    if (!supported) return;
    if (await HomeWidget.saveWidgetData<String>(key, json, deleteFile: false) !=
        true) {
      throw StateError('Native widget write was not confirmed');
    }
  }

  @override
  Future<void> requestUpdate() async {
    if (!supported) return;
    if (await HomeWidget.updateWidget(qualifiedAndroidName: provider) != true) {
      throw StateError('Native widget redraw request was not confirmed');
    }
  }

  @override
  Future<void> scheduleUpdates(List<DateTime> times) async {
    if (!supported) return;
    if (times.isEmpty) return cancelScheduledUpdates();
    if (await HomeWidget.scheduleWidgetUpdates(
          times,
          qualifiedAndroidName: provider,
        ) !=
        true) {
      throw StateError('Native widget redraw schedule was not confirmed');
    }
  }

  @override
  Future<void> cancelScheduledUpdates() async {
    if (!supported) return;
    if (await HomeWidget.cancelScheduledWidgetUpdates(
          qualifiedAndroidName: provider,
        ) !=
        true) {
      throw StateError('Native widget schedule cancel was not confirmed');
    }
  }

  @override
  Future<void> setReceiverEnabled(bool enabled) async {
    if (!supported) return;
    final applied = await _componentChannel.invokeMethod<bool>(
      'setProviderEnabled',
      {'enabled': enabled},
    );
    if (applied != true) {
      throw StateError('Native widget receiver state was not confirmed');
    }
  }
}

/// Headless work never reads accounts or writes the global snapshot key.
Future<void> redrawHomeWidgetInBackground() async {
  try {
    await PlatformHomeWidgetBridge().requestUpdate();
  } catch (error, stack) {
    TaliaLogger.w('Background widget redraw failed', error, stack);
  }
}
