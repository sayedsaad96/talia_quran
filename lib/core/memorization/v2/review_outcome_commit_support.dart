import 'dart:math';

import 'package:isar/isar.dart';

import '../../../features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import '../../../features/memorization_plus/data/models/isar_v2_session.dart';
import '../../../features/memorization_plus/domain/entities/ayah_review_record.dart';
import '../../../features/memorization_plus/domain/entities/kids_session_policy.dart';
import '../learning_launch_context.dart';
import 'hint_usage.dart';
import 'self_grade.dart';
import 'session_state.dart';

/// Stateless construction helpers for the review-outcome transaction.
abstract final class V2ReviewOutcomeCommitSupport {
  static IsarV2Session checkpointFromState(
    V2SessionState state, {
    required String ownerId,
    required String sessionId,
    required LearningLaunchContext? launchContext,
    MemorizationAudience audience = MemorizationAudience.adult,
  }) {
    final failures = <int, int>{};
    for (final failure in state.failureTracker.allFailures) {
      failures[failure.ayahNumber] = failure.failureCount;
    }
    final hints = <int, int>{};
    for (final hint in state.hintTracker.allUsages) {
      hints[hint.ayahNumber] = hint.level.index;
    }
    return IsarV2Session.create(
      surahId: state.surahId,
      blockAyahNumbers: state.blockAyahs
          .map((ayah) => ayah.numberInSurah)
          .toList(growable: false),
      currentAyahIndex: state.currentAyahIndex,
      phaseIndex: state.phase.index,
      passedAyahNumbers: state.passedAyahNumbers,
      failureCounts: failures,
      hintLevels: hints,
      blockReviewRequired: state.blockReviewRequired,
      ownerId: ownerId,
      audience: audience,
      sessionId: sessionId,
      launchContext: launchContext,
      review: state.isReview,
    );
  }

  static PerformanceRating ratingFor(V2SessionState state, int ayahNumber) {
    final hint = state.hintTracker.levelFor(state.surahId, ayahNumber);
    final failures = state.failureTracker.failureCountFor(
      state.surahId,
      ayahNumber,
    );
    // A final success cannot erase evidence of a difficult recitation in the
    // same task. The threshold deliberately follows the learner-facing policy:
    // full text or two failures is weak; one prompt/failure is average.
    if (hint == V2HintLevel.fullAyah || failures >= 2) {
      return PerformanceRating.weak;
    }
    if (hint == V2HintLevel.firstWord || failures == 1) {
      return PerformanceRating.average;
    }
    return PerformanceRating.excellent;
  }

  /// SM-2 rating for a self-assessed pass. Self-report is less reliable than
  /// automatic evidence, so it never exceeds [PerformanceRating.average] and
  /// still reflects hints/failures recorded during the same task.
  static PerformanceRating manualRatingFor(
    V2SessionState state,
    int ayahNumber,
    V2SelfGrade grade,
  ) {
    if (grade != V2SelfGrade.mastered) return PerformanceRating.weak;
    final evidence = ratingFor(state, ayahNumber);
    return evidence == PerformanceRating.excellent
        ? PerformanceRating.average
        : evidence;
  }

  static String? nonEmpty(String? value) =>
      value == null || value.isEmpty ? null : value;

  static String studyDayKey(DateTime utc) {
    final local = utc.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  static String newOpaqueId() {
    final random = Random.secure();
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final suffix = List<int>.generate(
      4,
      (_) => random.nextInt(1 << 32),
    ).map((value) => value.toRadixString(16).padLeft(8, '0')).join();
    return '$timestamp-$suffix';
  }
}

/// Writes deterministic side-effect requests inside the outcome transaction.
final class ReviewEffectOutboxWriter {
  const ReviewEffectOutboxWriter(this._isar);

  final Isar _isar;

  Future<void> put({
    required String eventId,
    required String ownerId,
    required String audience,
    required String effectType,
    required String receiptKey,
    required DateTime createdAt,
    int? activityDelta,
  }) async {
    final existing = await _isar.isarReviewEffectOutboxs
        .filter()
        .receiptKeyEqualTo(receiptKey)
        .findFirst();
    if (existing != null) return;
    await _isar.isarReviewEffectOutboxs.put(
      IsarReviewEffectOutbox()
        ..receiptKey = receiptKey
        ..eventId = eventId
        ..ownerId = ownerId
        ..audience = audience
        ..effectType = effectType
        ..activityDelta = activityDelta
        ..createdAt = createdAt,
    );
  }

  Future<void> enqueueCompletionEffects({
    required String eventId,
    required String ownerId,
    required String audience,
    required String sessionId,
    required int activityDelta,
    required bool includeCertificate,
    required DateTime createdAt,
    bool isReview = false,
  }) async {
    await put(
      eventId: eventId,
      ownerId: ownerId,
      audience: audience,
      effectType: 'completion',
      receiptKey: 'completion:$sessionId',
      activityDelta: activityDelta,
      createdAt: createdAt,
    );
    await put(
      eventId: eventId,
      ownerId: ownerId,
      audience: audience,
      // A one-ayah review is lighter work than a memorized block (A7).
      effectType: isReview ? 'xpReview' : 'xp',
      receiptKey: 'xp:$sessionId',
      activityDelta: activityDelta,
      createdAt: createdAt,
    );
    await put(
      eventId: eventId,
      ownerId: ownerId,
      audience: audience,
      effectType: 'streak',
      receiptKey: 'streak:$sessionId',
      activityDelta: activityDelta,
      createdAt: createdAt,
    );
    if (includeCertificate) {
      await put(
        eventId: eventId,
        ownerId: ownerId,
        audience: audience,
        effectType: 'certificate',
        receiptKey: 'certificate:$sessionId',
        createdAt: createdAt,
      );
    }
  }
}
