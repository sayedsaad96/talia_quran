import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/constants/surah_names.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_surah_house_summary_builder.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_quran_journey_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_quran_journey_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_quran_journey_map.dart';

List<KidsSurahHouse> _houses({KidsSurahHouseStatus Function(int id)? status}) =>
    [
      for (var id = 1; id <= 114; id++)
        KidsSurahHouse(
          surahId: id,
          ayahCount: 5,
          juz: 1 + (id - 1) ~/ 3,
          status: status?.call(id) ?? KidsSurahHouseStatus.notStarted,
          completedCount: 0,
        ),
    ];

KidsQuranJourneyLoaded _state({
  List<KidsSurahHouse>? houses,
  int current = 1,
}) => KidsQuranJourneyLoaded(
  houses: houses ?? _houses(),
  currentSurahId: current,
  surahNames: {for (var id = 1; id <= 114; id++) id: 'ar$id'},
);

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Future<void> _pump(
  WidgetTester tester,
  KidsQuranJourneyLoaded state, {
  ValueChanged<int>? onOpen,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1200);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    tester.view.reset();
  });
  await tester.pumpWidget(
    _app(
      KidsQuranJourneyContent(
        state: state,
        onBack: () {},
        onOpenSurah: onOpen ?? (_) {},
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('builds lazily: fewer than 20 house cards in the tree for 114 '
      'houses', (tester) async {
    await _pump(tester, _state());
    final count = find.byType(KidsSurahHouseCard).evaluate().length;
    expect(count, greaterThan(0));
    expect(count, lessThan(20));
  });

  testWidgets('juz signpost appears before the first house of each juz', (
    tester,
  ) async {
    await _pump(tester, _state());
    // Houses 1-3 are juz 1, 4-6 juz 2: one signpost each, not one per house.
    expect(find.text('Juz 1'), findsOneWidget);
    expect(find.text('Juz 2'), findsOneWidget);
    expect(find.text('Juz 3'), findsOneWidget);
  });

  testWidgets('tapping a notStarted house that is not current asks for '
      'confirmation', (tester) async {
    final opened = <int>[];
    await _pump(tester, _state(), onOpen: opened.add);

    await tester.tap(find.text(SurahNames.english[2]!));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text(
        'Start Surah ${SurahNames.english[2]}? '
        'Surah ${SurahNames.english[1]} will wait for you.',
      ),
      findsOneWidget,
    );
    expect(opened, isEmpty);

    await tester.tap(find.text("Let's start"));
    await tester.pumpAndSettle();
    expect(opened, [2]);
  });

  testWidgets('declining the confirmation does not open the house', (
    tester,
  ) async {
    final opened = <int>[];
    await _pump(tester, _state(), onOpen: opened.add);

    await tester.tap(find.text(SurahNames.english[2]!));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(opened, isEmpty);
  });

  testWidgets('tapping the current house opens it without a dialog', (
    tester,
  ) async {
    final opened = <int>[];
    await _pump(tester, _state(), onOpen: opened.add);

    await tester.tap(find.text(SurahNames.english[1]!));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(opened, [1]);
  });

  testWidgets('all houses completed shows the journey-complete message', (
    tester,
  ) async {
    final houses = [
      for (final h in _houses(status: (_) => KidsSurahHouseStatus.completed))
        KidsSurahHouse(
          surahId: h.surahId,
          ayahCount: h.ayahCount,
          juz: h.juz,
          status: h.status,
          completedCount: h.ayahCount,
        ),
    ];
    await _pump(tester, _state(houses: houses));
    expect(
      find.text(
        'You finished the whole Quran journey! '
        'Tell your guardian about this great achievement.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('no completion message while a house is unfinished', (
    tester,
  ) async {
    await _pump(tester, _state());
    expect(
      find.textContaining('You finished the whole Quran journey'),
      findsNothing,
    );
  });
}
