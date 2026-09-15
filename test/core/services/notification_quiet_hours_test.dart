import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';

void main() {
  group('applyQuietHours', () {
    test('returns input unchanged when disabled even inside window', () {
      final result = applyQuietHours(
        hour: 23,
        minute: 30,
        enabled: false,
        startHour: 23,
        endHour: 4,
      );
      expect(result.hour, 23);
      expect(result.minute, 30);
    });

    test('returns input unchanged when outside the window', () {
      final result = applyQuietHours(
        hour: 14,
        minute: 15,
        enabled: true,
        startHour: 23,
        endHour: 4,
      );
      expect(result.hour, 14);
      expect(result.minute, 15);
    });

    test('moves times inside window before midnight to window end', () {
      final result = applyQuietHours(
        hour: 23,
        minute: 30,
        enabled: true,
        startHour: 23,
        endHour: 4,
      );
      expect(result.hour, 4);
      expect(result.minute, 0);
    });

    test('moves after-midnight times inside window to window end', () {
      final result = applyQuietHours(
        hour: 2,
        minute: 45,
        enabled: true,
        startHour: 23,
        endHour: 4,
      );
      expect(result.hour, 4);
      expect(result.minute, 0);
    });

    test('boundary: the start hour itself is inside the window', () {
      final result = applyQuietHours(
        hour: 23,
        minute: 0,
        enabled: true,
        startHour: 23,
        endHour: 4,
      );
      expect(result.hour, 4);
      expect(result.minute, 0);
    });

    test('boundary: the end hour itself is NOT inside the window', () {
      final result = applyQuietHours(
        hour: 4,
        minute: 0,
        enabled: true,
        startHour: 23,
        endHour: 4,
      );
      expect(result.hour, 4);
      expect(result.minute, 0);
    });

    test('supports non-wrapping windows', () {
      final result = applyQuietHours(
        hour: 13,
        minute: 20,
        enabled: true,
        startHour: 12,
        endHour: 15,
      );
      expect(result.hour, 15);
      expect(result.minute, 0);
    });

    test('non-wrapping window leaves times outside unchanged', () {
      final result = applyQuietHours(
        hour: 11,
        minute: 59,
        enabled: true,
        startHour: 12,
        endHour: 15,
      );
      expect(result.hour, 11);
      expect(result.minute, 59);
    });

    test('minute is preserved when no shift is needed', () {
      final result = applyQuietHours(
        hour: 22,
        minute: 37,
        enabled: true,
        startHour: 23,
        endHour: 4,
      );
      expect(result.hour, 22);
      expect(result.minute, 37);
    });
  });
}
