import 'package:isar/isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/streak/domain/entities/streak_entity.dart';
import '../../features/streak/domain/entities/streak_result.dart';

class StreakService {
  StreakService(this._isar);

  final Isar _isar;

  static const List<int> _milestones = [3, 7, 14, 30, 60, 100, 365];

  Future<StreakEntity> getStreak() async {
    final data = await _isar.streakIsars.get(1);
    if (data == null) return const StreakEntity(currentStreak: 0, longestStreak: 0);
    return StreakEntity(
      currentStreak: data.currentStreak,
      longestStreak: data.longestStreak,
      lastActivityDate: data.lastActivityDate,
      freezesAvailable: data.freezesAvailable,
    );
  }

  Future<StreakResult> recordActivity() async {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    return _isar.writeTxn(() async {
      final data = await _isar.streakIsars.get(1) ?? StreakIsar();
      final lastDate = data.lastActivityDate;

      if (lastDate != null) {
        final lastNormalized =
            DateTime(lastDate.year, lastDate.month, lastDate.day);

        // Same day → no change
        if (lastNormalized == todayDate) {
          return const StreakResult.sameDay();
        }

        final yesterday = todayDate.subtract(const Duration(days: 1));

        if (lastNormalized == yesterday) {
          // Consecutive day
          data.currentStreak += 1;
        } else {
          // Streak broken — reset to 1
          data.currentStreak = 1;
        }
      } else {
        // First time
        data.currentStreak = 1;
      }

      final isNewRecord = data.currentStreak > data.longestStreak;
      if (isNewRecord) data.longestStreak = data.currentStreak;

      data.lastActivityDate = todayDate;
      await _isar.streakIsars.put(data);

      return StreakResult(
        currentStreak: data.currentStreak,
        longestStreak: data.longestStreak,
        isNewActivity: true,
        isNewRecord: isNewRecord,
        milestoneReached: _milestones.contains(data.currentStreak)
            ? data.currentStreak
            : null,
      );
    });
  }

  Future<void> useFreeze() async {
    await _isar.writeTxn(() async {
      final data = await _isar.streakIsars.get(1);
      if (data == null || data.freezesAvailable <= 0) return;
      data.freezesAvailable -= 1;
      if (data.lastActivityDate != null) {
        data.lastActivityDate =
            data.lastActivityDate!.add(const Duration(days: 1));
      }
      await _isar.streakIsars.put(data);
    });
  }

  Future<void> addFreeze(int count) async {
    await _isar.writeTxn(() async {
      final data = await _isar.streakIsars.get(1) ?? StreakIsar();
      data.freezesAvailable += count;
      await _isar.streakIsars.put(data);
    });
  }
}
