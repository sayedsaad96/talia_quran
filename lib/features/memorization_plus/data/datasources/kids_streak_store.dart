import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/services/streak_day.dart';
import '../../../../core/services/streak_reader.dart';
import '../../../streak/domain/entities/streak_entity.dart';

/// Streak state copied from the shared adult streak the first time the kids
/// store is read, so a child who built a streak before the split keeps it.
class KidsStreakSeed {
  const KidsStreakSeed({required this.streak, this.activityByDay = const {}});

  final StreakEntity streak;

  /// `YYYY-MM-DD` → activity count, as [getActivityMap] returns it.
  final Map<String, int> activityByDay;
}

/// The kids track's own streak and daily activity, owner-scoped.
///
/// Kids sessions and kids reading never touch the shared [StreakService]:
/// that streak belongs to the primary (adult) learner and is shown on home
/// and "تقدمي". Same day rule as the adult streak ([StreakDay]).
class KidsStreakStore implements StreakReader {
  KidsStreakStore(
    this._prefs,
    this._owner, {
    DateTime Function()? clock,
    Future<KidsStreakSeed?> Function()? legacySeed,
    Future<void> Function()? onRecorded,
  }) : _clock = clock ?? DateTime.now,
       _legacySeed = legacySeed,
       _onRecorded = onRecorded;

  static const int retainDays = 60;

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final DateTime Function() _clock;
  final Future<KidsStreakSeed?> Function()? _legacySeed;

  /// Runs after an activity is stored; its failure never undoes the write.
  final Future<void> Function()? _onRecorded;
  Future<void> _tail = Future<void>.value();

  String get _key => 'kids_streak_${_owner.currentOwnerId}';

  @override
  Future<StreakEntity> getStreak() async {
    final data = await _read();
    return StreakEntity(
      currentStreak: data.current,
      longestStreak: data.longest,
      lastActivityDate: data.lastDay,
    );
  }

  /// `YYYY-MM-DD` → activity count for the last [days] days.
  Future<Map<String, int>> getActivityMap({int days = 30}) async {
    final data = await _read();
    final since = _dayString(
      StreakDay.of(_clock()).subtract(Duration(days: days - 1)),
    );
    return {
      for (final entry in data.days.entries)
        if (entry.key.compareTo(since) >= 0) entry.key: entry.value,
    };
  }

  Future<void> recordActivity({int activityDelta = 1}) {
    // Serialize the read-modify-write so overlapping calls never drop one.
    final result = _tail.then((_) => _record(activityDelta));
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _record(int activityDelta) async {
    final today = StreakDay.of(_clock());
    final data = await _read();
    final next = StreakDay.transition(
      currentStreak: data.current,
      longestStreak: data.longest,
      lastDay: data.lastDay,
      lastMercyDay: data.lastMercyDay,
      today: today,
    );
    final todayKey = _dayString(today);
    final cutoff = _dayString(today.subtract(const Duration(days: retainDays)));
    final days = Map<String, int>.of(data.days)
      ..removeWhere((day, _) => day.compareTo(cutoff) < 0)
      ..update(
        todayKey,
        (count) => count + activityDelta,
        ifAbsent: () => activityDelta,
      );
    await _write(
      _KidsStreakData(
        current: next.currentStreak,
        longest: next.longestStreak,
        lastDay: next.isNewDay ? today : data.lastDay,
        lastMercyDay: next.lastMercyDay,
        days: days,
      ),
    );
    try {
      await _onRecorded?.call();
    } catch (_) {}
  }

  Future<_KidsStreakData> _read() async {
    final raw = _prefs.getString(_key);
    if (raw != null) return _KidsStreakData.decode(raw);
    final seed = await _seed();
    if (seed == null) return _KidsStreakData.empty;
    final data = _KidsStreakData(
      current: seed.streak.currentStreak,
      longest: seed.streak.longestStreak,
      lastDay: seed.streak.lastActivityDate == null
          ? null
          : StreakDay.stored(seed.streak.lastActivityDate!),
      lastMercyDay: null,
      days: seed.activityByDay,
    );
    await _write(data);
    return data;
  }

  Future<KidsStreakSeed?> _seed() async {
    try {
      return await _legacySeed?.call();
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(_KidsStreakData data) =>
      _prefs.setString(_key, data.encode());

  static String _dayString(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}'
      '-${day.day.toString().padLeft(2, '0')}';
}

class _KidsStreakData {
  const _KidsStreakData({
    required this.current,
    required this.longest,
    required this.lastDay,
    required this.lastMercyDay,
    required this.days,
  });

  static const empty = _KidsStreakData(
    current: 0,
    longest: 0,
    lastDay: null,
    lastMercyDay: null,
    days: {},
  );

  final int current;
  final int longest;
  final DateTime? lastDay;
  final DateTime? lastMercyDay;
  final Map<String, int> days;

  String encode() => jsonEncode({
    'current': current,
    'longest': longest,
    'lastDay': lastDay?.toIso8601String(),
    'lastMercyDay': lastMercyDay?.toIso8601String(),
    'days': days,
  });

  static _KidsStreakData decode(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return empty;
      DateTime? day(Object? value) {
        final parsed = value is String ? DateTime.tryParse(value) : null;
        return parsed == null ? null : StreakDay.stored(parsed);
      }

      final rawDays = json['days'];
      return _KidsStreakData(
        current: json['current'] is int ? json['current'] as int : 0,
        longest: json['longest'] is int ? json['longest'] as int : 0,
        lastDay: day(json['lastDay']),
        lastMercyDay: day(json['lastMercyDay']),
        days: {
          if (rawDays is Map)
            for (final entry in rawDays.entries)
              if (entry.key is String && entry.value is int)
                entry.key as String: entry.value as int,
        },
      );
    } catch (_) {
      return empty;
    }
  }
}
