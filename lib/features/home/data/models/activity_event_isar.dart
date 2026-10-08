import 'package:isar_community/isar.dart';

part 'activity_event_isar.g.dart';

/// Append-only home activity feed. Stores identifiers only — never Quran text.
@collection
class ActivityEventIsar {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime occurredAt;

  /// [ActivityEventKind.index].
  late int kindIndex;

  int? surahId;
  int? startAyah;
  int? endAyah;
  int? pageNumber;

  /// True for kids-track entries. Null on rows written before the tag
  /// existed; legacy kids rows are recognised by their idempotency key.
  bool? isKids;

  @Index(unique: true)
  late String idempotencyKey;
}
