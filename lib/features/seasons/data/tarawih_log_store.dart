import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/identity/record_owner_provider.dart';

/// One night of tarawih: the page range the imam recited. Self-log only; it is
/// never counted toward a khatmah.
final class TarawihEntry extends Equatable {
  const TarawihEntry({
    required this.nightKey,
    required this.fromPage,
    required this.toPage,
  });

  /// Local date, `yyyy-mm-dd`.
  final String nightKey;
  final int fromPage;
  final int toPage;

  bool get isValid => fromPage >= 1 && fromPage <= toPage && toPage <= 604;

  Map<String, Object> toJson() => {
    'night': nightKey,
    'from': fromPage,
    'to': toPage,
  };

  static TarawihEntry? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final night = raw['night'];
    final from = raw['from'];
    final to = raw['to'];
    if (night is! String || from is! int || to is! int) return null;
    final entry = TarawihEntry(nightKey: night, fromPage: from, toPage: to);
    return entry.isValid ? entry : null;
  }

  @override
  List<Object?> get props => [nightKey, fromPage, toPage];
}

class TarawihLogStore {
  TarawihLogStore(this._prefs, this._owner);

  static const String _base = 'ramadan_tarawih';

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  Future<void> _queue = Future<void>.value();

  String get _key => '$_base|${_owner.currentOwnerId}';

  Future<List<TarawihEntry>> entries() => _read(_key);

  Future<List<TarawihEntry>> _read(String key) async {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final result = <TarawihEntry>[];
      for (final item in decoded) {
        final entry = TarawihEntry.tryFromJson(item);
        if (entry != null) result.add(entry);
      }
      result.sort((a, b) => a.nightKey.compareTo(b.nightKey));
      return result;
    } catch (_) {
      return const [];
    }
  }

  /// Runs [action] after earlier writes finish, so concurrent calls cannot
  /// lose updates. The owner key is captured by the caller before queueing.
  Future<void> _serialized(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.catchError((_) {});
    return next;
  }

  /// Throws [ArgumentError] for a range outside 1 <= from <= to <= 604.
  Future<void> upsert(TarawihEntry entry) {
    if (!entry.isValid) {
      throw ArgumentError.value(entry, 'entry', 'Invalid page range');
    }
    final key = _key;
    return _serialized(() async {
      final all = (await _read(
        key,
      )).where((e) => e.nightKey != entry.nightKey).toList()..add(entry);
      await _write(key, all);
    });
  }

  Future<void> remove(String nightKey) {
    final key = _key;
    return _serialized(() async {
      final all = (await _read(
        key,
      )).where((e) => e.nightKey != nightKey).toList();
      await _write(key, all);
    });
  }

  /// Distinct pages across [entries]; overlapping ranges count once.
  int totalPagesHeard(List<TarawihEntry> entries) {
    final pages = <int>{};
    for (final e in entries) {
      for (var p = e.fromPage; p <= e.toPage; p++) {
        pages.add(p);
      }
    }
    return pages.length;
  }

  Future<void> _write(String key, List<TarawihEntry> all) =>
      _prefs.setString(key, jsonEncode(all.map((e) => e.toJson()).toList()));
}
