import 'package:flutter/material.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_completion_page.dart';

void main() {
  final testPlan = KhatmahPlan(
    id: 'khatmah-1',
    title: 'ختمة رمضان المبارك',
    startPage: 1,
    completedPages: {for (var page = 1; page <= 604; page++) page},
    targetPagesPerDay: 20,
    targetDays: 30,
    startDate: DateTime(2026, 3, 1),
    lastReadDate: DateTime(2026, 3, 5),
    expectedEndDate: DateTime(2026, 3, 31),
    status: KhatmahStatus.completed,
    dedication: const KhatmahDedication(
      isDedicated: true,
      recipientName: 'الوالدة حفظها الله',
      relationship: 'الأم',
      condition: DedicationCondition.alive,
    ),
  );

  Widget createWidget({
    KhatmahPlan? plan,
    VoidCallback? onReadDua,
    VoidCallback? onShare,
    VoidCallback? onHome,
  }) {
    final router = GoRouter(
      initialLocation: '/khatmah/completion',
      routes: [
        GoRoute(
          path: '/khatmah/completion',
          builder: (context, state) => KhatmahCompletionPage(
            completion: KhatmahReadingResult(
              plan: plan ?? testPlan,
              newlyCompletedPages: const {604},
              historyEntry: KhatmahHistoryEntry(
                id: testPlan.id,
                khatmahNumber: 1,
                title: testPlan.title,
                startDate: testPlan.startDate,
                completedDate: DateTime(2026, 3, 5),
                totalDays: 5,
              ),
            ),
            enableConfetti: false,
            onReadDua: onReadDua,
            onShare: onShare,
            onHome: onHome,
          ),
        ),
        GoRoute(
          path: '/quran/khatm-dua',
          builder: (context, state) =>
              const Scaffold(body: Text('Khatm Dua Destination Page')),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('Home Destination Page')),
        ),
      ],
    );

    return MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    );
  }

  setUp(() {});

  testWidgets('shows actual elapsed days rather than planned duration', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();
    expect(find.text('5 days'), findsOneWidget);
    expect(find.text('30 days'), findsNothing);
    expect(find.text('2026-03-05'), findsOneWidget);
  });

  testWidgets('null completion cannot fabricate an achievement', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: KhatmahCompletionPage(enableConfetti: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('khatmah_completion_share_button')),
      findsNothing,
    );
    expect(find.textContaining('مبارك ختم القرآن'), findsNothing);
  });

  testWidgets('invalid completion inputs never expose celebration or sharing', (
    tester,
  ) async {
    final history = KhatmahHistoryEntry(
      id: testPlan.id,
      khatmahNumber: 1,
      title: testPlan.title,
      startDate: testPlan.startDate,
      completedDate: DateTime(2026, 3, 5),
      totalDays: 5,
    );
    final invalid = [
      KhatmahReadingResult(plan: testPlan, newlyCompletedPages: const {}),
      for (final plan in [
        testPlan.copyWith(id: 'different-plan'),
        testPlan.copyWith(status: KhatmahStatus.active),
        testPlan.copyWith(status: KhatmahStatus.paused),
        testPlan.copyWith(completedPages: {604}),
        testPlan.copyWith(startDate: DateTime(2026, 3, 6)),
      ])
        KhatmahReadingResult(
          plan: plan,
          historyEntry: history,
          newlyCompletedPages: const {},
        ),
    ];
    for (final completion in invalid) {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: KhatmahCompletionPage(
            completion: completion,
            enableConfetti: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('khatmah_completion_share_button')),
        findsNothing,
      );
      expect(find.textContaining('مبارك ختم القرآن'), findsNothing);
    }
  });

  testWidgets('share sheet receives actual days and unchanged dedication', (
    tester,
  ) async {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    String? sharedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'share') {
        sharedText = (call.arguments as Map)['text'] as String;
      }
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();
    final share = find.byKey(const Key('khatmah_completion_share_button'));
    await tester.ensureVisible(share);
    await tester.tap(share);
    await tester.pumpAndSettle();
    expect(sharedText, contains('in 5 days'));
    expect(sharedText, isNot(contains('30 days')));
    expect(sharedText, contains('الوالدة حفظها الله'));
  });

  testWidgets('displays congratulations heading and celebratory details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidget(plan: testPlan));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Congratulations on completing the Quran'),
      findsOneWidget,
    );
    expect(find.textContaining('ختمة رمضان المبارك'), findsOneWidget);
    expect(find.textContaining('604'), findsOneWidget);
  });

  testWidgets('renders tailored dedication section when plan has dedication', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidget(plan: testPlan));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('khatmah_completion_dedication_section')),
      findsOneWidget,
    );
    expect(find.textContaining('الوالدة حفظها الله'), findsOneWidget);
    expect(find.text('Mother'), findsOneWidget);
  });

  testWidgets('tapping read dua button invokes callback or navigates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool readDuaCalled = false;
    await tester.pumpWidget(
      createWidget(plan: testPlan, onReadDua: () => readDuaCalled = true),
    );
    await tester.pumpAndSettle();

    final readDuaBtn = find.byKey(
      const Key('khatmah_completion_read_dua_button'),
    );
    expect(readDuaBtn, findsOneWidget);
    await tester.ensureVisible(readDuaBtn);

    await tester.tap(readDuaBtn);
    await tester.pumpAndSettle();

    expect(readDuaCalled, isTrue);
  });

  testWidgets('tapping share button invokes share callback', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool shareCalled = false;
    await tester.pumpWidget(
      createWidget(plan: testPlan, onShare: () => shareCalled = true),
    );
    await tester.pumpAndSettle();

    final shareBtn = find.byKey(const Key('khatmah_completion_share_button'));
    expect(shareBtn, findsOneWidget);
    await tester.ensureVisible(shareBtn);

    await tester.tap(shareBtn);
    await tester.pumpAndSettle();

    expect(shareCalled, isTrue);
  });

  testWidgets('tapping home button navigates to home', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool homeCalled = false;
    await tester.pumpWidget(
      createWidget(plan: testPlan, onHome: () => homeCalled = true),
    );
    await tester.pumpAndSettle();

    final homeBtn = find.byKey(const Key('khatmah_completion_home_button'));
    expect(homeBtn, findsOneWidget);
    await tester.ensureVisible(homeBtn);

    await tester.tap(homeBtn);
    await tester.pumpAndSettle();

    expect(homeCalled, isTrue);
  });
}
