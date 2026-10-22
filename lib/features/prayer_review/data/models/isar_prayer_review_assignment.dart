import 'package:isar_community/isar.dart';

part 'isar_prayer_review_assignment.g.dart';

/// Adult-only frozen selection. The composite identity enables first writer
/// wins for concurrent card and notification preparation paths.
@collection
class IsarPrayerReviewAssignment {
  Id id = Isar.autoIncrement;

  @Index(
    unique: true,
    replace: false,
    composite: [CompositeIndex('occurrenceKey')],
  )
  late String ownerId;

  late String occurrenceKey;
  late String audience;

  @Index()
  late String localDayKey;

  late int prayerKeyIndex;
  late DateTime scheduledAt;
  late DateTime selectedAt;
  late int surahId;
  late int startAyah;
  late int endAyah;
  late int selectionVersion;
  bool promptConsumed = false;

  static const adultAudience = 'adult';
}
