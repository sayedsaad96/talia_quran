import '../../identity/account_data_barrier.dart';
import '../../identity/record_owner_provider.dart';
import '../v2/recitation_evaluator.dart';
import '../v2/session_phase.dart';
import 'similar_ayah_attempt_authority.dart';
import 'similar_ayah_confusion_detector.dart';

/// Resolves ALL approved neighbors to their original runtime ayah bodies.
/// Null means unavailable/unapproved; a partial result must never be returned.
abstract interface class SimilarAyahCandidateSource {
  Future<List<SimilarAyahCandidate>?> loadCandidates(String targetKey);
}

/// Production stays inert until a reviewed final index is available.
final class UnavailableSimilarAyahCandidateSource
    implements SimilarAyahCandidateSource {
  const UnavailableSimilarAyahCandidateSource();
  @override
  Future<List<SimilarAyahCandidate>?> loadCandidates(String targetKey) async =>
      null;
}

/// Coordinates ephemeral attribution without owning a transaction or verdict.
final class SimilarAyahAttemptService {
  const SimilarAyahAttemptService({
    required this._owner,
    required this._barrier,
    required this._isEnabled,
    required this._readAdultEligibility,
    required this._candidates,
  });

  final RecordOwnerProvider _owner;
  final AccountDataBarrier _barrier;
  final bool Function() _isEnabled;
  final Future<bool> Function() _readAdultEligibility;
  final SimilarAyahCandidateSource _candidates;
  static const _detector = SimilarAyahConfusionDetector();

  Stream<void> get accountChanges => _barrier.changes;

  /// Null while the trainer is off, so a session takes exactly the pre-trainer
  /// path (no account-barrier dependency, no attribution writes).
  SimilarAyahAttemptAuthority? captureAuthority() {
    if (!_isEnabled()) return null;
    final authority = SimilarAyahAttemptAuthority(
      ownerId: _owner.currentOwnerId,
      lease: _barrier.capture(),
    );
    authority.check();
    return authority;
  }

  Future<SimilarAyahConfusionMatch?> detect({
    required SimilarAyahAttemptAuthority authority,
    required String targetKey,
    required String spokenText,
    required V2RecitationResult original,
    required V2SessionPhase phase,
    required bool acceptedFailure,
    V2RecitationEvaluator evaluator = const V2RecitationEvaluator(),
  }) async {
    authority.check();
    if (!_isEnabled() ||
        !acceptedFailure ||
        phase != V2SessionPhase.reciting ||
        original.passed ||
        original.isNoAttempt ||
        original.assessmentMethod != V2AssessmentMethod.automatic ||
        original.verdict == RecitationVerdict.technicalUnavailable) {
      return null;
    }
    try {
      final adult = await _readAdultEligibility();
      authority.check();
      if (!adult || !_isEnabled()) return null;
      final candidates = await _candidates.loadCandidates(targetKey);
      authority.check();
      if (candidates == null || !_isEnabled()) return null;
      return _detector.detect(
        targetKey: targetKey,
        spokenText: spokenText,
        original: original,
        candidates: candidates,
        isAdult: adult,
        phase: phase,
        acceptedFailure: acceptedFailure,
        evaluator: evaluator,
      );
    } on AccountDataUnavailableException {
      rethrow;
    } catch (_) {
      // Payload-bearing exceptions are never logged or sent to persistence.
      authority.check();
      return null;
    }
  }
}
