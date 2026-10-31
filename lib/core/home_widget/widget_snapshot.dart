import 'package:equatable/equatable.dart';

/// One future fard prayer the native renderer may pick at draw time.
typedef WidgetPrayerTime = ({String key, DateTime at});
typedef WidgetReviewCount = ({DateTime at, int count});

/// Review and wird fields for one local day. The native side swaps to this
/// after [WidgetSnapshot.dayEndsAt] without reading the account again.
final class WidgetNextDay extends Equatable {
  const WidgetNextDay({
    this.dueReviewCount = 0,
    this.reviewsSettled = false,
    this.noKhatmahPlan = false,
    this.wirdFromPage,
    this.wirdToPage,
    this.wirdDonePages,
    this.wirdSurahName,
  });

  final int dueReviewCount;
  final bool reviewsSettled;
  final bool noKhatmahPlan;
  final int? wirdFromPage;
  final int? wirdToPage;
  final int? wirdDonePages;
  final String? wirdSurahName;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    if (dueReviewCount > 0) json['dueReviewCount'] = dueReviewCount;
    if (reviewsSettled) json['reviewsSettled'] = true;
    if (noKhatmahPlan) json['noKhatmahPlan'] = true;
    _put(json, 'wirdFromPage', wirdFromPage);
    _put(json, 'wirdToPage', wirdToPage);
    _put(json, 'wirdDonePages', wirdDonePages);
    _put(json, 'wirdSurahName', wirdSurahName);
    return Map.unmodifiable(json);
  }

  void _put(Map<String, Object?> json, String key, Object? value) {
    if (value != null) json[key] = value;
  }

  @override
  List<Object?> get props => [
    dueReviewCount,
    reviewsSettled,
    noKhatmahPlan,
    wirdFromPage,
    wirdToPage,
    wirdDonePages,
    wirdSurahName,
  ];
}

/// Privacy-safe, immutable data sent to the platform home widget.
///
/// Additive fields keep `schemaVersion` 1: older snapshots still parse and
/// older native code ignores them. The foreground isolate is the only writer.
final class WidgetSnapshot extends Equatable {
  const WidgetSnapshot({
    this.nextPrayerKey,
    this.nextPrayerAt,
    this.dueReviewCount = 0,
    this.wirdFromPage,
    this.wirdToPage,
    this.wirdDonePages,
    this.wirdSurahName,
    this.expiresAt,
    this.dayEndsAt,
    this.upcomingPrayers = const [],
    this.languageCode,
    this.adultNoData = false,
    this.prayerUnset = false,
    this.reviewsSettled = false,
    this.noKhatmahPlan = false,
    this.showPrayer = true,
    this.showReviews = true,
    this.showWird = true,
    this.nextDay,
    this.reviewCounts = const [],
  });

  const WidgetSnapshot.empty()
    : nextPrayerKey = null,
      nextPrayerAt = null,
      dueReviewCount = 0,
      wirdFromPage = null,
      wirdToPage = null,
      wirdDonePages = null,
      expiresAt = null,
      dayEndsAt = null,
      wirdSurahName = null,
      upcomingPrayers = const [],
      languageCode = null,
      adultNoData = false,
      prayerUnset = false,
      reviewsSettled = false,
      noKhatmahPlan = false,
      showPrayer = true,
      showReviews = true,
      showWird = true,
      nextDay = null,
      reviewCounts = const [];

