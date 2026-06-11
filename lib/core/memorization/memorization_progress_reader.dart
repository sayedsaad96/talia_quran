import 'package:dartz/dartz.dart';

import '../error/app_failure.dart';
import '../services/app_session_service.dart';
import '../../features/hifz/domain/repositories/hifz_repository.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'memorization_snapshot.dart';

/// Unified read-only entry point for memorization and review state.
///
/// Does not write, schedule, score, or recommend. Existing repositories
/// remain the source of truth.
abstract class MemorizationProgressReader {
  Future<Either<Failure, MemorizationSnapshot>> readSnapshot();
}

class MemorizationProgressReaderImpl implements MemorizationProgressReader {
  MemorizationProgressReaderImpl(
    this._memorizationPlusRepository,
    this._hifzRepository,
    this._sessionService,
  );

  final MemorizationPlusRepository _memorizationPlusRepository;
  final HifzRepository _hifzRepository;
  final AppSessionService _sessionService;

  @override
  Future<Either<Failure, MemorizationSnapshot>> readSnapshot() async {
    final profileResult = await _memorizationPlusRepository
        .getMemorizationProfile();
    Failure? failure = profileResult.fold((f) => f, (_) => null);
    if (failure != null) return Left(failure);
    final profile = profileResult.getOrElse(
      () => throw StateError('profile expected'),
    );

    final reviewRecordsResult = await _memorizationPlusRepository
        .getAllReviewRecords();
    failure = reviewRecordsResult.fold((f) => f, (_) => null);
    if (failure != null) return Left(failure);
    final reviewRecords = reviewRecordsResult.getOrElse(() => const []);

    final cachedPlanResult = await _memorizationPlusRepository
        .getCachedDailyPlan();
    failure = cachedPlanResult.fold((f) => f, (_) => null);
    if (failure != null) return Left(failure);
    final cachedDailyPlan = cachedPlanResult.getOrElse(() => null);

    final customPlanResult = await _memorizationPlusRepository.getCustomPlan();
    failure = customPlanResult.fold((f) => f, (_) => null);
    if (failure != null) return Left(failure);
    final customPlan = customPlanResult.getOrElse(() => null);

    final kidsProgressResult = await _memorizationPlusRepository
        .getKidsProgress();
    failure = kidsProgressResult.fold((f) => f, (_) => null);
    if (failure != null) return Left(failure);
    final kidsProgress = kidsProgressResult.getOrElse(
      () => throw StateError('kids progress expected'),
    );

    final kidsLogsResult = await _memorizationPlusRepository
        .getKidsSessionLogs();
    failure = kidsLogsResult.fold((f) => f, (_) => null);
    if (failure != null) return Left(failure);
    final kidsSessionLogs = kidsLogsResult.getOrElse(() => const []);

    final hifzDueResult = await _hifzRepository.getDueReviews();
    failure = hifzDueResult.fold((f) => f, (_) => null);
    if (failure != null) return Left(failure);
    final hifzDueReviews = hifzDueResult.getOrElse(() => const []);

    final hifzSurahResult = await _hifzRepository.getAllSurahProgress();
    failure = hifzSurahResult.fold((f) => f, (_) => null);
    if (failure != null) return Left(failure);
    final hifzSurahProgress = hifzSurahResult.getOrElse(() => const []);

    return Right(
      MemorizationSnapshot(
        profile: profile,
        lastRestorableLocation: _sessionService.getLastRestorableLocation(),
        reviewRecords: reviewRecords,
        cachedDailyPlan: cachedDailyPlan,
        customPlan: customPlan,
        hifzDueReviews: hifzDueReviews,
        hifzSurahProgress: hifzSurahProgress,
        kidsProgress: kidsProgress,
        kidsSessionLogs: kidsSessionLogs,
      ),
    );
  }
}
