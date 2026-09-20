import 'package:isar/isar.dart';
part 'streak_isar.g.dart';

@collection
class StreakIsar {
  // id ثابت = 1 لأننا نريد سجلاً واحداً دائماً
  Id id = 1;
  int currentStreak = 0;
  int longestStreak = 0;
  DateTime? lastActivityDate;
  int freezesAvailable = 0;

  /// Last day "يوم الرحمة" (Mercy Day) revived a broken streak. Local-only
  /// (not synced to cloud); null on fresh installs means mercy is available.
  DateTime? lastMercyDate;

  /// Null on legacy rows is treated as dirty until first successful cloud push.
  bool? cloudDirty;

  DateTime? lastSyncedAt;
}
