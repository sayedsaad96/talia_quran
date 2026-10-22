import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_lengths.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';

void main() {
  late SharedPreferences prefs;
  late AccountDataBarrier barrier;
  late PrayerReviewLengths settings;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    barrier = AccountDataBarrier.forPreferences(prefs)
      ..owner = const FixedRecordOwnerProvider('owner');
    settings = PrayerReviewLengths(prefs, barrier);
  });

  test(
    'defaults every prayer to seven and persists only chosen prayer',
    () async {
      expect(settings.read('owner', PrayerKey.fajr), 7);
      await settings.write('owner', PrayerKey.fajr, 15, barrier.capture());
      expect(settings.read('owner', PrayerKey.fajr), 15);
      expect(settings.read('owner', PrayerKey.dhuhr), 7);
      expect(settings.read('other', PrayerKey.fajr), 7);
      expect(prefs.getString('prayer_review_lengths|owner'), '{"fajr":15}');
    },
  );

  test(
    'invalid values and stale authority cannot mutate preferences',
    () async {
      await expectLater(
        settings.write('owner', PrayerKey.fajr, 4, barrier.capture()),
        throwsFormatException,
      );
      final lease = barrier.capture();
      barrier.invalidate();
      await expectLater(
        settings.write('owner', PrayerKey.fajr, 3, lease),
        throwsA(isA<AccountDataUnavailableException>()),
      );
      expect(prefs.containsKey('prayer_review_lengths|owner'), isFalse);
    },
  );

  test('malformed persisted settings fail closed to defaults', () async {
    for (final raw in ['[]', '{"fajr":4}', '{"unknown":3}', '{"fajr":"15"}']) {
      await prefs.setString('prayer_review_lengths|owner', raw);
      expect(settings.read('owner', PrayerKey.fajr), 7);
    }
  });
}
