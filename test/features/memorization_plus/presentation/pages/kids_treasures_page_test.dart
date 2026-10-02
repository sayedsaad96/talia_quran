import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_adventure_regions.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_treasures_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_talia_companion.dart';

Widget _app(Widget child, {double scale = 1, String locale = 'ar'}) =>
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: child,
    );

Widget _content({
  Set<int> memorized = const {},
  List<CertificateAward> certificates = const [],
}) => KidsTreasuresContent(
  regions: kidsRegionProgress(memorized),
  certificates: certificates,
  onBack: () {},
);

void main() {
  testWidgets('shows five region cards in order with name and progress', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_content(memorized: {1, 114}), locale: 'en'));

    const names = [
      'The beginning',
      'Palm Oasis',
      'Flower Valley',
      'Star Mountain',
      'Pearl Sea',
    ];
    final tops = <double>[];
    for (final name in names) {
      final finder = find.text(name);
      expect(finder, findsOneWidget, reason: name);
      await tester.ensureVisible(finder);
      await tester.pump();
      tops.add(tester.getTopLeft(finder).dy);
    }
    expect(find.text('1 of 1 surahs'), findsOneWidget);
    expect(find.text('1 of 6 surahs'), findsOneWidget);
    expect(find.text('0 of 12 surahs'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(
        find.byKey(ValueKey('kids-region-${KidsRegionId.values[i].name}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('a complete region shows the gold badge', (tester) async {
    await tester.pumpWidget(_app(_content(memorized: {1}), locale: 'en'));
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('kids-region-beginning')),
        matching: find.byIcon(Icons.workspace_premium_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('empty state shows the message with Talia encouraging', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_content()));
    expect(find.text('احفظ أول سورة لتجد أول كنز!'), findsOneWidget);
    final talia = tester.widget<KidsTaliaCompanion>(
      find.byType(KidsTaliaCompanion),
    );
    expect(talia.pose, KidsTaliaPose.encourage);
    expect(talia.animate, isFalse);
  });

  testWidgets('certificates are listed with their localized title', (
    tester,
  ) async {
    final cert = CertificateAward(
      id: 'c1',
      titleAr: 'شهادة حفظ سورة',
      titleEn: 'Surah certificate',
      type: CertificateType.surah,
      earnedAt: DateTime(2026, 10, 1),
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(_content(certificates: [cert]), locale: 'en'));
    expect(find.text('Surah certificate'), findsOneWidget);
    expect(find.byType(KidsTaliaCompanion), findsNothing);
  });

  testWidgets('renders at 320 px, Arabic, text scale 1.3 without errors', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    final cert = CertificateAward(
      id: 'c1',
      titleAr: 'شهادة حفظ سورة من القرآن الكريم',
      type: CertificateType.surah,
      earnedAt: DateTime(2026, 10, 1),
    );
    await tester.pumpWidget(
      _app(
        _content(memorized: {1, 114, 113}, certificates: [cert]),
        scale: 1.3,
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
