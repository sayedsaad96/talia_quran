import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import '../../../../../core/error/app_failure.dart';
import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../../core/memorization/review_record_filters.dart';
import '../../../../../core/progress/progress_changed_reason.dart';
import '../../../../../core/progress/progress_events_bus.dart';
import '../../../../../core/services/streak_reader.dart';
import '../../../../../core/sync/cloud_sync_queue.dart';
import '../../../../../core/security/parent_pin_secure_store.dart';
import '../../../../../core/security/parent_pin_verifier.dart';
import '../../../../quran/domain/repositories/quran_repository.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../models/memorization_models.dart';

/// Kids-mode local domain: progress, journey stages, session logs, parent
/// dashboard, settings, PIN, rewards and points awarding (with per-ayah
/// concurrency locks). All data lives in the local datasource; streaks are
/// hydrated from [StreakReader] as the single source of truth.
class MemorizationKidsLocalService {
  MemorizationKidsLocalService(
    this._datasource,
    this._quranRepository,
    this._streakReader,
    this._progressEvents,
    this._cloudSyncQueue, {
    ParentPinSecureStore? parentPinStore,
    RecordOwnerProvider owner = const SupabaseRecordOwnerProvider(),
  }) : _parentPinStore = parentPinStore ?? FlutterParentPinSecureStore(),
      _owner = owner;

  final MemorizationPlusLocalDatasource _datasource;
  final QuranRepository _quranRepository;
  final StreakReader _streakReader;
  final ProgressEventsBus _progressEvents;
  final CloudSyncQueue? _cloudSyncQueue;
  final ParentPinSecureStore _parentPinStore;
  final RecordOwnerProvider _owner;

  final Map<String, Future<void>> _kidsAwardLocks = {};

  /// Overlays [KidsProgress.currentStreak] from [StreakService] (single SSOT).
  Future<KidsProgress> _hydrateKidsStreak(KidsProgress progress) async {
    final streak = await _streakReader.getStreak();
    return progress.copyWith(currentStreak: streak.currentStreak);
  }

  /// Persists kids prefs without a local streak counter (streak lives in Isar).
  KidsProgress _kidsProgressForStorage(KidsProgress progress) =>
      progress.copyWith(currentStreak: 0);

