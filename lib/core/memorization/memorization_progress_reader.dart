import 'package:dartz/dartz.dart';

import '../error/app_failure.dart';
import '../memorization/review_record_audience_scope.dart';
import '../services/app_session_service.dart';
import '../utils/talia_logger.dart';
import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
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
    this._sessionService,
  );

  final MemorizationPlusRepository _memorizationPlusRepository;
  final AppSessionService _sessionService;

  @override
  Future<Either<Failure, MemorizationSnapshot>> readSnapshot() async {
    final profileResult = await _memorizationPlusRepository
        .getMemorizationProfile();
    final failure = profileResult.fold((f) => f, (_) => null);
    if (failure != null) return Left(failure);
    final profile = profileResult.getOrElse(
      () => throw StateError('profile expected'),
    );

    final reviewScope = profile.isChild
        ? ReviewRecordReadScope.kids
        : ReviewRecordReadScope.adult;

    final reviewRecords = await _readOptional(
      label: 'Smart Coach review records',
      read: () => _memorizationPlusRepository.getAllReviewRecords(
        scope: reviewScope,
      ),
      fallback: const <AyahReviewRecord>[],
    );
    final cachedDailyPlan = await _readOptional<DailyPlan?>(
      label: 'Smart Coach cached daily plan',
      read: _memorizationPlusRepository.getCachedDailyPlan,
      fallback: null,
    );
    final customPlan = await _readOptional<CustomMemorizationPlan?>(
      label: 'Smart Coach custom plan',
      read: _memorizationPlusRepository.getCustomPlan,
      fallback: null,
    );
    final kidsProgress = await _readOptional<KidsProgress?>(
      label: 'Smart Coach kids progress',
      read: _memorizationPlusRepository.getKidsProgress,
      fallback: null,
    );
    final kidsSessionLogs = await _readOptional(
      label: 'Smart Coach kids session logs',
      read: _memorizationPlusRepository.getKidsSessionLogs,
      fallback: const <KidsSessionLog>[],
    );
    return Right(
      MemorizationSnapshot(
        profile: profile,
        lastRestorableLocation: _sessionService.getLastRestorableLocation(),
        reviewRecords: reviewRecords,
        cachedDailyPlan: cachedDailyPlan,
        customPlan: customPlan,
        kidsProgress: kidsProgress,
        kidsSessionLogs: kidsSessionLogs,
      ),
    );
  }

  Future<T> _readOptional<T>({
    required String label,
    required Future<Either<Failure, T>> Function() read,
    required T fallback,
  }) async {
    try {
      final result = await read();
      final T value = result.fold((failure) {
        TaliaLogger.w('$label unavailable; using partial snapshot', failure);
        return fallback;
      }, (value) => value);
      return value;
    } catch (error, stack) {
      TaliaLogger.w('$label threw; using partial snapshot', error, stack);
      return fallback;
    }
  }
}
