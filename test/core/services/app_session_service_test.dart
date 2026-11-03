import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/backup/portable_reading_data.dart';
import 'package:talia_quran/core/identity/account_deletion_marker.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
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
      await service.saveLocation(
        '/memorization-v2/session?surahId=2&startAyah=5',
      );

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

    test(
      'free reading elsewhere (Al-Kahf, going back) never moves it',
      () async {
        await service.saveDailyWirdTarget(50, today);
        await service.advanceDailyWird(50, now: today);

        expect(await service.advanceDailyWird(293, now: today), isFalse);
        expect(await service.advanceDailyWird(12, now: today), isFalse);
        expect(await service.advanceDailyWird(53, now: today), isFalse);
        expect(service.getDailyWirdLastCompletedPage(), 50);
      },
    );

    test('without a target for today nothing is advanced', () async {
      expect(await service.advanceDailyWird(10, now: today), isFalse);
      expect(service.getDailyWirdLastCompletedPage(), isNull);
    });
  });

  group('Quran reading checkpoint export', () {
    AppSessionService serviceFor(String ownerId) =>
        AppSessionService(prefs, owner: FixedRecordOwnerProvider(ownerId));

    test('exports the page saved under the active owner', () async {
      final owner = serviceFor('a');
      await owner.saveQuranCheckpoint(expectedOwnerId: 'a', pageNumber: 42);

      final checkpoint = await owner.exportQuranCheckpoint(
        expectedOwnerId: 'a',
      );

      expect(checkpoint, QuranReadingCheckpoint(pageNumber: 42));
    });

    test('exports null when the owner never saved a checkpoint', () async {
      expect(
        await serviceFor('a').exportQuranCheckpoint(expectedOwnerId: 'a'),
        isNull,
      );
    });

    test('does not turn a legacy route into an owner checkpoint', () async {
      final owner = serviceFor('a');
      await owner.saveLocation('/quran/page/42');
      await owner.saveLocation('/quran/surah/2');

      expect(await owner.exportQuranCheckpoint(expectedOwnerId: 'a'), isNull);
    });

    test('keeps checkpoints isolated per owner', () async {
      await serviceFor(
        'a',
      ).saveQuranCheckpoint(expectedOwnerId: 'a', pageNumber: 42);

      expect(
        await serviceFor('b').exportQuranCheckpoint(expectedOwnerId: 'b'),
        isNull,
      );
    });

    test('refuses to export or save for a non-active owner', () async {
      final owner = serviceFor('a');
      await owner.saveQuranCheckpoint(expectedOwnerId: 'a', pageNumber: 42);

      await expectLater(
        owner.exportQuranCheckpoint(expectedOwnerId: 'b'),
        throwsA(isA<PortableReadingDataException>()),
      );
      await expectLater(
        owner.saveQuranCheckpoint(expectedOwnerId: 'b', pageNumber: 7),
        throwsA(isA<PortableReadingDataException>()),
      );
      expect(
        (await owner.exportQuranCheckpoint(expectedOwnerId: 'a'))?.pageNumber,
        42,
      );
    });

    test('rejects pages outside 1..604 on save', () async {
      final owner = serviceFor('a');
      for (final page in [0, 605]) {
        await expectLater(
          owner.saveQuranCheckpoint(expectedOwnerId: 'a', pageNumber: page),
          throwsA(isA<PortableReadingDataException>()),
        );
      }
      expect(await owner.exportQuranCheckpoint(expectedOwnerId: 'a'), isNull);
    });

    test('fails instead of returning null for an unreadable value', () async {
      await prefs.setInt('quran_reading_checkpoint_owner_a', 605);
      await expectLater(
        serviceFor('a').exportQuranCheckpoint(expectedOwnerId: 'a'),
        throwsA(isA<PortableReadingDataException>()),
      );

      await prefs.setString('quran_reading_checkpoint_owner_a', 'garbage');
      await expectLater(
        serviceFor('a').exportQuranCheckpoint(expectedOwnerId: 'a'),
        throwsA(isA<PortableReadingDataException>()),
      );
    });

    test('refuses an owner whose account deletion is pending', () async {
      final owner = serviceFor('a');
      await owner.saveQuranCheckpoint(expectedOwnerId: 'a', pageNumber: 42);
      await AccountDeletionMarker.markRequested(prefs, 'a');

      await expectLater(
        owner.exportQuranCheckpoint(expectedOwnerId: 'a'),
        throwsA(isA<PortableReadingDataException>()),
      );
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
