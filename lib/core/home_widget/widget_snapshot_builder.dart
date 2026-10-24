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
  DateTime? tomorrowFajr,
  String? languageCode,
}) {
  if (!enabled || !isAdult || signedOutOrSwitching) {
    return const WidgetSnapshot.empty();
  }
  final upcoming = _upcomingPrayers(now, today, tomorrow, tomorrowFajr);
  final next = upcoming.isEmpty ? null : upcoming.first;
  final wird = _wird(activePlan, now);
  final expiresAt = DateTime(
    now.toLocal().year,
    now.toLocal().month,
    now.toLocal().day + 1,
  );
  final language = languageCode == 'ar' || languageCode == 'en'
      ? languageCode
      : null;
  final reviews = dueReviewCount < 0 ? 0 : dueReviewCount;
  if (next == null && reviews == 0 && wird == null) {
    return WidgetSnapshot(
      expiresAt: expiresAt,
      languageCode: language,
      adultNoData: true,
    );
  }
  return WidgetSnapshot(
    expiresAt: expiresAt,
    languageCode: language,
    nextPrayerKey: next?.key,
    nextPrayerAt: next?.at,
    upcomingPrayers: upcoming,
    dueReviewCount: reviews,
    wirdFromPage: wird?.from,
    wirdToPage: wird?.to,
    wirdDonePages: wird?.done,
    wirdSurahName: wird?.surahName,
  );
}

/// Today's remaining fard prayers and the next Fajr, ascending and distinct.
/// The production after-Isha snapshot carries tomorrow's Fajr only as
/// `nextName`/`nextTime`, so that pair is a candidate too.
List<WidgetPrayerTime> _upcomingPrayers(
  DateTime now,
  PrayerTimesSnapshot? today,
  PrayerTimesSnapshot? tomorrow,
  DateTime? tomorrowFajr,
) {
  final candidates = <WidgetPrayerTime>[];
  void add(String key, DateTime? at) {
    if (!WidgetSnapshot.fardPrayerKeys.contains(key) ||
        at == null ||
        !at.isAfter(now)) {
      return;
    }
    final exists = candidates.any(
      (candidate) =>
          candidate.key == key &&
          candidate.at.millisecondsSinceEpoch == at.millisecondsSinceEpoch,
    );
    if (!exists) candidates.add((key: key, at: at));
  }

  for (final snapshot in [today, tomorrow]) {
    if (snapshot == null) continue;
    add('fajr', snapshot.fajr);
    if (identical(snapshot, today)) {
      add('dhuhr', snapshot.dhuhr);
      add('asr', snapshot.asr);
      add('maghrib', snapshot.maghrib);
      add('isha', snapshot.isha);
      add(snapshot.nextName, snapshot.nextTime);
    }
  }
  add('fajr', tomorrowFajr);
  candidates.sort((left, right) => left.at.compareTo(right.at));
  return List.unmodifiable(candidates);
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
