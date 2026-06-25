// lib/core/memorization/v2/hint_usage.dart

import 'package:equatable/equatable.dart';

/// Hint levels — Product Rules §5 & §14.6
enum V2HintLevel {
  none, // Full score
  firstWord, // Reduced score
  fullAyah; // Minimum passing score — Smart Coach records dependency

  bool get hasPenalty => this != V2HintLevel.none;
  bool get isReading => this == V2HintLevel.fullAyah;
  int get value => index; // 0, 1, 2

  /// Level never decreases within a session.
  V2HintLevel max(V2HintLevel other) => index >= other.index ? this : other;
}

/// Immutable record of hint usage for one ayah in a session.
final class V2HintUsage extends Equatable {
  const V2HintUsage({
    required this.surahId,
    required this.ayahNumber,
    required this.level,
    required this.usedAt,
  });

  final int surahId;
  final int ayahNumber;
  final V2HintLevel level;
  final DateTime usedAt;

  String get ayahKey => '$surahId:$ayahNumber';

  V2HintUsage escalate(V2HintLevel newLevel) {
    if (newLevel.index <= level.index) return this;
    return V2HintUsage(
      surahId: surahId,
      ayahNumber: ayahNumber,
      level: newLevel,
      usedAt: DateTime.now().toUtc(),
    );
  }

  @override
  List<Object?> get props => [surahId, ayahNumber, level, usedAt];
}

/// Tracks all hint usages within a single V2 session.
final class V2HintTracker extends Equatable {
  const V2HintTracker({Map<String, V2HintUsage>? usages})
    : _usages = usages ?? const {};

  final Map<String, V2HintUsage> _usages;

  static const empty = V2HintTracker();

  V2HintLevel levelFor(int surahId, int ayahNumber) =>
      _usages['$surahId:$ayahNumber']?.level ?? V2HintLevel.none;

  V2HintTracker record({
    required int surahId,
    required int ayahNumber,
    required V2HintLevel level,
  }) {
    final key = '$surahId:$ayahNumber';
    final existing = _usages[key];
    final updated = existing == null
        ? V2HintUsage(
            surahId: surahId,
            ayahNumber: ayahNumber,
            level: level,
            usedAt: DateTime.now().toUtc(),
          )
        : existing.escalate(level);

    if (existing != null && updated.level == existing.level) return this;
    return V2HintTracker(usages: {..._usages, key: updated});
  }

  Iterable<V2HintUsage> get allUsages => _usages.values;
  Iterable<V2HintUsage> get fullAyahDependencies =>
      _usages.values.where((u) => u.level == V2HintLevel.fullAyah);
  bool get hasAnyHint => _usages.isNotEmpty;
  int get hintedAyahCount => _usages.length;

  @override
  List<Object?> get props => [_usages];
}
