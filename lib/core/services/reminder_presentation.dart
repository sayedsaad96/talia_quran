import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Calm reminders stay in the notification list without asking for attention.
/// Prayer-time and athan details never pass through this policy.
NotificationDetails reminderPresentation(
  NotificationDetails details, {
  required bool calmMode,
}) {
  if (!calmMode) return details;
  final android = details.android;
  final ios = details.iOS;
  return NotificationDetails(
    android: android == null
        ? null
        : AndroidNotificationDetails(
            // Android channel behavior is immutable after creation. A stable
            // separate channel also makes this work for existing installs.
            '${android.channelId}_calm_v1',
            android.channelName,
            channelDescription: android.channelDescription,
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            enableVibration: false,
            enableLights: false,
            channelShowBadge: false,
            onlyAlertOnce: true,
            color: android.color,
            icon: android.icon,
            actions: android.actions,
          ),
    iOS: ios == null
        ? null
        : DarwinNotificationDetails(
            presentAlert: false,
            presentBanner: false,
            presentList: true,
            presentBadge: false,
            presentSound: false,
            interruptionLevel: InterruptionLevel.passive,
            categoryIdentifier: ios.categoryIdentifier,
          ),
  );
}
