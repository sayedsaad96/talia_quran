import 'package:isar_community/isar.dart';

part 'isar_prayer_review_receipt.g.dart';

/// Durable exact-passage daily fence. Grade is deliberately not part of the
/// identity: the first accepted decision remains authoritative.
@collection
class IsarPrayerReviewReceipt {
  Id id = Isar.autoIncrement;

  @Index(
    unique: true,
    replace: false,
    composite: [CompositeIndex('receiptKey')],
  )
  late String ownerId;

  late String receiptKey;
  late String audience;

  @Index()
  late String localDayKey;

  late int surahId;
  late int startAyah;
  late int endAyah;
  late int gradeIndex;
  late DateTime committedAt;
  List<String> eventIds = [];

  static const adultAudience = 'adult';
}
