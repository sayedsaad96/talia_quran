import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/error/app_failure.dart';
import '../../../../../core/l10n/cubit_message_codes.dart';
import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/identity/account_data_barrier.dart';
import '../../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../../core/memorization/review_record_filters.dart';
import '../../../../../core/memorization/kids_progress_cloud_merge.dart';
import '../../../../../core/progress/progress_changed_reason.dart';
import '../../../../../core/progress/progress_events_bus.dart';
import '../../../../../core/services/streak_reader.dart';
import '../../../../../core/sync/cloud_sync_queue.dart';
import '../../../../../core/utils/talia_logger.dart';
import '../../../../../core/security/parent_pin_secure_store.dart';
import '../../../../../core/security/parent_pin_verifier.dart';
import '../../../../quran/domain/repositories/quran_repository.dart';
import '../../../domain/entities/kids_home_mission.dart';
import '../../../domain/entities/kids_journey_path_definition.dart';
import '../../../domain/entities/kids_legacy_resume_recovery.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../../domain/services/kids_due_review_policy.dart';
import '../../../domain/services/kids_house_review_policy.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../models/memorization_models.dart';
import 'kids_legacy_resume_recovery_probe.dart';

bool _quranJourneyOff() => false;

bool _promiseOn() => true;

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
    this._owner = const SupabaseRecordOwnerProvider(),
    this._quranJourneyEnabled = _quranJourneyOff,
    this._remotePlanEnabled,
    this._remoteMilestoneUnlock,
    this._remoteMilestoneEnabled,
    this._barrier,
    this._legacyResumeProbe,
    this._promiseEnabled = _promiseOn,
  }) : _parentPinStore = parentPinStore ?? FlutterParentPinSecureStore();

  final MemorizationPlusLocalDatasource _datasource;
  final QuranRepository _quranRepository;
  final StreakReader _streakReader;
  final ProgressEventsBus _progressEvents;
  final CloudSyncQueue? _cloudSyncQueue;
  final ParentPinSecureStore _parentPinStore;
  final RecordOwnerProvider _owner;
  final bool Function() _quranJourneyEnabled;
  final bool Function()? _remotePlanEnabled;
  final Future<void> Function(int surahId)? _remoteMilestoneUnlock;
  final bool Function()? _remoteMilestoneEnabled;
  final AccountDataBarrier? _barrier;
  final KidsLegacyResumeProbe? _legacyResumeProbe;

  /// Whether surah-linked gifts keep their condition. With the feature off a
  /// milestone gift behaves as a plain gift, so it can never be stranded
  /// locked with no way to open it.
  final bool Function() _promiseEnabled;

  final Map<String, Future<void>> _kidsAwardLocks = {};

  /// Base reward for a newly memorized ayah.
  static const kKidsBasePoints = 10;

  /// Excellence bonus on top of [kKidsBasePoints]: a first-try, hint-free,
  /// excellent recitation of a new ayah.
  static const kKidsExcellenceBonus = 5;

  /// Reduced reward for completing a due/linked/resumed review — review
  /// days are real work and must show visible progress, never a dead
  /// zero-point day.
  static const kKidsReviewPoints = 5;

  /// A surah of at most this many ayahs may be memorized as one whole house.
  static const kKidsWholeSurahMaxAyahs = kKidsWholeSurahMaxAyahsLimit;

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
      final progress = await _reconcileKidsProjection();
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
      KidsDueReviewPolicy.isDue(record, DateTime.now());

  /// The stage's most overdue ayah (earliest review date among its due
  /// records), or null when nothing in it is due. A stage "needs review"
  /// exactly when this is non-null, and its review opens this ayah (K30).
  static int? _mostOverdueKidsAyah({
    required int surahId,
    required List<int> ayahRange,
    required Map<String, AyahReviewRecord> kidsRecordsByKey,
  }) {
    AyahReviewRecord? mostOverdue;
    for (final ayah in ayahRange) {
      final record = kidsRecordsByKey['${surahId}_$ayah'];
      if (record == null || !_ayahNeedsKidsReview(record)) continue;
      if (mostOverdue == null ||
          record.nextReviewDate.isBefore(mostOverdue.nextReviewDate)) {
        mostOverdue = record;
      }
    }
    return mostOverdue?.ayahNumber;
  }

  Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
    required int surahId,
    bool freezeForSession = false,
  }) async {
    try {
      final ownerId = _owner.currentOwnerId;
      final lease = _barrier?.capture();
      if (freezeForSession && lease == null) throw const CacheFailure();
      final logs = await _datasource.getKidsSessionLogs();
      final completed = logs
          .where(
            (log) =>
                log.surahId == surahId &&
                KidsSessionLogsCloudMerge.isCanonicalRewardLog(log),
          )
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

      final detailResult = await _quranRepository.getSurahDetail(surahId);
      final detail = detailResult.fold((failure) => null, (detail) => detail);
      if (detail == null ||
          detail.surah.id != surahId ||
          detail.surah.ayahCount < 1 ||
          detail.ayahs.length != detail.surah.ayahCount ||
          detail.ayahs.map((ayah) => ayah.numberInSurah).toSet().length !=
              detail.surah.ayahCount ||
          detail.ayahs.any(
            (ayah) =>
                ayah.surahId != surahId ||
                ayah.numberInSurah < 1 ||
                ayah.numberInSurah > detail.surah.ayahCount,
          )) {
        return const Left(CacheFailure());
      }
      final totalAyahs = detail.surah.ayahCount;

      final profile = await _datasource.getMemorizationProfile();
      _ensureKidsAuthority(ownerId, lease);
      final stageSize = await _houseSize(
        surahId,
        logs,
        profile.childAge,
        ownerId,
        ayahCount: totalAyahs,
        freezeForSession: freezeForSession,
        lease: lease,
      );
      final settings = await _datasource.getParentSettings();
      final blockedByEarlierSurah = await _earlierHouseUnfinished(
        surahId,
        logs,
        settings,
        profile.childAge,
        ownerId,
      );
      _ensureKidsAuthority(ownerId, lease);
      final stages = <KidsJourneyStage>[];
      var foundCurrent = blockedByEarlierSurah;
      for (var start = 1; start <= totalAyahs; start += stageSize) {
        final end = min(start + stageSize - 1, totalAyahs);
        final ayahRange = List<int>.generate(end - start + 1, (i) => start + i);
        final stageCompleted = ayahRange
            .where((ayah) => completed.contains(ayah))
            .toList();

        KidsJourneyStageStatus status;
        int? reviewAyah;
        final pendingHouseReviewAyahs = KidsHouseReviewPolicy.pendingAyahs(
          logs,
          surahId,
          ayahRange,
        );
        if (foundCurrent) {
          status = KidsJourneyStageStatus.locked;
        } else if (stageCompleted.length == ayahRange.length &&
            pendingHouseReviewAyahs.isNotEmpty) {
          status = KidsJourneyStageStatus.needsReview;
          reviewAyah = pendingHouseReviewAyahs.first;
          foundCurrent = true;
        } else if (stageCompleted.length == ayahRange.length) {
          reviewAyah = _mostOverdueKidsAyah(
            surahId: surahId,
            ayahRange: ayahRange,
            kidsRecordsByKey: kidsRecordsByKey,
          );
          status = reviewAyah != null
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
            reviewAyah: reviewAyah,
            requiresHouseReview:
                status != KidsJourneyStageStatus.locked &&
                pendingHouseReviewAyahs.isNotEmpty,
            pendingHouseReviewAyahs: pendingHouseReviewAyahs,
          ),
        );
      }
      return Right(stages);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(CacheFailure.from(e));
    }
  }

  Future<int> _houseSize(
    int surahId,
    List<KidsSessionLog> logs,
    int? age,
    String ownerId, {
    required int ayahCount,
    required bool freezeForSession,
    AccountDataLease? lease,
  }) async {
    final settings = await _datasource.getParentSettings();
    _ensureKidsAuthority(ownerId, lease);
    // "Whole" is checked first, so a stray size key never overrides it and
    // nothing is frozen for a whole surah.
    if (settings.kidsWholeSurahIds.contains(surahId) &&
        ayahCount <= kKidsWholeSurahMaxAyahs) {
      return ayahCount;
    }
    final frozen = sanitizeKidsAyahsPerHouse(
      settings.kidsHouseSizesBySurah[surahId],
    );
    if (frozen != null) return frozen;
    final ageDefault = KidsSessionPolicy.forChildAge(age).journeyStageSize;
    if (logs.any(
      (log) =>
          log.surahId == surahId &&
          KidsSessionLogsCloudMerge.isCanonicalRewardLog(log),
    )) {
      final saved = await _freezeHouseSize(
        surahId, ageDefault, ownerId, lease: lease,
      );
      return _frozenWinner(saved, surahId, ayahCount);
    }
    final unknownPartition = await _requireLegacySplitChoice(
      surahId: surahId,
      ownerId: ownerId,
      lease: lease,
      ayahCount: ayahCount,
      safeDefault: sanitizeKidsAyahsPerHouse(settings.kidsAyahsPerHouse) ??
          ageDefault,
      freezeForSession: freezeForSession,
    );
    if (unknownPartition) {
      return sanitizeKidsAyahsPerHouse(settings.kidsAyahsPerHouse) ?? ageDefault;
    }
    final remote = _remotePlanEnabled?.call() == true
        ? settings.remotePlan.ayahsPerSession
        : null;
    final selected = sanitizeKidsAyahsPerHouse(remote) ??
        sanitizeKidsAyahsPerHouse(settings.kidsAyahsPerHouse) ??
        ageDefault;
    if (!freezeForSession) return selected;
    final saved = await _freezeHouseSize(
      surahId, selected, ownerId, lease: lease,
    );
    return _frozenWinner(saved, surahId, ayahCount);
  }

  Future<bool> _requireLegacySplitChoice({
    required int surahId,
    required String ownerId,
    required AccountDataLease? lease,
    required int ayahCount,
    required int safeDefault,
    required bool freezeForSession,
  }) async {
    if (lease == null) return false;
    final probe = _legacyResumeProbe;
    if (probe == null) return false;
    final result = await probe.inspect(surahId: surahId, lease: lease);
    _ensureKidsAuthority(ownerId, lease);
    switch (result) {
      case KidsLegacyResumeProbeChoiceRequired(:final checkpointAyah):
        if (checkpointAyah < 1 || checkpointAyah > ayahCount) return false;
        if (!freezeForSession) return true;
        throw KidsSplitChoiceRequiredFailure(
          KidsLegacyResumeRecoveryTicket(
            ownerId: ownerId,
            lease: lease,
            surahId: surahId,
            verifiedAyahCount: ayahCount,
            defaultStageSize: safeDefault,
            checkpointAyah: checkpointAyah,
          ),
        );
      case KidsLegacyResumeProbeUnavailable():
        // An unreadable checkpoint never blocks the child's session: use the
        // safe default unfrozen, exactly as before the probe existed.
        return true;
      case KidsLegacyResumeProbeNone():
        return false;
    }
  }

  int _frozenWinner(ParentSettings settings, int surahId, int ayahCount) {
    if (settings.kidsWholeSurahIds.contains(surahId) &&
        ayahCount <= kKidsWholeSurahMaxAyahs) {
      return ayahCount;
    }
    final size = sanitizeKidsAyahsPerHouse(
      settings.kidsHouseSizesBySurah[surahId],
    );
    if (size == null) throw const CacheFailure();
    return size;
  }

  Future<bool> _earlierHouseUnfinished(
    int target,
    List<KidsSessionLog> logs,
    ParentSettings settings,
    int? age,
    String ownerId,
  ) async {
    final journeyPath = resolveKidsJourneyPath(
      storedPathId: settings.kidsJourneyPathId,
      quranJourneyEnabled: _quranJourneyEnabled(),
    );
    if (!journeyPath.locksAhead) return false;
    const path = KidsJourneyPath.surahIds;
    // A house the child already started stays accessible: its earned stages
    // never relock, even if an earlier house is unfinished (legacy frontier,
    // or a guardian moving the starting surah). Pending house recitations
    // elsewhere are still enforced by the mandatory-mission routing
    // (MemorizationNavigationResolver._mandatoryKidsHouseSurah): the Quran
    // journey scans its whole path; the adventure scans its own order from
    // the starting surah, then started surahs off the adventure path.
    final targetAlreadyStarted = logs.any(
      (log) =>
          log.surahId == target &&
          KidsSessionLogsCloudMerge.isCanonicalRewardLog(log),
    );
    if (targetAlreadyStarted) return false;
    final targetIndex = path.indexOf(target);
    final firstIndex = path.indexOf(settings.startingSurahId);
    if (targetIndex < 0 || firstIndex < 0 || targetIndex <= firstIndex) {
      return false;
    }
    for (final id in path.sublist(firstIndex, targetIndex)) {
      final passed = logs
          .where(
            (log) =>
                log.surahId == id &&
                KidsSessionLogsCloudMerge.isCanonicalRewardLog(log),
          )
          .map((log) => log.ayahNumber)
          .toSet();
      if (passed.isEmpty) return true;
      final outcome = await _quranRepository.getSurahDetail(id);
      final detail = outcome.fold(
        (failure) => throw failure,
        (detail) => detail,
      );
      if (detail.surah.id != id ||
          detail.surah.ayahCount < 1 ||
          detail.ayahs.length != detail.surah.ayahCount ||
          detail.ayahs.map((ayah) => ayah.numberInSurah).toSet().length !=
              detail.surah.ayahCount ||
          detail.ayahs.any(
            (ayah) =>
                ayah.surahId != id ||
                ayah.numberInSurah < 1 ||
                ayah.numberInSurah > detail.surah.ayahCount,
          )) {
        throw const CacheFailure();
      }
      if (detail.ayahs.any((ayah) => !passed.contains(ayah.numberInSurah))) {
        return true;
      }
      final size = await _houseSize(
        id,
        logs,
        age,
        ownerId,
        ayahCount: detail.surah.ayahCount,
        freezeForSession: false,
        lease: null,
      );
      for (var start = 1; start <= detail.surah.ayahCount; start += size) {
        final range = [
          for (
            var ayah = start;
            ayah <= min(start + size - 1, detail.surah.ayahCount);
            ayah++
          )
            ayah,
        ];
        if (KidsHouseReviewPolicy.pendingAyahs(logs, id, range).isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  Future<ParentSettings> _freezeHouseSize(
    int surahId,
    int size,
    String ownerId, {
    AccountDataLease? lease,
  }
  ) async {
    _ensureKidsAuthority(ownerId, lease);
    Future<ParentSettings> write() => _datasource.updateKidsHouseSettings((current) {
      _ensureKidsAuthority(ownerId, lease);
      if (current.kidsWholeSurahIds.contains(surahId) ||
          current.kidsHouseSizesBySurah.containsKey(surahId)) {
        return current;
      }
      return current.copyWith(
        kidsHouseSizesBySurah: {
          surahId: size,
          ...current.kidsHouseSizesBySurah,
        },
      );
    });
    final barrier = _barrier;
    final saved = lease == null || barrier == null
        ? await write()
        : await barrier.run((_) => write(), authority: lease);
    _ensureKidsAuthority(ownerId, lease);
    return saved;
  }

  void _ensureKidsAuthority(String ownerId, AccountDataLease? lease) {
    _ensureKidsOwner(ownerId);
    lease?.checkOwner(ownerId);
  }

  Future<Either<Failure, ParentSettings>> setKidsAyahsPerHouse(
    int? count,
  ) async {
    if (count != null && sanitizeKidsAyahsPerHouse(count) == null) {
      return const Left(ValidationFailure());
    }
    try {
      final ownerId = _owner.currentOwnerId;
      final logs = await _datasource.getKidsSessionLogs();
      final profile = await _datasource.getMemorizationProfile();
      _ensureKidsOwner(ownerId);
      final ageDefault = KidsSessionPolicy.forChildAge(
        profile.childAge,
      ).journeyStageSize;
      final started = logs
          .where(KidsSessionLogsCloudMerge.isCanonicalRewardLog)
          .map((log) => log.surahId)
          .toSet();
      final next = await _datasource.updateKidsHouseSettings((current) {
        _ensureKidsOwner(ownerId);
        return current.copyWith(
          kidsAyahsPerHouse: count,
          clearKidsAyahsPerHouse: count == null,
          kidsHouseSizesBySurah: {
            for (final id in started) id: ageDefault,
            ...current.kidsHouseSizesBySurah,
          },
        );
      });
      _ensureKidsOwner(ownerId);
      return Right(next);
    } catch (error) {
      return Left(CacheFailure.from(error));
    }
  }

  Future<Either<Failure, KidsJourneyPathDefinition>>
  getKidsJourneyPath() async {
    try {
      final settings = await _datasource.getParentSettings();
      return Right(
        resolveKidsJourneyPath(
          storedPathId: settings.kidsJourneyPathId,
          quranJourneyEnabled: _quranJourneyEnabled(),
        ),
      );
    } catch (error) {
      return Left(CacheFailure.from(error));
    }
  }

  Future<Either<Failure, ParentSettings>> setKidsJourneyPath(
    KidsJourneyPathId id,
  ) async {
    try {
      final ownerId = _owner.currentOwnerId;
      _ensureKidsOwner(ownerId);
      final def = KidsJourneyPathDefinition.of(id);
      final next = await _datasource.updateKidsHouseSettings((current) {
        _ensureKidsOwner(ownerId);
        // A start the new path lacks would be stale (R10): restart at the
        // new path's first surah.
        final keepStart = def.contains(current.startingSurahId);
        return current.copyWith(
          kidsJourneyPathId: id.storageValue,
          startingSurahId: keepStart
              ? current.startingSurahId
              : def.surahIds.first,
        );
      });
      _ensureKidsOwner(ownerId);
      return Right(next);
    } catch (error) {
      return Left(CacheFailure.from(error));
    }
  }

  /// Chooses, for one surah, to memorize it as a single whole house (only up
  /// to [kKidsWholeSurahMaxAyahs] ayahs) or in stages of [stageSize] ayahs.
  Future<Either<Failure, ParentSettings>> setKidsSurahSplit(
    int surahId, {
    required bool whole,
    int? stageSize,
  }) async {
    if (surahId < 1 || surahId > 114) return const Left(ValidationFailure());
    final size = whole ? null : sanitizeKidsAyahsPerHouse(stageSize);
    if (!whole && size == null) return const Left(ValidationFailure());
    try {
      final ownerId = _owner.currentOwnerId;
      if (whole) {
        final outcome = await _quranRepository.getSurahDetail(surahId);
        final detail = outcome.fold((failure) => throw failure, (d) => d);
        if (detail.surah.id != surahId) return const Left(CacheFailure());
        final ayahCount = detail.surah.ayahCount;
        if (ayahCount > kKidsWholeSurahMaxAyahs) {
          return const Left(ValidationFailure());
        }
      }
      _ensureKidsOwner(ownerId);
      final next = await _datasource.updateKidsHouseSettings((current) {
        _ensureKidsOwner(ownerId);
        final sizes = {...current.kidsHouseSizesBySurah};
        final wholeIds = {...current.kidsWholeSurahIds};
        if (whole) {
          wholeIds.add(surahId);
          sizes.remove(surahId);
        } else {
          wholeIds.remove(surahId);
          sizes[surahId] = size!;
        }
        return current.copyWith(
          kidsHouseSizesBySurah: sizes,
          kidsWholeSurahIds: wholeIds,
        );
      });
      _ensureKidsOwner(ownerId);
      return Right(next);
    } catch (error) {
      return Left(CacheFailure.from(error));
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
    String? sessionId,
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    required int pointsEarned,
    KidsMissionType missionType = KidsMissionType.newMemorization,
    List<int> ayahNumbers = const [],
    int durationSeconds = 0,
    int attemptCount = 1,
    int hintCount = 0,
    PerformanceRating masteryRating = PerformanceRating.excellent,
  }) async {
    try {
      if (pointsEarned < 0) {
        return const Left(CacheFailure('Kids points cannot be negative'));
      }
      if (pointsEarned > 0) {
        return const Left(
          CacheFailure(
            'Positive Kids rewards must be committed by awardKidsPoints',
          ),
        );
      }

      // UTC: consistent with all other review/session date fields.
      final now = DateTime.now().toUtc();
      final log = KidsSessionLogModel(
        id: sessionId ?? '${now.microsecondsSinceEpoch}_${surahId}_$ayahNumber',
        surahId: surahId,
        ayahNumber: ayahNumber,
        repeatsCompleted: repeatsCompleted,
        pointsEarned: 0,
        completedAt: now,
        missionType: missionType,
        ayahNumbers: ayahNumbers.isEmpty ? [ayahNumber] : ayahNumbers,
        durationSeconds: max(0, durationSeconds),
        attemptCount: max(1, attemptCount),
        hintCount: max(0, hintCount),
        masteryRating: masteryRating,
      );
      return Right(await _appendImmutableKidsLog(log));
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
      final Either<Failure, ParentDashboard> result = journey
          .fold<Either<Failure, ParentDashboard>>(
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
      final ownerId = _owner.currentOwnerId;
      final settings = await _datasource.getParentSettings();
      _ensureKidsOwner(ownerId);
      return Right(await _reconcileLostPin(settings, ownerId));
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, void>> saveParentSettings(
    ParentSettings settings,
  ) async {
    try {
      final stored = await _datasource.getParentSettings();
      await _datasource.saveParentSettings(
        ParentSettingsModel.fromEntity(keepNewerPolicy(settings, stored)),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  /// A settings snapshot taken before a policy pull/CAS/edit must not roll
  /// the policy back: when [incoming] carries an older `policyVersion` or
  /// `policySyncedVersion`, the stored policy block is kept. Equal versions
  /// pass through (e.g. onboarding's session-goal write).
  static ParentSettings keepNewerPolicy(
    ParentSettings incoming,
    ParentSettings stored,
  ) {
    if (incoming.policyVersion >= stored.policyVersion &&
        incoming.policySyncedVersion >= stored.policySyncedVersion) {
      return incoming;
    }
    return incoming.copyWith(
      kidsReduceMotion: stored.kidsReduceMotion,
      maxDailySuggestions: stored.maxDailySuggestions,
      homeMissionsEnabled: stored.homeMissionsEnabled,
      sessionGoalMinutes: stored.sessionGoalMinutes,
      clearSessionGoalMinutes: stored.sessionGoalMinutes == null,
      policyVersion: stored.policyVersion,
      policySyncedVersion: stored.policySyncedVersion,
      policyLinkConfirmed: stored.policyLinkConfirmed,
      clearPolicyLinkConfirmed: stored.policyLinkConfirmed == null,
    );
  }

  Future<Either<Failure, bool>> verifyParentPin(String pin) async {
    try {
      final settings = await _datasource.getParentSettings();
      final stored = settings.pinHash;
      final ownerId = _owner.currentOwnerId;
      final blockedUntil = await _parentPinStore.readBlockedUntil(ownerId);
      if (blockedUntil != null &&
          blockedUntil.isAfter(DateTime.now().toUtc())) {
        return const Right(false);
      }
      switch (await _parentPinStore.lookupVerifier(ownerId)) {
        case ParentPinVerifierPresent(:final verifier):
          _verifierConfirmed.add(ownerId);
          return await _verifySecurePin(ownerId, pin, verifier);
        case ParentPinVerifierUnreadable() when stored == _securePinMarker:
          // The keystore failed to answer: no PIN can be checked, so this is
          // neither a wrong guess (no throttle) nor a lost PIN (kept).
          return const Right(false);
        case ParentPinVerifierAbsent() when stored == _securePinMarker:
          // The verifier is gone for good: no PIN can ever match again.
          // A fresh lookup just proved it gone: drop any session cache.
          _verifierConfirmed.remove(ownerId);
          await _reconcileLostPin(settings, ownerId);
          return const Right(false);
        case ParentPinVerifierUnreadable() || ParentPinVerifierAbsent():
          // No secure PIN: a legacy hash may still be upgraded below.
          break;
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
      await _parentPinStore.writeVerifier(
        ownerId,
        await ParentPinVerifier.createInBackground(pin),
      );
      // The store swallows write failures: a marker without a stored
      // verifier would claim a PIN that protects nothing.
      await _requireStoredVerifier(ownerId);
      await _clearPinThrottle(ownerId);
      _ensureKidsOwner(ownerId);
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

  /// Clears the guardian PIN so a new one can be created. Rewards are kept:
  /// every caller has already proven guardianship (open dashboard or account
  /// password), so wiping them would only lose the family's data.
  Future<Either<Failure, void>> resetParentAccess() async {
    try {
      final settings = await _datasource.getParentSettings();
      final ownerId = _owner.currentOwnerId;
      await _parentPinStore.clearVerifier(ownerId);
      _verifierConfirmed.remove(ownerId);
      await _clearPinThrottle(ownerId);
      await _datasource.saveParentSettings(
        ParentSettingsModel.fromEntity(
          settings.copyWith(clearPin: true, remoteLinkEnabled: false),
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, List<ParentReward>>> saveParentReward(
    String title, {
    int? milestoneSurahId,
  }) async {
    try {
      final trimmed = title.trim();
      if (trimmed.isEmpty) {
        return const Left(
          CacheFailure(CubitMessageCodes.parentRewardTitleRequired),
        );
      }
      if (ParentReward.titleLength(trimmed) > ParentReward.titleMaxLength) {
        return const Left(
          CacheFailure(CubitMessageCodes.parentRewardTitleTooLong),
        );
      }
      final reward = ParentRewardModel(
        id: const Uuid().v4(),
        title: trimmed,
        status: ParentRewardStatus.locked,
        createdAt: DateTime.now(),
        milestoneSurahId: ParentReward.isValidMilestoneSurahId(milestoneSurahId)
            ? milestoneSurahId
            : null,
        origin: ParentRewardOrigin.local,
        ownerId: _owner.currentOwnerId,
      );
      var limitReached = false;
      final next = await _datasource.updateParentRewards((rewards) async {
        if (rewards.where((stored) => stored.origin == ParentRewardOrigin.local).length >= 3) {
          limitReached = true;
          return rewards;
        }
        return [...rewards, reward];
      });
      if (limitReached) {
        return const Left(
          CacheFailure(CubitMessageCodes.parentRewardLimitReached),
        );
      }
      return Right(next);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, List<ParentReward>>> getParentRewards() async {
    try {
      return Right(await _datasource.getParentRewards());
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  /// Guardian: opens a locked gift early.
  Future<Either<Failure, List<ParentReward>>> unlockParentReward(
    String id, {
    AccountDataLease? authority,
  }) =>
      _transitionParentReward(
        id,
        authority: authority,
        from: ParentRewardStatus.locked,
        to: ParentRewardStatus.unlocked,
        alreadyDone: const {
          ParentRewardStatus.unlocked,
          ParentRewardStatus.requested,
          ParentRewardStatus.claimed,
        },
        stamp: (reward, now) => reward.copyWith(unlockedAt: now),
      );

  /// Child: asks to receive an unlocked gift.
  Future<Either<Failure, List<ParentReward>>> requestParentReward(
    String id, {
    AccountDataLease? authority,
  }) =>
      _transitionParentReward(
        id,
        authority: authority,
        from: ParentRewardStatus.unlocked,
        to: ParentRewardStatus.requested,
        alreadyDone: const {
          ParentRewardStatus.requested,
          ParentRewardStatus.claimed,
        },
        stamp: (reward, now) => reward.copyWith(requestedAt: now),
      );

  /// Guardian: confirms the gift was handed over.
  Future<Either<Failure, List<ParentReward>>> approveParentReward(
    String id, {
    AccountDataLease? authority,
  }) =>
      _transitionParentReward(
        id,
        authority: authority,
        from: ParentRewardStatus.requested,
        to: ParentRewardStatus.claimed,
        alreadyDone: const {ParentRewardStatus.claimed},
        stamp: (reward, now) => reward.copyWith(claimedAt: now),
      );

  /// Mirrors the server RPCs: repeating a finished step is a no-op, any
  /// other out-of-order step is refused.
  Future<Either<Failure, List<ParentReward>>> _transitionParentReward(
    String id, {
    AccountDataLease? authority,
    required ParentRewardStatus from,
    required ParentRewardStatus to,
    required Set<ParentRewardStatus> alreadyDone,
    required ParentReward Function(ParentReward, DateTime) stamp,
  }) async {
    try {
      var unavailable = false;
      final next = await _datasource.updateParentRewards((rewards) async {
        final index = rewards.indexWhere(
          (reward) => (reward.storageIdentity == id || reward.id == id) &&
              reward.origin == ParentRewardOrigin.local,
        );
        if (index == -1) {
          unavailable = true;
          return rewards;
        }
        final current = rewards[index];
        if (alreadyDone.contains(current.status)) return rewards;
        if (current.status != from) {
          unavailable = true;
          return rewards;
        }
        final changed = [...rewards];
        changed[index] = ParentRewardModel.fromEntity(
          stamp(current, DateTime.now().toUtc()).copyWith(status: to),
        );
        return changed;
      }, authority: authority);
      if (unavailable) {
        return const Left(
          CacheFailure(CubitMessageCodes.parentRewardUnavailable),
        );
      }
      return Right(next);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  static const kHomeMissionTitleMaxLength = 120;

  Future<Either<Failure, List<KidsHomeMission>>> getHomeMissions() async {
    try {
      return Right(await _datasource.getHomeMissions());
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, List<KidsHomeMission>>> addLocalHomeMission(
    String title,
  ) async {
    try {
      final trimmed = title.trim();
      if (trimmed.isEmpty || trimmed.length > kHomeMissionTitleMaxLength) {
        return const Left(
          ValidationFailure(CubitMessageCodes.kidsHomeMissionInvalidTitle),
        );
      }
      final now = DateTime.now();
      final next = await _datasource.updateHomeMissions(
        (missions) async => [
          ...missions,
          KidsHomeMission(
            id: 'local-${now.microsecondsSinceEpoch}',
            title: trimmed,
            status: KidsHomeMissionStatus.assigned,
            createdAt: now,
          ),
        ],
      );
      return Right(next);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  /// The child reports a mission as done. Idempotent. When
  /// [markPendingSync] is true (a signed-in, cloud-linked child) the report is
  /// flagged `pendingReportSync` and a kids push is queued so it reaches the
  /// guardian once online; an unlinked child stores locally only.
  Future<Either<Failure, List<KidsHomeMission>>> reportHomeMission(
    String id, {
    bool markPendingSync = false,
  }) async {
    try {
      var found = true;
      var changed = false;
      final next = await _datasource.updateHomeMissions((missions) async {
        final index = missions.indexWhere((m) => m.id == id);
        if (index < 0) {
          found = false;
          return missions;
        }
        if (missions[index].status != KidsHomeMissionStatus.assigned) {
          return missions;
        }
        changed = true;
        final updated = [...missions];
        updated[index] = missions[index].copyWith(
          status: KidsHomeMissionStatus.reported,
          reportedAt: DateTime.now(),
          pendingReportSync: markPendingSync,
        );
        return updated;
      });
      if (!found) return const Left(NotFoundFailure());
      if (changed && markPendingSync) {
        // The report is already saved; a queue hiccup must not undo that.
        // The next sync still finds the pending flag.
        try {
          await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.kidsProgressPush);
        } catch (e) {
          TaliaLogger.w('Home mission report could not be queued', e);
        }
      }
      return Right(next);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, List<KidsHomeMission>>> acknowledgeLocalHomeMission(
    String id,
  ) async {
    try {
      var found = true;
      var valid = true;
      final next = await _datasource.updateHomeMissions((missions) async {
        final index = missions.indexWhere((m) => m.id == id);
        if (index < 0) {
          found = false;
          return missions;
        }
        if (missions[index].status != KidsHomeMissionStatus.reported) {
          valid = false;
          return missions;
        }
        final updated = [...missions];
        updated[index] = missions[index].copyWith(
          status: KidsHomeMissionStatus.acknowledged,
          acknowledgedAt: DateTime.now(),
        );
        return updated;
      });
      if (!found) return const Left(NotFoundFailure());
      if (!valid) return const Left(ValidationFailure());
      return Right(next);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, KidsCompletionResult>> awardKidsPoints({
    bool completionAuthorized = false,
    String? sessionId,
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    KidsMissionType missionType = KidsMissionType.newMemorization,
    List<int> ayahNumbers = const [],
    int durationSeconds = 0,
    int attemptCount = 1,
    int hintCount = 0,
    PerformanceRating masteryRating = PerformanceRating.excellent,
    bool firstTryBonusEligible = true,
  }) {
    final ownerId = _owner.currentOwnerId;
    if (missionType == KidsMissionType.newMemorization &&
        !completionAuthorized) {
      return Future.value(
        const Left(
          CacheFailure('Kids reward requires authorized completion evidence'),
        ),
      );
    }
    return _withKidsAwardLock(surahId, ayahNumber, () async {
      try {
        _ensureKidsOwner(ownerId);
        final current = await _reconcileKidsProjection();
        _ensureKidsOwner(ownerId);
        final logs = await _datasource.getKidsSessionLogs();
        _ensureKidsOwner(ownerId);
        final alreadyCompleted = logs.any(
          (log) =>
              log.surahId == surahId &&
              log.ayahNumber == ayahNumber &&
              KidsSessionLogsCloudMerge.isCanonicalRewardLog(log),
        );
        if (missionType != KidsMissionType.newMemorization) {
          // Reduced review reward (W2): a review pass is a distinct positive
          // event, committed directly like the canonical path so the positive
          // evidence survives projection rebuilds.
          final reviewNow = DateTime.now().toUtc();
          final reviewLog = KidsSessionLogModel(
            id:
                sessionId ??
                '${reviewNow.microsecondsSinceEpoch}_${surahId}_$ayahNumber',
            surahId: surahId,
            ayahNumber: ayahNumber,
            repeatsCompleted: repeatsCompleted,
            pointsEarned: kKidsReviewPoints,
            completedAt: reviewNow,
            missionType: missionType,
            ayahNumbers: ayahNumbers.isEmpty ? [ayahNumber] : ayahNumbers,
            durationSeconds: max(0, durationSeconds),
            attemptCount: max(1, attemptCount),
            hintCount: max(0, hintCount),
            masteryRating: masteryRating,
          );
          final reviewCommitted = await _appendImmutableKidsLog(
            reviewLog,
            expectedOwnerId: ownerId,
          );
          _ensureKidsOwner(ownerId);
          final reviewUpdated = await _reconcileKidsProjection();
          await _runKidsRewardAncillaryEffects();
          final reviewWasNewCommit = reviewCommitted.id == reviewLog.id;

          return Right(
            KidsCompletionResult(
              progress: await _hydrateKidsStreak(reviewUpdated),
              pointsEarned: reviewWasNewCommit ? kKidsReviewPoints : 0,
              starsEarned: 0,
              // Review passes are distinct events, never the canonical
              // double-award guard.
              alreadyCompleted: false,
            ),
          );
        }
        if (alreadyCompleted) {
          await _runKidsRewardAncillaryEffects();
          return Right(
            KidsCompletionResult(
              progress: await _hydrateKidsStreak(current),
              pointsEarned: 0,
              starsEarned: 0,
              alreadyCompleted: true,
            ),
          );
        }

        // Listening repetitions are practice, not a rewardable action. A
        // perfect first-try recitation earns an excellence bonus on top of the
        // base reward so early mastery is visibly celebrated.
        final excellence =
            firstTryBonusEligible &&
            attemptCount <= 1 &&
            hintCount == 0 &&
            masteryRating == PerformanceRating.excellent;
        final points =
            kKidsBasePoints + (excellence ? kKidsExcellenceBonus : 0);
        final now = DateTime.now().toUtc();
        final log = KidsSessionLogModel(
          id:
              sessionId ??
              '${now.microsecondsSinceEpoch}_${surahId}_$ayahNumber',
          surahId: surahId,
          ayahNumber: ayahNumber,
          repeatsCompleted: repeatsCompleted,
          pointsEarned: points,
          completedAt: now,
          missionType: missionType,
          ayahNumbers: ayahNumbers.isEmpty ? [ayahNumber] : ayahNumbers,
          durationSeconds: max(0, durationSeconds),
          attemptCount: max(1, attemptCount),
          hintCount: max(0, hintCount),
          masteryRating: masteryRating,
        );
        if (_owner.currentOwnerId != ownerId) {
          throw StateError('Kids data owner changed during reward commit');
        }
        // The immutable positive log is the commit point. The aggregate below is
        // a projection and can be repaired from this log after interruption.
        if (KidsSessionLogsCloudMerge.isCanonicalRewardLog(log)) {
          final settings = await _datasource.getParentSettings();
          final profile = await _datasource.getMemorizationProfile();
          _ensureKidsOwner(ownerId);
          await _freezeHouseSize(
            surahId,
            sanitizeKidsAyahsPerHouse(settings.kidsAyahsPerHouse) ??
                KidsSessionPolicy.forChildAge(
                  profile.childAge,
                ).journeyStageSize,
            ownerId,
          );
          _ensureKidsOwner(ownerId);
        }
        final committed = await _appendImmutableKidsLog(
          log,
          expectedOwnerId: ownerId,
        );
        if (_owner.currentOwnerId != ownerId) {
          throw StateError('Kids data owner changed during reward commit');
        }
        final updated = await _reconcileKidsProjection();
        final wasNewCommit = committed.id == log.id;
        await _runKidsRewardAncillaryEffects(
          completedSurahId: wasNewCommit ? surahId : null,
        );

        return Right(
          KidsCompletionResult(
            progress: await _hydrateKidsStreak(updated),
            pointsEarned: wasNewCommit ? points : 0,
            starsEarned: wasNewCommit
                ? updated.starsEarned - current.starsEarned
                : 0,
            alreadyCompleted: !wasNewCommit,
          ),
        );
      } catch (e) {
        return Left(CacheFailure.from(e));
      }
    });
  }

  Future<T> _withKidsAwardLock<T>(
    int surahId,
    int ayahNumber,
    Future<T> Function() action,
  ) async {
    final key = '${_owner.currentOwnerId}|kids|${surahId}_$ayahNumber';
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

  Future<KidsProgress> _reconcileKidsProjection() async {
    final ownerId = _owner.currentOwnerId;
    final logs = await _datasource.getKidsSessionLogs();
    _ensureKidsOwner(ownerId);
    final rebuilt = KidsSessionLogsCloudMerge.rebuildProjection(logs);
    final stored = await _datasource.getKidsProgress();
    _ensureKidsOwner(ownerId);
    final legacyCloudFloor = await _datasource.getKidsLegacyCloudFloor();
    _ensureKidsOwner(ownerId);
    // Only a value explicitly imported from the legacy cloud contract may be
    // a compatibility floor. Ordinary cached progress is never authoritative.
    final projected = KidsProgressCloudMerge.merge(
      local: rebuilt,
      remote: legacyCloudFloor,
    );
    final changed =
        stored.totalPoints != projected.totalPoints ||
        stored.currentLevel != projected.currentLevel ||
        stored.starsEarned != projected.starsEarned ||
        stored.ayahsCompleted != projected.ayahsCompleted ||
        stored.lastSessionAt != projected.lastSessionAt;
    if (changed) {
      await _datasource.saveKidsProgress(
        KidsProgressModel.fromEntity(_kidsProgressForStorage(projected)),
      );
      _ensureKidsOwner(ownerId);
    }
    return projected;
  }

  Future<KidsSessionLogModel> _appendImmutableKidsLog(
    KidsSessionLogModel candidate, {
    String? expectedOwnerId,
  }) async {
    final ownerId = expectedOwnerId ?? _owner.currentOwnerId;
    _ensureKidsOwner(ownerId);
    var committed = candidate;
    // The dedupe scan and the append run in one atomic read-modify-write:
    // a concurrent award or cloud-sync writer holding the same lock can no
    // longer drop this evidence.
    await _datasource.updateKidsSessionLogs((logs) async {
      _ensureKidsOwner(ownerId);
      for (final existing in logs) {
        if (existing.id == candidate.id) {
          final conflicts =
              existing.surahId != candidate.surahId ||
              existing.ayahNumber != candidate.ayahNumber ||
              existing.missionType != candidate.missionType ||
              existing.pointsEarned != candidate.pointsEarned;
          if (conflicts) {
            throw StateError(
              'Kids session id conflicts with immutable evidence',
            );
          }
          committed = existing;
          return logs;
        }
        if (KidsSessionLogsCloudMerge.isCanonicalRewardLog(candidate) &&
            KidsSessionLogsCloudMerge.isCanonicalRewardLog(existing) &&
            existing.surahId == candidate.surahId &&
            existing.ayahNumber == candidate.ayahNumber) {
          committed = existing;
          return logs;
        }
      }
      committed = candidate;
      return [...logs, candidate]
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    });
    _ensureKidsOwner(ownerId);
    return committed;
  }

  Future<void> _runKidsRewardAncillaryEffects({int? completedSurahId}) async {
    final ownerId = _owner.currentOwnerId;
    await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.kidsProgressPush);
    _ensureKidsOwner(ownerId);
    await _unlockWeeklyRewardIfNeeded();
    _ensureKidsOwner(ownerId);
    if (completedSurahId != null && _remoteMilestoneUnlock != null &&
        _remoteMilestoneEnabled?.call() == true) {
      // Completion is already durable. Cloud gifts are retried on Treasures;
      // connectivity must never hold up or undo the child's success screen.
      unawaited(_tryUnlockRemoteMilestone(completedSurahId));
    }
    _progressEvents.notify(ProgressChangedReason.kidsProgress);
  }

  Future<void> _tryUnlockRemoteMilestone(int surahId) async {
    final ownerId = _owner.currentOwnerId;
    try {
      final authority = _barrier?.capture();
      if (authority == null) return;
      authority.checkOwner(ownerId);
      final complete = await _isCanonicalSurahComplete(surahId);
      authority.checkOwner(ownerId);
      if (complete) await _remoteMilestoneUnlock?.call(surahId);
    } catch (error, stack) {
      TaliaLogger.w('Remote milestone will retry from Treasures', error, stack);
    }
  }

  Future<bool> _isCanonicalSurahComplete(int surahId) async {
    final detail = await _quranRepository.getSurahDetail(surahId);
    final surah = detail.fold((_) => null, (value) => value.surah);
    if (surah == null || surah.id != surahId || surah.ayahCount <= 0) return false;
    final total = surah.ayahCount;
    final logs = await _datasource.getKidsSessionLogs();
    final completed = <int>{
      for (final log in logs)
        if (log.surahId == surahId &&
            KidsSessionLogsCloudMerge.isCanonicalRewardLog(log))
          log.ayahNumber,
    };
    for (var ayah = 1; ayah <= total; ayah++) {
      if (!completed.contains(ayah)) return false;
    }
    return true;
  }

  void _ensureKidsOwner(String ownerId) {
    if (_owner.currentOwnerId != ownerId) {
      throw StateError('Kids data owner changed during operation');
    }
  }

  String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  static const _securePinMarker = 'secure-v2';

  /// Owners whose stored verifier was seen this session, so the hot
  /// settings read does not go back to the keystore on every call.
  final Set<String> _verifierConfirmed = {};

  /// A secure PIN whose verifier the store no longer holds (Android KeyStore
  /// keys can be invalidated, and the storage plugin then resets its data)
  /// can never be entered again, which would lock the guardian out of every
  /// guardian action. Such a device is returned to "no PIN yet", the same
  /// state as a child set up without one: unlinked devices create a PIN at
  /// the next guardian action, linked ones still need guardian recovery.
  /// A store that cannot be read keeps the PIN, since that may be transient.
  ///
  /// The clear re-reads the settings under the kids settings lock and is
  /// bound to [ownerId], so an account switch or a concurrent settings write
  /// is never overwritten by the snapshot that triggered it.
  Future<ParentSettings> _reconcileLostPin(
    ParentSettings settings,
    String ownerId,
  ) async {
    if (settings.pinHash != _securePinMarker) return settings;
    if (_verifierConfirmed.contains(ownerId)) return settings;
    if (!await _verifierIsAbsent(ownerId)) return settings;
    // Re-check right before writing: a PIN created meanwhile wins.
    if (!await _verifierIsAbsent(ownerId)) return settings;
    final cleared = await _datasource.updateKidsHouseSettings((current) {
      _ensureKidsOwner(ownerId);
      return current.pinHash == _securePinMarker
          ? current.copyWith(clearPin: true)
          : current;
    });
    _ensureKidsOwner(ownerId);
    await _clearPinThrottle(ownerId);
    TaliaLogger.w('Parent PIN verifier missing; cleared the stale PIN marker');
    return cleared;
  }

  Future<bool> _verifierIsAbsent(String ownerId) async {
    final lookup = await _parentPinStore.lookupVerifier(ownerId);
    _ensureKidsOwner(ownerId);
    if (lookup is ParentPinVerifierPresent) _verifierConfirmed.add(ownerId);
    return lookup is ParentPinVerifierAbsent;
  }

  Future<void> _requireStoredVerifier(String ownerId) async {
    final lookup = await _parentPinStore.lookupVerifier(ownerId);
    _ensureKidsOwner(ownerId);
    if (lookup is! ParentPinVerifierPresent) {
      throw StateError('Parent PIN verifier was not stored');
    }
    _verifierConfirmed.add(ownerId);
  }

  Future<Either<Failure, bool>> _verifySecurePin(
    String ownerId,
    String pin,
    String verifier,
  ) async {
    if (await ParentPinVerifier.verifyInBackground(pin, verifier)) {
      await _clearPinThrottle(ownerId);
      return const Right(true);
    }
    await _recordFailedPinAttempt(ownerId);
    return const Right(false);
  }

  bool _matchesLegacyPin(String? stored, String pin) =>
      stored == _hashPin(pin) ||
      (_isLegacyPlaintextPin(stored) && stored == pin);

  Future<void> _upgradeLegacyPin(
    String ownerId,
    String pin,
    ParentSettings settings,
  ) async {
    await _parentPinStore.writeVerifier(
      ownerId,
      await ParentPinVerifier.createInBackground(pin),
    );
    await _clearPinThrottle(ownerId);
    // Keep the legacy hash when the verifier did not land: the PIN must stay
    // usable rather than point at a verifier that is not there.
    final lookup = await _parentPinStore.lookupVerifier(ownerId);
    _ensureKidsOwner(ownerId);
    if (lookup is! ParentPinVerifierPresent) return;
    _verifierConfirmed.add(ownerId);
    await _datasource.saveParentSettings(
      ParentSettingsModel.fromEntity(
        settings.copyWith(pinHash: _securePinMarker),
      ),
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
    final promiseOn = _promiseEnabled();
    final alreadyUnlockedThisWeek = rewards.any(
      (reward) =>
          reward.origin == ParentRewardOrigin.local &&
          (!promiseOn || reward.milestoneSurahId == null) &&
          reward.unlockedAt != null &&
          !reward.unlockedAt!.toUtc().isBefore(weekStart),
    );
    if (alreadyUnlockedThisWeek) return;
    final sessionsThisWeek = logs
        .where(
          (log) =>
              KidsSessionLogsCloudMerge.isCanonicalRewardLog(log) &&
              !log.completedAt.isBefore(weekStart),
        )
        .length;
    if (sessionsThisWeek < settings.weeklyGoalSessions) return;

    var unlockedOne = false;
    final next = rewards.map((reward) {
      // A surah promise opens only when its surah is completed.
      if (!unlockedOne &&
          reward.origin == ParentRewardOrigin.local &&
          reward.status == ParentRewardStatus.locked &&
          (!promiseOn || reward.milestoneSurahId == null)) {
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
    if (!unlockedOne) return;
    ParentRewardModel? unlocked;
    for (final reward in next) {
      if (reward.status == ParentRewardStatus.unlocked &&
          !rewards.any((old) =>
              old.storageIdentity == reward.storageIdentity &&
              old.status == ParentRewardStatus.unlocked)) {
        unlocked = reward;
        break;
      }
    }
    if (unlocked == null) return;
    final unlockedReward = unlocked;
    await _datasource.updateParentRewards((current) async => current.map((reward) {
      return reward.storageIdentity == unlockedReward.storageIdentity &&
              reward.status == ParentRewardStatus.locked
          ? ParentRewardModel.fromEntity(unlockedReward)
          : reward;
    }).toList());
  }
}
