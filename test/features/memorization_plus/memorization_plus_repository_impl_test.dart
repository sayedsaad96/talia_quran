import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/constants/app_constants.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

void main() {
  group('MemorizationPlusRepositoryImpl', () {
    late MemorizationPlusLocalDatasourceImpl datasource;
    late MemorizationPlusRepositoryImpl repository;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      datasource = MemorizationPlusLocalDatasourceImpl(prefs);
      repository = MemorizationPlusRepositoryImpl(
        datasource,
        _UnusedQuranRepository(),
      );
    });

    test('markAyahMemorized stores a smart memorized review record', () async {
      final result = await repository.markAyahMemorized(
        surahId: 114,
        ayahNumber: 1,
      );

      final record = result.getOrElse(
        () => throw StateError('Expected markAyahMemorized to succeed'),
      );
      final persisted = await datasource.getReviewRecord(114, 1);

      expect(record.isMemorized, isTrue);
      expect(record.strengthLevel, greaterThanOrEqualTo(6));
      expect(persisted, isNotNull);
      expect(persisted!.isMemorized, isTrue);
    });

    test(
      'getKidsJourney builds unlocked current stage and locked next stages',
      () async {
        final result = await repository.getKidsJourney(surahId: 114);

        final stages = result.getOrElse(
          () => throw StateError('Expected journey generation to succeed'),
        );

        expect(stages, hasLength(2));
        expect(stages.first.startAyah, 1);
        expect(stages.first.endAyah, 5);
        expect(stages.first.status.name, 'current');
        expect(stages.last.status.name, 'locked');
      },
    );

    test('saveKidsSessionLog persists local kids session log', () async {
      final result = await repository.saveKidsSessionLog(
        surahId: 114,
        ayahNumber: 1,
        repeatsCompleted: 3,
        pointsEarned: 14,
      );

      final log = result.getOrElse(
        () => throw StateError('Expected session log to save'),
      );
      final logs = await datasource.getKidsSessionLogs();

      expect(log.ayahNumber, 1);
      expect(logs, hasLength(1));
      expect(logs.single.pointsEarned, 14);
    });

    test('saveKidsSessionLog is idempotent per ayah', () async {
      await repository.saveKidsSessionLog(
        surahId: 114,
        ayahNumber: 1,
        repeatsCompleted: 3,
        pointsEarned: 14,
      );

      final duplicate = await repository.saveKidsSessionLog(
        surahId: 114,
        ayahNumber: 1,
        repeatsCompleted: 3,
        pointsEarned: 14,
      );

      final logs = await datasource.getKidsSessionLogs();
      final returned = duplicate.getOrElse(
        () => throw StateError('Expected duplicate log to return existing log'),
      );

      expect(logs, hasLength(1));
      expect(returned.id, logs.single.id);
    });

    test('awardKidsPoints awards only once per completed ayah', () async {
      final first = await repository.awardKidsPoints(
        surahId: 114,
        ayahNumber: 1,
        repeatsCompleted: 3,
      );
      final firstResult = first.getOrElse(
        () => throw StateError('Expected first award to succeed'),
      );

      final replay = await repository.awardKidsPoints(
        surahId: 114,
        ayahNumber: 1,
        repeatsCompleted: 3,
      );
      final replayResult = replay.getOrElse(
        () => throw StateError('Expected replay award to succeed'),
      );
      final progress = await datasource.getKidsProgress();
      final logs = await datasource.getKidsSessionLogs();

      expect(firstResult.alreadyCompleted, isFalse);
      expect(firstResult.pointsEarned, 14);
      expect(firstResult.starsEarned, 1);
      expect(replayResult.alreadyCompleted, isTrue);
      expect(replayResult.pointsEarned, 0);
      expect(replayResult.starsEarned, 0);
      expect(progress.totalPoints, 14);
      expect(progress.starsEarned, 1);
      expect(progress.ayahsCompleted, 1);
      expect(logs, hasLength(1));
    });

    test('rapid duplicate kids completion awards only once', () async {
      await datasource.saveParentSettings(
        const ParentSettingsModel(weeklyGoalSessions: 1),
      );
      await repository.saveParentReward('رحلة عائلية');

      final results = await Future.wait([
        repository.awardKidsPoints(
          surahId: 114,
          ayahNumber: 1,
          repeatsCompleted: 3,
        ),
        repository.awardKidsPoints(
          surahId: 114,
          ayahNumber: 1,
          repeatsCompleted: 3,
        ),
      ]);

      final completions = results
          .map(
            (result) => result.getOrElse(
              () => throw StateError('Expected rapid completion to succeed'),
            ),
          )
          .toList();
      final progress = await datasource.getKidsProgress();
      final logs = await datasource.getKidsSessionLogs();
      final rewards = await datasource.getParentRewards();

      expect(
        completions.where((result) => !result.alreadyCompleted),
        hasLength(1),
      );
      expect(
        completions.where((result) => result.alreadyCompleted),
        hasLength(1),
      );
      expect(
        completions.fold<int>(0, (sum, result) => sum + result.pointsEarned),
        14,
      );
      expect(
        completions.fold<int>(0, (sum, result) => sum + result.starsEarned),
        1,
      );
      expect(progress.totalPoints, 14);
      expect(progress.starsEarned, 1);
      expect(progress.ayahsCompleted, 1);
      expect(logs, hasLength(1));
      expect(
        rewards.where((reward) => reward.status == ParentRewardStatus.unlocked),
        hasLength(1),
      );
    });

    test('duplicate kids completion does not disturb journey status', () async {
      for (var ayah = 1; ayah <= 5; ayah++) {
        await repository.saveKidsSessionLog(
          surahId: 114,
          ayahNumber: ayah,
          repeatsCompleted: 3,
          pointsEarned: 14,
        );
      }
      await repository.saveKidsSessionLog(
        surahId: 114,
        ayahNumber: 5,
        repeatsCompleted: 3,
        pointsEarned: 14,
      );

      final logs = await datasource.getKidsSessionLogs();
      final journey = await repository.getKidsJourney(surahId: 114);
      final stages = journey.getOrElse(
        () => throw StateError('Expected journey to load'),
      );

      expect(logs.where((log) => log.ayahNumber == 5), hasLength(1));
      expect(stages.first.status, KidsJourneyStageStatus.completed);
      expect(stages.last.status, KidsJourneyStageStatus.current);
    });

    test('parent settings and rewards are stored locally', () async {
      await repository.setParentPin('1234');
      final verified = await repository.verifyParentPin('1234');
      final rewards = await repository.saveParentReward('نزهة قصيرة');
      final settings = await datasource.getParentSettings();

      expect(verified.getOrElse(() => false), isTrue);
      expect(settings.pinHash, isNot('1234'));
      expect(settings.pinHash, hasLength(64));
      expect(rewards.getOrElse(() => const []), hasLength(1));
    });

    test(
      'legacy plaintext parent PIN verifies once and migrates to hash',
      () async {
        await datasource.saveParentSettings(
          const ParentSettingsModel(pinHash: '1234'),
        );

        final verified = await repository.verifyParentPin('1234');
        final migrated = await datasource.getParentSettings();

        expect(verified.getOrElse(() => false), isTrue);
        expect(migrated.pinHash, isNot('1234'));
        expect(migrated.pinHash, hasLength(64));
        expect(
          (await repository.verifyParentPin('0000')).getOrElse(() => true),
          isFalse,
        );
      },
    );

    test(
      'selectMemorizationPath(adult) stores profile and legacy track',
      () async {
        final result = await repository.selectMemorizationPath(
          MemorizationPath.adult,
        );

        final profile = result.getOrElse(
          () => throw StateError('Expected adult profile selection to succeed'),
        );

        expect(profile.selectedPath, MemorizationPath.adult);
        expect(
          profile.guardianOnboardingStatus,
          GuardianOnboardingStatus.completed,
        );
        expect(profile.guardianLinkStatus, GuardianLinkStatus.none);
        expect(datasource.getSelectedTrack(), MemorizationTrack.adults.name);
      },
    );

    test(
      'selecting kids track creates a child profile without parent mode',
      () async {
        final result = await repository.saveSelectedTrack(
          MemorizationTrack.kids,
        );

        expect(result.isRight(), isTrue);
        expect(datasource.getSelectedTrack(), MemorizationTrack.kids.name);
        expect(datasource.getIsParentMode(), isFalse);

        final profile = await datasource.getMemorizationProfile();
        expect(profile.selectedPath, MemorizationPath.child);
        expect(
          profile.guardianOnboardingStatus,
          GuardianOnboardingStatus.required,
        );
      },
    );

    test(
      'migrates legacy Hifz backward path to skipped child profile',
      () async {
        await prefs.setString(AppConstants.kHifzPathMode, 'backward');

        final result = await repository.getMemorizationProfile();
        final profile = result.getOrElse(
          () =>
              throw StateError('Expected legacy profile migration to succeed'),
        );

        expect(profile.selectedPath, MemorizationPath.child);
        expect(
          profile.guardianOnboardingStatus,
          GuardianOnboardingStatus.skipped,
        );
        expect(
          (await datasource.getMemorizationProfile()).selectedPath,
          profile.selectedPath,
        );
      },
    );

    test(
      'continueWithoutGuardian preserves child path and skips re-prompting',
      () async {
        await repository.selectMemorizationPath(MemorizationPath.child);

        final result = await repository.continueWithoutGuardian();
        final profile = result.getOrElse(
          () => throw StateError('Expected guardian skip to succeed'),
        );

        expect(profile.selectedPath, MemorizationPath.child);
        expect(profile.guardianLinkStatus, GuardianLinkStatus.none);
        expect(
          profile.guardianOnboardingStatus,
          GuardianOnboardingStatus.skipped,
        );
      },
    );

    test('guest child cannot create guardian QR token or session', () async {
      await repository.selectMemorizationPath(MemorizationPath.child);

      final result = await repository.createGuardianPairingSession();
      final session = await datasource.getPairingSession();
      final profile = await datasource.getMemorizationProfile();

      expect(result.isLeft(), isTrue);
      expect(session, isNull);
      expect(profile.guardianLinkStatus, GuardianLinkStatus.none);
    });

    test(
      'refreshPairingSession expires stale pending sessions locally',
      () async {
        final now = DateTime.now();
        await datasource.saveMemorizationProfile(
          MemorizationProfileModel(
            schemaVersion: 1,
            selectedPath: MemorizationPath.child,
            guardianLinkStatus: GuardianLinkStatus.pending,
            guardianOnboardingStatus: GuardianOnboardingStatus.required,
            isParentGuardian: false,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await datasource.savePairingSession(
          PairingSessionModel(
            id: 'expired',
            pairingCode: '111222',
            qrData: 'talia-kids-link:111222',
            createdAt: now.subtract(const Duration(minutes: 20)),
            expiresAt: now.subtract(const Duration(minutes: 5)),
            status: PairingSessionStatus.pending,
            isUsed: false,
          ),
        );

        final result = await repository.refreshPairingSession();
        final session = result.getOrElse(
          () => throw StateError('Expected pairing refresh to succeed'),
        );
        final profile = await datasource.getMemorizationProfile();

        expect(session?.status, PairingSessionStatus.expired);
        expect(profile.guardianLinkStatus, GuardianLinkStatus.none);
        expect(
          profile.guardianOnboardingStatus,
          GuardianOnboardingStatus.required,
        );
      },
    );

    test(
      'reset identity preserves smart settings and review records',
      () async {
        await repository.selectMemorizationPath(MemorizationPath.child);
        await repository.saveSmartSettings(
          const SmartMemorizationSettings(
            dailySchedule: 'after-fajr',
            reviewDays: [1, 3],
            ayahIsolationEnabled: true,
          ),
        );
        await repository.markAyahMemorized(surahId: 114, ayahNumber: 1);
        await prefs.setString(AppConstants.kHifzPathMode, 'backward');

        final result = await repository.resetMemorizationIdentity();
        final profile = result.getOrElse(
          () => throw StateError('Expected identity reset to succeed'),
        );
        final settings = await datasource.getSmartSettings();
        final record = await datasource.getReviewRecord(114, 1);

        expect(profile.selectedPath, isNull);
        expect(datasource.getSelectedTrack(), isNull);
        expect(prefs.getString(AppConstants.kHifzPathMode), isNull);
        expect(settings.dailySchedule, 'after-fajr');
        expect(record, isNotNull);
      },
    );
  });
}

class _UnusedQuranRepository implements QuranRepository {
  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async =>
      Right(
        SurahDetail(
          surah: const Surah(
            id: 114,
            nameAr: 'الناس',
            nameEn: 'An-Nas',
            ayahCount: 6,
            juz: 30,
            type: 'meccan',
            page: 604,
          ),
          ayahs: List.generate(
            6,
            (index) => Ayah(
              number: index + 1,
              surahId: 114,
              text: 'آية ${index + 1}',
              numberInSurah: index + 1,
              juz: 30,
              page: 604,
            ),
          ),
        ),
      );

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) =>
      throw UnimplementedError();
}
