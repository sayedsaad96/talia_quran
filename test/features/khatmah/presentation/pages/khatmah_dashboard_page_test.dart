import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_scheduling_engine.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/complete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_progress_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_dashboard_page.dart';

class MockGetActiveKhatmahUsecase extends Mock implements GetActiveKhatmahUsecase {}
class MockUpdateKhatmahProgressUsecase extends Mock implements UpdateKhatmahProgressUsecase {}
class MockCompleteKhatmahUsecase extends Mock implements CompleteKhatmahUsecase {}
class MockPauseResumeKhatmahUsecase extends Mock implements PauseResumeKhatmahUsecase {}
class MockDeleteKhatmahUsecase extends Mock implements DeleteKhatmahUsecase {}
class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  late MockGetActiveKhatmahUsecase mockGetActive;
  late MockUpdateKhatmahProgressUsecase mockUpdateProgress;
  late MockCompleteKhatmahUsecase mockComplete;
  late MockPauseResumeKhatmahUsecase mockPauseResume;
  late MockDeleteKhatmahUsecase mockDelete;

  final testPlan = KhatmahPlan(
    id: 'khatmah-test-1',
    title: 'ختمة رمضان المبارك',
    startPage: 1,
    currentPage: 20,
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
  });

  setUp(() {
    mockGetActive = MockGetActiveKhatmahUsecase();
    mockUpdateProgress = MockUpdateKhatmahProgressUsecase();
    mockComplete = MockCompleteKhatmahUsecase();
    mockPauseResume = MockPauseResumeKhatmahUsecase();
    mockDelete = MockDeleteKhatmahUsecase();
  });

  KhatmahCubit buildCubit() => KhatmahCubit(
        mockGetActive,
        mockUpdateProgress,
        mockComplete,
        mockPauseResume,
        mockDelete,
      );

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
            return Scaffold(
              body: Text('Page: $page, Mode: $mode'),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  testWidgets('renders header with title, dedication badge, and progress gauge', (tester) async {
    when(() => mockGetActive()).thenAnswer((_) async => testPlan);
    final cubit = buildCubit();

    await tester.pumpWidget(buildWidget(cubit: cubit));
    await tester.pumpAndSettle();

    expect(find.text('ختمة رمضان المبارك'), findsOneWidget);
    expect(find.textContaining('والدتي الغالية'), findsOneWidget);
    expect(find.byKey(const Key('khatmah_dashboard_dedication_badge')), findsOneWidget);
    expect(find.byKey(const Key('khatmah_progress_gauge')), findsOneWidget);
  });

  testWidgets('renders today\'s wird and clicking continue reading navigates to reader in khatmah mode', (tester) async {
    when(() => mockGetActive()).thenAnswer((_) async => testPlan);
    String? navigatedRoute;
    final cubit = buildCubit();

    await tester.pumpWidget(buildWidget(
      cubit: cubit,
      onNavigate: (route) => navigatedRoute = route,
    ));
    await tester.pumpAndSettle();

    final wird = KhatmahSchedulingEngine.todaysWird(testPlan.currentPage, testPlan.targetPagesPerDay);
    // Button to continue reading
    final continueBtn = find.byKey(const Key('khatmah_dashboard_continue_reading_button'));
    expect(continueBtn, findsOneWidget);

    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    expect(navigatedRoute, '/quran/page/${wird.startPage}?mode=khatmah');
  });

  testWidgets('physical mushaf logger dialog records read page and updates progress', (tester) async {
    when(() => mockGetActive()).thenAnswer((_) async => testPlan);
    when(() => mockUpdateProgress(any(), any())).thenAnswer(
      (inv) async => (inv.positionalArguments[0] as KhatmahPlan).copyWith(
        currentPage: inv.positionalArguments[1] as int,
      ),
    );
    final cubit = buildCubit();

    await tester.pumpWidget(buildWidget(cubit: cubit));
    await tester.pumpAndSettle();

    // Tap physical mushaf logger button
    final logMushafBtn = find.byKey(const Key('khatmah_dashboard_log_mushaf_button'));
    expect(logMushafBtn, findsOneWidget);
    await tester.ensureVisible(logMushafBtn);
    await tester.tap(logMushafBtn);
    await tester.pumpAndSettle();

    // Input page number
    final pageInput = find.byKey(const Key('khatmah_dashboard_mushaf_page_input'));
    expect(pageInput, findsOneWidget);
    await tester.enterText(pageInput, '25');
    await tester.pumpAndSettle();

    // Tap save
    final saveBtn = find.byKey(const Key('khatmah_dashboard_mushaf_save_button'));
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    verify(() => mockUpdateProgress(any(), 25)).called(1);
  });

  testWidgets('pausing khatmah calls cubit.pause() and allows resume', (tester) async {
    when(() => mockGetActive()).thenAnswer((_) async => testPlan);
    final pausedPlan = testPlan.copyWith(status: KhatmahStatus.paused);
    when(() => mockPauseResume.pause(any())).thenAnswer((_) async => pausedPlan);
    when(() => mockPauseResume.resume(any())).thenAnswer((_) async => testPlan);

    final cubit = buildCubit();

    await tester.pumpWidget(buildWidget(cubit: cubit));
    await tester.pumpAndSettle();

    // Pause button
    final pauseBtn = find.byKey(const Key('khatmah_dashboard_pause_resume_button'));
    expect(pauseBtn, findsOneWidget);
    await tester.ensureVisible(pauseBtn);
    await tester.tap(pauseBtn);
    await tester.pumpAndSettle();

    verify(() => mockPauseResume.pause(any())).called(1);

    // After pausing, button should allow resuming
    when(() => mockGetActive()).thenAnswer((_) async => pausedPlan);
    final resumeBtn = find.byKey(const Key('khatmah_dashboard_pause_resume_button'));
    expect(resumeBtn, findsOneWidget);
    await tester.ensureVisible(resumeBtn);
    await tester.tap(resumeBtn);
    await tester.pumpAndSettle();

    verify(() => mockPauseResume.resume(any())).called(1);
  });

  testWidgets('abandoning khatmah shows confirmation dialog and calls delete', (tester) async {
    when(() => mockGetActive()).thenAnswer((_) async => testPlan);
    when(() => mockDelete()).thenAnswer((_) async {});

    final cubit = buildCubit();

    await tester.pumpWidget(buildWidget(cubit: cubit));
    await tester.pumpAndSettle();

    // Tap abandon button
    final abandonBtn = find.byKey(const Key('khatmah_dashboard_abandon_button'));
    expect(abandonBtn, findsOneWidget);
    await tester.ensureVisible(abandonBtn);
    await tester.tap(abandonBtn);
    await tester.pumpAndSettle();

    // Confirm in dialog
    final confirmBtn = find.byKey(const Key('khatmah_dashboard_abandon_confirm_button'));
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    verify(() => mockDelete()).called(1);
  });

  testWidgets('adaptive controls: calm adjustment and mild compensation trigger updates', (tester) async {
    when(() => mockGetActive()).thenAnswer((_) async => testPlan);
    when(() => mockUpdateProgress(any(), any())).thenAnswer(
      (inv) async => inv.positionalArguments[0] as KhatmahPlan,
    );

    final cubit = buildCubit();

    await tester.pumpWidget(buildWidget(cubit: cubit));
    await tester.pumpAndSettle();

    final calmBtn = find.byKey(const Key('khatmah_dashboard_calm_adjustment_button'));
    expect(calmBtn, findsOneWidget);
    await tester.ensureVisible(calmBtn);
    await tester.tap(calmBtn);
    await tester.pumpAndSettle();

    verify(() => mockUpdateProgress(any(), any())).called(1);

    final mildBtn = find.byKey(const Key('khatmah_dashboard_mild_compensation_button'));
    expect(mildBtn, findsOneWidget);
    await tester.ensureVisible(mildBtn);
    await tester.tap(mildBtn);
    await tester.pumpAndSettle();

    verify(() => mockUpdateProgress(any(), any())).called(1);
  });
}
