import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/azkar_time_context.dart';

/// One persisted in-progress/completed smart-wird session for a given day.
class SmartWirdSession {
  const SmartWirdSession({
    required this.dayPart,
    required this.counts,
    required this.updatedAt,
    this.period,
  });

  final AzkarDayPart dayPart;

  /// Morning or evening. Null for sessions saved before this field existed;
  /// those resume by [dayPart] only.
  final AzkarPeriod? period;

  /// Persisted counts keyed by zikr id (only entries > 0 are stored).
  final Map<String, int> counts;

  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'dayPart': dayPart.name,
        'period': period?.name,
        'counts': counts,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  static SmartWirdSession fromJson(Map<String, dynamic> json) {
    final rawCounts = (json['counts'] as Map<String, dynamic>? ?? const {});
    return SmartWirdSession(
      dayPart: AzkarTimeContext.dayPartFromName(
        json['dayPart'] as String? ?? '',
      ),
      period: AzkarPeriod.values
          .where((value) => value.name == json['period'])
          .firstOrNull,
      counts: {
        for (final entry in rawCounts.entries)
          if (entry.value is int && (entry.value as int) > 0)
            entry.key: entry.value as int,
      },
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['updatedAt'] as int? ?? 0,
      ),
    );
  }
}

/// Persistence for the smart wird: one active session per calendar day
/// (resumable), plus an append-only log of completed sessions for the last
/// [maxHistory] days so the hub can show streak-like progress.
class SmartWirdProgressStore {
  SmartWirdProgressStore(this._prefs, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  static const activeKeyPrefix = 'azkar_smart_wird_active';
  static const _historyKey = 'azkar_smart_wird_history';
  static const maxHistory = 30;

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  Future<void> _tail = Future<void>.value();

  /// Completes when every queued write has finished — used by tests to wait
  /// for unawaited persistence calls deterministically.
  Future<void> flush() => _tail;

  String _dayKey([DateTime? date]) {
    final now = date ?? _now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// The active (in-progress or freshly completed) session for today, if any.
  SmartWirdSession? activeSession([DateTime? date]) {
    final raw = _prefs.getString('$activeKeyPrefix:${_dayKey(date)}');
    if (raw == null) return null;
    try {
      return SmartWirdSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves or updates today's active session (resume point). The optional
  /// [date] mirrors the caller's session clock (tests inject a fixed time).
  Future<void> saveActiveSession(SmartWirdSession session, [DateTime? date]) =>
      _serialize(() {
        return _prefs.setString(
          '$activeKeyPrefix:${_dayKey(date)}',
          jsonEncode(session.toJson()),
        );
      });

  /// Clears today's active session (after reset).
  Future<void> clearActiveSession([DateTime? date]) => _serialize(() {
        return _prefs.remove('$activeKeyPrefix:${_dayKey(date)}');
      });

  /// Appends a completed session to the rolling history log.
  Future<void> recordCompletion({
    required AzkarDayPart dayPart,
    required List<String> itemIds,
    DateTime? date,
  }) =>
      _serialize(() async {
        final raw = _prefs.getString(_historyKey);
        final history = <Map<String, dynamic>>[];
        if (raw != null) {
          try {
            final decoded = jsonDecode(raw) as List<dynamic>;
            history.addAll(decoded.cast<Map<String, dynamic>>());
          } catch (_) {
            // Corrupt history starts fresh; active sessions are untouched.
          }
        }
        history.add({
          'dayPart': dayPart.name,
          'itemIds': itemIds,
          'completedAt': (date ?? _now()).millisecondsSinceEpoch,
        });
        // Rolling window: keep only the most recent entries.
        final trimmed = history.length > maxHistory
            ? history.sublist(history.length - maxHistory)
            : history;
        await _prefs.setString(_historyKey, jsonEncode(trimmed));
      });

  /// Completed session timestamps within the last [days] days, oldest first.
  List<DateTime> completionHistory({int days = maxHistory}) {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final cutoff = _now().subtract(Duration(days: days));
      return decoded
          .cast<Map<String, dynamic>>()
          .map((entry) =>
              DateTime.fromMillisecondsSinceEpoch(entry['completedAt'] as int))
          .where((time) => time.isAfter(cutoff))
          .toList()
        ..sort();
    } catch (_) {
      return const [];
    }
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}
