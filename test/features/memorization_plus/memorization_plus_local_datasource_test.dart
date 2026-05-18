import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  late SharedPreferences prefs;
  late MemorizationPlusLocalDatasourceImpl datasource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    datasource = MemorizationPlusLocalDatasourceImpl(prefs);
  });

  group('MemorizationPlusLocalDatasourceImpl', () {
    test('returns an empty profile when no identity has been saved', () async {
      final profile = await datasource.getMemorizationProfile();

      expect(profile.selectedPath, isNull);
      expect(profile.guardianLinkStatus, GuardianLinkStatus.none);
      expect(
        profile.guardianOnboardingStatus,
        GuardianOnboardingStatus.required,
      );
    });

    test('saves and clears memorization profile and pairing session', () async {
      final now = DateTime(2026, 5, 17, 10);
      final profile = MemorizationProfileModel(
        schemaVersion: 1,
        selectedPath: MemorizationPath.child,
        guardianLinkStatus: GuardianLinkStatus.pending,
        guardianOnboardingStatus: GuardianOnboardingStatus.required,
        isParentGuardian: false,
        createdAt: now,
        updatedAt: now,
      );
      final session = PairingSessionModel(
        id: 'session-1',
        pairingCode: '123456',
        qrData: 'talia-kids-link:123456',
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
        status: PairingSessionStatus.pending,
        isUsed: false,
      );

      await datasource.saveMemorizationProfile(profile);
      await datasource.savePairingSession(session);

      expect(
        (await datasource.getMemorizationProfile()).selectedPath,
        MemorizationPath.child,
      );
      expect((await datasource.getPairingSession())?.pairingCode, '123456');

      await datasource.clearMemorizationProfile();
      await datasource.clearPairingSession();

      expect((await datasource.getMemorizationProfile()).selectedPath, isNull);
      expect(await datasource.getPairingSession(), isNull);
    });

    test('saves and loads selected track', () async {
      await datasource.saveSelectedTrack(MemorizationTrack.kids.name);

      expect(datasource.getSelectedTrack(), MemorizationTrack.kids.name);
    });

    test(
      'ignores corrupted review records while loading all records',
      () async {
        await prefs.setString('mem_plus_review_1_1', '{bad json');
        await datasource.saveReviewRecord(AyahReviewRecordModel.initial(1, 2));

        final records = await datasource.getAllReviewRecords();

        expect(records, hasLength(1));
        expect(records.single.ayahNumber, 2);
      },
    );

    test('returns null for corrupted cached daily plan', () async {
      await prefs.setString('mem_plus_daily_plan', '{bad json');

      expect(await datasource.getCachedDailyPlan(), isNull);
    });

    test(
      'returns empty kids progress when stored value is corrupted',
      () async {
        await prefs.setString('mem_plus_kids_progress', '{bad json');

        final progress = await datasource.getKidsProgress();

        expect(progress.totalPoints, 0);
        expect(progress.currentLevel, 1);
      },
    );

    test('saves and deletes custom plan', () async {
      final plan = CustomMemorizationPlanModel(
        name: 'Plan',
        startSurahId: 1,
        endSurahId: 2,
        newAyahsPerDay: 3,
        availableDaysPerWeek: 5,
        sessionMinutes: 20,
        difficulty: MemorizationDifficulty.moderate,
        enableNearRevision: true,
        enableFarRevision: true,
        nearRevisionCount: 5,
        farRevisionCount: 5,
        startAyah: 1,
        createdAt: DateTime(2026, 5, 5),
      );

      await datasource.saveCustomPlan(plan);
      expect(await datasource.getCustomPlan(), isNotNull);

      await datasource.deleteCustomPlan();
      expect(await datasource.getCustomPlan(), isNull);
    });

    test('saves smart settings separately from memorization profile', () async {
      final now = DateTime(2026, 5, 17, 10);
      await datasource.saveMemorizationProfile(
        MemorizationProfileModel(
          schemaVersion: 1,
          selectedPath: MemorizationPath.adult,
          guardianLinkStatus: GuardianLinkStatus.none,
          guardianOnboardingStatus: GuardianOnboardingStatus.completed,
          isParentGuardian: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await datasource.saveSmartSettings(
        const SmartMemorizationSettingsModel(
          dailySchedule: 'after-fajr',
          reviewDays: [1, 3, 5],
          ayahIsolationEnabled: true,
        ),
      );

      final profile = await datasource.getMemorizationProfile();
      final settings = await datasource.getSmartSettings();

      expect(profile.selectedPath, MemorizationPath.adult);
      expect(profile.isParentGuardian, isTrue);
      expect(settings.dailySchedule, 'after-fajr');
      expect(settings.reviewDays, [1, 3, 5]);
      expect(settings.ayahIsolationEnabled, isTrue);
    });
  });
}
