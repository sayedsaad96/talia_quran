import '../../../core/seasons/season_calendar.dart';
import 'season_flag_store.dart';

/// Remembers which generic season home cards the user hid for one period, per
/// owner. The period is the Hijri year for yearly seasons and the civil date
/// for the weekly and monthly ones, so a hidden Friday card returns next week.
class SeasonCardDismissStore {
  SeasonCardDismissStore(this._flags);

  final SeasonFlagStore _flags;

  /// Period key for [season] seen on civil date [today].
  static String periodFor(ActiveSeason season, DateTime today) {
    final year = season.hijriYear;
    return year == null ? seasonDateKey(today) : 'y$year';
  }

  static String _name(SeasonId id, SeasonStage stage, String period) =>
      'dismissed_${id.name}_${stage.name}_$period';

  bool isDismissed(ActiveSeason season, DateTime today) =>
      _flags.isSet(_name(season.id, season.stage, periodFor(season, today)));

  Future<void> dismiss(ActiveSeason season, DateTime today) => _flags.set(
    _name(season.id, season.stage, periodFor(season, today)),
    true,
  );
}
