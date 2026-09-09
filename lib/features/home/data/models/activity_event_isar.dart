import 'package:isar/isar.dart';

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

  @Index(unique: true)
  late String idempotencyKey;
}
