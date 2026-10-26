import 'season_flag_store.dart';

/// The six optional fasting days of Shawwal the user marks by hand, per owner
/// and Hijri year. One mark per civil date; a mark can be taken back.
class ShawwalSixStore {
  ShawwalSixStore(this._flags);

  /// Days that complete the tracker.
  static const int target = 6;

  final SeasonFlagStore _flags;

  static String _prefix(int hijriYear) => 'shawwal_${hijriYear}_';

  static String _name(int hijriYear, DateTime date) =>
      '${_prefix(hijriYear)}${seasonDateKey(date)}';

  /// Marked civil dates (`yyyy-mm-dd`) of [hijriYear].
  Set<String> markedDates(int hijriYear) {
    final head = _prefix(hijriYear);
    return {
      for (final name in _flags.namesWithPrefix(head))
        name.substring(head.length),
    };
  }

  int count(int hijriYear) => markedDates(hijriYear).length;

  bool isDone(int hijriYear) => count(hijriYear) >= target;

  bool isMarked(int hijriYear, DateTime date) =>
      _flags.isSet(_name(hijriYear, date));

  Future<void> mark(int hijriYear, DateTime date) =>
      _flags.set(_name(hijriYear, date), true);

  Future<void> unmark(int hijriYear, DateTime date) =>
      _flags.set(_name(hijriYear, date), false);

  /// Marks the day when unmarked, clears it when marked. Returns the new state.
  Future<bool> toggle(int hijriYear, DateTime date) async {
    final next = !isMarked(hijriYear, date);
    await _flags.set(_name(hijriYear, date), next);
    return next;
  }
}
