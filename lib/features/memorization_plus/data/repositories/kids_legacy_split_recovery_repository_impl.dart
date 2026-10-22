import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/memorization/kids_progress_cloud_merge.dart';
import '../../domain/entities/kids_legacy_resume_recovery.dart';
import '../../domain/entities/kids_journey_path_definition.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/kids_legacy_split_recovery_repository.dart';
import '../datasources/memorization_plus_local_datasource.dart';

/// An explicit new choice for a legacy checkpoint; never guesses its old split.
class KidsLegacySplitRecoveryRepositoryImpl
    implements KidsLegacySplitRecoveryRepository {
  const KidsLegacySplitRecoveryRepositoryImpl(
    this._source,
    this._owner,
    this._barrier,
  );
  final MemorizationPlusLocalDatasource _source;
  final RecordOwnerProvider _owner;
  final AccountDataBarrier _barrier;

  @override
  Future<Either<Failure, ParentSettings>> save(
    KidsLegacyResumeRecoveryTicket ticket, {
    required bool whole,
    int? stageSize,
  }) async {
    try {
      _check(ticket);
      if (!_validChoice(ticket, whole, stageSize)) {
        return const Left(CacheFailure());
      }
      final saved = await _barrier.run(
        (_) => _commitChoice(ticket, whole, stageSize),
        authority: ticket.lease,
      );
      return Right(saved);
    } catch (error) {
      return Left(CacheFailure.from(error));
    }
  }

  bool _validChoice(
    KidsLegacyResumeRecoveryTicket ticket,
    bool whole,
    int? size,
  ) =>
      ticket.surahId >= 1 &&
      ticket.surahId <= 114 &&
      ticket.verifiedAyahCount > 0 &&
      ticket.checkpointAyah > 0 &&
      ticket.checkpointAyah <= ticket.verifiedAyahCount &&
      (whole
          ? ticket.verifiedAyahCount <= kKidsWholeSurahMaxAyahsLimit
          : sanitizeKidsAyahsPerHouse(size) != null);

  Future<ParentSettings> _commitChoice(
    KidsLegacyResumeRecoveryTicket ticket,
    bool whole,
    int? stageSize,
  ) async {
    _check(ticket);
    final logs = await _source.getKidsSessionLogs();
    _check(ticket);
    final hasHistory = logs.any(
      (log) =>
          log.surahId == ticket.surahId &&
          KidsSessionLogsCloudMerge.isCanonicalRewardLog(log),
    );
    final settings = await _source.updateKidsHouseSettings((current) {
      _check(ticket);
      if (hasHistory) return current;
      return _keepOrApply(current, ticket, whole, stageSize);
    });
    _check(ticket);
    return settings;
  }

  ParentSettings _keepOrApply(
    ParentSettings current,
    KidsLegacyResumeRecoveryTicket ticket,
    bool whole,
    int? stageSize,
  ) {
    if (current.kidsWholeSurahIds.contains(ticket.surahId) ||
        sanitizeKidsAyahsPerHouse(
              current.kidsHouseSizesBySurah[ticket.surahId],
            ) !=
            null) {
      return current;
    }
    return whole
        ? current.copyWith(
            kidsWholeSurahIds: {...current.kidsWholeSurahIds, ticket.surahId},
          )
        : current.copyWith(
            kidsHouseSizesBySurah: {
              ...current.kidsHouseSizesBySurah,
              ticket.surahId: stageSize!,
            },
          );
  }

  void _check(KidsLegacyResumeRecoveryTicket ticket) {
    ticket.lease.checkOwner(ticket.ownerId);
    if (_owner.currentOwnerId != ticket.ownerId) {
      throw const AccountDataUnavailableException();
    }
  }
}
