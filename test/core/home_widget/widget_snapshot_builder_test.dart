import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:talia_quran/core/constants/surah_names.dart';
import 'package:talia_quran/core/home_widget/widget_snapshot.dart';
import 'package:talia_quran/core/home_widget/widget_snapshot_builder.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';

void main() {
  final now = DateTime(2026, 10, 23, 22);

  group('buildWidgetSnapshot', () {
    test(
      'returns empty when the widget is disabled or account is unavailable',
      () {
        for (final conditions in [
          (enabled: false, isAdult: true, signedOutOrSwitching: false),
          (enabled: true, isAdult: false, signedOutOrSwitching: false),
          (enabled: true, isAdult: true, signedOutOrSwitching: true),
        ]) {
          final snapshot = buildWidgetSnapshot(
            enabled: conditions.enabled,
            isAdult: conditions.isAdult,
            signedOutOrSwitching: conditions.signedOutOrSwitching,
            today: _snapshot(now),
            tomorrow: _snapshot(now.add(const Duration(days: 1))),
            dueReviewCount: 3,
            activePlan: _plan(now),
            now: now,
          );

          expect(snapshot, const WidgetSnapshot.empty());
          expect(snapshot.toJson(), {'schemaVersion': 1, 'isEmpty': true});
        }
      },
    );

    test(
      'uses tomorrow fajr after isha and does not treat sunrise as prayer',
      () {
        final snapshot = buildWidgetSnapshot(
          enabled: true,
          isAdult: true,
          signedOutOrSwitching: false,
          today: _snapshot(now),
          tomorrow: _snapshot(now.add(const Duration(days: 1))),
          dueReviewCount: 0,
          activePlan: null,
          now: now,
        );

        expect(snapshot.nextPrayerKey, 'fajr');
        expect(snapshot.nextPrayerAt, DateTime(2026, 10, 24, 5));
      },
    );

    test('excludes a prayer due at the exact current instant', () {
      final instant = DateTime(2026, 10, 23, 12);
      final snapshot = buildWidgetSnapshot(
        enabled: true,
        isAdult: true,
        signedOutOrSwitching: false,
        today: _snapshot(instant),
        tomorrow: _snapshot(instant.add(const Duration(days: 1))),
        dueReviewCount: 0,
        activePlan: null,
        now: instant,
      );

      expect(snapshot.nextPrayerKey, 'asr');
      expect(snapshot.nextPrayerAt, DateTime(2026, 10, 23, 15));
    });

    test(
      'clamps a negative review count and omits wird fields without a plan',
      () {
        final snapshot = buildWidgetSnapshot(
          enabled: true,
          isAdult: true,
          signedOutOrSwitching: false,
          today: _snapshot(now),
          tomorrow: _snapshot(now.add(const Duration(days: 1))),
          dueReviewCount: -1,
          activePlan: null,
          now: now,
        );

        expect(snapshot.dueReviewCount, 0);
        expect(snapshot.wirdFromPage, isNull);
        expect(snapshot.wirdToPage, isNull);
        expect(snapshot.wirdDonePages, isNull);
        expect(snapshot.wirdSurahName, isNull);
      },
    );

    test('uses the active plan daily range and actual completed pages', () {
      final snapshot = buildWidgetSnapshot(
        enabled: true,
        isAdult: true,
        signedOutOrSwitching: false,
        today: _snapshot(now),
        tomorrow: _snapshot(now.add(const Duration(days: 1))),
        dueReviewCount: 2,
        activePlan: _plan(now, completedPages: {10, 11, 12}),
        now: now,
      );

      expect(snapshot.wirdFromPage, 10);
      expect(snapshot.wirdToPage, 12);
      expect(snapshot.wirdDonePages, 3);
    });

    test('maps every valid wird start page to its first canonical surah', () {
      for (var page = 1; page <= 604; page++) {
        final raw = qcf.getPageData(page);
        final expectedSurah = raw.first['surah'] as int;
        final snapshot = buildWidgetSnapshot(
          enabled: true,
          isAdult: true,
          signedOutOrSwitching: false,
          today: _snapshot(now),
          tomorrow: _snapshot(now.add(const Duration(days: 1))),
          dueReviewCount: 0,
          activePlan: _plan(
            now,
            dailyTargetStartPage: page,
            dailyTargetEndPage: page,
          ),
          now: now,
        );

        expect(snapshot.wirdSurahName, SurahNames.nameAr(expectedSurah));
      }
    });

    test('uses the plan fallback for a stale or missing daily anchor', () {
      for (final plan in [
        _plan(now, dailyTargetDate: now.subtract(const Duration(days: 1))),
        _plan(now, noDailyTarget: true),
      ]) {
        final expected = plan.dailyTargetFor(now);
        final snapshot = buildWidgetSnapshot(
          enabled: true,
          isAdult: true,
          signedOutOrSwitching: false,
          today: _snapshot(now),
          tomorrow: _snapshot(now.add(const Duration(days: 1))),
          dueReviewCount: 0,
          activePlan: plan,
          now: now,
        );

        expect(snapshot.wirdFromPage, expected.startPage);
        expect(snapshot.wirdToPage, expected.endPage);
        expect(snapshot.wirdFromPage, isNot(10));
      }
    });

    test('omits paused and completed plan fields', () {
      for (final plan in [
        _plan(now, status: KhatmahStatus.paused),
        _plan(now, status: KhatmahStatus.completed),
      ]) {
        final snapshot = buildWidgetSnapshot(
          enabled: true,
          isAdult: true,
          signedOutOrSwitching: false,
          today: _snapshot(now),
          tomorrow: _snapshot(now.add(const Duration(days: 1))),
          dueReviewCount: 0,
          activePlan: plan,
          now: now,
        );

        expect(snapshot.wirdFromPage, isNull);
        expect(snapshot.wirdToPage, isNull);
        expect(snapshot.wirdDonePages, isNull);
        expect(snapshot.wirdSurahName, isNull);
      }
    });

    test(
      'serializes dates as epoch milliseconds and only permits display strings',
      () {
        final snapshot = buildWidgetSnapshot(
          enabled: true,
          isAdult: true,
          signedOutOrSwitching: false,
          today: _snapshot(now),
          tomorrow: _snapshot(now.add(const Duration(days: 1))),
          dueReviewCount: 1,
          activePlan: _plan(now),
          now: now,
        );
        final json = snapshot.toJson();
        final stringEntries = json.entries.where(
          (entry) => entry.value is String,
        );

        expect(json['schemaVersion'], 1);
        expect(json['nextPrayerAt'], isA<int>());
        expect(
          json['nextPrayerOffsetMinutes'],
          snapshot.nextPrayerAt!.timeZoneOffset.inMinutes,
        );
        expect(
          json['expiresAt'],
          DateTime(now.year, now.month, now.day + 1).millisecondsSinceEpoch,
        );
        expect(
          stringEntries.map((entry) => entry.key),
          everyElement(isIn({'nextPrayerKey', 'wirdSurahName'})),
        );
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('title'), isFalse);
        expect(json.containsKey('owner'), isFalse);
        expect(json.containsKey('text'), isFalse);
      },
    );
  });
}

