import 'dart:ui' show SemanticsAction;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/constants/surah_names.dart';
import 'package:talia_quran/core/icons/talia_icon_data.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/utils/locale_number_formatter.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_quran_map_visuals.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_surah_house_summary_builder.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_quran_journey_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_quran_journey_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_quran_journey_map.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_surah_house_card.dart';

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
  Map<int, String>? surahNames,
}) => KidsQuranJourneyLoaded(
  houses: houses ?? _houses(),
  currentSurahId: current,
  surahNames: surahNames ?? {for (var id = 1; id <= 114; id++) id: 'ar$id'},
);

Widget _app(
  Widget child, {
  Locale locale = const Locale('en'),
  TextScaler? textScaler,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  // Animations off so pumpAndSettle stays valid around the new ring and
  // ribbon widgets.
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: true,
      textScaler: textScaler ?? TextScaler.noScaling,
    ),
    child: Scaffold(body: child),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  KidsQuranJourneyLoaded state, {
  ValueChanged<int>? onOpen,
  Locale locale = const Locale('en'),
  TextScaler? textScaler,
}) async {
  tester.view.devicePixelRatio = 1;
  // Tall enough that the first three juz ribbons stay visible at the 200 px
  // row extent.
  tester.view.physicalSize = const Size(800, 2000);
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
      locale: locale,
      textScaler: textScaler,
    ),
  );
  await tester.pump();
}

