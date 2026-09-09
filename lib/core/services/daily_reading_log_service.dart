import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../identity/account_data_barrier.dart';

/// Day-scoped log of Quran pages the user confirmed as read.
class DailyReadingLogService {
  DailyReadingLogService(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _prefix = 'daily_read_pages_';
  static const _retentionDays = 60;
  static const totalQuranPages = 604;

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  AccountDataBarrier get _barrier => AccountDataBarrier.forPreferences(_prefs);

  String _keyFor(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '$_prefix${local.year}-$mm-$dd';
  }

  List<int> pagesReadOn(DateTime date) {
    final raw = _prefs.getString(_keyFor(date));
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is int && item >= 1 && item <= totalQuranPages) item,
      ];
    } catch (_) {
      return const [];
    }
  }

  bool contains(int pageNumber, {DateTime? date}) {
    return pagesReadOn(date ?? _now()).contains(pageNumber);
  }

  Future<void> recordPage(int pageNumber, {DateTime? date}) async {
    if (pageNumber < 1 || pageNumber > totalQuranPages) return;
    final authority = _barrier.capture();
    await _barrier.run<void>((lease) async {
      final day = date ?? _now();
      final pages = [...pagesReadOn(day)];
      if (pages.contains(pageNumber)) return;
      pages.add(pageNumber);
      await _prefs.setString(_keyFor(day), jsonEncode(pages));
      lease.check();
      await _prune(
        olderThan: _retentionDays,
        relativeTo: day,
        authority: lease,
      );
    }, authority: authority);
  }

  Future<void> prune({int olderThan = _retentionDays, DateTime? relativeTo}) async {
    final authority = _barrier.capture();
    await _barrier.run<void>(
      (lease) => _prune(
        olderThan: olderThan,
        relativeTo: relativeTo,
        authority: lease,
      ),
      authority: authority,
    );
  }

  Future<void> _prune({
    required int olderThan,
    required DateTime? relativeTo,
    required AccountDataLease authority,
  }) async {
    final origin = relativeTo ?? _now();
    final cutoff = DateTime(origin.year, origin.month, origin.day)
        .subtract(Duration(days: olderThan));
    final keys = _prefs.getKeys()
        .where((key) => key.startsWith(_prefix))
        .toList(growable: false);
    for (final key in keys) {
      final stamp = key.substring(_prefix.length);
      final parsed = DateTime.tryParse(stamp);
      if (parsed == null) continue;
      if (parsed.isBefore(cutoff)) {
        await _prefs.remove(key);
        authority.check();
      }
    }
  }
}
