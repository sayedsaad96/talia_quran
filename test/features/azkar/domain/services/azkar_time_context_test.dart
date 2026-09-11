import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_time_context.dart';

void main() {
  group('AzkarTimeContext', () {
    test('resolves morning period between 04:00 and 15:29', () {
      expect(
        AzkarTimeContext.resolvePeriod(DateTime(2026, 9, 10, 4, 0)),
        AzkarPeriod.morning,
      );
      expect(
        AzkarTimeContext.resolvePeriod(DateTime(2026, 9, 10, 10, 30)),
        AzkarPeriod.morning,
      );
      expect(
        AzkarTimeContext.resolvePeriod(DateTime(2026, 9, 10, 15, 29)),
        AzkarPeriod.morning,
      );
    });

    test('resolves evening period between 15:30 and 03:59', () {
      expect(
        AzkarTimeContext.resolvePeriod(DateTime(2026, 9, 10, 15, 30)),
        AzkarPeriod.evening,
      );
      expect(
        AzkarTimeContext.resolvePeriod(DateTime(2026, 9, 10, 19, 0)),
        AzkarPeriod.evening,
      );
      expect(
        AzkarTimeContext.resolvePeriod(DateTime(2026, 9, 10, 23, 59)),
        AzkarPeriod.evening,
      );
      expect(
        AzkarTimeContext.resolvePeriod(DateTime(2026, 9, 10, 0, 0)),
        AzkarPeriod.evening,
      );
      expect(
        AzkarTimeContext.resolvePeriod(DateTime(2026, 9, 10, 3, 59)),
        AzkarPeriod.evening,
      );
    });
  });
}
