import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/features/seasons/domain/last_ten_reminder.dart';

void main() {
  final first = DateTime(2027, 2, 8);
  final eve = DateTime(2027, 2, 27); // Ramadan day 20
  RamadanInfo info(RamadanPhase phase, {int? day}) => RamadanInfo(
    phase: phase,
    day: day,
    monthLength: 30,
    firstDay: first,
    lastDay: DateTime(2027, 3, 9),
  );

  test('the eve is Ramadan day 20, known before and during days 1-20', () {
    expect(lastTenEveDate(info(RamadanPhase.invite)), eve);
    expect(lastTenEveDate(info(RamadanPhase.ramadan, day: 5)), eve);
    expect(lastTenEveDate(info(RamadanPhase.ramadan, day: 20)), eve);
    expect(lastTenEveDate(info(RamadanPhase.lastTen, day: 21)), isNull);
    expect(lastTenEveDate(info(RamadanPhase.afterEid)), isNull);
    expect(lastTenEveDate(const RamadanInfo(phase: RamadanPhase.none)), isNull);
  });

  test('fires 30 minutes before that day\'s Maghrib', () {
    final at = lastTenReminderAt(
      info: info(RamadanPhase.ramadan, day: 5),
      now: DateTime(2027, 2, 12),
      maghrib: DateTime(2027, 2, 27, 17, 52),
    );
    expect(at, DateTime(2027, 2, 27, 17, 22));
  });

  test('falls back to 17:30 without that day\'s Maghrib', () {
    for (final maghrib in [null, DateTime(2027, 2, 26, 17, 50)]) {
      expect(
        lastTenReminderAt(
          info: info(RamadanPhase.invite),
          now: DateTime(2027, 2, 3),
          maghrib: maghrib,
        ),
        DateTime(2027, 2, 27, 17, 30),
      );
    }
  });

  test('nothing once the time has passed or the eve is behind', () {
    expect(
      lastTenReminderAt(
        info: info(RamadanPhase.ramadan, day: 20),
        now: DateTime(2027, 2, 27, 18),
      ),
      isNull,
    );
    expect(
      lastTenReminderAt(
        info: info(RamadanPhase.lastTen, day: 22),
        now: DateTime(2027, 3, 1),
      ),
      isNull,
    );
  });
}