  /// Allow-listed prayer keys; anything else never reaches the widget.
  static const fardPrayerKeys = {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'};

  int get schemaVersion => 1;
  final String? nextPrayerKey;
  final DateTime? nextPrayerAt;
  final int dueReviewCount;
  final int? wirdFromPage;
  final int? wirdToPage;
  final int? wirdDonePages;
  final String? wirdSurahName;
  final DateTime? expiresAt;

  /// End of the snapshot's local day. From then on the native side uses
  /// [nextDay] for the review and wird rows when it was precomputed, and
  /// otherwise hides those rows. The prayer list keeps rolling on its own.
  final DateTime? dayEndsAt;

  /// Today's remaining fard prayers plus tomorrow's five, ascending. The native
  /// side picks the first one still in the future whenever it draws.
  final List<WidgetPrayerTime> upcomingPrayers;

  /// App language, `ar` or `en`; the native side falls back to the device.
  final String? languageCode;

  /// An adult with nothing to show: stored so the widget can say so in the app
  /// language instead of the generic "open Talia" hint.
  final bool adultNoData;

  /// Prayer times were not available. The widget asks the user to set them
  /// instead of hiding the row.
  final bool prayerUnset;

  /// [dueReviewCount] is a real zero from a successful read, not an omission.
  final bool reviewsSettled;

  /// There is no khatmah plan. Distinct from a paused or finished plan.
  final bool noKhatmahPlan;

  /// Device display choices copied into the snapshot. Defaults stay visible
  /// and are omitted from JSON so older snapshots keep every section.
  final bool showPrayer;
  final bool showReviews;
  final bool showWird;

  /// Precomputed next local day. Drawn after [dayEndsAt] until [expiresAt]
  /// without opening the app or reading the account.
  final WidgetNextDay? nextDay;

  /// Aggregate future counts, without individual review record details.
  final List<WidgetReviewCount> reviewCounts;

  bool get isEmpty =>
      nextPrayerKey == null &&
      nextPrayerAt == null &&
      dueReviewCount == 0 &&
      wirdFromPage == null &&
      wirdToPage == null &&
      wirdDonePages == null &&
      wirdSurahName == null &&
      upcomingPrayers.isEmpty;

  bool get hasGuidance =>
      prayerUnset || reviewsSettled || noKhatmahPlan || nextDay != null;

  /// True when the native key must be removed rather than written.
  bool get clearsNative => isEmpty && !adultNoData && !hasGuidance;

  /// Instants after [now] at which the widget must redraw: each upcoming
  /// prayer, the day end and the expiry.
  List<DateTime> redrawTimes(DateTime now) {
    final times = <DateTime>{
      for (final prayer in upcomingPrayers) prayer.at,
      ?nextPrayerAt,
      ?dayEndsAt,
      ?expiresAt,
      for (final review in reviewCounts) review.at,
    }.where((time) => time.isAfter(now)).toList()..sort();
    return List.unmodifiable(times);
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'schemaVersion': schemaVersion};
    if (isEmpty) {
      if (!adultNoData && !hasGuidance) {
        return Map.unmodifiable({...json, 'isEmpty': true});
      }
      json['isEmpty'] = true;
      if (adultNoData) json['adultNoData'] = true;
      _put(json, 'locale', _language);
      _put(json, 'expiresAt', expiresAt?.millisecondsSinceEpoch);
      _put(json, 'dayEndsAt', dayEndsAt?.millisecondsSinceEpoch);
      _writeGuidance(json);
      return Map.unmodifiable(json);
    }
    json['isEmpty'] = false;
    json['dueReviewCount'] = dueReviewCount;
    _put(json, 'locale', _language);
    _put(json, 'nextPrayerKey', nextPrayerKey);
    _put(json, 'nextPrayerAt', nextPrayerAt?.millisecondsSinceEpoch);
    _put(
      json,
      'nextPrayerOffsetMinutes',
      nextPrayerAt?.timeZoneOffset.inMinutes,
    );
    final prayers = [
      for (final prayer in upcomingPrayers)
        if (fardPrayerKeys.contains(prayer.key))
          {
            'key': prayer.key,
            'at': prayer.at.millisecondsSinceEpoch,
            'offsetMinutes': prayer.at.timeZoneOffset.inMinutes,
          },
    ];
    if (prayers.isNotEmpty) json['upcomingPrayers'] = prayers;
    _put(json, 'expiresAt', expiresAt?.millisecondsSinceEpoch);
    _put(json, 'dayEndsAt', dayEndsAt?.millisecondsSinceEpoch);
    _put(json, 'wirdFromPage', wirdFromPage);
    _put(json, 'wirdToPage', wirdToPage);
    _put(json, 'wirdDonePages', wirdDonePages);
    _put(json, 'wirdSurahName', wirdSurahName);
    _writeGuidance(json);
    return Map.unmodifiable(json);
  }

  void _writeGuidance(Map<String, Object?> json) {
    if (reviewCounts.isNotEmpty) {
      json['reviewCounts'] = [
        for (final review in reviewCounts)
          {'at': review.at.millisecondsSinceEpoch, 'count': review.count},
      ];
    }
    if (prayerUnset) json['prayerUnset'] = true;
    if (reviewsSettled) json['reviewsSettled'] = true;
    if (noKhatmahPlan) json['noKhatmahPlan'] = true;
    if (!showPrayer) json['showPrayer'] = false;
    if (!showReviews) json['showReviews'] = false;
    if (!showWird) json['showWird'] = false;
    final day = nextDay;
    if (day != null) json['nextDay'] = day.toJson();
  }

  String? get _language =>
      languageCode == 'ar' || languageCode == 'en' ? languageCode : null;

  void _put(Map<String, Object?> json, String key, Object? value) {
    if (value != null) json[key] = value;
  }

  @override
  List<Object?> get props => [
    nextPrayerKey,
    nextPrayerAt,
    dueReviewCount,
    wirdFromPage,
    wirdToPage,
    wirdDonePages,
    wirdSurahName,
    expiresAt,
    dayEndsAt,
    upcomingPrayers,
    languageCode,
    adultNoData,
    prayerUnset,
    reviewsSettled,
    noKhatmahPlan,
    showPrayer,
    showReviews,
    showWird,
    nextDay,
    reviewCounts,
  ];
}
