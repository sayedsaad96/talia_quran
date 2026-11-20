import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/reminder_presentation.dart';

void main() {
  const original = NotificationDetails(
    android: AndroidNotificationDetails(
      'review',
      'Review',
      channelDescription: 'Practice reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: 'notification_icon',
      actions: [AndroidNotificationAction('review', 'Open review')],
    ),
    iOS: DarwinNotificationDetails(
      presentSound: true,
      presentBanner: true,
      categoryIdentifier: 'review_category',
    ),
  );

  test('calm reminders remain visible without sound, vibration or banners', () {
    final details = reminderPresentation(original, calmMode: true);
    expect(details.android!.importance, Importance.low);
    expect(details.android!.priority, Priority.low);
    expect(details.android!.playSound, isFalse);
    expect(details.android!.enableVibration, isFalse);
    expect(details.android!.enableLights, isFalse);
    expect(details.android!.channelShowBadge, isFalse);
    expect(details.iOS!.presentSound, isFalse);
    expect(details.iOS!.presentBanner, isFalse);
    expect(details.iOS!.presentAlert, isFalse);
    expect(details.iOS!.presentList, isTrue);
    expect(details.iOS!.interruptionLevel, InterruptionLevel.passive);
  });

  test('uses stable separate Android channels for existing installations', () {
    final first = reminderPresentation(original, calmMode: true);
    final again = reminderPresentation(original, calmMode: true);
    expect(first.android!.channelId, 'review_calm_v1');
    expect(again.android!.channelId, first.android!.channelId);
    expect(first.android!.channelName, 'Review');
    expect(first.android!.channelDescription, 'Practice reminders');
  });

  test('retains action navigation and iOS category', () {
    final details = reminderPresentation(original, calmMode: true);
    expect(details.android!.actions!.single.id, 'review');
    expect(details.android!.icon, 'notification_icon');
    expect(details.iOS!.categoryIdentifier, 'review_category');
  });

  test('disabling calm mode returns original presentation unchanged', () {
    expect(reminderPresentation(original, calmMode: false), same(original));
  });
}
