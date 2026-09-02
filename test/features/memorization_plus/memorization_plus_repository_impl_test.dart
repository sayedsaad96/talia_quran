import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/constants/app_constants.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/progress_metrics.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/core/memorization/kids_hifz_feature_flags.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/core/security/parent_pin_secure_store.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

void main() {
  group('MemorizationPlusRepositoryImpl', () {
    late MemorizationPlusLocalDatasourceImpl datasource;
    late MemorizationPlusRepositoryImpl repository;
    late SharedPreferences prefs;
    late _FakeStreakReader streakReader;
    late _MemoryParentPinStore parentPinStore;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      datasource = MemorizationPlusLocalDatasourceImpl(prefs);
      streakReader = _FakeStreakReader(currentStreak: 5);
      parentPinStore = _MemoryParentPinStore();
      repository = MemorizationPlusRepositoryImpl(
        datasource,
        _UnusedQuranRepository(),
        streakReader,
        ProgressEventsBus(),
        prefs,
        parentPinStore: parentPinStore,
      );
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

    test(
      'getKidsJourney uses a three-ayah stage for ages five to seven',
      () async {
        final now = DateTime.now().toUtc();
        await datasource.saveMemorizationProfile(
          MemorizationProfileModel(
            schemaVersion: 1,
            selectedPath: MemorizationPath.child,
            guardianLinkStatus: GuardianLinkStatus.none,
            guardianOnboardingStatus: GuardianOnboardingStatus.completed,
            isParentGuardian: false,
            createdAt: now,
            updatedAt: now,
            childAge: 6,
          ),
        );

        final result = await repository.getKidsJourney(surahId: 114);
        final stages = result.getOrElse(
          () => throw StateError('Expected journey generation to succeed'),
        );

        expect(stages, hasLength(2));
        expect(stages.first.endAyah, 3);
        expect(stages[1].startAyah, 4);
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

    test(
      'saveKidsSessionLog persists learning metrics without speech',
      () async {
        final result = await repository.saveKidsSessionLog(
          sessionId: 'session-114-1',
          surahId: 114,
          ayahNumber: 1,
          repeatsCompleted: 1,
          pointsEarned: 10,
          missionType: KidsMissionType.newMemorization,
          ayahNumbers: const [1],
          durationSeconds: 92,
          attemptCount: 2,
          hintCount: 1,
          masteryRating: PerformanceRating.average,
        );

        final log = result.getOrElse(
          () => throw StateError('Expected metric session log to save'),
        );

        expect(log.id, 'session-114-1');
        expect(log.durationSeconds, 92);
        expect(log.attemptCount, 2);
        expect(log.hintCount, 1);
        expect(log.masteryRating, PerformanceRating.average);
        expect(log.ayahNumbers, const [1]);
      },
    );

    test('a due review is logged without granting a second reward', () async {
      final first = await repository.awardKidsPoints(
        sessionId: 'new-114-1',
        surahId: 114,
        ayahNumber: 1,
        repeatsCompleted: 1,
        masteryRating: PerformanceRating.excellent,
      );
      final review = await repository.awardKidsPoints(
        sessionId: 'review-114-1',
        surahId: 114,
        ayahNumber: 1,
        repeatsCompleted: 1,
        missionType: KidsMissionType.dueReview,
        durationSeconds: 45,
        attemptCount: 2,
        masteryRating: PerformanceRating.average,
      );

      final firstResult = first.getOrElse(
        () => throw StateError('Expected first completion to succeed'),
      );
      final reviewResult = review.getOrElse(
        () => throw StateError('Expected due review to succeed'),
      );
      final progress = await datasource.getKidsProgress();
      final logs = await datasource.getKidsSessionLogs();

      expect(firstResult.starsEarned, 3);
      expect(reviewResult.alreadyCompleted, isTrue);
      expect(reviewResult.pointsEarned, 0);
      expect(reviewResult.starsEarned, 0);
      expect(progress.totalPoints, 10);
      expect(progress.starsEarned, 3);
      expect(logs, hasLength(2));
      final reviewLog = logs.singleWhere((log) => log.id == 'review-114-1');
      expect(reviewLog.missionType, KidsMissionType.dueReview);
      expect(reviewLog.pointsEarned, 0);
      expect(reviewLog.masteryRating, PerformanceRating.average);
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
      expect(firstResult.pointsEarned, 10);
      expect(firstResult.starsEarned, 3);
      expect(replayResult.alreadyCompleted, isTrue);
      expect(replayResult.pointsEarned, 0);
      expect(replayResult.starsEarned, 0);
      expect(progress.totalPoints, 10);
      expect(progress.starsEarned, 3);
      expect(progress.ayahsCompleted, 1);
      expect(logs, hasLength(1));
    });

    test(
      'getKidsProgress hydrates streak from StreakService not SharedPrefs',
      () async {
        await datasource.saveKidsProgress(
          const KidsProgressModel(
            totalPoints: 20,
            currentLevel: 1,
            currentStreak: 99,
            starsEarned: 2,
            ayahsCompleted: 2,
            lastSessionAt: null,
          ),
        );
        streakReader.currentStreak = 5;

        final progress = (await repository.getKidsProgress()).getOrElse(
          () => throw StateError('Expected kids progress'),
        );

        expect(progress.currentStreak, 5);
      },
    );

    test(
      'awardKidsPoints does not persist a local streak counter in prefs',
      () async {
        streakReader.currentStreak = 4;

        await repository.awardKidsPoints(
          surahId: 114,
          ayahNumber: 1,
          repeatsCompleted: 3,
        );

        final stored = await datasource.getKidsProgress();
        expect(stored.currentStreak, 0);

        final hydrated = (await repository.getKidsProgress()).getOrElse(
          () => throw StateError('Expected kids progress'),
        );
        expect(hydrated.currentStreak, 4);
      },
    );

    test(
      'kids session log drives journey while kidsMode records feed kids metrics only',
      () async {
        await repository.saveKidsSessionLog(
          surahId: 114,
          ayahNumber: 1,
          repeatsCompleted: 3,
          pointsEarned: 14,
        );
        await repository.saveReviewRecord(
          AyahReviewRecord(
            surahId: 114,
            ayahNumber: 1,
            strengthLevel: 6,
            intervalDays: 30,
            lastReviewedAt: DateTime.utc(2026, 1, 1),
            nextReviewDate: DateTime.utc(2026, 2, 1),
            totalReviews: 1,
            lastRating: PerformanceRating.excellent,
            createdByMode: ReviewRecordCreatedByMode.kidsMode,
          ),
        );

        final stages = (await repository.getKidsJourney(
          surahId: 114,
        )).getOrElse(() => throw StateError('Expected journey'));
        expect(stages.first.status, KidsJourneyStageStatus.current);

        const metrics = ProgressMetricsService();
        final records = await datasource.getAllReviewRecords(
          includeAllAudiences: true,
        );
        final adult = metrics.calculate(
          records: records,
          now: DateTime.utc(2026, 6, 1),
          audience: ProgressAudience.adult,
        );
        final kids = metrics.calculate(
          records: records,
          now: DateTime.utc(2026, 6, 1),
          audience: ProgressAudience.kids,
        );

        expect(adult.memorizedAyahs, 0);
        expect(kids.memorizedAyahs, 1);
      },
    );

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
        10,
      );
      expect(
        completions.fold<int>(0, (sum, result) => sum + result.starsEarned),
        3,
      );
      expect(progress.totalPoints, 10);
      expect(progress.starsEarned, 3);
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

    test(
      'parent settings synchronize kids reminder and V2 feature keys',
      () async {
        final result = await repository.saveParentSettings(
          const ParentSettings(
            reminderEnabled: true,
            reminderHour: 17,
            reminderMinute: 25,
            kidsHifzV2Enabled: true,
          ),
        );

        expect(result.isRight(), isTrue);
        expect(
          prefs.getBool(TaliaNotificationService.kidsReminderPreferenceKey),
          isTrue,
        );
        expect(
          prefs.getInt(
            '${TaliaNotificationService.kidsReminderPreferenceKey}_hour',
          ),
          17,
        );
        expect(
          prefs.getInt(
            '${TaliaNotificationService.kidsReminderPreferenceKey}_minute',
          ),
          25,
        );
        expect(prefs.getBool(KidsHifzFeatureFlags.enabledKey), isTrue);
      },
    );

    test('parent settings and rewards are stored locally', () async {
      await repository.setParentPin('1234');
      final verified = await repository.verifyParentPin('1234');
      final rewards = await repository.saveParentReward('نزهة قصيرة');
      final settings = await datasource.getParentSettings();

      expect(verified.getOrElse(() => false), isTrue);
      expect(settings.pinHash, isNot('1234'));
      expect(settings.pinHash, 'secure-v2');
      expect(
        await parentPinStore.readVerifier('local'),
        startsWith('pbkdf2-sha256\$'),
      );
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
        expect(migrated.pinHash, 'secure-v2');
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

    // ─── Phase 7: Production sync (Parent Mode completion) ────────────────────
    //
    // Supabase.instance is never initialized in the unit-test environment,
    // so `_isSupabaseReady` is always false here. This exercises the
    // "best-effort" contract: cloud-touching calls must never throw and
    // must degrade gracefully instead of blocking/failing local operations.

    test(
      'saveReviewRecord succeeds locally even when cloud is unavailable',
      () async {
        final record = AyahReviewRecordModel.initial(
          114,
          1,
        ).copyWith(createdByMode: ReviewRecordCreatedByMode.v2Session);

        final result = await repository.saveReviewRecord(record);

        expect(result.isRight(), isTrue);
        expect(await datasource.getReviewRecord(114, 1), isNotNull);
      },
    );

    test(
      'resyncProductionDataToCloud is a no-op success when cloud is unavailable',
      () async {
        await datasource.saveReviewRecord(
          AyahReviewRecordModel.fromEntity(
            AyahReviewRecordModel.initial(
              114,
              1,
            ).copyWith(createdByMode: ReviewRecordCreatedByMode.v2Session),
          ),
        );

        final result = await repository.resyncProductionDataToCloud();

        expect(result.isRight(), isTrue);
      },
    );

    test(
      'pushCertificatesToCloud is a no-op success for an empty list',
      () async {
        final result = await repository.pushCertificatesToCloud(const []);

        expect(result.isRight(), isTrue);
      },
    );

    test(
      'revokeGuardianLink fails with NetworkFailure when cloud is unavailable',
      () async {
        final result = await repository.revokeGuardianLink('parent-1');

        expect(result.isLeft(), isTrue);
        expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
      },
    );

    test('removeChild delegates to revokeGuardianLink', () async {
      final result = await repository.removeChild('child-1');

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
    });

    test(
      'unlinkGuardian preserves the local link when server revocation fails',
      () async {
        final now = DateTime.now();
        await datasource.saveMemorizationProfile(
          MemorizationProfileModel(
            schemaVersion: 1,
            selectedPath: MemorizationPath.child,
            guardianLinkStatus: GuardianLinkStatus.linked,
            guardianOnboardingStatus: GuardianOnboardingStatus.completed,
            guardianId: 'parent-1',
            isParentGuardian: false,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final result = await repository.unlinkGuardian();
        final profile = await datasource.getMemorizationProfile();

        expect(
          result.isLeft(),
          isTrue,
          reason:
              'The server must never disagree with what the child device '
              'believes about the link (Phase 5) — a failed revocation must '
              'not silently clear the local link.',
        );
        expect(profile.guardianLinkStatus, GuardianLinkStatus.linked);
        expect(profile.guardianId, 'parent-1');
      },
    );

    test(
      'unlinkGuardian preserves a linked profile when counterpart id is missing',
      () async {
        final now = DateTime.now();
        await datasource.saveMemorizationProfile(
          MemorizationProfileModel(
            schemaVersion: 1,
            selectedPath: MemorizationPath.child,
            guardianLinkStatus: GuardianLinkStatus.linked,
            guardianOnboardingStatus: GuardianOnboardingStatus.completed,
            isParentGuardian: false,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final result = await repository.unlinkGuardian();
        final profile = await datasource.getMemorizationProfile();

        expect(result.isLeft(), isTrue);
        expect(profile.guardianLinkStatus, GuardianLinkStatus.linked);
        expect(profile.guardianId, isNull);
      },
    );

    test(
      'unlinkGuardian clears the local profile when there is no guardian to revoke',
      () async {
        final now = DateTime.now();
        await datasource.saveMemorizationProfile(
          MemorizationProfileModel(
            schemaVersion: 1,
            selectedPath: MemorizationPath.child,
            guardianLinkStatus: GuardianLinkStatus.none,
            guardianOnboardingStatus: GuardianOnboardingStatus.completed,
            isParentGuardian: false,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final result = await repository.unlinkGuardian();

        expect(result.isRight(), isTrue);
        expect(
          result
              .getOrElse(() => throw StateError('expected profile'))
              .guardianLinkStatus,
          GuardianLinkStatus.none,
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
        await datasource.saveReviewRecord(
          AyahReviewRecordModel.fromEntity(
            AyahReviewRecordModel.initial(
              114,
              1,
            ).copyWith(createdByMode: ReviewRecordCreatedByMode.v2Session),
          ),
        );
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

class _MemoryParentPinStore implements ParentPinSecureStore {
  final Map<String, String> _verifiers = {};
  final Map<String, DateTime> _blockedUntil = {};
  final Map<String, int> _failures = {};

  @override
  Future<void> clearVerifier(String ownerId) async {
    _verifiers.remove(ownerId);
  }

  @override
  Future<DateTime?> readBlockedUntil(String ownerId) async =>
      _blockedUntil[ownerId];

  @override
  Future<int> readFailureCount(String ownerId) async => _failures[ownerId] ?? 0;

  @override
  Future<String?> readVerifier(String ownerId) async => _verifiers[ownerId];

  @override
  Future<void> writeBlockedUntil(String ownerId, DateTime? blockedUntil) async {
    if (blockedUntil == null) {
      _blockedUntil.remove(ownerId);
    } else {
      _blockedUntil[ownerId] = blockedUntil;
    }
  }

  @override
  Future<void> writeFailureCount(String ownerId, int count) async {
    _failures[ownerId] = count;
  }

  @override
  Future<void> writeVerifier(String ownerId, String verifier) async {
    _verifiers[ownerId] = verifier;
  }
}

class _FakeStreakReader implements StreakReader {
  _FakeStreakReader({this.currentStreak = 0});

  int currentStreak;

  @override
  Future<StreakEntity> getStreak() async =>
      StreakEntity(currentStreak: currentStreak, longestStreak: currentStreak);
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
