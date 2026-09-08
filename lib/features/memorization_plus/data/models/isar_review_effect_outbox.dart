import 'package:isar/isar.dart';

part 'isar_review_effect_outbox.g.dart';

/// A durable, idempotent non-Isar side effect caused by a review outcome.
///
/// SharedPreferences daily-plan updates and gamification do not participate in
/// the review transaction. They must be processed later from this outbox using
/// [receiptKey]; no UI path may award them inline.
@collection
class IsarReviewEffectOutbox {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String receiptKey;

  @Index()
  late String eventId;
  @Index()
  late String ownerId;
  @Index()
  late String audience;
  @Index()
  late String effectType;
  /// The deterministic activity amount used by idempotent reward effects.
  ///
  /// Kept on the effect rather than reconstructed from a session checkpoint so
  /// it remains available after that resumable checkpoint is cleaned up.
  int? activityDelta;
  late DateTime createdAt;
  int attempts = 0;
  DateTime? processedAt;
  String? lastErrorCode;
}
