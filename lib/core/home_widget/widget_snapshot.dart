import 'package:equatable/equatable.dart';

/// One future fard prayer the native renderer may pick at draw time.
typedef WidgetPrayerTime = ({String key, DateTime at});

/// Privacy-safe, immutable data sent to the platform home widget.
///
/// Additive fields (`upcomingPrayers`, `locale`, `adultNoData`) keep
/// `schemaVersion` 1: older snapshots still parse and older native code ignores
/// them.
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
      adultNoData = false;

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

  /// End of the snapshot's local day. From then on the native side hides the
  /// review and wird rows (they describe that day) but keeps the prayer row.
  /// Missing in older snapshots, which means no day end.
  final DateTime? dayEndsAt;

  /// Today's remaining fard prayers plus tomorrow's five, ascending. The native
  /// side picks the first one still in the future whenever it draws.
  final List<WidgetPrayerTime> upcomingPrayers;

  /// App language, `ar` or `en`; the native side falls back to the device.
  final String? languageCode;

  /// An adult with nothing to show: stored so the widget can say so in the app
  /// language instead of the generic "open Talia" hint.
  final bool adultNoData;

  bool get isEmpty =>
      nextPrayerKey == null &&
      nextPrayerAt == null &&
      dueReviewCount == 0 &&
      wirdFromPage == null &&
      wirdToPage == null &&
      wirdDonePages == null &&
      wirdSurahName == null &&
      upcomingPrayers.isEmpty;

  /// True when the native key must be removed rather than written.
  bool get clearsNative => isEmpty && !adultNoData;

  /// Instants after [now] at which the widget must redraw: each upcoming
  /// prayer, the day end and the expiry.
  List<DateTime> redrawTimes(DateTime now) {
    final times = <DateTime>{
      for (final prayer in upcomingPrayers) prayer.at,
      ?nextPrayerAt,
      ?dayEndsAt,
      ?expiresAt,
    }.where((time) => time.isAfter(now)).toList()..sort();
    return List.unmodifiable(times);
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'schemaVersion': schemaVersion};
    if (isEmpty) {
      if (!adultNoData) return Map.unmodifiable({...json, 'isEmpty': true});
      json['isEmpty'] = true;
      json['adultNoData'] = true;
      _put(json, 'locale', _language);
      _put(json, 'expiresAt', expiresAt?.millisecondsSinceEpoch);
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
    return Map.unmodifiable(json);
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
  ];
}
