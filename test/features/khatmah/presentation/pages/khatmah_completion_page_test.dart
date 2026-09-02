import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_completion_page.dart';

void main() {
  final testPlan = KhatmahPlan(
    id: 'khatmah-1',
    title: 'ختمة رمضان المبارك',
    startPage: 1,
    currentPage: 604,
    targetPagesPerDay: 20,
    targetDays: 30,
    startDate: DateTime(2026, 3, 1),
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
            plan: plan ?? testPlan,
            enableConfetti: false,
            onReadDua: onReadDua,
            onShare: onShare,
            onHome: onHome,
          ),
        ),
        GoRoute(
          path: '/quran/khatm-dua',
          builder: (context, state) => const Scaffold(
            body: Text('Khatm Dua Destination Page'),
          ),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Text('Home Destination Page'),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      locale: const Locale('ar'),
      routerConfig: router,
    );
  }

  setUp(() {});

  testWidgets('displays congratulations heading and celebratory details', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidget(plan: testPlan));
    await tester.pumpAndSettle();

    expect(find.textContaining('مبارك ختم القرآن'), findsOneWidget);
    expect(find.textContaining('ختمة رمضان المبارك'), findsOneWidget);
    expect(find.textContaining('604'), findsOneWidget);
  });

  testWidgets('renders tailored dedication section when plan has dedication', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidget(plan: testPlan));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('khatmah_completion_dedication_section')), findsOneWidget);
    expect(find.textContaining('الوالدة حفظها الله'), findsNWidgets(2));
    expect(find.textContaining('الأم'), findsOneWidget);
  });

  testWidgets('tapping read dua button invokes callback or navigates', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool readDuaCalled = false;
    await tester.pumpWidget(
      createWidget(
        plan: testPlan,
        onReadDua: () => readDuaCalled = true,
      ),
    );
    await tester.pumpAndSettle();

    final readDuaBtn = find.byKey(const Key('khatmah_completion_read_dua_button'));
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
      createWidget(
        plan: testPlan,
        onShare: () => shareCalled = true,
      ),
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
      createWidget(
        plan: testPlan,
        onHome: () => homeCalled = true,
      ),
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