PrayerTimesSnapshot _snapshot(DateTime date) {
  DateTime at(int hour) => DateTime(date.year, date.month, date.day, hour);
  return PrayerTimesSnapshot(
    city: const PrayerCity(
      id: 'city',
      nameAr: 'مدينة',
      nameEn: 'City',
      latitude: 0,
      longitude: 0,
      timeZone: 'Africa/Cairo',
      countryId: 'country',
      countryAr: 'بلد',
      countryEn: 'Country',
      defaultMethod: 'muslim_world_league',
    ),
    nextName: 'fajr',
    nextTime: at(5),
    minutesUntil: 0,
    fajr: at(5),
    sunrise: at(6),
    dhuhr: at(12),
    asr: at(15),
    maghrib: at(18),
    isha: at(21),
  );
}

KhatmahPlan _plan(
  DateTime now, {
  Set<int> completedPages = const {10},
  DateTime? dailyTargetDate,
  bool noDailyTarget = false,
  int dailyTargetStartPage = 10,
  int dailyTargetEndPage = 12,
  KhatmahStatus status = KhatmahStatus.active,
}) {
  return KhatmahPlan(
    id: 'private-plan-id',
    title: 'Private title',
    startPage: 1,
    completedPages: completedPages,
    targetPagesPerDay: 3,
    targetDays: 200,
    startDate: now.subtract(const Duration(days: 1)),
    expectedEndDate: now.add(const Duration(days: 200)),
    status: status,
    dailyTargetDate: noDailyTarget ? null : (dailyTargetDate ?? now),
    dailyTargetStartPage: noDailyTarget ? null : dailyTargetStartPage,
    dailyTargetEndPage: noDailyTarget ? null : dailyTargetEndPage,
  );
}
