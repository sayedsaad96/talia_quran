import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_stats.dart';

void main() {
  KhatmahHistoryEntry entry(int days) => KhatmahHistoryEntry(
    id: '$days',
    khatmahNumber: 1,
    title: 't',
    startDate: DateTime(2026, 1, 1),
    completedDate: DateTime(2026, 1, days),
    totalDays: days,
  );

  test('stats need at least two completions', () {
    expect(KhatmahHistoryStats.from([entry(30)]), isNull);
    expect(KhatmahHistoryStats.from(const []), isNull);
  });

  test('count, rounded average and fastest', () {
    final stats = KhatmahHistoryStats.from([entry(30), entry(20), entry(25)])!;
    expect(stats.count, 3);
    expect(stats.averageDays, 25);
    expect(stats.fastestDays, 20);
  });
}
