import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/core/seasons/season_preferences.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/seasons/data/ramadan_card_dismiss_store.dart';
import 'package:talia_quran/features/seasons/data/season_dua_loader.dart';
import 'package:talia_quran/features/seasons/data/tarawih_log_store.dart';
import 'package:talia_quran/features/seasons/domain/last_ten_reminder.dart';
import 'package:talia_quran/features/seasons/presentation/widgets/home_ramadan_card.dart';

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.id);
  String id;
  @override
  String get currentOwnerId => id;
  @override
  bool get isSignedIn => true;
}

class _CountingDismiss extends RamadanCardDismissStore {
  _CountingDismiss(super.prefs, super.owner);
  int calls = 0;
  @override
  bool isDismissed(RamadanPhase phase, int hijriYear) {
    calls++;
    return super.isDismissed(phase, hijriYear);
  }
}

class _CountingTarawih extends TarawihLogStore {
  _CountingTarawih(super.prefs, super.owner);
  int calls = 0;
  @override
  Future<List<TarawihEntry>> entries() {
    calls++;
    return super.entries();
  }
}

void main() {
  late SharedPreferences prefs;
  late RamadanCardDismissStore dismiss;
  late TarawihLogStore tarawih;

  final first = DateTime(2027, 2, 8);
  final last = DateTime(2027, 3, 9);
  RamadanInfo info(RamadanPhase p, {int? day}) => RamadanInfo(
    phase: p,
    day: day,
    monthLength: 30,
    firstDay: first,
    lastDay: last,
  );

  setUp(() async {
    HomeSkin.blurEnabled = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('a');
    dismiss = RamadanCardDismissStore(prefs, owner);
    tarawih = TarawihLogStore(prefs, owner);
  });

  tearDown(() {
    HomeSkin.blurEnabled = true;
    if (getIt.isRegistered<ExperienceFlags>()) {
      getIt.unregister<ExperienceFlags>();
    }
  });

  void flag(bool on) {
    getIt.registerSingleton<ExperienceFlags>(
      ExperienceFlags(
        (key) =>
            key == ExperienceFeature.seasonalRamadan.storageKey ? on : null,
      ),
    );
  }

  Future<void> pump(
    WidgetTester tester,
    RamadanInfo i, {
    Future<List<DateTime>> Function()? completions,
    RamadanCardDismissStore? dismissStore,
    TarawihLogStore? tarawihStore,
    bool active = false,
    bool routed = false,
    Locale locale = const Locale('ar'),
    SharedPreferences? reminderPrefs,
    void Function(BuildContext context)? onReminderChanged,
    SeasonPreferences? seasonPrefs,
    DateTime? now,
    Future<RamadanPrayerTimes?> Function(DateTime day)? prayerTimes,
    SeasonLineLoader? lineLoader,
    Duration countdownInterval = const Duration(minutes: 1),
    DateTime Function()? clock,
  }) async {
    final body = Scaffold(
      body: SingleChildScrollView(
        child: HomeRamadanCard(
          key: UniqueKey(),
          skin: HomeSkin.forBrightness(Brightness.light),
          info: i,
          now: clock ?? () => now ?? DateTime(2027, 2, 20),
          loadPrayerTimes: prayerTimes ?? (_) async => null,
          lineLoader: lineLoader ?? (_) async => null,
          countdownInterval: countdownInterval,
          dismissStore: dismissStore ?? dismiss,
          tarawihStore: tarawihStore ?? tarawih,
          loadKhatmahCompletions: completions ?? () async => [],
          hasActiveKhatmah: () async => active,
          prefs: reminderPrefs,
          onReminderChanged: onReminderChanged,
          seasonPrefs: seasonPrefs,
        ),
      ),
    );
    const delegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
    await tester.pumpWidget(
      routed
          ? MaterialApp.router(
              locale: locale,
              localizationsDelegates: delegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: GoRouter(
                routes: [
                  GoRoute(path: '/', builder: (_, _) => body),
                  GoRoute(
                    path: AppRoutes.khatmahSetup,
                    builder: (_, _) => const Text('SETUP_PAGE'),
                  ),
                  GoRoute(
                    path: AppRoutes.khatmahDashboard,
                    builder: (_, _) => const Text('DASH_PAGE'),
                  ),
                ],
              ),
            )
          : MaterialApp(
              locale: locale,
              localizationsDelegates: delegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: body,
            ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  final card = find.byKey(const ValueKey('home_ramadan_card'));

  for (final width in [320.0, 390.0]) {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      testWidgets('every phase fits $width px in ${locale.languageCode}', (
        tester,
      ) async {
        flag(true);
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final i in [
          info(RamadanPhase.invite),
          info(RamadanPhase.ramadan, day: 5),
          info(RamadanPhase.lastTen, day: 25),
          info(RamadanPhase.afterEid),
        ]) {
          await pump(
            tester,
            i,
            locale: locale,
            completions: () async => [DateTime(2027, 2, 20)],
          );
          expect(card, findsOneWidget, reason: '${i.phase}');
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull, reason: '${i.phase}');
        }
      });
    }
  }

  testWidgets('the last-ten reminder is off until tapped, then toggles', (
    tester,
  ) async {
    flag(true);
    var changes = 0;
    const toggle = ValueKey('home_ramadan_last_ten_reminder');
    await pump(
      tester,
      info(RamadanPhase.ramadan, day: 5),
      reminderPrefs: prefs,
      onReminderChanged: (_) => changes++,
    );
    expect(find.text('ذكّرني قبل بدئها'), findsOneWidget);
    expect(prefs.getBool(lastTenReminderPreferenceKey), isNull);

    await tester.tap(find.byKey(toggle));
    await tester.pumpAndSettle();
    expect(prefs.getBool(lastTenReminderPreferenceKey), isTrue);
    expect(find.text('سنذكّرك قبل بدئها'), findsOneWidget);

    await tester.tap(find.byKey(toggle));
    await tester.pumpAndSettle();
    expect(prefs.getBool(lastTenReminderPreferenceKey), isFalse);
    expect(changes, 2);
  });

  testWidgets('opting in leaves the shared seasonal reminders switch alone', (
    tester,
  ) async {
    flag(true);
    final seasons = SeasonPreferences(
      prefs,
      const FixedRecordOwnerProvider('a'),
    );
    expect(seasons.remindersEnabled, isFalse);
    await pump(
      tester,
      info(RamadanPhase.ramadan, day: 5),
      reminderPrefs: prefs,
      onReminderChanged: (_) {},
      seasonPrefs: seasons,
    );
    await tester.tap(
      find.byKey(const ValueKey('home_ramadan_last_ten_reminder')),
    );
    await tester.pumpAndSettle();
    expect(prefs.getBool(lastTenReminderPreferenceKey), isTrue);
    expect(seasons.remindersEnabled, isFalse);
    expect(prefs.getBool('season_pref_reminders|a'), isNull);
  });

  testWidgets('reminder shows on only while opted in and the season is visible', (
    tester,
  ) async {
    flag(true);
    await prefs.setBool(lastTenReminderPreferenceKey, true);
    final seasons = SeasonPreferences(
      prefs,
      const FixedRecordOwnerProvider('a'),
    );
    await pump(
      tester,
      info(RamadanPhase.ramadan, day: 5),
      reminderPrefs: prefs,
      seasonPrefs: seasons,
    );
    expect(find.text('سنذكّرك قبل بدئها'), findsOneWidget);
  });

  testWidgets('no reminder toggle once the last ten have begun', (
    tester,
  ) async {
    flag(true);
    await pump(
      tester,
      info(RamadanPhase.lastTen, day: 22),
      reminderPrefs: prefs,
    );
    expect(
      find.byKey(const ValueKey('home_ramadan_last_ten_reminder')),
      findsNothing,
    );
  });

  testWidgets('each phase renders its card; none and flag off render nothing', (
    tester,
  ) async {
    flag(true);
    await pump(tester, info(RamadanPhase.invite));
    expect(find.text('استعد لرمضان'), findsOneWidget);
    expect(find.byKey(const ValueKey('home_ramadan_tarawih')), findsNothing);

    await pump(tester, info(RamadanPhase.ramadan, day: 5));
    expect(find.textContaining('من رمضان'), findsOneWidget);
    expect(find.textContaining('تبدأ العشر الأواخر بعد'), findsOneWidget);
    expect(find.textContaining('من العشر الأواخر'), findsNothing);
    expect(find.byKey(const ValueKey('home_ramadan_tarawih')), findsOneWidget);

    await pump(tester, info(RamadanPhase.ramadan, day: 19));
    expect(find.text('تبدأ العشر الأواخر مساء الغد'), findsOneWidget);

    await pump(tester, info(RamadanPhase.ramadan, day: 20));
    expect(find.text('تبدأ العشر الأواخر الليلة بعد المغرب'), findsOneWidget);

    await pump(tester, info(RamadanPhase.lastTen, day: 25));
    expect(find.textContaining('من العشر الأواخر'), findsOneWidget);
    expect(find.textContaining('تبدأ العشر الأواخر'), findsNothing);

    await tester.runAsync(() async {
      await tarawih.upsert(
        const TarawihEntry(nightKey: '2027-02-10', fromPage: 1, toPage: 3),
      );
      await tarawih.upsert(
        const TarawihEntry(nightKey: '2027-04-01', fromPage: 5, toPage: 9),
      );
    });
    await pump(
      tester,
      info(RamadanPhase.afterEid),
      completions: () async => [DateTime(2027, 3, 1), DateTime(2027, 5, 1)],
    );
    expect(find.text('حصاد رمضان'), findsOneWidget);
    expect(find.textContaining('ليلة واحدة'), findsOneWidget);
    expect(find.textContaining('ختمة واحدة'), findsOneWidget);

    await pump(tester, const RamadanInfo(phase: RamadanPhase.none));
    expect(card, findsNothing);

    getIt.unregister<ExperienceFlags>();
    flag(false);
    await pump(tester, info(RamadanPhase.invite));
    expect(card, findsNothing);
  });

  testWidgets('unregistered flags render nothing', (tester) async {
    await pump(tester, info(RamadanPhase.invite));
    expect(card, findsNothing);
  });

  testWidgets('dismiss hides the card for that phase and year only', (
    tester,
  ) async {
    flag(true);
    await pump(tester, info(RamadanPhase.invite));
    await tester.tap(find.byKey(const ValueKey('home_ramadan_dismiss')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(card, findsNothing);
    expect(
      prefs.getKeys().where(
        (k) => k.startsWith('ramadan_card_dismissed_invite_1448|a'),
      ),
      hasLength(1),
    );

    await pump(tester, info(RamadanPhase.invite));
    expect(card, findsNothing);

    await pump(tester, info(RamadanPhase.ramadan, day: 3));
    expect(card, findsOneWidget);

    final nextYear = RamadanInfo(
      phase: RamadanPhase.invite,
      monthLength: 30,
      firstDay: DateTime(2028, 1, 28),
      lastDay: DateTime(2028, 2, 26),
    );
    await pump(tester, nextYear);
    expect(card, findsOneWidget);
  });

  Future<void> dismissCard(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('home_ramadan_dismiss')));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> seedNight(WidgetTester tester, TarawihEntry e) =>
      tester.runAsync(() => tarawih.upsert(e)).then((_) {});

  testWidgets('afterEid dismiss persists across a re-pump', (tester) async {
    flag(true);
    await seedNight(
      tester,
      const TarawihEntry(nightKey: '2027-02-10', fromPage: 1, toPage: 3),
    );
    await pump(tester, info(RamadanPhase.afterEid));
    expect(find.text('حصاد رمضان'), findsOneWidget);
    await dismissCard(tester);
    expect(card, findsNothing);
    await pump(tester, info(RamadanPhase.afterEid));
    expect(card, findsNothing);
  });

  testWidgets('dismissing invite does not hide lastTen or afterEid', (
    tester,
  ) async {
    flag(true);
    await seedNight(
      tester,
      const TarawihEntry(nightKey: '2027-02-10', fromPage: 1, toPage: 3),
    );
    await pump(tester, info(RamadanPhase.invite));
    await dismissCard(tester);
    await pump(tester, info(RamadanPhase.invite));
    expect(card, findsNothing);
    await pump(tester, info(RamadanPhase.lastTen, day: 25));
    expect(card, findsOneWidget);
    await pump(tester, info(RamadanPhase.afterEid));
    expect(find.text('حصاد رمضان'), findsOneWidget);
  });

  testWidgets('dismissal is scoped to the owner', (tester) async {
    flag(true);
    final owner = _MutableOwner('a');
    final store = RamadanCardDismissStore(prefs, owner);
    await pump(tester, info(RamadanPhase.invite), dismissStore: store);
    await dismissCard(tester);
    await pump(tester, info(RamadanPhase.invite), dismissStore: store);
    expect(card, findsNothing);
    owner.id = 'b';
    await pump(tester, info(RamadanPhase.invite), dismissStore: store);
    expect(card, findsOneWidget);
  });

  testWidgets('afterEid range edges are inclusive and exact', (tester) async {
    flag(true);
    for (final e in const [
      TarawihEntry(nightKey: '2027-02-07', fromPage: 3, toPage: 3),
      TarawihEntry(nightKey: '2027-02-08', fromPage: 1, toPage: 1),
      TarawihEntry(nightKey: '2027-03-09', fromPage: 2, toPage: 2),
      TarawihEntry(nightKey: '2027-03-10', fromPage: 4, toPage: 4),
    ]) {
      await seedNight(tester, e);
    }
    await pump(
      tester,
      info(RamadanPhase.afterEid),
      completions: () async => [
        DateTime(2027, 2, 7, 23, 59),
        DateTime(2027, 2, 8),
        DateTime(2027, 3, 9, 23, 59),
        DateTime(2027, 3, 10),
      ],
    );
    expect(find.textContaining('ليلتين'), findsOneWidget);
    expect(find.textContaining('صفحتين'), findsOneWidget);
    expect(find.textContaining('ختمتين'), findsOneWidget);
  });

  testWidgets('afterEid with nothing to report hides the card', (tester) async {
    flag(true);
    await pump(tester, info(RamadanPhase.afterEid));
    expect(card, findsNothing);
  });

  testWidgets('afterEid with only a khatmah omits the nights line', (
    tester,
  ) async {
    flag(true);
    await pump(
      tester,
      info(RamadanPhase.afterEid),
      completions: () async => [DateTime(2027, 3, 1)],
    );
    expect(find.textContaining('ختمة واحدة'), findsOneWidget);
    expect(find.textContaining('التراويح'), findsNothing);
  });

  testWidgets('flag off and phase none touch no store', (tester) async {
    const owner = FixedRecordOwnerProvider('a');
    final d = _CountingDismiss(prefs, owner);
    final t = _CountingTarawih(prefs, owner);
    var loads = 0;
    Future<List<DateTime>> counted() async {
      loads++;
      return [];
    }

    // Flag unregistered.
    await pump(
      tester,
      info(RamadanPhase.afterEid),
      completions: counted,
      dismissStore: d,
      tarawihStore: t,
    );
    // Flag off.
    flag(false);
    await pump(
      tester,
      info(RamadanPhase.afterEid),
      completions: counted,
      dismissStore: d,
      tarawihStore: t,
    );
    getIt.unregister<ExperienceFlags>();
    // Flag on, phase none.
    flag(true);
    await pump(
      tester,
      const RamadanInfo(phase: RamadanPhase.none),
      completions: counted,
      dismissStore: d,
      tarawihStore: t,
    );
    expect(d.calls, 0);
    expect(t.calls, 0);
    expect(loads, 0);
    expect(card, findsNothing);
  });

  testWidgets('khatmah button opens setup, or the dashboard when active', (
    tester,
  ) async {
    flag(true);
    await pump(tester, info(RamadanPhase.ramadan, day: 5), routed: true);
    await tester.tap(find.byKey(const ValueKey('home_ramadan_khatmah')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('SETUP_PAGE'), findsOneWidget);

    await pump(
      tester,
      info(RamadanPhase.ramadan, day: 5),
      routed: true,
      active: true,
    );
    await tester.tap(find.byKey(const ValueKey('home_ramadan_khatmah')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('DASH_PAGE'), findsOneWidget);
  });

  testWidgets('tarawih button opens the log sheet', (tester) async {
    flag(true);
    await pump(tester, info(RamadanPhase.ramadan, day: 5));
    expect(find.byKey(const ValueKey('tarawih_from')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('home_ramadan_tarawih')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('tarawih_from')), findsOneWidget);
  });

  SeasonPreferences seasonPrefs() =>
      SeasonPreferences(prefs, const FixedRecordOwnerProvider('a'));

  testWidgets('the season preference off hides the whole card', (tester) async {
    flag(true);
    final seasons = seasonPrefs();
    await seasons.setSeasonEnabled(SeasonId.ramadan, false);
    await pump(
      tester,
      info(RamadanPhase.ramadan, day: 5),
      seasonPrefs: seasons,
    );
    expect(card, findsNothing);
  });

  testWidgets('the master seasons switch off hides the card too', (
    tester,
  ) async {
    flag(true);
    final seasons = seasonPrefs();
    await seasons.setMasterEnabled(false);
    await pump(
      tester,
      info(RamadanPhase.ramadan, day: 5),
      seasonPrefs: seasons,
    );
    expect(card, findsNothing);
  });

  testWidgets('hide-this-season turns the switch off and undo restores', (
    tester,
  ) async {
    flag(true);
    final seasons = seasonPrefs();
    await pump(
      tester,
      info(RamadanPhase.ramadan, day: 5),
      seasonPrefs: seasons,
    );
    expect(card, findsOneWidget);
    expect(seasons.isSeasonEnabled(SeasonId.ramadan), isTrue);

    await tester.tap(find.byKey(const ValueKey('home_ramadan_hide_season')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(card, findsNothing);
    expect(seasons.isSeasonEnabled(SeasonId.ramadan), isFalse);
    // The bottom notice offers undo.
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(l10n.ramadanHideSeasonDone), findsOneWidget);

    // Let the notice finish sliding in before tapping its action.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(l10n.undo));
    await tester.pump(const Duration(milliseconds: 300));
    expect(card, findsOneWidget);
    expect(seasons.isSeasonEnabled(SeasonId.ramadan), isTrue);
    // The helper's fallback timer must not outlive the test.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('hide-this-season is independent of hide-this-year', (
    tester,
  ) async {
    flag(true);
    final seasons = seasonPrefs();
    await pump(
      tester,
      info(RamadanPhase.ramadan, day: 5),
      seasonPrefs: seasons,
    );
    await tester.tap(find.byKey(const ValueKey('home_ramadan_dismiss')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(card, findsNothing);
    // Dismissed for the year only: the season switch is untouched.
    expect(seasons.isSeasonEnabled(SeasonId.ramadan), isTrue);
  });
  group('iftar and suhoor line', () {
    final times = RamadanPrayerTimes(
      fajrToday: DateTime(2027, 2, 20, 5, 10),
      maghribToday: DateTime(2027, 2, 20, 17, 45),
      fajrTomorrow: DateTime(2027, 2, 21, 5, 9),
    );
    const line = ValueKey('home_ramadan_countdown');

    testWidgets('before Maghrib it counts down to iftar', (tester) async {
      flag(true);
      await pump(
        tester,
        info(RamadanPhase.ramadan, day: 5),
        now: DateTime(2027, 2, 20, 15, 30),
        prayerTimes: (_) async => times,
      );
      expect(find.byKey(line), findsOneWidget);
      expect(find.text('الإفطار بعد ساعتين و١٥ دقيقة'), findsOneWidget);
    });

    testWidgets('after Maghrib it shows when suhoor ends', (tester) async {
      flag(true);
      await pump(
        tester,
        info(RamadanPhase.ramadan, day: 5),
        now: DateTime(2027, 2, 20, 19),
        prayerTimes: (_) async => times,
      );
      expect(find.textContaining('السحور حتى'), findsOneWidget);
    });

    for (final length in [29, 30]) {
      testWidgets('after Maghrib on day $length of $length there is no suhoor line', (
        tester,
      ) async {
        flag(true);
        final lastDay = RamadanInfo(
          phase: RamadanPhase.lastTen,
          day: length,
          monthLength: length,
          firstDay: first,
          lastDay: last,
        );
        await pump(
          tester,
          lastDay,
          now: DateTime(2027, 2, 20, 19),
          prayerTimes: (_) async => times,
        );
        expect(find.byKey(line), findsNothing);
        // Before Maghrib the iftar countdown still shows.
        await pump(
          tester,
          lastDay,
          now: DateTime(2027, 2, 20, 15, 30),
          prayerTimes: (_) async => times,
        );
        expect(find.byKey(line), findsOneWidget);
      });
    }

    testWidgets('the day before the last still shows suhoor after Maghrib', (
      tester,
    ) async {
      flag(true);
      await pump(
        tester,
        RamadanInfo(
          phase: RamadanPhase.lastTen,
          day: 28,
          monthLength: 29,
          firstDay: first,
          lastDay: last,
        ),
        now: DateTime(2027, 2, 20, 19),
        prayerTimes: (_) async => times,
      );
      expect(find.textContaining('السحور حتى'), findsOneWidget);
    });

    testWidgets('is hidden without prayer times', (tester) async {
      flag(true);
      await pump(tester, info(RamadanPhase.ramadan, day: 5));
      expect(card, findsOneWidget);
      expect(find.byKey(line), findsNothing);
    });

    testWidgets('is not shown in the invite or summary phases', (tester) async {
      flag(true);
      for (final i in [info(RamadanPhase.invite), info(RamadanPhase.afterEid)]) {
        await pump(
          tester,
          i,
          now: DateTime(2027, 2, 20, 15, 30),
          prayerTimes: (_) async => times,
          completions: () async => [DateTime(2027, 2, 20)],
        );
        expect(find.byKey(line), findsNothing, reason: '${i.phase}');
      }
    });

    testWidgets('re-reads the clock on every tick and stops on dispose', (
      tester,
    ) async {
      flag(true);
      var current = DateTime(2027, 2, 20, 17, 0);
      await pump(
        tester,
        info(RamadanPhase.ramadan, day: 5),
        clock: () => current,
        prayerTimes: (_) async => times,
        countdownInterval: const Duration(seconds: 1),
      );
      expect(find.text('الإفطار بعد ٤٥ دقيقة'), findsOneWidget);
      current = DateTime(2027, 2, 20, 17, 30);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('الإفطار بعد ١٥ دقيقة'), findsOneWidget);
      // Replacing the card disposes it and cancels the ticker.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('last-ten approved line', () {
    Future<ApprovedSeasonLine?> fake(String id) async => ApprovedSeasonLine(
      id: id,
      text: 'LINE_TEXT_$id',
      citation: 'CITATION_$id',
    );

    testWidgets('shows only the approved dp4 record, with its citation', (
      tester,
    ) async {
      flag(true);
      final asked = <String>[];
      await pump(
        tester,
        info(RamadanPhase.lastTen, day: 25),
        lineLoader: (id) {
          asked.add(id);
          return fake(id);
        },
      );
      expect(asked, [SeasonLineIds.lastTenDua]);
      expect(find.text('LINE_TEXT_dp4'), findsOneWidget);
      expect(find.text('CITATION_dp4'), findsOneWidget);
    });

    testWidgets('disappears when the record cannot be loaded', (tester) async {
      flag(true);
      await pump(tester, info(RamadanPhase.lastTen, day: 25));
      expect(card, findsOneWidget);
      expect(find.byKey(const ValueKey('season_line_dp4')), findsNothing);
    });

    testWidgets('is not requested before the last ten', (tester) async {
      flag(true);
      final asked = <String>[];
      await pump(
        tester,
        info(RamadanPhase.ramadan, day: 5),
        lineLoader: (id) {
          asked.add(id);
          return fake(id);
        },
      );
      expect(asked, isEmpty);
    });
  });

}
