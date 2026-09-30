import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_period_resolver.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_time_context.dart';

DateTime _at(int hour, [int minute = 0, int day = 29]) =>
    DateTime(2026, 9, day, hour, minute);

class _FixedSource implements AzkarPrayerWindowSource {
  const _FixedSource(this.window);
  final AzkarPrayerWindow? window;

  @override
  Future<AzkarPrayerWindow?> load(DateTime now) async => window;
}

class _ThrowingSource implements AzkarPrayerWindowSource {
  const _ThrowingSource();

  @override
  Future<AzkarPrayerWindow?> load(DateTime now) async =>
      throw StateError('prayer lookup failed');
}

void main() {
  final window = AzkarPrayerWindow(fajr: _at(4, 30), asr: _at(15, 45));

  group('with a prayer window', () {
    test('morning runs from Fajr up to Asr', () {
      expect(
        AzkarPeriodResolver.resolve(_at(4, 29), window: window),
        AzkarPeriod.evening,
      );
      expect(
        AzkarPeriodResolver.resolve(_at(4, 30), window: window),
        AzkarPeriod.morning,
      );
      expect(
        AzkarPeriodResolver.resolve(_at(15, 44), window: window),
        AzkarPeriod.morning,
      );
    });

    test('evening starts at Asr and lasts until the next Fajr', () {
      expect(
        AzkarPeriodResolver.resolve(_at(15, 45), window: window),
        AzkarPeriod.evening,
      );
      expect(
        AzkarPeriodResolver.resolve(_at(18, 30), window: window),
        AzkarPeriod.evening,
      );
      expect(
        AzkarPeriodResolver.resolve(_at(0, 30), window: window),
        AzkarPeriod.evening,
      );
    });

    test('15:40 is still morning when Asr is later than 15:30', () {
      // The fixed rule would say evening here; the window must win.
      expect(AzkarTimeContext.resolvePeriod(_at(15, 40)), AzkarPeriod.evening);
      expect(
        AzkarPeriodResolver.resolve(_at(15, 40), window: window),
        AzkarPeriod.morning,
      );
    });
  });

  group('without a usable window', () {
    test('no window uses the fixed rule', () {
      expect(AzkarPeriodResolver.resolve(_at(15, 29)), AzkarPeriod.morning);
      expect(AzkarPeriodResolver.resolve(_at(16)), AzkarPeriod.evening);
    });

    test('a stale window from two days ago is ignored', () {
      final stale = AzkarPrayerWindow(
        fajr: _at(4, 30, 27),
        asr: _at(15, 45, 27),
      );
      // If the stale window were applied, 10:00 on the 29th would be after its
      // Asr and read as evening.
      expect(
        AzkarPeriodResolver.resolve(_at(10), window: stale),
        AzkarPeriod.morning,
      );
    });

    test('a window with Fajr after Asr is ignored', () {
      final broken = AzkarPrayerWindow(fajr: _at(16), asr: _at(5));
      expect(broken.isConsistent, isFalse);
      expect(
        AzkarPeriodResolver.resolve(_at(10), window: broken),
        AzkarPeriod.morning,
      );
    });
  });

  group('resolveWith', () {
    test('uses the window a source returns', () async {
      final period = await AzkarPeriodResolver.resolveWith(
        _at(15, 40),
        _FixedSource(window),
      );
      expect(period, AzkarPeriod.morning);
    });

    test('falls back to the fixed rule when there is no source', () async {
      expect(
        await AzkarPeriodResolver.resolveWith(_at(15, 40), null),
        AzkarPeriod.evening,
      );
    });

    test('falls back to the fixed rule when the source returns null', () async {
      expect(
        await AzkarPeriodResolver.resolveWith(
          _at(15, 40),
          const _FixedSource(null),
        ),
        AzkarPeriod.evening,
      );
    });

    test('falls back to the fixed rule when the source throws', () async {
      expect(
        await AzkarPeriodResolver.resolveWith(
          _at(15, 40),
          const _ThrowingSource(),
        ),
        AzkarPeriod.evening,
      );
    });
  });
}
