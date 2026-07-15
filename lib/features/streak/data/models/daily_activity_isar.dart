import 'package:isar/isar.dart';
part 'daily_activity_isar.g.dart';

/// Stores a count of reading/memorization actions per calendar day.
/// One record per UTC day — id is derived from the date integer YYYYMMDD.
@collection
class DailyActivityIsar {
  Id id = Isar.autoIncrement;

  /// Stored as int YYYYMMDD for fast lookup (e.g. 20260504)
  @Index(unique: true)
  late int dayKey;

  /// Total ayahs reviewed/read that day
  int activityCount = 0;

  /// Null on legacy rows is treated as dirty until first successful cloud push.
  bool? cloudDirty;

  DateTime? lastSyncedAt;
}
