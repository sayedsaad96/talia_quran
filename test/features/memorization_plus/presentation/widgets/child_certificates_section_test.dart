import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/kids_enrichment_feature_flags.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/family_dashboard.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_progress.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/remote_child_summary.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/child_certificates_section.dart';

void main() {
  final local = CertificateAward(
    id: 'cert_surah_114',
    titleAr: 'شهادة حفظ سورة الناس',
    type: CertificateType.surah,
    earnedAt: DateTime.utc(2026, 10, 1),
    surahId: 114,
  );

  const localChild = FamilyChildEntry(
    childUserId: 'local',
    displayName: 'مريم',
    isLocal: true,
  );

  FamilyChildEntry remoteChild(List<RemoteCertificateAward> certs) =>
      FamilyChildEntry(
        childUserId: 'c1',
        displayName: 'يوسف',
        isLocal: false,
        remoteSummary: RemoteChildSummary(
          childUserId: 'c1',
          displayName: 'يوسف',
          progress: const KidsProgress.initial(),
          logs: const [],
          rewards: const [],
          production: RemoteChildProductionSummary(
            totalMemorizedAyahs: 0,
            totalAyahsTracked: 0,
            completionPercent: 0,
            reviewsCompleted: 0,
            reviewsOverdue: 0,
            dailyPlanTotal: 0,
            dailyPlanCompleted: 0,
            activeDaysLast30: 0,
            certificates: certs,
          ),
        ),
      );

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({
      KidsEnrichmentFeature.guardianCertificates.storageKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<KidsEnrichmentFlags>(
      KidsEnrichmentFlags.fromPreferences(prefs),
    );
  });

  tearDown(() => getIt.reset());

  Future<Map<String, dynamic>?> pump(
    WidgetTester tester,
    FamilyChildEntry child, {
    List<CertificateAward> localCertificates = const [],
    bool tapFirst = false,
    String? tapId,
  }) async {
    Map<String, dynamic>? opened;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: SingleChildScrollView(
              child: ChildCertificatesSection(
                child: child,
                childName: child.displayName,
                localCertificates: () => localCertificates,
              ),
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
    if (tapId != null) {
      await tester.tap(find.byKey(ValueKey('guardian-certificate-$tapId')));
      await tester.pumpAndSettle();
    }
    return opened;
  }

  testWidgets('a local child shows the certificates earned on this device', (
    tester,
  ) async {
    await pump(tester, localChild, localCertificates: [local]);

    expect(find.text('شهادات طفلك'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('guardian-certificate-cert_surah_114')),
      findsOneWidget,
    );
    expect(find.text('شهادة حفظ سورة الناس'), findsOneWidget);
  });

  testWidgets('a linked child maps the cloud awards and shows them', (
    tester,
  ) async {
    await pump(
      tester,
      remoteChild([
        RemoteCertificateAward(
          certId: 'cert_juz_30',
          titleAr: 'شهادة حفظ جزء عمّ',
          certType: 'juz',
          earnedAt: DateTime.utc(2026, 9, 1),
        ),
      ]),
    );

    expect(
      find.byKey(const ValueKey('guardian-certificate-cert_juz_30')),
      findsOneWidget,
    );
    expect(find.text('شهادة حفظ جزء عمّ'), findsOneWidget);
  });

  testWidgets('no certificates shows the empty state, not an issue button', (
    tester,
  ) async {
    await pump(tester, localChild);

    expect(
      find.text('لا شهادات بعد. تُمنح الشهادة عند إتمام سورة أو جزء.'),
      findsOneWidget,
    );
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('tapping opens the certificate route with that award and name', (
    tester,
  ) async {
    final opened = await pump(
      tester,
      localChild,
      localCertificates: [local],
      tapId: 'cert_surah_114',
    );

    expect(opened?['award'], local);
    expect(opened?['userName'], 'مريم');
  });

  test('the section is off unless the flag is on', () async {
    expect(ChildCertificatesSection.isEnabled(), isTrue);
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    expect(ChildCertificatesSection.isEnabled(), isFalse);
  });
}
