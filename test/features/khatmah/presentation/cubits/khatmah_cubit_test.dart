import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/complete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_progress_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';

import '../../../../helpers/bloc_test_helper.dart';

class MockGetActiveKhatmahUsecase extends Mock
    implements GetActiveKhatmahUsecase {}

class MockUpdateKhatmahProgressUsecase extends Mock
    implements UpdateKhatmahProgressUsecase {}

class MockCompleteKhatmahUsecase extends Mock
    implements CompleteKhatmahUsecase {}

class MockPauseResumeKhatmahUsecase extends Mock
    implements PauseResumeKhatmahUsecase {}

class MockDeleteKhatmahUsecase extends Mock
    implements DeleteKhatmahUsecase {}

class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  late MockGetActiveKhatmahUsecase mockGetActive;
  late MockUpdateKhatmahProgressUsecase mockUpdateProgress;
  late MockCompleteKhatmahUsecase mockComplete;
  late MockPauseResumeKhatmahUsecase mockPauseResume;
  late MockDeleteKhatmahUsecase mockDelete;

  final testPlan = KhatmahPlan(
    id: 'test-khatmah-1',
    title: 'Ramadan Khatmah',
    startPage: 1,
    completedPages: {for (var page = 1; page <= 10; page++) page},
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 6, 1),
    status: KhatmahStatus.active,
    dedication: const KhatmahDedication(
      isDedicated: true,
      recipientName: 'Father',
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

  group('KhatmahCubit Initial State', () {
    test('initial state is KhatmahInitial', () {
      final cubit = buildCubit();
      expect(cubit.state, equals(const KhatmahInitial()));
      cubit.close();
    });
  });

  group('load()', () {
    blocTest<KhatmahCubit, KhatmahState>(
      'emits [KhatmahLoading, KhatmahActive] when active plan exists',
      build: () {
        when(() => mockGetActive()).thenAnswer((_) async => testPlan);
        return buildCubit();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const KhatmahLoading(),
        KhatmahActive(
          plan: testPlan,
          wirdStartPage: 11,
          wirdEndPage: 14,
        ),
      ],
      verify: (_) {
        verify(() => mockGetActive()).called(1);
      },
    );

    blocTest<KhatmahCubit, KhatmahState>(
      'emits [KhatmahLoading, KhatmahNoActivePlan] when no plan exists',
      build: () {
        when(() => mockGetActive()).thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const KhatmahLoading(),
        const KhatmahNoActivePlan(),
      ],
    );

    blocTest<KhatmahCubit, KhatmahState>(
      'emits [KhatmahLoading, KhatmahNoActivePlan] when stored plan is paused',
      build: () {
        final pausedPlan = testPlan.copyWith(status: KhatmahStatus.paused);
        when(() => mockGetActive()).thenAnswer((_) async => pausedPlan);
        return buildCubit();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const KhatmahLoading(),
        const KhatmahNoActivePlan(),
      ],
    );

    blocTest<KhatmahCubit, KhatmahState>(
      'emits [KhatmahLoading, KhatmahNoActivePlan] when stored plan is completed',
      build: () {
        final completedPlan =
            testPlan.copyWith(status: KhatmahStatus.completed);
        when(() => mockGetActive()).thenAnswer((_) async => completedPlan);
        return buildCubit();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const KhatmahLoading(),
        const KhatmahNoActivePlan(),
      ],
    );
  });

  group('advancePage()', () {
    blocTest<KhatmahCubit, KhatmahState>(
      'does nothing if state is not KhatmahActive',
      build: buildCubit,
      act: (cubit) => cubit.advancePage(12),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockUpdateProgress(any(), any()));
      },
    );

    blocTest<KhatmahCubit, KhatmahState>(
      'emits updated KhatmahActive when reading within daily wird',
      build: () {
        final updatedPlan = testPlan.recordThroughPage(12);
        when(() => mockGetActive()).thenAnswer((_) async => testPlan);
        when(() => mockUpdateProgress(testPlan, 12))
            .thenAnswer((_) async => updatedPlan);
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.advancePage(12);
      },
      expect: () => [
        const KhatmahLoading(),
        KhatmahActive(
          plan: testPlan,
          wirdStartPage: 11,
          wirdEndPage: 14,
        ),
        KhatmahActive(
          plan: testPlan.recordThroughPage(12),
          wirdStartPage: 13,
          wirdEndPage: 16,
        ),
      ],
      verify: (_) {
        verify(() => mockUpdateProgress(testPlan, 12)).called(1);
      },
    );

    blocTest<KhatmahCubit, KhatmahState>(
      'emits KhatmahWirdCompleted when reaching or exceeding daily wird end page',
      build: () {
        final updatedPlan = testPlan.recordThroughPage(14);
        when(() => mockGetActive()).thenAnswer((_) async => testPlan);
        when(() => mockUpdateProgress(testPlan, 14))
            .thenAnswer((_) async => updatedPlan);
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.advancePage(14);
      },
      expect: () => [
        const KhatmahLoading(),
        KhatmahActive(
          plan: testPlan,
          wirdStartPage: 11,
          wirdEndPage: 14,
        ),
        KhatmahWirdCompleted(plan: testPlan.recordThroughPage(14)),
      ],
      verify: (_) {
        verify(() => mockUpdateProgress(testPlan, 14)).called(1);
        verifyNever(() => mockComplete(any()));
      },
    );

    blocTest<KhatmahCubit, KhatmahState>(
      'calls complete and emits KhatmahCompleted with completed status when reaching page 604',
      build: () {
        final nearEndPlan = testPlan.recordThroughPage(600);
        final updatedPlan = nearEndPlan.recordThroughPage(604);
        when(() => mockGetActive()).thenAnswer((_) async => nearEndPlan);
        when(() => mockUpdateProgress(nearEndPlan, 604))
            .thenAnswer((_) async => updatedPlan);
        when(() => mockComplete(any())).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.advancePage(604);
      },
      expect: () => [
        const KhatmahLoading(),
        KhatmahActive(
          plan: testPlan.recordThroughPage(600),
          wirdStartPage: 601,
          wirdEndPage: 604,
        ),
        isA<KhatmahCompleted>()
            .having(
              (s) => s.plan.status,
              'plan.status',
              KhatmahStatus.completed,
            )
            .having(
              (s) => s.plan.currentPage,
              'plan.currentPage',
              604,
            ),
      ],
      verify: (_) {
        verify(() => mockComplete(any())).called(1);
      },
    );
  });

  group('pause()', () {
    blocTest<KhatmahCubit, KhatmahState>(
      'does nothing if state is not KhatmahActive',
      build: buildCubit,
      act: (cubit) => cubit.pause(),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockPauseResume.pause(any()));
      },
    );

    blocTest<KhatmahCubit, KhatmahState>(
      'pauses plan and emits KhatmahNoActivePlan when state is KhatmahActive',
      build: () {
        final pausedPlan = testPlan.copyWith(status: KhatmahStatus.paused);
        when(() => mockGetActive()).thenAnswer((_) async => testPlan);
        when(() => mockPauseResume.pause(testPlan))
            .thenAnswer((_) async => pausedPlan);
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.pause();
      },
      expect: () => [
        const KhatmahLoading(),
        KhatmahActive(
          plan: testPlan,
          wirdStartPage: 11,
          wirdEndPage: 14,
        ),
        const KhatmahNoActivePlan(),
      ],
      verify: (_) {
        verify(() => mockPauseResume.pause(testPlan)).called(1);
      },
    );
  });

  group('resume()', () {
    blocTest<KhatmahCubit, KhatmahState>(
      'resumes paused plan and emits KhatmahActive',
      build: () {
        final pausedPlan = testPlan.copyWith(status: KhatmahStatus.paused);
        final resumedPlan = testPlan.copyWith(status: KhatmahStatus.active);
        when(() => mockGetActive()).thenAnswer((_) async => pausedPlan);
        when(() => mockPauseResume.resume(pausedPlan))
            .thenAnswer((_) async => resumedPlan);
        return buildCubit();
      },
      act: (cubit) => cubit.resume(),
      expect: () => [
        KhatmahActive(
          plan: testPlan.copyWith(status: KhatmahStatus.active),
          wirdStartPage: 11,
          wirdEndPage: 14,
        ),
      ],
      verify: (_) {
        verify(() => mockGetActive()).called(1);
        verify(() => mockPauseResume.resume(any())).called(1);
      },
    );

    blocTest<KhatmahCubit, KhatmahState>(
      'falls back to load() when getActive returns active or null',
      build: () {
        when(() => mockGetActive()).thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (cubit) => cubit.resume(),
      expect: () => [
        const KhatmahLoading(),
        const KhatmahNoActivePlan(),
      ],
      verify: (_) {
        verifyNever(() => mockPauseResume.resume(any()));
      },
    );
  });

  group('abandonPlan()', () {
    blocTest<KhatmahCubit, KhatmahState>(
      'calls deleteKhatmah, emits KhatmahNoActivePlan, and subsequent load() emits KhatmahNoActivePlan',
      build: () {
        when(() => mockDelete()).thenAnswer((_) async {});
        when(() => mockGetActive()).thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.abandonPlan();
        await cubit.load();
      },
      expect: () => [
        const KhatmahNoActivePlan(),
        const KhatmahLoading(),
        const KhatmahNoActivePlan(),
      ],
      verify: (_) {
        verify(() => mockDelete()).called(1);
        verify(() => mockGetActive()).called(1);
      },
    );
  });
}