  Future<Either<Failure, KidsProgress>> getKidsProgress() async {
    try {
      final progress = await _datasource.getKidsProgress();
      return Right(await _hydrateKidsStreak(progress));
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, void>> saveKidsProgress(KidsProgress progress) async {
    try {
      await _datasource.saveKidsProgress(
        KidsProgressModel.fromEntity(_kidsProgressForStorage(progress)),
      );
      await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.kidsProgressPush);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  /// Kids journey "needs review" when a completed stage has weak or overdue SRS.
  static bool _ayahNeedsKidsReview(AyahReviewRecord record) =>
      record.isDue || record.lastRating == PerformanceRating.weak;

  static bool _stageNeedsKidsReview({
    required int surahId,
    required List<int> ayahRange,
    required Map<String, AyahReviewRecord> kidsRecordsByKey,
  }) {
    for (final ayah in ayahRange) {
      final record = kidsRecordsByKey['${surahId}_$ayah'];
      if (record != null && _ayahNeedsKidsReview(record)) return true;
    }
    return false;
  }

  Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
    required int surahId,
  }) async {
    try {
      final logs = await _datasource.getKidsSessionLogs();
      final completed = logs
          .where((log) => log.surahId == surahId)
          .map((log) => log.ayahNumber)
          .toSet();

      final kidsRecords = await _datasource.getAllReviewRecords(
        scope: ReviewRecordReadScope.kids,
      );
      final kidsRecordsByKey = {
        for (final record in kidsRecords.where(
          (r) => r.surahId == surahId && ReviewRecordFilters.isKidsSource(r),
        ))
          record.key: record,
      };

      var totalAyahs = 7;
      final detailResult = await _quranRepository.getSurahDetail(surahId);
      detailResult.fold(
        (_) {},
        (detail) => totalAyahs = detail.surah.ayahCount,
      );

      const stageSize = 5;
      final stages = <KidsJourneyStage>[];
      var foundCurrent = false;
      for (var start = 1; start <= totalAyahs; start += stageSize) {
        final end = min(start + stageSize - 1, totalAyahs);
        final ayahRange = List<int>.generate(end - start + 1, (i) => start + i);
        final stageCompleted = ayahRange
            .where((ayah) => completed.contains(ayah))
            .toList();

        KidsJourneyStageStatus status;
        if (stageCompleted.length == ayahRange.length) {
          status =
              _stageNeedsKidsReview(
                surahId: surahId,
                ayahRange: ayahRange,
                kidsRecordsByKey: kidsRecordsByKey,
              )
              ? KidsJourneyStageStatus.needsReview
              : KidsJourneyStageStatus.completed;
        } else if (!foundCurrent) {
          status = KidsJourneyStageStatus.current;
          foundCurrent = true;
        } else {
          status = KidsJourneyStageStatus.locked;
        }

        stages.add(
          KidsJourneyStage(
            stageNumber: stages.length + 1,
            surahId: surahId,
            startAyah: start,
            endAyah: end,
            completedAyahs: stageCompleted,
            status: status,
          ),
        );
      }
      return Right(stages);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async {
    try {
      return Right(await _datasource.getKidsSessionLogs());
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, KidsSessionLog>> saveKidsSessionLog({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    required int pointsEarned,
  }) async {
    try {
      final logs = await _datasource.getKidsSessionLogs();
      KidsSessionLogModel? existing;
      for (final log in logs) {
        if (log.surahId == surahId && log.ayahNumber == ayahNumber) {
          existing = log;
          break;
        }
      }
      if (existing != null) return Right(existing);

      // UTC: consistent with all other review/session date fields.
      final now = DateTime.now().toUtc();
      final log = KidsSessionLogModel(
        id: '${now.microsecondsSinceEpoch}_${surahId}_$ayahNumber',
        surahId: surahId,
        ayahNumber: ayahNumber,
        repeatsCompleted: repeatsCompleted,
        pointsEarned: pointsEarned,
        completedAt: now,
      );
      await _datasource.saveKidsSessionLog(log);
      await _unlockWeeklyRewardIfNeeded();
      await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.kidsProgressPush);
      _progressEvents.notify(ProgressChangedReason.kidsProgress);
      return Right(log);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, ParentDashboard>> getParentDashboard({
    required int surahId,
  }) async {
    try {
      final progressResult = await getKidsProgress();
      final progress = progressResult.getOrElse(
        () => throw StateError('Expected kids progress'),
      );
      final logs = await _datasource.getKidsSessionLogs();
      final settings = await _datasource.getParentSettings();
      final rewards = await _datasource.getParentRewards();
      final journey = await getKidsJourney(surahId: surahId);
      final Either<Failure, ParentDashboard> result =
          journey.fold<Either<Failure, ParentDashboard>>(
        Left.new,
        (stages) => Right(
          ParentDashboard(
            progress: progress,
            stages: stages,
            logs: logs,
            rewards: rewards,
            settings: settings,
          ),
        ),
      );
      return result;
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, ParentSettings>> getParentSettings() async {
    try {
      return Right(await _datasource.getParentSettings());
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, void>> saveParentSettings(
    ParentSettings settings,
  ) async {
    try {
      await _datasource.saveParentSettings(
        ParentSettingsModel.fromEntity(settings),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, bool>> verifyParentPin(String pin) async {
    try {
      final settings = await _datasource.getParentSettings();
      final stored = settings.pinHash;
      final ownerId = _owner.currentOwnerId;
      final blockedUntil = await _parentPinStore.readBlockedUntil(ownerId);
      if (blockedUntil != null && blockedUntil.isAfter(DateTime.now().toUtc())) {
        return const Right(false);
      }
      final verifier = await _parentPinStore.readVerifier(ownerId);
      if (verifier != null) {
        return await _verifySecurePin(ownerId, pin, verifier);
      }
      if (_matchesLegacyPin(stored, pin)) {
        await _upgradeLegacyPin(ownerId, pin, settings);
        return const Right(true);
      }
      await _recordFailedPinAttempt(ownerId);
      return const Right(false);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, void>> setParentPin(String pin) async {
    try {
      final settings = await _datasource.getParentSettings();
      final ownerId = _owner.currentOwnerId;
      await _parentPinStore.writeVerifier(ownerId, ParentPinVerifier.create(pin));
      await _clearPinThrottle(ownerId);
      await _datasource.saveParentSettings(
        ParentSettingsModel.fromEntity(
          settings.copyWith(pinHash: _securePinMarker),
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, void>> resetParentAccess() async {
    try {
      final settings = await _datasource.getParentSettings();
      final ownerId = _owner.currentOwnerId;
      await _parentPinStore.clearVerifier(ownerId);
      await _clearPinThrottle(ownerId);
      await _datasource.saveParentSettings(
        ParentSettingsModel.fromEntity(
          settings.copyWith(clearPin: true, remoteLinkEnabled: false),
        ),
      );
      await _datasource.saveParentRewards(const []);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, List<ParentReward>>> saveParentReward(
    String title,
  ) async {
    try {
      final trimmed = title.trim();
      if (trimmed.isEmpty) {
        return const Left(CacheFailure('اكتب اسم المكافأة أولاً'));
      }
      final rewards = await _datasource.getParentRewards();
      if (rewards.length >= 3) {
        return const Left(CacheFailure('يمكن إضافة 3 مكافآت فقط'));
      }
      final reward = ParentRewardModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: trimmed,
        status: ParentRewardStatus.locked,
        createdAt: DateTime.now(),
      );
      final next = [...rewards, reward];
      await _datasource.saveParentRewards(next);
      return Right(next);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, List<ParentReward>>> claimParentReward(
    String id,
  ) async {
    try {
      final rewards = await _datasource.getParentRewards();
      final next = rewards
          .map(
            (reward) => reward.id == id
                ? ParentRewardModel.fromEntity(
                    reward.copyWith(
                      status: ParentRewardStatus.claimed,
                      claimedAt: DateTime.now(),
                    ),
                  )
                : reward,
          )
          .toList();
      await _datasource.saveParentRewards(next);
      return Right(next);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, KidsCompletionResult>> awardKidsPoints({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
  }) => _withKidsAwardLock(surahId, ayahNumber, () async {
    try {
      final current = await _datasource.getKidsProgress();
      final logs = await _datasource.getKidsSessionLogs();
      final alreadyCompleted = logs.any(
        (log) => log.surahId == surahId && log.ayahNumber == ayahNumber,
      );
      if (alreadyCompleted) {
        return Right(
          KidsCompletionResult(
            progress: await _hydrateKidsStreak(current),
            pointsEarned: 0,
            starsEarned: 0,
            alreadyCompleted: true,
          ),
        );
      }

      // Points: 10 base + 2 per extra repeat
      final points = 10 + ((repeatsCompleted - 1) * 2).clamp(0, 20);
      final updated = current.addPoints(points);
      await _datasource.saveKidsProgress(
        KidsProgressModel.fromEntity(_kidsProgressForStorage(updated)),
      );
      final logResult = await saveKidsSessionLog(
        surahId: surahId,
        ayahNumber: ayahNumber,
        repeatsCompleted: repeatsCompleted,
        pointsEarned: points,
      );
      final logFailure = logResult.fold((failure) => failure, (_) => null);
      if (logFailure != null) return Left(logFailure);

      return Right(
        KidsCompletionResult(
          progress: await _hydrateKidsStreak(updated),
          pointsEarned: points,
          starsEarned: updated.starsEarned - current.starsEarned,
          alreadyCompleted: false,
        ),
      );
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  });

  Future<T> _withKidsAwardLock<T>(
    int surahId,
    int ayahNumber,
    Future<T> Function() action,
  ) async {
    final key = '${surahId}_$ayahNumber';
    final previous = _kidsAwardLocks[key];
    final completer = Completer<void>();
    final current = previous == null
        ? completer.future
        : previous.catchError((_) {}).then((_) => completer.future);
    _kidsAwardLocks[key] = current;

    if (previous != null) {
      try {
        await previous;
      } catch (_) {}
    }

    try {
      return await action();
    } finally {
      completer.complete();
      if (_kidsAwardLocks[key] == current) {
        unawaited(_kidsAwardLocks.remove(key));
      }
    }
  }

  String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  static const _securePinMarker = 'secure-v2';

  Future<Either<Failure, bool>> _verifySecurePin(
    String ownerId,
    String pin,
    String verifier,
  ) async {
    if (ParentPinVerifier.verify(pin, verifier)) {
      await _clearPinThrottle(ownerId);
      return const Right(true);
    }
    await _recordFailedPinAttempt(ownerId);
    return const Right(false);
  }

  bool _matchesLegacyPin(String? stored, String pin) =>
      stored == _hashPin(pin) || (_isLegacyPlaintextPin(stored) && stored == pin);

  Future<void> _upgradeLegacyPin(
    String ownerId,
    String pin,
    ParentSettings settings,
  ) async {
    await _parentPinStore.writeVerifier(ownerId, ParentPinVerifier.create(pin));
    await _clearPinThrottle(ownerId);
    await _datasource.saveParentSettings(
      ParentSettingsModel.fromEntity(settings.copyWith(pinHash: _securePinMarker)),
    );
  }

  Future<void> _recordFailedPinAttempt(String ownerId) async {
    final failures = await _parentPinStore.readFailureCount(ownerId) + 1;
    final delaySeconds = min(60, 1 << min(6, failures));
    await _parentPinStore.writeFailureCount(ownerId, failures);
    await _parentPinStore.writeBlockedUntil(
      ownerId,
      DateTime.now().toUtc().add(Duration(seconds: delaySeconds)),
    );
  }

  Future<void> _clearPinThrottle(String ownerId) async {
    await _parentPinStore.writeFailureCount(ownerId, 0);
    await _parentPinStore.writeBlockedUntil(ownerId, null);
  }

  bool _isLegacyPlaintextPin(String? value) {
    return value != null && value.length == 4 && int.tryParse(value) != null;
  }

  Future<void> _unlockWeeklyRewardIfNeeded() async {
    final logs = await _datasource.getKidsSessionLogs();
    final settings = await _datasource.getParentSettings();
    final rewards = await _datasource.getParentRewards();
    if (rewards.isEmpty ||
        rewards.every((r) => r.status != ParentRewardStatus.locked)) {
      return;
    }
    // P1-06 FIX: Use UTC to match completedAt (stored as UTC at line ~883).
    // Mixing local weekStart with UTC logs shifted week boundaries by the
    // timezone offset (e.g. UTC+3 in Egypt).
    final now = DateTime.now().toUtc();
    final weekStart = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final sessionsThisWeek = logs
        .where((log) => !log.completedAt.isBefore(weekStart))
        .length;
    if (sessionsThisWeek < settings.weeklyGoalSessions) return;

    var unlockedOne = false;
    final next = rewards.map((reward) {
      if (!unlockedOne && reward.status == ParentRewardStatus.locked) {
        unlockedOne = true;
        return ParentRewardModel.fromEntity(
          reward.copyWith(
            status: ParentRewardStatus.unlocked,
            unlockedAt: DateTime.now().toUtc(),
          ),
        );
      }
      return reward;
    }).toList();
    await _datasource.saveParentRewards(next);
  }
}
