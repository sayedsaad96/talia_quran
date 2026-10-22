import 'package:equatable/equatable.dart';
import 'package:isar_community/isar.dart';

import '../../../../../core/identity/account_data_barrier.dart';
import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/memorization/v2/session_phase.dart';
import '../../../domain/entities/kids_session_policy.dart';
import '../../models/isar_v2_session.dart';

/// Read-only result for a legacy single-ayah kids checkpoint whose original
/// house partition is unknowable. No result permits an inferred partition.
sealed class KidsLegacyResumeProbeResult extends Equatable {
  const KidsLegacyResumeProbeResult();

  const factory KidsLegacyResumeProbeResult.none() = KidsLegacyResumeProbeNone;
  const factory KidsLegacyResumeProbeResult.choiceRequired({
    required int checkpointAyah,
  }) = KidsLegacyResumeProbeChoiceRequired;
  const factory KidsLegacyResumeProbeResult.unavailable() =
      KidsLegacyResumeProbeUnavailable;
}

final class KidsLegacyResumeProbeNone extends KidsLegacyResumeProbeResult {
  const KidsLegacyResumeProbeNone();

  @override
  List<Object?> get props => const [];
}

final class KidsLegacyResumeProbeChoiceRequired
    extends KidsLegacyResumeProbeResult {
  const KidsLegacyResumeProbeChoiceRequired({required this.checkpointAyah});

  final int checkpointAyah;

  @override
  List<Object?> get props => [checkpointAyah];
}

final class KidsLegacyResumeProbeUnavailable
    extends KidsLegacyResumeProbeResult {
  const KidsLegacyResumeProbeUnavailable();

  @override
  List<Object?> get props => const [];
}

/// Reads only the current owner's kids memorization checkpoint. It never
/// backfills, claims, clears, or otherwise mutates a checkpoint.
abstract interface class KidsLegacyResumeProbe {
  Future<KidsLegacyResumeProbeResult> inspect({
    required int surahId,
    required AccountDataLease lease,
  });
}

final class KidsLegacyResumeRecoveryProbe implements KidsLegacyResumeProbe {
  const KidsLegacyResumeRecoveryProbe({
    required this._isar,
    required this._owner,
    required this._barrier,
  });

  final Isar _isar;
  final RecordOwnerProvider _owner;
  final AccountDataBarrier _barrier;

  @override
  Future<KidsLegacyResumeProbeResult> inspect({
    required int surahId,
    required AccountDataLease lease,
  }) async {
    final ownerId = _owner.currentOwnerId;
    try {
      _checkLease(ownerId, lease);
      // One unique-key lookup, never a scan of every owner's checkpoints.
      final key = IsarV2Session.keyFor(
        ownerId: ownerId,
        audience: MemorizationAudience.kids,
        surahId: surahId,
      );
      final row = await _barrier.run(
        (_) => _isar.isarV2Sessions.getBySessionKey(key),
        authority: lease,
      );
      final rows = [?row];
      _checkLease(ownerId, lease);
      final checkpoint = _matchingCheckpoint(rows, ownerId, surahId);
      return checkpoint == null
          ? const KidsLegacyResumeProbeResult.none()
          : KidsLegacyResumeProbeResult.choiceRequired(
              checkpointAyah: checkpoint.blockAyahNumbers.single,
            );
    } catch (_) {
      return const KidsLegacyResumeProbeResult.unavailable();
    }
  }

  void _checkLease(String ownerId, AccountDataLease lease) {
    lease.checkOwner(ownerId);
  }

  IsarV2Session? _matchingCheckpoint(
    List<IsarV2Session> rows,
    String ownerId,
    int surahId,
  ) {
    final matching = rows.where((row) {
      if (row.ownerId != ownerId || row.surahId != surahId) return false;
      if (row.audienceIndex != MemorizationAudience.kids.index) return false;
      if (row.sessionKey !=
          IsarV2Session.keyFor(
            ownerId: ownerId,
            audience: MemorizationAudience.kids,
            surahId: surahId,
          )) {
        return false;
      }
      final phaseIndex = row.phaseIndex;
      if (phaseIndex < 0 || phaseIndex >= V2SessionPhase.values.length) {
        return false;
      }
      final phase = V2SessionPhase.values[phaseIndex];
      final block = row.blockAyahNumbers;
      return phase != V2SessionPhase.created &&
          !phase.isTerminal &&
          row.currentAyahIndex == 0 &&
          block.length == 1;
    }).toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return matching.isEmpty ? null : matching.first;
  }
}
