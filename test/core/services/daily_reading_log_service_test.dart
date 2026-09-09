import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/services/daily_reading_log_service.dart';

void main() {
  test('records pages for today and prunes old keys', () async {
    SharedPreferences.setMockInitialValues({
      'daily_read_pages_2020-01-01': '[1]',
    });
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime(2026, 9, 8);
    final log = DailyReadingLogService(prefs, now: () => now);

    await log.recordPage(12, date: now);
    expect(log.contains(12, date: now), isTrue);
    expect(log.pagesReadOn(now), [12]);
    expect(prefs.containsKey('daily_read_pages_2020-01-01'), isFalse);
  });

  test('rejects a reading write after account authority is invalidated', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final log = DailyReadingLogService(prefs, now: () => DateTime(2026, 9, 8));
    AccountDataBarrier.forPreferences(prefs).invalidate();

    await expectLater(
      log.recordPage(12),
      throwsA(isA<AccountDataUnavailableException>()),
    );
    expect(log.contains(12), isFalse);
  });
}
