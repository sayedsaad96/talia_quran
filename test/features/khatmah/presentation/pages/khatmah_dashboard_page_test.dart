import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_scheduling_engine.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_schedule_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_dashboard_page.dart';

class MockGetActiveKhatmahUsecase extends Mock
    implements GetActiveKhatmahUsecase {}

class MockRecordKhatmahReadingUsecase extends Mock
    implements RecordKhatmahReadingUsecase {}

class MockUpdateKhatmahScheduleUsecase extends Mock
    implements UpdateKhatmahScheduleUsecase {}

class MockPauseResumeKhatmahUsecase extends Mock
    implements PauseResumeKhatmahUsecase {}

class MockDeleteKhatmahUsecase extends Mock implements DeleteKhatmahUsecase {}

class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  late MockGetActiveKhatmahUsecase mockGetActive;
  late MockRecordKhatmahReadingUsecase mockRecordReading;
  late MockUpdateKhatmahScheduleUsecase mockUpdateSchedule;
  late MockPauseResumeKhatmahUsecase mockPauseResume;
  late MockDeleteKhatmahUsecase mockDelete;
  KhatmahCubit? createdCubit;

  final testPlan = KhatmahPlan(
    id: 'khatmah-test-1',
    title: 'ختمة رمضان المبارك',
    startPage: 1,
    completedPages: {for (var page = 1; page <= 20; page++) page},
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 6, 1),
    status: KhatmahStatus.active,
    dedication: const KhatmahDedication(
      isDedicated: true,
      recipientName: 'والدتي الغالية',
      relationship: 'والدة',
      condition: DedicationCondition.deceased,
    ),
  );

  setUpAll(() {
    registerFallbackValue(FakeKhatmahPlan());
    registerFallbackValue(KhatmahReadingSource.digital);
  });

  setUp(() {
    mockGetActive = MockGetActiveKhatmahUsecase();
    mockRecordReading = MockRecordKhatmahReadingUsecase();
    mockUpdateSchedule = MockUpdateKhatmahScheduleUsecase();
    mockPauseResume = MockPauseResumeKhatmahUsecase();
    mockDelete = MockDeleteKhatmahUsecase();
  });

  tearDown(() async {
    await createdCubit?.close();
    createdCubit = null;
  });

  KhatmahCubit buildCubit() {
    createdCubit = KhatmahCubit(
      mockGetActive,
      mockRecordReading,
      mockPauseResume,
      mockDelete,
      mockUpdateSchedule,
    );
    return createdCubit!;
  }

  Widget buildWidget({
    required KhatmahCubit cubit,
    ValueChanged<String>? onNavigate,
  }) {
    final router = GoRouter(
      initialLocation: '/khatmah/dashboard',
      routes: [
        GoRoute(
          path: '/khatmah/dashboard',
          builder: (context, state) => KhatmahDashboardPage(cubit: cubit),
        ),
        GoRoute(
          path: '/quran/page/:page',
          builder: (context, state) {
            final page = state.pathParameters['page'];
            final mode = state.uri.queryParameters['mode'];
            onNavigate?.call('/quran/page/$page?mode=$mode');
            return Scaffold(body: Text('Page: $page, Mode: $mode'));
          },
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets(
    'renders header with title, dedication badge, and progress gauge',
    (tester) async {
      when(() => mockGetActive()).thenAnswer((_) async => testPlan);
      final cubit = buildCubit();

      await tester.pumpWidget(buildWidget(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('ختمة رمضان المبارك'), findsOneWidget);
      expect(find.textContaining('والدتي الغالية'), findsOneWidget);
      expect(
        find.byKey(const Key('khatmah_dashboard_dedication_badge')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('khatmah_progress_gauge')), findsOneWidget);
    },
  );

  testWidgets(
    'renders today\'s wird and clicking continue reading navigates to reader in khatmah mode',
    (tester) async {
      when(() => mockGetActive()).thenAnswer((_) async => testPlan);
      String? navigatedRoute;
      final cubit = buildCubit();

      await tester.pumpWidget(
        buildWidget(
          cubit: cubit,
          onNavigate: (route) => navigatedRoute = route,
        ),
      );
      await tester.pumpAndSettle();

      final wird = KhatmahSchedulingEngine.todaysWird(
        testPlan.currentPage,
        testPlan.targetPagesPerDay,
      );
      // Button to continue reading
      final continueBtn = find.byKey(
        const Key('khatmah_dashboard_continue_reading_button'),
      );
      expect(continueBtn, findsOneWidget);

      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(navigatedRoute, '/quran/page/${wird.startPage}?mode=khatmah');
    },
  );

  testWidgets(
    'physical mushaf logger dialog records read page and updates progress',
    (tester) async {
      when(() => mockGetActive()).thenAnswer((_) async => testPlan);
      when(
        () => mockRecordReading(any(), any(), source: any(named: 'source')),
      ).thenAnswer((inv) async {
        final plan = inv.positionalArguments[0] as KhatmahPlan;
        final page = inv.positionalArguments[1] as int;
        return KhatmahReadingResult(
          plan: plan.recordThroughPage(page),
          newlyCompletedPages: const {},
        );
      });
      final cubit = buildCubit();

      await tester.pumpWidget(buildWidget(cubit: cubit));
      await tester.pumpAndSettle();

      // Tap physical mushaf logger button
      final logMushafBtn = find.byKey(
        const Key('khatmah_dashboard_log_mushaf_button'),
      );
      expect(logMushafBtn, findsOneWidget);
      await tester.ensureVisible(logMushafBtn);
      await tester.tap(logMushafBtn);
      await tester.pumpAndSettle();

      // Input page number
      final pageInput = find.byKey(
        const Key('khatmah_dashboard_mushaf_page_input'),
      );
      expect(pageInput, findsOneWidget);
      await tester.enterText(pageInput, '25');
      await tester.pumpAndSettle();

      // Tap save
      final saveBtn = find.byKey(
        const Key('khatmah_dashboard_mushaf_save_button'),
      );
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      verify(
        () =>
            mockRecordReading(any(), 25, source: KhatmahReadingSource.physical),
      ).called(1);
    },
  );

  testWidgets('physical logger waits for durable success before closing', (
    tester,
  ) async {
    when(() => mockGetActive()).thenAnswer((_) async => testPlan);
    final durableWrite = Completer<KhatmahReadingResult>();
    when(
      () => mockRecordReading(
        testPlan,
        25,
        source: KhatmahReadingSource.physical,
      ),
    ).thenAnswer((_) => durableWrite.future);
    final cubit = buildCubit();

    await tester.pumpWidget(buildWidget(cubit: cubit));
    await tester.pumpAndSettle();
    final logButton = find.byKey(
      const Key('khatmah_dashboard_log_mushaf_button'),
    );
    await tester.ensureVisible(logButton);
    await tester.tap(logButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('khatmah_dashboard_mushaf_page_input')),
      '25',
    );
    await tester.tap(
      find.byKey(const Key('khatmah_dashboard_mushaf_save_button')),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('khatmah_dashboard_mushaf_page_input')),
      findsOneWidget,
    );
    expect(find.textContaining('successfully'), findsNothing);

    durableWrite.complete(
      KhatmahReadingResult(
        plan: testPlan.recordThroughPage(25),
        newlyCompletedPages: const {21, 22, 23, 24, 25},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('khatmah_dashboard_mushaf_page_input')),
      findsNothing,
    );
    expect(find.textContaining('successfully'), findsOneWidget);
  });

  testWidgets(
    'physical logger preserves page and offers same-page retry after failure',
    (tester) async {
      when(() => mockGetActive()).thenAnswer((_) async => testPlan);
      var attempts = 0;
      when(
        () => mockRecordReading(
          testPlan,
          25,
          source: KhatmahReadingSource.physical,
        ),
      ).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) throw Exception('disk unavailable');
        return KhatmahReadingResult(
          plan: testPlan.recordThroughPage(25),
          newlyCompletedPages: const {21, 22, 23, 24, 25},
        );
      });
      final cubit = buildCubit();

      await tester.pumpWidget(buildWidget(cubit: cubit));
      await tester.pumpAndSettle();
      final logButton = find.byKey(
        const Key('khatmah_dashboard_log_mushaf_button'),
      );
      await tester.ensureVisible(logButton);
      await tester.tap(logButton);
      await tester.pumpAndSettle();
      final input = find.byKey(
        const Key('khatmah_dashboard_mushaf_page_input'),
      );
      await tester.enterText(input, '25');
      await tester.tap(
        find.byKey(const Key('khatmah_dashboard_mushaf_save_button')),
      );
      await tester.pump();
      await tester.pump();

      expect(input, findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(
        find.byKey(const Key('khatmah_dashboard_mushaf_save_error')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('khatmah_dashboard_mushaf_save_button')),
      );
      await tester.pumpAndSettle();

      expect(attempts, 2);
      verify(
        () => mockRecordReading(
          testPlan,
          25,
          source: KhatmahReadingSource.physical,
        ),
      ).called(2);
    },
  );

  testWidgets('paused plan remains visible with resume action', (tester) async {
    final paused = testPlan.copyWith(status: KhatmahStatus.paused);
    when(() => mockGetActive()).thenAnswer((_) async => paused);
    final cubit = buildCubit();

    await tester.pumpWidget(buildWidget(cubit: cubit));
    await tester.pumpAndSettle();

    expect(find.text(paused.title), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets('pausing khatmah calls cubit.pause() and allows resume', (
    tester,
  ) async {
    when(() => mockGetActive()).thenAnswer((_) async => testPlan);
    final pausedPlan = testPlan.copyWith(status: KhatmahStatus.paused);
    when(
      () => mockPauseResume.pause(any()),
    ).thenAnswer((_) async => pausedPlan);
    when(() => mockPauseResume.resume(any())).thenAnswer((_) async => testPlan);

    final cubit = buildCubit();

    await tester.pumpWidget(buildWidget(cubit: cubit));
    await tester.pumpAndSettle();

    // Pause button
    final pauseBtn = find.byKey(
      const Key('khatmah_dashboard_pause_resume_button'),
    );
    expect(pauseBtn, findsOneWidget);
    await tester.ensureVisible(pauseBtn);
    await tester.tap(pauseBtn);
    await tester.pumpAndSettle();

    verify(() => mockPauseResume.pause(any())).called(1);

    // After pausing, button should allow resuming
    when(() => mockGetActive()).thenAnswer((_) async => pausedPlan);
    final resumeBtn = find.byKey(
      const Key('khatmah_dashboard_pause_resume_button'),
    );
    expect(resumeBtn, findsOneWidget);
    await tester.ensureVisible(resumeBtn);
    await tester.tap(resumeBtn);
    await tester.pumpAndSettle();

    verify(() => mockPauseResume.resume(any())).called(1);
  });

  testWidgets('abandoning khatmah shows confirmation dialog and calls delete', (
    tester,
  ) async {
    when(() => mockGetActive()).thenAnswer((_) async => testPlan);
    when(() => mockDelete()).thenAnswer((_) async {});

    final cubit = buildCubit();

    await tester.pumpWidget(buildWidget(cubit: cubit));
    await tester.pumpAndSettle();

    // Tap abandon button
    final abandonBtn = find.byKey(
      const Key('khatmah_dashboard_abandon_button'),
    );
    expect(abandonBtn, findsOneWidget);
    await tester.ensureVisible(abandonBtn);
    await tester.tap(abandonBtn);
    await tester.pumpAndSettle();

    // Confirm in dialog
    final confirmBtn = find.byKey(
      const Key('khatmah_dashboard_abandon_confirm_button'),
    );
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    verify(() => mockDelete()).called(1);
  });

  testWidgets(
    'adaptive controls: calm adjustment and mild compensation trigger updates',
    (tester) async {
      when(() => mockGetActive()).thenAnswer((_) async => testPlan);
      when(
        () => mockUpdateSchedule(
          planId: testPlan.id,
          targetPagesPerDay: any(named: 'targetPagesPerDay'),
          targetDays: any(named: 'targetDays'),
          expectedEndDate: any(named: 'expectedEndDate'),
        ),
      ).thenAnswer((_) async => testPlan);
      when(
        () => mockRecordReading(any(), any(), source: any(named: 'source')),
      ).thenAnswer((inv) async {
        final plan = inv.positionalArguments[0] as KhatmahPlan;
        final page = inv.positionalArguments[1] as int;
        return KhatmahReadingResult(
          plan: plan.recordThroughPage(page),
          newlyCompletedPages: const {},
        );
      });

      final cubit = buildCubit();

      await tester.pumpWidget(buildWidget(cubit: cubit));
      await tester.pumpAndSettle();

      final calmBtn = find.byKey(
        const Key('khatmah_dashboard_calm_adjustment_button'),
      );
      expect(calmBtn, findsOneWidget);
      await tester.ensureVisible(calmBtn);
      await tester.tap(calmBtn);
      await tester.pumpAndSettle();

      verify(
        () => mockUpdateSchedule(
          planId: testPlan.id,
          targetPagesPerDay: any(named: 'targetPagesPerDay'),
          targetDays: any(named: 'targetDays'),
          expectedEndDate: any(named: 'expectedEndDate'),
        ),
      ).called(1);

      final mildBtn = find.byKey(
        const Key('khatmah_dashboard_mild_compensation_button'),
      );
      expect(mildBtn, findsOneWidget);
      await tester.ensureVisible(mildBtn);
      await tester.tap(mildBtn);
      await tester.pumpAndSettle();

      verify(
        () => mockUpdateSchedule(
          planId: testPlan.id,
          targetPagesPerDay: any(named: 'targetPagesPerDay'),
          targetDays: any(named: 'targetDays'),
          expectedEndDate: any(named: 'expectedEndDate'),
        ),
      ).called(1);
    },
  );
}
