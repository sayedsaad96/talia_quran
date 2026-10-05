import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/services/kids_daily_missions.dart';

/// Owner-scoped record of the Mushaf pages the child explicitly confirmed
/// reading, per local day. Stored as `{ "yyyy-MM-dd": [sorted unique pages] }`.
/// Opening a page never records it; only an explicit confirmation does.
class KidsReadingReceiptStore {
  KidsReadingReceiptStore(
    this._prefs,
    this._owner, {
    DateTime Function()? clock,
    Future<void> Function()? onRecorded,
  }) : _clock = clock ?? DateTime.now,
       _onRecorded = onRecorded;

  static const int retainDays = 60;
  static const int _lastPage = 604;

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final DateTime Function() _clock;

  /// Runs after a page is stored; its failure never undoes the receipt.
  final Future<void> Function()? _onRecorded;
  Future<void> _tail = Future<void>.value();

  String get _key => 'kids_reading_receipts_${_owner.currentOwnerId}';

  /// Records [pageNumber] (1..604) for today; returns today's unique pages.
  Future<Set<int>> recordPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > _lastPage) {
      throw ArgumentError.value(pageNumber, 'pageNumber', 'must be 1..604');
    }
    // Serialize the read-modify-write so overlapping calls never drop a page,
    // even if the previous call failed.
    final result = _tail.then((_) => _record(pageNumber));
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<Set<int>> _record(int pageNumber) async {
    final now = _clock();
    final today = kidsDayKey(now);
    final cutoff = kidsDayKey(now.subtract(const Duration(days: retainDays)));
    final all = _readAll();
    // yyyy-MM-dd keys compare chronologically as strings.
    all.removeWhere((day, _) => day.compareTo(cutoff) < 0);
    final pages = (all[today] ?? <int>{})..add(pageNumber);
    all[today] = pages;
    await _prefs.setString(
      _key,
      jsonEncode({
        for (final entry in all.entries)
          entry.key: entry.value.toList()..sort(),
      }),
    );
    try {
      await _onRecorded?.call();
    } catch (_) {}
    return Set<int>.of(pages);
  }

  Future<Set<int>> pagesOn(String dayKey) async =>
      Set<int>.of(_readAll()[dayKey] ?? const <int>{});

  /// Distinct pages across the retained [retainDays] history.
  Future<Set<int>> allPages() async => {
    for (final pages in _readAll().values) ...pages,
  };

  Map<String, Set<int>> _readAll() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is List)
            entry.key as String: {
              for (final p in entry.value as List)
                if (p is int && p >= 1 && p <= _lastPage) p,
            },
      };
    } catch (_) {
      return {};
    }
  }
}
