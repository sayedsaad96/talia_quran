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
  List<WidgetPrayerTime> tomorrowPrayers = const [],
  String? languageCode,
  bool reviewsKnown = false,
  int? nextDueReviewCount,
  List<WidgetReviewCount> reviewCounts = const [],
  bool showPrayer = true,
  bool showReviews = true,
  bool showWird = true,
}) {
  if (!enabled || !isAdult || signedOutOrSwitching) {
    return const WidgetSnapshot.empty();
  }
  final upcoming = _upcomingPrayers(
    now,
    today,
    tomorrow,
    tomorrowFajr,
    tomorrowPrayers,
  );
  final next = upcoming.isEmpty ? null : upcoming.first;
  final wird = _wird(activePlan, now);
  final dayEndsAt = DateTime(
    now.toLocal().year,
    now.toLocal().month,
    now.toLocal().day + 1,
  );
  // The prayer list and the precomputed [nextDay] stay valid until the end of
  // tomorrow. Without a next day, the review and wird rows stop at [dayEndsAt].
  final expiresAt = DateTime(
    now.toLocal().year,
    now.toLocal().month,
    now.toLocal().day + 2,
  );
  final language = languageCode == 'ar' || languageCode == 'en'
      ? languageCode
      : null;
  final reviews = dueReviewCount < 0 ? 0 : dueReviewCount;
  final prayerUnset =
      next == null &&
      today == null &&
      tomorrow == null &&
      tomorrowFajr == null &&
      tomorrowPrayers.isEmpty;
  final noPlan = activePlan == null;
  final settled = reviewsKnown && reviews == 0;
  final nextDay = _nextDay(
    plan: activePlan,
    at: dayEndsAt.add(const Duration(hours: 12)),
    nextDueReviewCount: nextDueReviewCount,
    reviewsKnown: reviewsKnown,
  );
  final nothingToday = next == null && reviews == 0 && wird == null;
  if (nothingToday) {
    return WidgetSnapshot(
      expiresAt: nextDay == null ? dayEndsAt : expiresAt,
      dayEndsAt: nextDay == null ? null : dayEndsAt,
      languageCode: language,
      adultNoData: true,
      prayerUnset: prayerUnset,
      reviewsSettled: settled,
      noKhatmahPlan: noPlan,
      showPrayer: showPrayer,
      showReviews: showReviews,
      showWird: showWird,
      nextDay: nextDay,
      reviewCounts: reviewCounts,
    );
  }
  return WidgetSnapshot(
    expiresAt: expiresAt,
    dayEndsAt: dayEndsAt,
    languageCode: language,
    nextPrayerKey: next?.key,
    nextPrayerAt: next?.at,
    upcomingPrayers: upcoming,
    dueReviewCount: reviews,
    wirdFromPage: wird?.from,
    wirdToPage: wird?.to,
    wirdDonePages: wird?.done,
    wirdSurahName: wird?.surahName,
    prayerUnset: prayerUnset,
    reviewsSettled: settled,
    noKhatmahPlan: noPlan && wird == null,
    showPrayer: showPrayer,
    showReviews: showReviews,
    showWird: showWird,
    nextDay: nextDay,
    reviewCounts: reviewCounts,
  );
}

/// Tomorrow's review count and wird, computed while the app is open.
/// Null when the caller did not supply a next-day review count and there is
/// no plan: older call sites keep the previous "hide after midnight" behavior.
WidgetNextDay? _nextDay({
  required KhatmahPlan? plan,
  required DateTime at,
  required int? nextDueReviewCount,
  required bool reviewsKnown,
}) {
  if (nextDueReviewCount == null && plan == null) return null;
  final wird = _wird(plan, at);
  final count = nextDueReviewCount == null
      ? 0
      : (nextDueReviewCount < 0 ? 0 : nextDueReviewCount);
  return WidgetNextDay(
    dueReviewCount: count,
    reviewsSettled: reviewsKnown && nextDueReviewCount != null && count == 0,
    noKhatmahPlan: plan == null,
    wirdFromPage: wird?.from,
    wirdToPage: wird?.to,
    wirdDonePages: wird?.done,
    wirdSurahName: wird?.surahName,
  );
}

/// Today's remaining fard prayers and tomorrow's, ascending and distinct, so
/// the widget stays right after midnight before the app reopens.
/// The production after-Isha snapshot carries tomorrow's Fajr only as
/// `nextName`/`nextTime`, so that pair is a candidate too.
List<WidgetPrayerTime> _upcomingPrayers(
  DateTime now,
  PrayerTimesSnapshot? today,
  PrayerTimesSnapshot? tomorrow,
  DateTime? tomorrowFajr,
  List<WidgetPrayerTime> tomorrowPrayers,
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
  for (final prayer in tomorrowPrayers) {
    add(prayer.key, prayer.at);
  }
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
