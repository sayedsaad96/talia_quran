import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/memorization/listening/listening_round_result.dart';

final class ListeningReviewStats extends Equatable {
  const ListeningReviewStats({
    this.lastCorrect,
    this.lastScored,
    this.bestPercentByMode = const {},
  });

  static const empty = ListeningReviewStats();

  final int? lastCorrect;
  final int? lastScored;
  final Map<ListeningQuizMode, int> bestPercentByMode;

  bool get hasPlayed => lastScored != null;

  int? bestPercentFor(ListeningQuizMode mode) => bestPercentByMode[mode];

  @override
  List<Object?> get props => [lastCorrect, lastScored, bestPercentByMode];
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
      final best = (map['bestByMode'] as Map<String, dynamic>?) ?? const {};
      return ListeningReviewStats(
        lastCorrect: map['lastCorrect'] as int?,
        lastScored: map['lastScored'] as int?,
        bestPercentByMode: {
          for (final mode in ListeningQuizMode.values)
            if (best[mode.name] case final int percent) mode: percent,
        },
      );
    } catch (_) {
      return ListeningReviewStats.empty;
    }
  }

  Future<void> record(
    ListeningRoundResult result, {
    required ListeningQuizMode mode,
  }) async {
    if (result.scored == 0) return;
    final percent = (result.correct * 100 / result.scored).round();
    final best = {...read().bestPercentByMode};
    best[mode] = max(percent, best[mode] ?? 0);
    await _prefs.setString(
      _key,
      jsonEncode({
        'lastCorrect': result.correct,
        'lastScored': result.scored,
        'bestByMode': {for (final e in best.entries) e.key.name: e.value},
      }),
    );
  }
}
