import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/memorization/listening/listening_round_result.dart';

final class ListeningReviewStats extends Equatable {
  const ListeningReviewStats({
    this.lastCorrect,
    this.lastScored,
    this.bestPercent,
  });

  static const empty = ListeningReviewStats();

  final int? lastCorrect;
  final int? lastScored;
  final int? bestPercent;

  bool get hasPlayed => lastScored != null;

  @override
  List<Object?> get props => [lastCorrect, lastScored, bestPercent];
}

/// Local, owner-scoped practice stats. Not progress of record: never synced
/// and never read by SRS.
class ListeningReviewStatsStore {
  ListeningReviewStatsStore(this._prefs, this._owner);

  static const _keyPrefix = 'listening_review_stats_v1_';

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  String get _key => '$_keyPrefix${_owner.currentOwnerId}';

  ListeningReviewStats read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return ListeningReviewStats.empty;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ListeningReviewStats(
        lastCorrect: map['lastCorrect'] as int?,
        lastScored: map['lastScored'] as int?,
        bestPercent: map['bestPercent'] as int?,
      );
    } catch (_) {
      return ListeningReviewStats.empty;
    }
  }

  Future<void> record(ListeningRoundResult result) async {
    if (result.scored == 0) return;
    final percent = (result.correct * 100 / result.scored).round();
    final best = max(percent, read().bestPercent ?? 0);
    await _prefs.setString(
      _key,
      jsonEncode({
        'lastCorrect': result.correct,
        'lastScored': result.scored,
        'bestPercent': best,
      }),
    );
  }
}
