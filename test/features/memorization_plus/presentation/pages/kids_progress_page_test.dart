import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_progress_snapshot.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_progress_page.dart';

void main() {
  final award = CertificateAward(
    id: 'cert_surah_114',
    titleAr: 'شهادة حفظ سورة الناس',
    type: CertificateType.surah,
    earnedAt: DateTime.utc(2026, 10, 1),
    surahId: 114,
  );

  final snapshot = KidsProgressSnapshot(
    level: 1,
    levelProgress: 0,
    points: 0,
    stars: 0,
    currentStreak: 0,
    longestStreak: 0,
    memorizedAyahs: 0,
    weekPages: 0,
    achievements: const [],
    certificates: [award],
    recentActivity: const [],
  );

  Future<Map<String, dynamic>?> openCertificate(
    WidgetTester tester, {
    String? childName,
  }) async {
    Map<String, dynamic>? opened;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => KidsProgressContent(
            snapshot: snapshot,
            childName: childName,
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

    final certificate = find.byKey(
      const ValueKey('kids-progress-certificate-cert_surah_114'),
    );
    await tester.ensureVisible(certificate);
    await tester.tap(certificate);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    return opened;
  }

  for (final scenario in <({String name, String? childName})>[
    (name: 'a local child nickname', childName: 'مريم'),
    (
      name: 'the localized child fallback when the nickname is blank',
      childName: ' ',
    ),
  ]) {
    testWidgets('opens a kids certificate with ${scenario.name}', (
      tester,
    ) async {
      final opened = await openCertificate(
        tester,
        childName: scenario.childName,
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

      expect(
        opened?['userName'],
        scenario.childName?.trim().isNotEmpty == true
            ? scenario.childName!.trim()
            : l10n.certificateChildLearner,
      );
      expect(opened?['userName'], isNot(l10n.taliaUser));
      expect(opened?['award'], award);
    });
  }
}
