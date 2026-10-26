import 'season_flag_store.dart';

/// The «قرأتها» tick for Surat al-Kahf on one civil Friday, per owner. Self
/// report only; nothing else reads it.
class FridayKahfReadStore {
  FridayKahfReadStore(this._flags);

  final SeasonFlagStore _flags;

  static String _name(DateTime date) => 'friday_read_${seasonDateKey(date)}';

  bool isRead(DateTime date) => _flags.isSet(_name(date));

  Future<void> setRead(DateTime date, bool value) =>
      _flags.set(_name(date), value);
}
