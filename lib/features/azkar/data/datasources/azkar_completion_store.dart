import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/azkar_entities.dart';

/// Shared persistence for azkar counters, shared by [AzkarCubit] and Home.
class AzkarCompletionStore {
  AzkarCompletionStore(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const counterPrefix = 'azkar_counter_';
  static const datePrefix = 'azkar_date_';
  static const donePrefix = 'azkar_all_done_';

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  Future<void> _tail = Future<void>.value();

  String todayKey([DateTime? date]) {
    final now = date ?? _now();
    return '${now.year}-${now.month}-${now.day}';
  }

  bool isToday(AzkarCategory category, [DateTime? date]) {
    return _prefs.getString('$datePrefix${category.name}') == todayKey(date);
  }

  int countFor(AzkarCategory category, String zikrId, [DateTime? date]) {
    if (!isToday(category, date)) return 0;
    return _prefs.getInt('$counterPrefix${category.name}_$zikrId') ?? 0;
  }

  bool isCategoryComplete(AzkarCategory category, [DateTime? date]) {
    if (!isToday(category, date)) return false;
    return _prefs.getBool('$donePrefix${category.name}') ?? false;
  }

  bool isCompleteFromSessions({
    required AzkarCategory category,
    required Iterable<Zikr> items,
    DateTime? date,
  }) {
    if (items.isEmpty) return false;
    if (!isToday(category, date)) return false;
    return items.every((zikr) => countFor(category, zikr.id, date) >= zikr.totalCount);
  }

  /// Makes [category] ready for [date], clearing stale counters atomically
  /// before publishing the new day stamp.
  Future<void> prepareForToday(AzkarCategory category, [DateTime? date]) =>
      _serialize(() => _rolloverIfNeeded(category, date));

  /// Legacy name kept for callers that only need to establish today's state.
  Future<void> stampDate(AzkarCategory category, [DateTime? date]) =>
      prepareForToday(category, date);

  Future<void> setCount({
    required AzkarCategory category,
    required String zikrId,
    required int count,
    DateTime? date,
  }) => _serialize(() async {
    await _rolloverIfNeeded(category, date);
    await _prefs.setInt('$counterPrefix${category.name}_$zikrId', count);
  });

  Future<void> setAllDone(AzkarCategory category, bool done, [DateTime? date]) =>
      _serialize(() async {
        await _rolloverIfNeeded(category, date);
        await _prefs.setBool('$donePrefix${category.name}', done);
      });

  Future<void> clearCategory(AzkarCategory category) =>
      _serialize(() => _clearCategory(category));

  Future<void> _rolloverIfNeeded(
    AzkarCategory category,
    DateTime? date,
  ) async {
    if (isToday(category, date)) return;
    await _clearCategory(category);
    await _prefs.setString('$datePrefix${category.name}', todayKey(date));
  }

  Future<void> _clearCategory(AzkarCategory category) async {
    final prefix = '$counterPrefix${category.name}_';
    for (final key in _prefs.getKeys().where((k) => k.startsWith(prefix))) {
      await _prefs.remove(key);
    }
    await _prefs.remove('$donePrefix${category.name}');
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
