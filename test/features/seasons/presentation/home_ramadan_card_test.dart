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
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/seasons/data/ramadan_card_dismiss_store.dart';
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
  }) async {
    final body = Scaffold(
      body: SingleChildScrollView(
        child: HomeRamadanCard(
          key: UniqueKey(),
          skin: HomeSkin.forBrightness(Brightness.light),
          info: i,
          now: () => DateTime(2027, 2, 20),
          dismissStore: dismissStore ?? dismiss,
          tarawihStore: tarawihStore ?? tarawih,
          loadKhatmahCompletions: completions ?? () async => [],
          hasActiveKhatmah: () async => active,
          prefs: reminderPrefs,
          onReminderChanged: onReminderChanged,
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
}
