import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/features/seasons/data/friday_kahf_read_store.dart';
import 'package:talia_quran/features/seasons/data/season_badge_store.dart';
import 'package:talia_quran/features/seasons/data/season_card_dismiss_store.dart';
import 'package:talia_quran/features/seasons/data/season_flag_store.dart';
import 'package:talia_quran/features/seasons/data/shawwal_six_store.dart';
import 'package:talia_quran/features/seasons/domain/season_windows.dart';

class _Owner implements RecordOwnerProvider {
  _Owner(this.id);
  String id;
  @override
  String get currentOwnerId => id;
  @override
  bool get isSignedIn => true;
}

void main() {
  late SharedPreferences prefs;
  late _Owner owner;
  late SeasonFlagStore flags;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = _Owner('a');
    flags = SeasonFlagStore(prefs, owner);
  });

  group('SeasonFlagStore', () {
    test('marks are per owner and a cleared mark leaves no key', () async {
      await flags.set('x', true);
      expect(flags.isSet('x'), isTrue);
      expect(prefs.getKeys(), contains('season_flag_x|a'));
      owner.id = 'b';
      expect(flags.isSet('x'), isFalse);
      owner.id = 'a';
      await flags.set('x', false);
      expect(
        prefs.getKeys().where((k) => k.startsWith('season_flag_')),
        isEmpty,
      );
    });
  });

  group('ShawwalSixStore', () {
    const year = 1448;
    test('one mark per civil date, unmark allowed, six is done', () async {
      final store = ShawwalSixStore(flags);
      final d = DateTime(2027, 3, 15);
      await store.mark(year, d);
      await store.mark(year, DateTime(2027, 3, 15, 22));
      expect(store.count(year), 1);
      expect(store.isMarked(year, d), isTrue);

      expect(await store.toggle(year, d), isFalse);
      expect(store.count(year), 0);
      expect(await store.toggle(year, d), isTrue);

      for (var i = 1; i <= 5; i++) {
        await store.mark(year, DateTime(2027, 3, 15 + i));
      }
      expect(store.count(year), 6);
      expect(store.isDone(year), isTrue);
      expect(store.count(year + 1), 0);
    });

    test('owners do not see each other', () async {
      final store = ShawwalSixStore(flags);
      await store.mark(year, DateTime(2027, 3, 15));
      owner.id = 'b';
      expect(store.count(year), 0);
      await store.mark(year, DateTime(2027, 3, 16));
      expect(store.count(year), 1);
      owner.id = 'a';
      expect(store.count(year), 1);
    });
  });

  group('FridayKahfReadStore', () {
    test('is per civil date and per owner', () async {
      final store = FridayKahfReadStore(flags);
      final friday = DateTime(2027, 2, 12);
      await store.setRead(friday, true);
      expect(store.isRead(DateTime(2027, 2, 12, 23)), isTrue);
      expect(store.isRead(DateTime(2027, 2, 19)), isFalse);
      owner.id = 'b';
      expect(store.isRead(friday), isFalse);
      owner.id = 'a';
      await store.setRead(friday, false);
      expect(store.isRead(friday), isFalse);
    });
  });

  group('SeasonCardDismissStore', () {
    test('yearly seasons dismiss per Hijri year and stage', () async {
      final store = SeasonCardDismissStore(flags);
      final today = DateTime(2027, 6, 1);
      const invite = ActiveSeason(
        id: SeasonId.dhulHijjahTen,
        stage: SeasonStage.invite,
        hijriYear: 1448,
      );
      const active = ActiveSeason(
        id: SeasonId.dhulHijjahTen,
        stage: SeasonStage.active,
        hijriYear: 1448,
        day: 3,
      );
      await store.dismiss(invite, today);
      expect(store.isDismissed(invite, today), isTrue);
      expect(store.isDismissed(active, today), isFalse);
      expect(
        store.isDismissed(
          const ActiveSeason(
            id: SeasonId.dhulHijjahTen,
            stage: SeasonStage.invite,
            hijriYear: 1449,
          ),
          today,
        ),
        isFalse,
      );
    });

    test('weekly seasons dismiss per civil date', () async {
      final store = SeasonCardDismissStore(flags);
      const friday = ActiveSeason(
        id: SeasonId.friday,
        stage: SeasonStage.active,
      );
      await store.dismiss(friday, DateTime(2027, 2, 12));
      expect(store.isDismissed(friday, DateTime(2027, 2, 12, 20)), isTrue);
      expect(store.isDismissed(friday, DateTime(2027, 2, 19)), isFalse);
    });
  });

  group('SeasonBadgeStore', () {
    test('awards are idempotent, per owner, newest year first', () async {
      final store = SeasonBadgeStore(flags);
      await store.award(SeasonBadgeKind.ramadanKhatmah, 1447);
      await store.award(SeasonBadgeKind.ramadanKhatmah, 1447);
      await store.award(SeasonBadgeKind.shawwalSix, 1448);
      expect(store.earned(), [
        const SeasonBadge(SeasonBadgeKind.shawwalSix, 1448),
        const SeasonBadge(SeasonBadgeKind.ramadanKhatmah, 1447),
      ]);
      owner.id = 'b';
      expect(store.earned(), isEmpty);
    });

    test('derives Ramadan and Dhul-Hijjah khatmah badges', () async {
      final store = SeasonBadgeStore(flags);
      final ramadan = hijriMonthFirstCivilDay(1448, 9, 0);
      final hajj = hijriMonthFirstCivilDay(1448, 12, 0);
      await store.syncFromKhatmahs([
        // Finished on day 20 of Ramadan.
        (
          start: DateTime(ramadan.year, ramadan.month, ramadan.day - 3),
          completed: DateTime(ramadan.year, ramadan.month, ramadan.day + 19),
        ),
        // Started on 1 Dhul-Hijjah, finished on the 12th.
        (
          start: hajj,
          completed: DateTime(hajj.year, hajj.month, hajj.day + 11),
        ),
        // Started before Dhul-Hijjah: no badge.
        (
          start: DateTime(hajj.year, hajj.month, hajj.day - 20),
          completed: DateTime(hajj.year, hajj.month, hajj.day + 5),
        ),
        // Outside both windows.
        (start: DateTime(2027, 4, 1), completed: DateTime(2027, 4, 20)),
      ], adjustmentDays: 0);
      expect(store.earned().map((b) => b.kind).toSet(), {
        SeasonBadgeKind.ramadanKhatmah,
        SeasonBadgeKind.dhulHijjahKhatmah,
      });
      expect(store.has(SeasonBadgeKind.ramadanKhatmah, 1448), isTrue);
      expect(store.has(SeasonBadgeKind.dhulHijjahKhatmah, 1448), isTrue);
    });

    test(
      'a khatmah started in Dhul-Hijjah but finished later earns none',
      () async {
        final store = SeasonBadgeStore(flags);
        final hajj = hijriMonthFirstCivilDay(1448, 12, 0);
        await store.syncFromKhatmahs([
          (
            start: hajj,
            completed: DateTime(hajj.year, hajj.month, hajj.day + 16),
          ),
        ], adjustmentDays: 0);
        expect(store.earned(), isEmpty);
      },
    );
  });
}
