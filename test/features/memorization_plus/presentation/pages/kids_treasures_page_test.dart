import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_home_mission.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_adventure_regions.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_treasures_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_talia_companion.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_palette.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_phase_controller.dart';

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
  testWidgets('tapping a certificate opens it with the child name', (
    tester,
  ) async {
    Map<String, dynamic>? opened;
    final cert = CertificateAward(
      id: 'cert_surah_114',
      titleAr: 'شهادة حفظ سورة الناس',
      type: CertificateType.surah,
      earnedAt: DateTime.utc(2026, 10, 1),
      surahId: 114,
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => KidsTreasuresContent(
            regions: kidsRegionProgress(const {}),
            certificates: [cert],
            childName: 'مريم',
            onBack: () {},
          ),
        ),
        GoRoute(
          path: '/certificate',
          builder: (_, state) {
            opened = state.extra as Map<String, dynamic>?;
            return const Scaffold(body: Text('certificate'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('kids-certificate-cert_surah_114'));
    await tester.scrollUntilVisible(card, 200);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(opened?['award'], cert);
    expect(opened?['userName'], 'مريم');
  });

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
    expect(find.byIcon(TaliaKidsIcons.certificate), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('kids-region-beginning')),
        matching: find.byIcon(TaliaKidsIcons.certificate),
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

  testWidgets('the certificates heading is dark on the day sky', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2000);
    addTearDown(tester.view.reset);
    final controller = KidsWorldPhaseController(
      prayerTimes: () async => null,
      clock: () => DateTime(2026, 10, 2, 12),
    );
    getIt.registerSingleton<KidsWorldPhaseController>(controller);
    final cert = CertificateAward(
      id: 'c1',
      titleAr: 'شهادة حفظ سورة',
      titleEn: 'Surah certificate',
      type: CertificateType.surah,
      earnedAt: DateTime(2026, 10, 1),
    );

    await tester.pumpWidget(_app(_content(certificates: [cert]), locale: 'en'));
    await tester.pump();
    await tester.pump();

    final heading = tester.widget<Text>(find.text('My Certificates'));
    expect(heading.style?.color, KidsWorldPalette.day.onScene);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    getIt.unregister<KidsWorldPhaseController>();
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

  group('gifts', () {
    ParentReward gift(String id, ParentRewardStatus status) => ParentReward(
      id: id,
      title: 'gift $id',
      status: status,
      createdAt: DateTime.utc(2026, 10, 1),
    );

    testWidgets('only an unlocked gift can be requested', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(tester.view.reset);
      final requested = <String>[];
      await tester.pumpWidget(
        _app(
          KidsTreasuresContent(
            regions: kidsRegionProgress(const {}),
            certificates: const [],
            rewards: [
              gift('a', ParentRewardStatus.locked),
              gift('b', ParentRewardStatus.unlocked),
              gift('c', ParentRewardStatus.requested),
            ],
            onRequestReward: requested.add,
            onBack: () {},
          ),
          locale: 'en',
        ),
      );

      expect(find.text('My gifts'), findsOneWidget);
      expect(find.text('Request sent, waiting for your grown-up'), findsOne);
      expect(find.byKey(const ValueKey('kids-gift-request-a')), findsNothing);
      expect(find.byKey(const ValueKey('kids-gift-request-c')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('kids-gift-request-b')));

      expect(requested, ['b']);
      expect(find.byType(KidsTaliaCompanion), findsNothing);
    });

    testWidgets('gifts render at 320 px, Arabic, text scale 1.3', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          KidsTreasuresContent(
            regions: kidsRegionProgress(const {}),
            certificates: const [],
            rewards: [gift('b', ParentRewardStatus.unlocked)],
            onRequestReward: (_) {},
            onBack: () {},
          ),
          scale: 1.3,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('أريدها!'), findsOneWidget);
    });
  });

  group('home missions', () {
    KidsHomeMission mission(String id, KidsHomeMissionStatus status) =>
        KidsHomeMission(
          id: id,
          title: 'mission $id',
          status: status,
          createdAt: DateTime.utc(2026, 10, 1),
        );

    testWidgets('lists every open mission; only a new one can be reported', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 2000);
      addTearDown(tester.view.reset);
      final reported = <String>[];
      await tester.pumpWidget(
        _app(
          KidsTreasuresContent(
            regions: kidsRegionProgress(const {}),
            certificates: const [],
            homeMissions: [
              mission('a', KidsHomeMissionStatus.assigned),
              mission('b', KidsHomeMissionStatus.assigned),
              mission('c', KidsHomeMissionStatus.reported),
            ],
            onReportHomeMission: reported.add,
            onBack: () {},
          ),
          locale: 'en',
        ),
      );

      expect(find.text('Missions from your guardian'), findsOneWidget);
      expect(find.text('New mission'), findsNWidgets(2));
      expect(
        find.text('You told your guardian. Waiting for them to see it'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('kids-home-mission-report-c')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('kids-home-mission-report-b')),
      );

      expect(reported, ['b']);
      expect(find.byType(KidsTaliaCompanion), findsNothing);
    });

    testWidgets('a paused policy explains why missions are hidden', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          KidsTreasuresContent(
            regions: kidsRegionProgress(const {}),
            certificates: const [],
            homeMissionsPaused: true,
            onBack: () {},
          ),
          locale: 'en',
        ),
      );

      expect(
        find.byKey(const ValueKey('kids-home-missions-paused')),
        findsOneWidget,
      );
      expect(find.byType(KidsTaliaCompanion), findsNothing);
    });

    testWidgets('missions render at 320 px, Arabic, text scale 1.3', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          KidsTreasuresContent(
            regions: kidsRegionProgress(const {}),
            certificates: const [],
            homeMissions: [mission('a', KidsHomeMissionStatus.assigned)],
            onReportHomeMission: (_) {},
            onBack: () {},
          ),
          scale: 1.3,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('أنجزتها!'), findsOneWidget);
    });
  });
}
