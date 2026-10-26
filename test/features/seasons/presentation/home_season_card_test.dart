import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/core/seasons/season_preferences.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/khatmah/presentation/khatmah_setup_prefill.dart';
import 'package:talia_quran/features/seasons/data/season_badge_store.dart';
import 'package:talia_quran/features/seasons/data/season_dua_loader.dart';
import 'package:talia_quran/features/seasons/data/season_flag_store.dart';
import 'package:talia_quran/features/seasons/data/shawwal_six_store.dart';
import 'package:talia_quran/features/seasons/data/tarawih_log_store.dart';
import 'package:talia_quran/features/seasons/domain/season_windows.dart';
import 'package:talia_quran/features/seasons/presentation/widgets/home_season_card.dart';

DateTime civilOf(int year, int month, int day, int adj) {
  final first = hijriMonthFirstCivilDay(year, month, adj);
  return DateTime(first.year, first.month, first.day + day - 1);
}

void main() {
  late SharedPreferences prefs;
  late SeasonFlagStore flags;
  late SeasonPreferences seasonPrefs;
  const owner = FixedRecordOwnerProvider('a');

  setUp(() async {
    HomeSkin.blurEnabled = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    flags = SeasonFlagStore(prefs, owner);
    seasonPrefs = SeasonPreferences(prefs, owner);
  });

  tearDown(() {
    HomeSkin.blurEnabled = true;
    if (getIt.isRegistered<ExperienceFlags>()) {
      getIt.unregister<ExperienceFlags>();
    }
  });

  final card = find.byKey(const ValueKey('home_season_card'));
  Finder key(String k) => find.byKey(ValueKey(k));

  Future<ApprovedSeasonLine?> fakeLine(String id) async =>
      ApprovedSeasonLine(id: id, text: 'LINE_TEXT_$id', citation: 'CITE_$id');

  final routes = <(String, Object?)>[];

  Future<void> pump(
    WidgetTester tester,
    DateTime now, {
    int adj = 0,
    SeasonLineLoader? lineLoader,
    SeasonPreferences? prefsOverride,
    SeasonFlagStore? flagsOverride,
    TarawihLogStore? tarawih,
    Future<List<DateTime>> Function()? completions,
    bool ignoreFlag = true,
    Locale locale = const Locale('ar'),
    List<String>? changes,
  }) async {
    routes.clear();
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeSeasonCard(
              key: UniqueKey(),
              skin: HomeSkin.forBrightness(Brightness.light),
              now: () => now,
              adjustmentDays: adj,
              seasonPrefs: prefsOverride ?? seasonPrefs,
              flags: flagsOverride ?? flags,
              tarawihStore: tarawih,
              loadKhatmahCompletions: completions ?? () async => [],
              lineLoader: lineLoader ?? (_) async => null,
              ignoreRolloutFlag: ignoreFlag,
              openRoute: (route, {extra}) => routes.add((route, extra)),
              onSeasonChanged: (_) => changes?.add('changed'),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tap(WidgetTester tester, String k) async {
    await tester.tap(key(k));
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('what each season shows', () {
    for (final adj in [-1, 0, 1]) {
      testWidgets('Shaban prep counts the days to Ramadan (adj $adj)', (
        tester,
      ) async {
        await pump(tester, civilOf(1448, 8, 20, adj), adj: adj);
        expect(find.textContaining('رمضان'), findsWidgets);
        expect(key('home_season_khatmah'), findsOneWidget);
        await tap(tester, 'home_season_khatmah');
        expect(routes.single.$1, AppRoutes.khatmahSetup);
      });
    }

    testWidgets('Dhul-Hijjah invite counts down; day 8 and 9 mention Arafah', (
      tester,
    ) async {
      await pump(tester, civilOf(1448, 11, 28, 0));
      expect(find.textContaining('العشر من ذي الحجة'), findsOneWidget);
      await pump(tester, civilOf(1448, 12, 3, 0));
      expect(find.text('العشر من ذي الحجة: اليوم ٣'), findsOneWidget);
      expect(key('home_season_body'), findsNothing);
      await pump(tester, civilOf(1448, 12, 8, 0));
      expect(find.text('تذكير: صيام يوم عرفة غدًا'), findsOneWidget);
      await pump(tester, civilOf(1448, 12, 9, 0));
      expect(find.text('اليوم يوم عرفة'), findsOneWidget);
    });

    testWidgets('the ten-day button opens setup prefilled with 10 days', (
      tester,
    ) async {
      await pump(tester, civilOf(1448, 12, 2, 0));
      await tap(tester, 'home_season_khatmah');
      final (route, extra) = routes.single;
      expect(route, AppRoutes.khatmahSetup);
      expect(extra, isA<KhatmahSetupPrefill>());
      final prefill = extra! as KhatmahSetupPrefill;
      expect(prefill.targetDays, 10);
      expect(prefill.pagesPerDay, 61);
    });

    testWidgets('Eid al-Adha is a greeting only', (tester) async {
      await pump(tester, civilOf(1448, 12, 11, 0));
      expect(find.text('عيد مبارك'), findsOneWidget);
      expect(key('home_season_khatmah'), findsNothing);
    });

    testWidgets('Hijri new year shows the year, the plan button and its line', (
      tester,
    ) async {
      final asked = <String>[];
      await pump(
        tester,
        civilOf(1449, 1, 2, 0),
        lineLoader: (id) {
          asked.add(id);
          return fakeLine(id);
        },
      );
      expect(find.text('عام هجري جديد ١٤٤٩'), findsOneWidget);
      expect(asked, [SeasonLineIds.newYearDua]);
      expect(find.text('LINE_TEXT_dua_quran_20_114'), findsOneWidget);
      expect(find.text('CITE_dua_quran_20_114'), findsOneWidget);
      await tap(tester, 'home_season_khatmah');
      expect(routes.single.$1, AppRoutes.khatmahSetup);
    });

    testWidgets('the New Year invite stays with the recap card', (
      tester,
    ) async {
      // Visible seasons: only the New Year row.
      for (final id in SeasonId.values) {
        await seasonPrefs.setSeasonEnabled(id, id == SeasonId.hijriNewYear);
      }
      await pump(tester, civilOf(1448, 12, 22, 0));
      expect(card, findsNothing);
    });

    testWidgets('Ashura invite counts days; the days themselves are neutral', (
      tester,
    ) async {
      await pump(tester, civilOf(1449, 1, 7, 0));
      expect(
        find.textContaining('صيام التاسع والعاشر من محرم'),
        findsOneWidget,
      );
      await pump(tester, civilOf(1449, 1, 9, 0));
      expect(find.text('اليوم التاسع من محرم'), findsOneWidget);
      await pump(tester, civilOf(1449, 1, 10, 0));
      expect(find.text('اليوم العاشر من محرم'), findsOneWidget);
    });

    testWidgets('white days: reminder on the 12th, day number on the 13th', (
      tester,
    ) async {
      await pump(tester, civilOf(1448, 3, 12, 0));
      expect(find.textContaining('يبدأ غدًا'), findsOneWidget);
      await pump(tester, civilOf(1448, 3, 14, 0));
      expect(find.text('اليوم ١٤ من الأيام البيض'), findsOneWidget);
    });

    testWidgets('Monday/Thursday shows a neutral line once switched on', (
      tester,
    ) async {
      final monday = DateTime(2027, 4, 12);
      expect(monday.weekday, DateTime.monday);
      await pump(tester, monday);
      expect(card, findsNothing);
      await seasonPrefs.setSeasonEnabled(SeasonId.monThu, true);
      await pump(tester, monday);
      expect(find.text('الاثنين والخميس'), findsOneWidget);
    });

    testWidgets('Friday: Kahf button, read tick, and the approved line', (
      tester,
    ) async {
      final friday = DateTime(2027, 4, 16);
      final asked = <String>[];
      await pump(
        tester,
        friday,
        lineLoader: (id) {
          asked.add(id);
          return fakeLine(id);
        },
      );
      expect(find.text('الجمعة: سورة الكهف'), findsOneWidget);
      expect(asked, [SeasonLineIds.fridayDua]);
      expect(find.text('LINE_TEXT_dua_quran_18_10'), findsOneWidget);

      await tap(tester, 'home_season_open_kahf');
      expect(routes.single.$1, '/quran/surah/18');

      await tap(tester, 'home_season_friday_read');
      expect(prefs.getKeys(), contains('season_flag_friday_read_2027-04-16|a'));
      await pump(tester, friday);
      expect(
        tester.widget<FilterChip>(key('home_season_friday_read')).selected,
        isTrue,
      );
      // Next Friday starts unticked.
      await pump(tester, DateTime(2027, 4, 23));
      expect(
        tester.widget<FilterChip>(key('home_season_friday_read')).selected,
        isFalse,
      );
    });
  });

  group('Eid al-Fitr', () {
    testWidgets('greets, lists the user\'s Ramadan, and shows its lines', (
      tester,
    ) async {
      final range = ramadanCivilRange(1448, 0);
      final tarawih = TarawihLogStore(prefs, owner);
      final night = range.first;
      await tarawih.upsert(
        TarawihEntry(
          nightKey:
              '${night.year}-${night.month.toString().padLeft(2, '0')}-'
              '${night.day.toString().padLeft(2, '0')}',
          fromPage: 1,
          toPage: 3,
        ),
      );
      final asked = <String>[];
      await pump(
        tester,
        civilOf(1448, 10, 1, 0),
        tarawih: tarawih,
        completions: () async => [
          DateTime(range.first.year, range.first.month, range.first.day + 10),
        ],
        lineLoader: (id) {
          asked.add(id);
          return fakeLine(id);
        },
      );
      expect(find.text('عيد مبارك'), findsOneWidget);
      expect(find.textContaining('ليلة واحدة'), findsOneWidget);
      expect(find.textContaining('ختمة واحدة'), findsOneWidget);
      expect(key('home_season_share'), findsOneWidget);
      expect(asked.toSet(), {
        SeasonLineIds.khatmahDua,
        SeasonLineIds.eidFitrDua,
      });
    });

    testWidgets('without Ramadan activity it still greets, with no share', (
      tester,
    ) async {
      final asked = <String>[];
      await pump(
        tester,
        civilOf(1448, 10, 1, 0),
        lineLoader: (id) {
          asked.add(id);
          return fakeLine(id);
        },
      );
      expect(find.text('عيد مبارك'), findsOneWidget);
      expect(key('home_season_share'), findsNothing);
      expect(asked, [SeasonLineIds.eidFitrDua]);
    });

    for (final adj in [-1, 1]) {
      testWidgets('follows the Hijri adjustment $adj', (tester) async {
        await pump(tester, civilOf(1448, 10, 2, adj), adj: adj);
        expect(find.text('عيد مبارك'), findsOneWidget);
      });
    }
  });

  group('six of Shawwal', () {
    final day = civilOf(1448, 10, 10, 0);

    testWidgets('marks today once, unmarks, and is done at six', (
      tester,
    ) async {
      await pump(tester, day);
      expect(find.text('ست من شوال'), findsOneWidget);
      expect(find.text('٠ من ٦ أيام'), findsOneWidget);
      await tap(tester, 'home_season_shawwal_mark');
      expect(find.text('١ من ٦ أيام'), findsOneWidget);
      expect(find.text('إلغاء تسجيل اليوم'), findsOneWidget);
      await tap(tester, 'home_season_shawwal_mark');
      expect(find.text('٠ من ٦ أيام'), findsOneWidget);

      final store = ShawwalSixStore(flags);
      for (var i = 1; i <= 5; i++) {
        await store.mark(1448, DateTime(day.year, day.month, day.day - i));
      }
      await pump(tester, day);
      await tap(tester, 'home_season_shawwal_mark');
      expect(find.text('أتممت الست من شوال'), findsOneWidget);
      expect(
        SeasonBadgeStore(flags).has(SeasonBadgeKind.shawwalSix, 1448),
        isTrue,
      );
    });

    testWidgets('a done tracker hides the mark button on an unmarked day', (
      tester,
    ) async {
      final store = ShawwalSixStore(flags);
      for (var i = 1; i <= 6; i++) {
        await store.mark(1448, DateTime(day.year, day.month, day.day - i));
      }
      await pump(tester, day);
      expect(find.text('أتممت الست من شوال'), findsOneWidget);
      expect(key('home_season_shawwal_mark'), findsNothing);
    });

    testWidgets('the Eid card carries the tracker from the 2nd of Shawwal', (
      tester,
    ) async {
      await pump(tester, civilOf(1448, 10, 1, 0));
      expect(find.text('عيد مبارك'), findsOneWidget);
      expect(key('home_season_shawwal_circles'), findsNothing);
      expect(key('home_season_shawwal_mark'), findsNothing);

      await pump(tester, civilOf(1448, 10, 2, 0));
      expect(find.text('عيد مبارك'), findsOneWidget);
      expect(key('home_season_shawwal_circles'), findsOneWidget);
      expect(find.text('٠ من ٦ أيام'), findsOneWidget);
      await tap(tester, 'home_season_shawwal_mark');
      expect(find.text('١ من ٦ أيام'), findsOneWidget);
      expect(
        ShawwalSixStore(flags).isMarked(1448, civilOf(1448, 10, 2, 0)),
        isTrue,
      );
    });

    testWidgets('no tracker on the Eid card when Shawwal is hidden', (
      tester,
    ) async {
      await seasonPrefs.setSeasonEnabled(SeasonId.shawwalSix, false);
      await pump(tester, civilOf(1448, 10, 2, 0));
      expect(find.text('عيد مبارك'), findsOneWidget);
      expect(key('home_season_shawwal_circles'), findsNothing);
      expect(key('home_season_shawwal_log'), findsNothing);
    });

    testWidgets('logs past days from a sheet, six at most', (tester) async {
      // The sheet is a lazy list: a tall surface builds every row.
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final today = civilOf(1448, 10, 10, 0);
      await pump(tester, today);
      await tap(tester, 'home_season_shawwal_log');
      await tester.pumpAndSettle();
      // Days 2 through 10 of Shawwal.
      for (var n = 2; n <= 10; n++) {
        expect(key('shawwal_log_row_$n'), findsOneWidget, reason: '$n');
      }
      expect(key('shawwal_log_row_1'), findsNothing);
      expect(key('shawwal_log_row_11'), findsNothing);

      await tester.tap(key('shawwal_log_row_3'));
      await tester.pump(const Duration(milliseconds: 300));
      final store = ShawwalSixStore(flags);
      expect(store.isMarked(1448, civilOf(1448, 10, 3, 0)), isTrue);
      expect(store.count(1448), 1);

      for (final n in [4, 5, 6, 7, 8]) {
        await tester.tap(key('shawwal_log_row_$n'));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(store.count(1448), ShawwalSixStore.target);
      expect(
        SeasonBadgeStore(flags).has(SeasonBadgeKind.shawwalSix, 1448),
        isTrue,
      );
      // A seventh mark is refused.
      await tester.tap(key('shawwal_log_row_9'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.count(1448), ShawwalSixStore.target);
      expect(store.isMarked(1448, civilOf(1448, 10, 9, 0)), isFalse);
      // A marked day can still be taken back.
      await tester.tap(key('shawwal_log_row_3'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.count(1448), 5);
    });

    testWidgets('another owner starts at zero', (tester) async {
      await ShawwalSixStore(flags).mark(1448, day);
      final other = SeasonFlagStore(prefs, const FixedRecordOwnerProvider('b'));
      await pump(tester, day, flagsOverride: other);
      expect(find.text('٠ من ٦ أيام'), findsOneWidget);
    });
  });

  group('controls', () {
    final eid = civilOf(1448, 12, 11, 0);

    testWidgets('hide turns the switch group off; undo restores it', (
      tester,
    ) async {
      final changes = <String>[];
      await pump(tester, eid, changes: changes);
      expect(card, findsOneWidget);
      await tap(tester, 'home_season_hide_season');
      expect(card, findsNothing);
      expect(seasonPrefs.isSeasonEnabled(SeasonId.eidAdha), isFalse);
      expect(seasonPrefs.isSeasonEnabled(SeasonId.dhulHijjahTen), isFalse);
      expect(seasonPrefs.isSeasonEnabled(SeasonId.eidFitr), isTrue);
      expect(changes, ['changed']);
      expect(find.textContaining('الإعدادات'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('تراجع'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(card, findsOneWidget);
      expect(seasonPrefs.isSeasonEnabled(SeasonId.eidAdha), isTrue);
      expect(changes, ['changed', 'changed']);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('dismiss hides it for this year only', (tester) async {
      await pump(tester, eid);
      await tap(tester, 'home_season_dismiss');
      expect(card, findsNothing);
      expect(seasonPrefs.isSeasonEnabled(SeasonId.eidAdha), isTrue);
      await pump(tester, eid);
      expect(card, findsNothing);
      await pump(tester, civilOf(1449, 12, 11, 0));
      expect(card, findsOneWidget);
    });

    testWidgets('a weekly card is dismissed per date', (tester) async {
      await pump(tester, DateTime(2027, 4, 16));
      await tap(tester, 'home_season_dismiss');
      expect(card, findsNothing);
      await pump(tester, DateTime(2027, 4, 16));
      expect(card, findsNothing);
      await pump(tester, DateTime(2027, 4, 23));
      expect(card, findsOneWidget);
    });

    testWidgets('dismissal belongs to its owner', (tester) async {
      await pump(tester, eid);
      await tap(tester, 'home_season_dismiss');
      final other = SeasonFlagStore(prefs, const FixedRecordOwnerProvider('b'));
      await pump(tester, eid, flagsOverride: other);
      expect(card, findsOneWidget);
    });

    testWidgets('the master switch and the season switch hide the card', (
      tester,
    ) async {
      await seasonPrefs.setMasterEnabled(false);
      await pump(tester, eid);
      expect(card, findsNothing);
      await seasonPrefs.setMasterEnabled(true);
      await seasonPrefs.setSeasonEnabled(SeasonId.eidAdha, false);
      await seasonPrefs.setSeasonEnabled(SeasonId.dhulHijjahTen, false);
      await pump(tester, eid);
      // Another season may take its place (a Friday), but never the Eid.
      expect(find.text('عيد مبارك'), findsNothing);
    });

    testWidgets('the rollout flag gates it', (tester) async {
      await pump(tester, eid, ignoreFlag: false);
      expect(card, findsNothing);
      getIt.registerSingleton<ExperienceFlags>(
        ExperienceFlags(
          (k) =>
              k == ExperienceFeature.seasonalRamadan.storageKey ? true : null,
        ),
      );
      await pump(tester, eid, ignoreFlag: false);
      expect(card, findsOneWidget);
    });
  });

  group('approved line', () {
    testWidgets('a missing or unapproved record leaves no line and no filler', (
      tester,
    ) async {
      await pump(tester, DateTime(2027, 4, 16));
      expect(card, findsOneWidget);
      expect(
        find.byKey(const ValueKey('season_line_dua_quran_18_10')),
        findsNothing,
      );
      expect(find.textContaining('LINE_TEXT'), findsNothing);
    });
  });

  for (final width in [320.0, 390.0]) {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      testWidgets(
        'every season card fits $width px in ${locale.languageCode}',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (final now in [
            civilOf(1448, 8, 20, 0),
            civilOf(1448, 10, 1, 0),
            civilOf(1448, 10, 10, 0),
            civilOf(1448, 12, 8, 0),
            civilOf(1448, 12, 11, 0),
            civilOf(1449, 1, 2, 0),
            civilOf(1449, 1, 7, 0),
            civilOf(1448, 3, 12, 0),
            DateTime(2027, 4, 16),
          ]) {
            await pump(tester, now, locale: locale, lineLoader: fakeLine);
            expect(card, findsOneWidget, reason: '$now');
            expect(tester.takeException(), isNull, reason: '$now');
          }
        },
      );
    }
  }
}
