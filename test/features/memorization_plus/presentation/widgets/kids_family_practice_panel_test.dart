import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_family_practice_receipt.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_family_practice_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_family_practice_panel.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    KidsFamilyPracticeRecorder? recorder,
    Future<bool> Function(BuildContext context)? verifyGuardian,
  }) => tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const ValueKey('open'),
              onPressed: () => showKidsFamilyPracticeSheet(
                context,
                surahId: 1,
                ayahNumber: 3,
                recorder: recorder,
                verifyGuardian: verifyGuardian,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
  }

  testWidgets('walks the four steps and finishes without side effects', (
    tester,
  ) async {
    await pumpHost(tester);
    await open(tester);

    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('kids-family-practice-step-listenTogether')),
      findsOneWidget,
    );

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('kids-family-practice-next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Step 4 of 4'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Done'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-family-practice-next')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('kids-family-practice-finished')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('kids-family-practice-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kids-family-practice')), findsNothing);
  });

  testWidgets('closing at any step just closes the sheet', (tester) async {
    await pumpHost(tester);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('kids-family-practice-next')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('kids-family-practice-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('kids-family-practice')), findsNothing);
    expect(find.byKey(const ValueKey('open')), findsOneWidget);
  });

  testWidgets('says it does not complete the ayah', (tester) async {
    await pumpHost(tester);
    await open(tester);

    expect(
      find.text('This is shared practice. It does not complete the ayah.'),
      findsOneWidget,
    );
  });

  testWidgets('renders in Arabic at a narrow width without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpHost(tester, locale: const Locale('ar'));
    await open(tester);

    expect(find.byKey(const ValueKey('kids-family-practice')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('guardian confirmation', () {
    Future<void> finish(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.tap(
          find.byKey(const ValueKey('kids-family-practice-next')),
        );
        await tester.pumpAndSettle();
      }
    }

    final confirm = find.byKey(const ValueKey('kids-family-practice-confirm'));

    testWidgets('is offered only when a recorder and verifier are wired', (
      tester,
    ) async {
      await pumpHost(tester);
      await open(tester);
      await finish(tester);

      expect(confirm, findsNothing);
    });

    testWidgets('a wrong or cancelled PIN records nothing', (tester) async {
      final saved = <KidsFamilyPracticeReceipt>[];
      await pumpHost(
        tester,
        recorder: (r) async {
          saved.add(r);
          return true;
        },
        verifyGuardian: (_) async => false,
      );
      await open(tester);
      await finish(tester);

      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(saved, isEmpty);
      expect(confirm, findsOneWidget);
    });

    testWidgets('a verified guardian records one receipt', (tester) async {
      final saved = <KidsFamilyPracticeReceipt>[];
      await pumpHost(
        tester,
        recorder: (r) async {
          saved.add(r);
          return true;
        },
        verifyGuardian: (_) async => true,
      );
      await open(tester);
      await finish(tester);

      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(saved.map((r) => (r.surahId, r.ayahNumber)), [(1, 3)]);
      expect(
        find.byKey(const ValueKey('kids-family-practice-confirmed')),
        findsOneWidget,
      );
      expect(confirm, findsNothing);
    });
  });
}
