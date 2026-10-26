import '../domain/season_windows.dart';
import 'season_flag_store.dart';

/// Effort badges, one per kind and Hijri year. They reward what the user did;
/// they promise nothing and are never ranked or shared between users.
enum SeasonBadgeKind { ramadanKhatmah, shawwalSix, dhulHijjahKhatmah }

class SeasonBadge implements Comparable<SeasonBadge> {
  const SeasonBadge(this.kind, this.hijriYear);

  final SeasonBadgeKind kind;
  final int hijriYear;

  @override
  int compareTo(SeasonBadge other) {
    final byYear = other.hijriYear.compareTo(hijriYear);
    return byYear != 0 ? byYear : kind.index.compareTo(other.kind.index);
  }

  @override
  bool operator ==(Object other) =>
      other is SeasonBadge &&
      other.kind == kind &&
      other.hijriYear == hijriYear;

  @override
  int get hashCode => Object.hash(kind, hijriYear);
}

/// A finished khatmah as the badge rules need it: civil start and completion.
typedef KhatmahSpan = ({DateTime start, DateTime completed});

class SeasonBadgeStore {
  SeasonBadgeStore(this._flags);

  final SeasonFlagStore _flags;

  static const _head = 'badge_';

  static String _name(SeasonBadgeKind kind, int year) =>
      '$_head${kind.name}_$year';

  bool has(SeasonBadgeKind kind, int hijriYear) =>
      _flags.isSet(_name(kind, hijriYear));

  Future<void> award(SeasonBadgeKind kind, int hijriYear) =>
      _flags.set(_name(kind, hijriYear), true);

  /// Earned badges, newest Hijri year first.
  List<SeasonBadge> earned() {
    final out = <SeasonBadge>[];
    for (final name in _flags.namesWithPrefix(_head)) {
      final rest = name.substring(_head.length);
      final cut = rest.lastIndexOf('_');
      if (cut <= 0) continue;
      final kind = SeasonBadgeKind.values
          .where((k) => k.name == rest.substring(0, cut))
          .firstOrNull;
      final year = int.tryParse(rest.substring(cut + 1));
      if (kind != null && year != null) out.add(SeasonBadge(kind, year));
    }
    return out..sort();
  }

  /// Derives the khatmah badges from finished khatmahs, so no hook in the
  /// completion flow is needed. Ramadan: finished on a day of Ramadan.
  /// Dhul-Hijjah: started on or after 1 Dhul-Hijjah and finished by the 13th
  /// of the same year (the plans are not linked to the 10-day button, so
  /// this is the effort the badge describes). Idempotent.
  Future<void> syncFromKhatmahs(
    Iterable<KhatmahSpan> khatmahs, {
    required int adjustmentDays,
  }) async {
    for (final k in khatmahs) {
      try {
        final done = hijriOfCivil(k.completed, adjustmentDays);
        if (done.month == 9) {
          await award(SeasonBadgeKind.ramadanKhatmah, done.year);
        } else if (done.month == 12 && done.day <= 13) {
          final began = hijriOfCivil(k.start, adjustmentDays);
          if (began.year == done.year && began.month == 12) {
            await award(SeasonBadgeKind.dhulHijjahKhatmah, done.year);
          }
        }
      } catch (_) {
        // A date the Hijri table cannot convert simply earns nothing.
      }
    }
  }
}
