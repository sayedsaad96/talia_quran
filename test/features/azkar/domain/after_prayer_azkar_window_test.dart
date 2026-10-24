import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/services/after_prayer_azkar_window.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DateTime at(int h, int m) => DateTime(2026, 10, 16, h, m);
  final times = {
    PrayerSlot.fajr: at(5, 0),
    PrayerSlot.dhuhr: at(12, 0),
    PrayerSlot.asr: at(15, 30),
    PrayerSlot.maghrib: at(18, 0),
    PrayerSlot.isha: at(19, 20),
  };

  test(
    'window opens at prayer+10, closes at +60, clipped before next prayer',
    () {
      final w = activeAfterPrayerWindow(todayTimes: times, now: at(12, 10));
      expect(w?.prayer, PrayerSlot.dhuhr);
      expect(w?.from, at(12, 10));
      expect(w?.until, at(13, 0));
      expect(
        activeAfterPrayerWindow(todayTimes: times, now: at(12, 59))?.prayer,
        PrayerSlot.dhuhr,
      );
      expect(
        activeAfterPrayerWindow(todayTimes: times, now: at(13, 0)),
        isNull,
      );
      final close = {...times, PrayerSlot.isha: at(18, 40)};
      final clipped = activeAfterPrayerWindow(
        todayTimes: close,
        now: at(18, 15),
      );
      expect(clipped?.prayer, PrayerSlot.maghrib);
      expect(clipped?.until, at(18, 40));
    },
  );

  test('before offset, between windows and before fajr are null; isha runs '
      'past midnight; custom offset honoured', () {
    expect(activeAfterPrayerWindow(todayTimes: times, now: at(12, 9)), isNull);
    expect(activeAfterPrayerWindow(todayTimes: times, now: at(14, 0)), isNull);
    expect(activeAfterPrayerWindow(todayTimes: times, now: at(4, 0)), isNull);
    final late = {...times, PrayerSlot.isha: at(23, 30)};
    final w = activeAfterPrayerWindow(
      todayTimes: late,
      now: DateTime(2026, 10, 17, 0, 15),
    );
    expect(w?.prayer, PrayerSlot.isha);
    expect(
      activeAfterPrayerWindow(
        todayTimes: times,
        now: at(12, 5),
        offsetMinutes: 5,
      )?.prayer,
      PrayerSlot.dhuhr,
    );
  });

  test('loadAfterPrayerAzkarIds keeps only records that pass the release '
      'notification gate', () async {
    final ids = await loadAfterPrayerAzkarIds(
      _FakeBundle(
        jsonEncode({
          'general': [
            _record('graded', grade: 'sahih'),
            _record('ungraded'),
            _record('other', grade: 'sahih', subcategory: 'أذكار النوم'),
          ],
        }),
      ),
    );
    expect(ids, ['graded']);
  });

  test('loadAfterPrayerAzkarIds from the real bundled asset fails closed on '
      'ungraded hadith', () async {
    // The bundled after-prayer records carry no authenticityGrade yet, so the
    // card stays hidden until they are graded in azkar_release.json.
    final ids = await loadAfterPrayerAzkarIds(rootBundle);
    expect(ids, isEmpty);
  });
}

Map<String, dynamic> _record(
  String id, {
  String? grade,
  String subcategory = afterPrayerAzkarSubcategory,
}) => {
  'id': id,
  'text': 'نص',
  'count': 1,
  'subcategory': subcategory,
  'sourceType': 'hadith',
  'reviewStatus': 'approved',
  'citation': 'مرجع',
  'sourceUrl': 'https://example.org/$id',
  'datasetVersion': 'test-1',
  'authenticityGrade': ?grade,
};

final class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._source);

  final String _source;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(utf8.encode(_source));

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _source;
}
