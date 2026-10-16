import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/seasons/data/ramadan_card_dismiss_store.dart';
import 'package:talia_quran/features/seasons/data/tarawih_log_store.dart';
import 'package:talia_quran/features/seasons/presentation/widgets/home_ramadan_card.dart';

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
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeRamadanCard(
              key: UniqueKey(),
              skin: HomeSkin.forBrightness(Brightness.light),
              info: i,
              now: () => DateTime(2027, 2, 20),
              dismissStore: dismiss,
              tarawihStore: tarawih,
              loadKhatmahCompletions: completions ?? () async => [],
              hasActiveKhatmah: () async => false,
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

  final card = find.byKey(const ValueKey('home_ramadan_card'));

  testWidgets('each phase renders its card; none and flag off render nothing', (
    tester,
  ) async {
    flag(true);
    await pump(tester, info(RamadanPhase.invite));
    expect(find.text('استعد لرمضان'), findsOneWidget);
    expect(find.byKey(const ValueKey('home_ramadan_tarawih')), findsNothing);

    await pump(tester, info(RamadanPhase.ramadan, day: 5));
    expect(find.textContaining('من رمضان'), findsOneWidget);
    expect(find.text('العشر الأواخر'), findsNothing);
    expect(find.byKey(const ValueKey('home_ramadan_tarawih')), findsOneWidget);

    await pump(tester, info(RamadanPhase.lastTen, day: 25));
    expect(find.text('العشر الأواخر'), findsOneWidget);

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
}
