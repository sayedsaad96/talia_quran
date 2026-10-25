import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/icons/talia_icon_data.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_surah_house_summary_builder.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_surah_house_card.dart';

/// The horizontal scale of the [index]-th filled star of the card, or null
/// when the star is not wrapped in a Transform (not popping).
double? _starScale(WidgetTester tester, int surahId, int index) {
  final icons = find
      .descendant(
        of: find.byKey(ValueKey('kids-quran-stars-$surahId')),
        matching: find.byIcon(TaliaKidsIcons.starFilled),
      )
      .at(index);
  if (icons.evaluate().isEmpty) return null;
  final transforms = find.ancestor(of: icons, matching: find.byType(Transform));
  if (transforms.evaluate().isEmpty) return null;
  return tester.widget<Transform>(transforms.first).transform.storage[0];
}

KidsSurahHouse _house(
  int surahId, {
  required KidsSurahHouseStatus status,
  required int ayahCount,
  required int completedCount,
}) => KidsSurahHouse(
  surahId: surahId,
  ayahCount: ayahCount,
  juz: 30,
  status: status,
  completedCount: completedCount,
);

Widget _app(Widget child, {bool disableAnimations = false}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(
      body: Center(child: SizedBox(width: 380, height: 104, child: child)),
    ),
  ),
);

KidsSurahHouseCard _card(KidsSurahHouse house, {required bool popStars}) =>
    KidsSurahHouseCard(
      house: house,
      name: 'ar${house.surahId}',
      isCurrent: false,
      popStars: popStars,
      onTap: () {},
    );

void main() {
  testWidgets('stars pop in when popStars arrives on a live card', (
    tester,
  ) async {
    // The map reloads its cubit while mounted, so the card receives
    // popStars on a widget update, not on first mount.
    final house = _house(
      108,
      status: KidsSurahHouseStatus.completed,
      ayahCount: 5,
      completedCount: 5,
    );
    await tester.pumpWidget(_app(_card(house, popStars: false)));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(_app(_card(house, popStars: true)));
    await tester.pump(const Duration(milliseconds: 100));

    // Mid-flight: the first star is scaled, the second has started.
    expect(_starScale(tester, 108, 0), isNotNull);
    expect(_starScale(tester, 108, 0)!, isNot(1.0));
    expect(_starScale(tester, 108, 1), isNotNull);

    // 100 ms + 1000 ms > the 900 ms total: all stars settle at 1.0.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(tester.hasRunningAnimations, isFalse);
    for (var i = 0; i < 3; i++) {
      expect(_starScale(tester, 108, i), 1.0);
    }
  });

  testWidgets('a reduce-motion flip mid-pop lands the final state '
      'immediately', (tester) async {
    final house = _house(
      108,
      status: KidsSurahHouseStatus.completed,
      ayahCount: 5,
      completedCount: 5,
    );
    await tester.pumpWidget(_app(_card(house, popStars: false)));
    await tester.pumpWidget(_app(_card(house, popStars: true)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    expect(_starScale(tester, 108, 0)!, isNot(1.0));

    // The system reduce-motion setting flips while the pop is running.
    await tester.pumpWidget(
      _app(_card(house, popStars: true), disableAnimations: true),
    );

    expect(tester.hasRunningAnimations, isFalse);
    for (var i = 0; i < 3; i++) {
      expect(_starScale(tester, 108, i), 1.0);
    }
  });

  testWidgets('a star count change mid-pop keeps every interval valid', (
    tester,
  ) async {
    // One earned star at mount (a 300 ms pop); the reload reports the surah
    // fully completed while the pop is running.
    var house = _house(
      108,
      status: KidsSurahHouseStatus.inProgress,
      ayahCount: 6,
      completedCount: 2,
    );
    await tester.pumpWidget(_app(_card(house, popStars: true)));
    await tester.pump(const Duration(milliseconds: 100));

    house = _house(
      108,
      status: KidsSurahHouseStatus.completed,
      ayahCount: 6,
      completedCount: 6,
    );
    await tester.pumpWidget(_app(_card(house, popStars: true)));

    // Without recomputing the pop duration, the third star's interval would
    // be built from the stale 300 ms total and exceed 1.0.
    await tester.pump(const Duration(milliseconds: 1100));
    expect(tester.takeException(), isNull);
    expect(tester.hasRunningAnimations, isFalse);
    for (var i = 0; i < 3; i++) {
      expect(_starScale(tester, 108, i), 1.0);
    }
  });
}
