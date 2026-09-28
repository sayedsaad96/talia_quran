import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/app_session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AppSessionService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = AppSessionService(prefs);
  });

  test('saves and restores a valid Quran reader page', () async {
    await service.saveLocation('/quran/page/42');

    expect(service.getLastRestorableLocation(), '/quran/page/42');
  });

  test('saves and restores the active family dashboard route', () async {
    await service.saveLocation('/family-dashboard');

    expect(service.getLastRestorableLocation(), '/family-dashboard');
  });

  test('does not save startup or onboarding routes', () async {
    await service.saveLocation('/quran/page/42');
    await service.saveLocation('/splash');
    await service.saveLocation('/onboarding');
    await service.saveLocation('/onboarding/child');

    expect(service.getLastRestorableLocation(), '/quran/page/42');
  });

  test('does not restore incomplete memorization routes', () async {
    await service.saveLocation('/memorization-plus/daily-plan');

    expect(service.getLastRestorableLocation(), isNull);
  });

  test('does not restore kids listen route until persistence exists', () async {
    await service.saveLocation(
      '/memorization-plus/kids?surahId=114&ayahNumber=1',
    );

    expect(service.getLastRestorableLocation(), isNull);
  });

  test(
    'restores memorization routes when required query data exists',
    () async {
      await service.saveLocation('/memorization-v2/session?surahId=2&startAyah=5');

      expect(
        service.getLastRestorableLocation(),
        '/memorization-v2/session?surahId=2&startAyah=5',
      );
    },
  );

  test('restores Kids Journey route aliases with a valid journey id', () async {
    await service.saveLocation('/memorization-plus/journey/114');

    expect(
      service.getLastRestorableLocation(),
      '/memorization-plus/journey/114',
    );
  });

  test(
    'does not restore Kids Journey route aliases without a valid id',
    () async {
      await service.saveLocation('/memorization-plus/journey/115');

      expect(service.getLastRestorableLocation(), isNull);
    },
  );

  test('never saves a khatmah-mode reader page as reading position', () async {
    await service.saveLocation('/quran/page/42');
    await service.saveLocation('/quran/page/100?mode=khatmah');

    expect(service.getLastRestorableLocation(), '/quran/page/42');
  });

  test('rejects legacy khatmah-mode values at read time', () async {
    // Simulate a value persisted by an older build (app-pause saved the raw
    // route including the khatmah query).
    await prefs.setString(
      'last_restorable_location',
      '/quran/page/100?mode=khatmah',
    );

    expect(service.getLastRestorableLocation(), isNull);
  });

  group('daily wird advances only from the wird itself (B1)', () {
    final today = DateTime(2026, 9, 27, 10);

    test("confirming today's target page advances the wird", () async {
      await service.saveDailyWirdTarget(50, today);

      final advanced = await service.advanceDailyWird(50, now: today);

      expect(advanced, isTrue);
      expect(service.getDailyWirdLastCompletedPage(), 50);
    });

    test('reading contiguously past the target extends the wird', () async {
      await service.saveDailyWirdTarget(50, today);
      await service.advanceDailyWird(50, now: today);

      expect(await service.advanceDailyWird(51, now: today), isTrue);
      expect(service.getDailyWirdLastCompletedPage(), 51);
    });

    test('free reading elsewhere (Al-Kahf, going back) never moves it', () async {
      await service.saveDailyWirdTarget(50, today);
      await service.advanceDailyWird(50, now: today);

      expect(await service.advanceDailyWird(293, now: today), isFalse);
      expect(await service.advanceDailyWird(12, now: today), isFalse);
      expect(await service.advanceDailyWird(53, now: today), isFalse);
      expect(service.getDailyWirdLastCompletedPage(), 50);
    });

    test('without a target for today nothing is advanced', () async {
      expect(await service.advanceDailyWird(10, now: today), isFalse);
      expect(service.getDailyWirdLastCompletedPage(), isNull);
    });
  });

  test("saving today's wird target prunes older daily targets (B2)", () async {
    await service.saveDailyWirdTarget(10, DateTime(2026, 9, 20));
    await service.saveDailyWirdTarget(11, DateTime(2026, 9, 21));

    await service.saveDailyWirdTarget(12, DateTime(2026, 9, 27));

    final targetKeys = prefs
        .getKeys()
        .where((key) => key.startsWith('daily_wird_target_'))
        .toList();
    expect(targetKeys, ['daily_wird_target_2026-09-27']);
    expect(service.getDailyWirdTarget(DateTime(2026, 9, 27)), 12);
  });
}