void main() {
  _semanticsTests();
  _ayahCountTests();
  _islandRowTests();
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

void _ayahCountTests() {
  Future<void> pumpCard(WidgetTester tester, int ayahCount) async {
    await tester.pumpWidget(
      _app(
        KidsSurahHouseCard(
          house: KidsSurahHouse(
            surahId: 108,
            ayahCount: ayahCount,
            juz: 30,
            status: KidsSurahHouseStatus.notStarted,
            completedCount: 0,
          ),
          name: 'ar108',
          isCurrent: false,
          onTap: () {},
        ),
        locale: const Locale('ar'),
      ),
    );
  }

  testWidgets('Arabic house card uses the plural ayah count', (tester) async {
    String ar(int n) => LocaleNumberFormatter.number(n, 'ar');
    await pumpCard(tester, 1);
    expect(find.text('آية واحدة'), findsOneWidget);
    await pumpCard(tester, 2);
    expect(find.text('آيتان'), findsOneWidget);
    await pumpCard(tester, 3);
    expect(find.text('${ar(3)} آيات'), findsOneWidget);
    await pumpCard(tester, 30);
    expect(find.text('${ar(30)} آية'), findsOneWidget);
  });
}

KidsSurahHouse _house(
  int id, {
  required KidsSurahHouseStatus status,
  int ayahCount = 5,
  int completedCount = 0,
}) => KidsSurahHouse(
  surahId: id,
  ayahCount: ayahCount,
  juz: 1 + (id - 1) ~/ 3,
  status: status,
  completedCount: completedCount,
);

void _islandRowTests() {
  void replaceOne(List<KidsSurahHouse> houses, KidsSurahHouse replacement) {
    houses[replacement.surahId - 1] = replacement;
  }

  testWidgets('a completed house shows three filled stars and no empty '
  'ones', (tester) async {
    final houses = _houses();
    replaceOne(
      houses,
      _house(1, status: KidsSurahHouseStatus.completed, completedCount: 5),
    );
    await _pump(tester, _state(houses: houses));

    final starsRow = find.byKey(const ValueKey('kids-quran-stars-1'));
    expect(starsRow, findsOneWidget);
    expect(
      find.descendant(
        of: starsRow,
        matching: find.byIcon(TaliaKidsIcons.starFilled),
      ),
      findsNWidgets(kidsSurahStars(houses[0])),
    );
    expect(
      find.descendant(of: starsRow, matching: find.byIcon(TaliaKidsIcons.star)),
      findsNothing,
    );
  });

  testWidgets('a third of the progress earns one filled star', (tester) async {
    final houses = _houses();
    replaceOne(
      houses,
      _house(
        1,
        status: KidsSurahHouseStatus.inProgress,
        completedCount: 2,
        ayahCount: 6,
      ),
    );
    await _pump(tester, _state(houses: houses));

    final starsRow = find.byKey(const ValueKey('kids-quran-stars-1'));
    expect(
      find.descendant(
        of: starsRow,
        matching: find.byIcon(TaliaKidsIcons.starFilled),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: starsRow, matching: find.byIcon(TaliaKidsIcons.star)),
      findsNWidgets(2),
    );
  });

  testWidgets('not started houses show a lock glyph in the ring', (
    tester,
  ) async {
    await _pump(tester, _state());
    expect(find.byIcon(TaliaKidsIcons.lock), findsWidgets);
  });

  testWidgets('a house needing review shows the refresh glyph in the ring', (
    tester,
  ) async {
    final houses = _houses();
    replaceOne(
      houses,
      _house(1, status: KidsSurahHouseStatus.needsReview, completedCount: 3),
    );
    await _pump(tester, _state(houses: houses));
    final ring = find.byKey(const ValueKey('kids-quran-ring-1'));
    expect(ring, findsOneWidget);
    expect(
      find.descendant(of: ring, matching: find.byIcon(TaliaKidsIcons.refresh)),
      findsOneWidget,
    );
  });

  testWidgets('a completed house shows the star glyph in the ring', (
    tester,
  ) async {
    final houses = _houses();
    replaceOne(
      houses,
      _house(1, status: KidsSurahHouseStatus.completed, completedCount: 5),
    );
    await _pump(tester, _state(houses: houses));
    final ring = find.byKey(const ValueKey('kids-quran-ring-1'));
    expect(ring, findsOneWidget);
    expect(
      find.descendant(
        of: ring,
        matching: find.byIcon(TaliaKidsIcons.starFilled),
      ),
      findsOneWidget,
    );
  });

  testWidgets('card semantics announce the earned stars', (tester) async {
    final handle = tester.ensureSemantics();
    final houses = _houses();
    replaceOne(
      houses,
      _house(
        1,
        status: KidsSurahHouseStatus.inProgress,
        ayahCount: 3,
        completedCount: 2,
      ),
    );
    await _pump(tester, _state(houses: houses));

    final node = tester.getSemantics(
      find.ancestor(
        of: find.text(SurahNames.english[1]!),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true,
        ),
      ),
    );
    expect(node.getSemanticsData().label, contains('2 of 3 stars'));
    handle.dispose();
  });

  testWidgets('each visible island renders one decorative island image', (
    tester,
  ) async {
    await _pump(tester, _state());

    String? islandAssetName(Image image) {
      final provider = image.image;
      if (provider is AssetImage) return provider.assetName;
      // cacheWidth wraps the asset provider in a ResizeImage.
      if (provider is ResizeImage) {
        final inner = provider.imageProvider;
        return inner is AssetImage ? inner.assetName : null;
      }
      return null;
    }

    final islands =
        tester
            .widgetList<Image>(
              find.byWidgetPredicate(
                (w) =>
                    w is Image &&
                    (islandAssetName(w)?.startsWith(
                          'assets/images/kids/islands/',
                        ) ??
                        false),
              ),
            )
            .toList();
    expect(islands, isNotEmpty);
    for (final island in islands) {
      expect(island.errorBuilder, isNotNull);
      expect(
        find.ancestor(
          of: find.byWidget(island),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    }
  });

  testWidgets('no overflow in English LTR at 1.3 text scale with a long '
  'name', (tester) async {
    await tester.pumpWidget(
      _app(
        Center(
          child: SizedBox(
            width: 380,
            height: 104,
            child: KidsSurahHouseCard(
              house: _house(
                108,
                status: KidsSurahHouseStatus.inProgress,
                ayahCount: 20,
                completedCount: 7,
              ),
              name: 'A' * 30,
              isCurrent: false,
              onTap: () {},
            ),
          ),
        ),
        textScaler: TextScaler.linear(1.3),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow in Arabic RTL at 1.3 text scale with a long '
  'name', (tester) async {
    final longName = 'س' * 30;
    final names = {for (var id = 1; id <= 114; id++) id: longName};
    await _pump(
      tester,
      _state(houses: _houses(), surahNames: names),
      locale: const Locale('ar'),
      textScaler: TextScaler.linear(1.3),
    );
    expect(tester.takeException(), isNull);
  });
}

void _semanticsTests() {
  testWidgets('house card is activatable and announces status and current', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final opened = <int>[];
    await _pump(tester, _state(), onOpen: opened.add);

    final node = tester.getSemantics(
      find.ancestor(
        of: find.text(SurahNames.english[1]!),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true,
        ),
      ),
    );
    final data = node.getSemanticsData();
    expect(data.label, contains('Not started'));
    expect(data.label, contains('You are here'));
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel(RegExp('You are here')));
    await tester.pumpAndSettle();
    expect(opened, [1]);
    handle.dispose();
  });

  testWidgets('opens scrolled to the current house', (tester) async {
    await _pump(tester, _state(current: 60));
    expect(find.text(SurahNames.english[60]!), findsOneWidget);
  });
}
