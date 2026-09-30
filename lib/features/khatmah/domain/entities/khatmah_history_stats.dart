import 'khatmah_history_entry.dart';

/// A small summary of completed khatmahs.
class KhatmahHistoryStats {
  const KhatmahHistoryStats({
    required this.count,
    required this.averageDays,
    required this.fastestDays,
  });

  final int count;
  final int averageDays;
  final int fastestDays;

  /// Null below two completions, where average and fastest mean nothing.
  static KhatmahHistoryStats? from(List<KhatmahHistoryEntry> entries) {
    if (entries.length < 2) return null;
    final days = entries.map((entry) => entry.totalDays).toList();
    final total = days.fold(0, (sum, value) => sum + value);
    return KhatmahHistoryStats(
      count: entries.length,
      averageDays: (total / entries.length).round(),
      fastestDays: days.reduce((a, b) => a < b ? a : b),
    );
  }
}
