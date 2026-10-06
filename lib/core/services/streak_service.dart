import 'dart:async';

import 'package:isar_community/isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/streak/domain/entities/streak_entity.dart';
import '../../features/streak/domain/entities/streak_result.dart';
import '../progress/progress_changed_reason.dart';
import '../progress/progress_events_bus.dart';
import 'milestone_notification.dart';
import 'streak_day.dart';
import 'streak_reader.dart';

class StreakService implements StreakReader {
  StreakService(this._isar, this._progressEvents);

  final Isar _isar;
  final ProgressEventsBus _progressEvents;

  static const List<int> _milestones = [3, 7, 14, 30, 60, 100, 365];

  @override
  Future<StreakEntity> getStreak() async {
    final data = await _isar.streakIsars.get(1);
    if (data == null) {
      return const StreakEntity(currentStreak: 0, longestStreak: 0);
    }
    return StreakEntity(
      currentStreak: data.currentStreak,
      longestStreak: data.longestStreak,
      lastActivityDate: data.lastActivityDate,
      freezesAvailable: data.freezesAvailable,
    );
  }

  Future<StreakResult> recordActivity({int activityDelta = 1}) async {
    // One shared rule: the learner's local calendar day (see [StreakDay]).
    final todayDate = StreakDay.of(DateTime.now());
    final dayKey = StreakDay.dayKey(todayDate);

    final result = await _isar.writeTxn(() async {
      final data = await _isar.streakIsars.get(1) ?? StreakIsar();
      final next = StreakDay.transition(
        currentStreak: data.currentStreak,
        longestStreak: data.longestStreak,
        lastDay: data.lastActivityDate,
        lastMercyDay: data.lastMercyDate,
        today: todayDate,
      );

      // Same day → increment daily activity but don't change streak.
      if (!next.isNewDay) {
        await _upsertDailyActivity(dayKey, activityDelta);
        _progressEvents.notify(ProgressChangedReason.streak);
        return const StreakResult.sameDay();
      }

      data.currentStreak = next.currentStreak;
      data.longestStreak = next.longestStreak;
      data.lastMercyDate = next.lastMercyDay;
      data.lastActivityDate = todayDate;
      data.cloudDirty = true;
      await _isar.streakIsars.put(data);

      // Record into DailyActivityIsar for the heatmap.
      await _upsertDailyActivity(dayKey, activityDelta);

      _progressEvents.notify(ProgressChangedReason.streak);

      return StreakResult(
        currentStreak: data.currentStreak,
        longestStreak: data.longestStreak,
        isNewActivity: true,
        isNewRecord: next.isNewRecord,
        milestoneReached: _milestones.contains(data.currentStreak)
            ? data.currentStreak
            : null,
        mercyApplied: next.mercyApplied,
      );
    });

    if (result.mercyApplied) {
      // The gentle mercy moment — fire-and-forget, never blocks the write.
      unawaited(fireStreakMercyCelebration());
    }
    return result;
  }

  /// Upsert a daily activity record (inside an existing write transaction).
  Future<void> _upsertDailyActivity(int dayKey, int delta) async {
    final existing = await _isar.dailyActivityIsars
        .where()
        .dayKeyEqualTo(dayKey)
        .findFirst();

    if (existing != null) {
      existing.activityCount += delta;
      existing.cloudDirty = true;
      await _isar.dailyActivityIsars.put(existing);
    } else {
      final entry = DailyActivityIsar()
        ..dayKey = dayKey
        ..activityCount = delta
        ..cloudDirty = true;
      await _isar.dailyActivityIsars.put(entry);
    }
  }

  /// Read activity map for the last [days] days. Returns Map<'YYYY-MM-DD', count>.
  Future<Map<String, int>> getActivityMap({int days = 365}) async {
    final since = StreakDay.of(
      DateTime.now(),
    ).subtract(Duration(days: days - 1));
    final sinceKey = StreakDay.dayKey(since);

    final records = await _isar.dailyActivityIsars
        .where()
        .dayKeyGreaterThan(sinceKey - 1)
        .findAll();

    final map = <String, int>{};
    for (final r in records) {
      final key = _dayKeyToString(r.dayKey);
      map[key] = r.activityCount;
    }
    return map;
  }

  String _dayKeyToString(int dayKey) {
    final y = dayKey ~/ 10000;
    final m = (dayKey % 10000) ~/ 100;
    final d = dayKey % 100;
    return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  Future<void> useFreeze() async {
    await _isar.writeTxn(() async {
      final data = await _isar.streakIsars.get(1);
      if (data == null || data.freezesAvailable <= 0) return;
      data.freezesAvailable -= 1;
      if (data.lastActivityDate != null) {
        data.lastActivityDate = data.lastActivityDate!.add(
          const Duration(days: 1),
        );
      }
      data.cloudDirty = true;
      await _isar.streakIsars.put(data);
    });
  }

  Future<void> addFreeze(int count) async {
    await _isar.writeTxn(() async {
      final data = await _isar.streakIsars.get(1) ?? StreakIsar();
      data.freezesAvailable += count;
      data.cloudDirty = true;
      await _isar.streakIsars.put(data);
    });
  }
}
