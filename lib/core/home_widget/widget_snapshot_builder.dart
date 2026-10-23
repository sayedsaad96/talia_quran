import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;

import '../../features/khatmah/domain/entities/khatmah_plan.dart';
import '../constants/surah_names.dart';
import '../services/prayer_times_service.dart';
import 'widget_snapshot.dart';

WidgetSnapshot buildWidgetSnapshot({
  required bool enabled,
  required bool isAdult,
  required bool signedOutOrSwitching,
  required PrayerTimesSnapshot? today,
  required PrayerTimesSnapshot? tomorrow,
  required int dueReviewCount,
  required KhatmahPlan? activePlan,
  required DateTime now,
}) {
  if (!enabled || !isAdult || signedOutOrSwitching) {
    return const WidgetSnapshot.empty();
  }
  final next = _nextPrayer(now, [today, tomorrow]);
  final wird = _wird(activePlan, now);
  return WidgetSnapshot(
    expiresAt: DateTime(
      now.toLocal().year,
      now.toLocal().month,
      now.toLocal().day + 1,
    ),
    nextPrayerKey: next?.key,
    nextPrayerAt: next?.at,
    dueReviewCount: dueReviewCount < 0 ? 0 : dueReviewCount,
    wirdFromPage: wird?.from,
    wirdToPage: wird?.to,
    wirdDonePages: wird?.done,
    wirdSurahName: wird?.surahName,
  );
}

({String key, DateTime at})? _nextPrayer(
  DateTime now,
  List<PrayerTimesSnapshot?> snapshots,
) {
  final candidates = <({String key, DateTime at})>[];
  for (final snapshot in snapshots) {
    if (snapshot == null) continue;
    _addCandidates(candidates, snapshot, now);
  }
  if (candidates.isEmpty) return null;
  candidates.sort((left, right) => left.at.compareTo(right.at));
  return candidates.first;
}

void _addCandidates(
  List<({String key, DateTime at})> candidates,
  PrayerTimesSnapshot snapshot,
  DateTime now,
) {
  const fard = {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'};
  final fields = <(String, DateTime?)>[
    ('fajr', snapshot.fajr),
    ('dhuhr', snapshot.dhuhr),
    ('asr', snapshot.asr),
    ('maghrib', snapshot.maghrib),
    ('isha', snapshot.isha),
    (snapshot.nextName, snapshot.nextTime),
  ];
  for (final field in fields) {
    if (fard.contains(field.$1) && field.$2 != null && field.$2!.isAfter(now)) {
      candidates.add((key: field.$1, at: field.$2!));
    }
  }
}

({int from, int to, int done, String surahName})? _wird(
  KhatmahPlan? plan,
  DateTime now,
) {
  if (plan == null || plan.status != KhatmahStatus.active || plan.isComplete) {
    return null;
  }
  final range = plan.dailyTargetFor(now);
  if (!_validRange(range.startPage, range.endPage)) return null;
  final surahName = _surahNameForPage(range.startPage);
  if (surahName == null) return null;
  final length = range.endPage - range.startPage + 1;
  final done = plan.dailyCompletedPages(now).clamp(0, length);
  return (
    from: range.startPage,
    to: range.endPage,
    done: done,
    surahName: surahName,
  );
}

bool _validRange(int start, int end) =>
    start >= 1 && end >= start && end <= 604;

String? _surahNameForPage(int page) {
  if (page < 1 || page > 604) return null;
  try {
    final raw = qcf.getPageData(page);
    if (raw.isEmpty || raw.first is! Map) return null;
    final surah = (raw.first as Map)['surah'];
    return surah is int && SurahNames.arabic.containsKey(surah)
        ? SurahNames.nameAr(surah)
        : null;
  } catch (_) {
    return null;
  }
}
