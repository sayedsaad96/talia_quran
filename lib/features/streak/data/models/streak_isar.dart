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

  /// Null on legacy rows is treated as dirty until first successful cloud push.
  bool? cloudDirty;

  DateTime? lastSyncedAt;
}
