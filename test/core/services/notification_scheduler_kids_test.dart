import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';

void main() {
  test('kids reminder is suppressed after a mission on the same local day', () {
    final now = DateTime.utc(2026, 9, 1, 18);

    expect(
      hasCompletedKidsMissionToday([DateTime.utc(2026, 9, 1, 8)], now: now),
      isTrue,
    );
    expect(
      hasCompletedKidsMissionToday([DateTime.utc(2026, 8, 31, 18)], now: now),
      isFalse,
    );
  });
}
