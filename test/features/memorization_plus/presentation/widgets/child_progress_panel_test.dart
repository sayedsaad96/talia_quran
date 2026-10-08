import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_achievements.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_progress_snapshot.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/child_progress_panel.dart';

void main() {
  final award = CertificateAward(
    id: 'cert_surah_114',
    titleAr: 'شهادة حفظ سورة الناس',
    type: CertificateType.surah,
    earnedAt: DateTime.utc(2026, 10, 1),
    surahId: 114,
  );

  KidsProgressSnapshot snapshot({List<CertificateAward>? certificates}) =>
      KidsProgressSnapshot(
        level: 2,
        levelProgress: 0.5,
        points: 90,
        stars: 4,
        currentStreak: 2,
        longestStreak: 6,
        memorizedAyahs: 11,
        weekPages: null,
        achievements: KidsAchievementCatalog.evaluate(
          const KidsAchievementInputs(memorizedAyahs: 11),
          now: DateTime.utc(2026, 10, 8),
        ),
        certificates: certificates ?? [award],
        recentActivity: const [],
      );

  Future<Map<String, dynamic>?> pump(
    WidgetTester tester,
    KidsProgressSnapshot data,
  ) async {
    Map<String, dynamic>? opened;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: SingleChildScrollView(
              child: ChildProgressPanel(snapshot: data, childName: 'مريم'),
            ),
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
    await tester.binding.setSurfaceSize(const Size(375, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('child-certificate-cert_surah_114')),
    );
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets('a certificate opens in the child\'s name to print or share', (
    tester,
  ) async {
    final opened = await pump(tester, snapshot());

    expect(tester.takeException(), isNull);
    expect(opened?['userName'], 'مريم');
    expect(opened?['award'], award);
  });

  testWidgets('shows the milestones, and a dash for unpublished reading', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChildProgressPanel(
              snapshot: snapshot(certificates: const []),
              childName: 'مريم',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('—'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('child-achievement-ayahs10')),
      findsOneWidget,
    );
    expect(find.text('لا توجد شهادات بعد'), findsOneWidget);
  });
}
