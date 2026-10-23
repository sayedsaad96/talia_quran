import 'package:equatable/equatable.dart';

/// Privacy-safe, immutable data sent to the platform home widget.
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
  });

  const WidgetSnapshot.empty()
    : nextPrayerKey = null,
      nextPrayerAt = null,
      dueReviewCount = 0,
      wirdFromPage = null,
      wirdToPage = null,
      wirdDonePages = null,
      expiresAt = null,
      wirdSurahName = null;

  int get schemaVersion => 1;
  final String? nextPrayerKey;
  final DateTime? nextPrayerAt;
  final int dueReviewCount;
  final int? wirdFromPage;
  final int? wirdToPage;
  final int? wirdDonePages;
  final String? wirdSurahName;
  final DateTime? expiresAt;

  bool get isEmpty =>
      nextPrayerKey == null &&
      nextPrayerAt == null &&
      dueReviewCount == 0 &&
      wirdFromPage == null &&
      wirdToPage == null &&
      wirdDonePages == null &&
      wirdSurahName == null;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'schemaVersion': schemaVersion};
    if (isEmpty) return Map.unmodifiable({...json, 'isEmpty': true});
    json['isEmpty'] = false;
    json['dueReviewCount'] = dueReviewCount;
    _put(json, 'nextPrayerKey', nextPrayerKey);
    _put(json, 'nextPrayerAt', nextPrayerAt?.millisecondsSinceEpoch);
    _put(
      json,
      'nextPrayerOffsetMinutes',
      nextPrayerAt?.timeZoneOffset.inMinutes,
    );
    _put(json, 'expiresAt', expiresAt?.millisecondsSinceEpoch);
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
    nextPrayerKey,
    nextPrayerAt,
    dueReviewCount,
    wirdFromPage,
    wirdToPage,
    wirdDonePages,
    wirdSurahName,
    expiresAt,
  ];
}
