import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_schedule_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';

class MockGetActiveKhatmahUsecase extends Mock
    implements GetActiveKhatmahUsecase {}

class MockRecordKhatmahReadingUsecase extends Mock
    implements RecordKhatmahReadingUsecase {}

class MockPauseResumeKhatmahUsecase extends Mock
    implements PauseResumeKhatmahUsecase {}

class MockDeleteKhatmahUsecase extends Mock implements DeleteKhatmahUsecase {}

class MockUpdateKhatmahScheduleUsecase extends Mock
    implements UpdateKhatmahScheduleUsecase {}

class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  late MockGetActiveKhatmahUsecase getActive;
  late MockRecordKhatmahReadingUsecase recordReading;
  late MockPauseResumeKhatmahUsecase pauseResume;
  late MockDeleteKhatmahUsecase deleteKhatmah;
  late MockUpdateKhatmahScheduleUsecase updateSchedule;

  final activePlan = KhatmahPlan(
    id: 'plan-1',
    title: 'Ramadan',
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 6, 1),
    completedPages: const {1},
    status: KhatmahStatus.active,
  );

  KhatmahCubit buildCubit() => KhatmahCubit(
    getActive,
    recordReading,
    pauseResume,
    deleteKhatmah,
    updateSchedule,
  );

  setUpAll(() => registerFallbackValue(FakeKhatmahPlan()));
  setUp(() {
    getActive = MockGetActiveKhatmahUsecase();
    recordReading = MockRecordKhatmahReadingUsecase();
    pauseResume = MockPauseResumeKhatmahUsecase();
    deleteKhatmah = MockDeleteKhatmahUsecase();
    updateSchedule = MockUpdateKhatmahScheduleUsecase();
  });

  test('starts in the initial state', () async {
    final cubit = buildCubit();
    expect(cubit.state, const KhatmahInitial());
    await cubit.close();
  });

  test('loads active, absent, and completed plans distinctly', () async {
    when(() => getActive()).thenAnswer((_) async => activePlan);
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state, isA<KhatmahActive>());

    when(() => getActive()).thenAnswer((_) async => null);
    await cubit.load();
    expect(cubit.state, const KhatmahNoActivePlan());

    when(() => getActive()).thenAnswer(
      (_) async => activePlan.copyWith(status: KhatmahStatus.completed),
    );
    await cubit.load();
    expect(cubit.state, const KhatmahNoActivePlan());
    await cubit.close();
  });

  test('loads a paused plan into the distinct paused state', () async {
    when(() => getActive()).thenAnswer(
      (_) async => activePlan.copyWith(status: KhatmahStatus.paused),
    );
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state, isA<KhatmahPaused>());
    await cubit.close();
  });

  test('digital page 604 alone does not complete a plan with gaps', () async {
    final page604Only = activePlan.recordPage(604);
    when(() => getActive()).thenAnswer((_) async => activePlan);
    when(
      () =>
          recordReading(activePlan, 604, source: KhatmahReadingSource.digital),
    ).thenAnswer(
      (_) async => KhatmahReadingResult(
        plan: page604Only,
        newlyCompletedPages: const {604},
      ),
    );
    final cubit = buildCubit();
    await cubit.load();
    await cubit.recordDigitalPage(604);
    expect(cubit.state, isA<KhatmahActive>());
    expect((cubit.state as KhatmahActive).plan.completedPages, contains(604));
    await cubit.close();
  });

  test(
    'complete explicit coverage emits the persisted history entry once',
    () async {
      final nearlyComplete = activePlan.copyWith(
        completedPages: {for (var page = 1; page < 604; page++) page},
      );
      final history = KhatmahHistoryEntry(
        id: 'history-1',
        khatmahNumber: 1,
        title: 'Ramadan',
        startDate: DateTime(2026, 1, 1),
        completedDate: DateTime(2026, 2, 1),
        totalDays: 32,
      );
      final completed = nearlyComplete
          .recordPage(604)
          .copyWith(status: KhatmahStatus.completed);
      when(() => getActive()).thenAnswer((_) async => nearlyComplete);
      when(
        () => recordReading(
          nearlyComplete,
          604,
          source: KhatmahReadingSource.digital,
        ),
      ).thenAnswer(
        (_) async => KhatmahReadingResult(
          plan: completed,
          historyEntry: history,
          newlyCompletedPages: const {604},
        ),
      );
      final cubit = buildCubit();
      await cubit.load();
      await cubit.recordDigitalPage(604);
      await cubit.recordDigitalPage(604);
      expect(
        cubit.state,
        KhatmahCompleted(plan: completed, historyEntry: history),
      );
      verify(
        () => recordReading(
          nearlyComplete,
          604,
          source: KhatmahReadingSource.digital,
        ),
      ).called(1);
      await cubit.close();
    },
  );

  test('storage failure preserves the action for retry', () async {
    when(() => getActive()).thenAnswer((_) async => activePlan);
    when(
      () => recordReading(activePlan, 2, source: KhatmahReadingSource.digital),
    ).thenThrow(Exception('disk unavailable'));
    final cubit = buildCubit();
    await cubit.load();
    await cubit.recordDigitalPage(2);
    expect(cubit.state, isA<KhatmahProgressFailure>());
    final failure = cubit.state as KhatmahProgressFailure;
    expect(failure.pageNumber, 2);
    expect(failure.source, KhatmahReadingSource.digital);
    await cubit.retryLastProgress();
    verify(
      () => recordReading(activePlan, 2, source: KhatmahReadingSource.digital),
    ).called(2);
    await cubit.close();
  });

  test(
    'paused plans reject digital progress without calling storage',
    () async {
      final paused = activePlan.copyWith(status: KhatmahStatus.paused);
      when(() => getActive()).thenAnswer((_) async => paused);
      final cubit = buildCubit();
      await cubit.load();
      await cubit.recordDigitalPage(2);
      expect(cubit.state, KhatmahPaused(plan: paused));
      verifyNever(
        () => recordReading(paused, 2, source: KhatmahReadingSource.digital),
      );
      await cubit.close();
    },
  );

  test('concurrent record requests persist only once', () async {
    final completer = Completer<KhatmahReadingResult>();
    when(() => getActive()).thenAnswer((_) async => activePlan);
    when(
      () => recordReading(activePlan, 2, source: KhatmahReadingSource.digital),
    ).thenAnswer((_) => completer.future);
    final cubit = buildCubit();
    await cubit.load();
    final first = cubit.recordDigitalPage(2);
    final second = cubit.recordDigitalPage(2);
    verify(
      () => recordReading(activePlan, 2, source: KhatmahReadingSource.digital),
    ).called(1);
    completer.complete(
      KhatmahReadingResult(
        plan: activePlan.recordPage(2),
        newlyCompletedPages: const {2},
      ),
    );
    await Future.wait([first, second]);
    await cubit.close();
  });

  test('physical progress dispatches the physical reading source', () async {
    final updated = activePlan.recordThroughPage(4);
    when(() => getActive()).thenAnswer((_) async => activePlan);
    when(
      () => recordReading(activePlan, 4, source: KhatmahReadingSource.physical),
    ).thenAnswer(
      (_) async => KhatmahReadingResult(
        plan: updated,
        newlyCompletedPages: const {2, 3, 4},
      ),
    );
    final cubit = buildCubit();
    await cubit.load();
    await cubit.recordPhysicalThroughPage(4);
    verify(
      () => recordReading(activePlan, 4, source: KhatmahReadingSource.physical),
    ).called(1);
    await cubit.close();
  });

  test('load error retains the last authoritative plan', () async {
    when(() => getActive()).thenAnswer((_) async => activePlan);
    final cubit = buildCubit();
    await cubit.load();
    when(() => getActive()).thenThrow(Exception('corrupt storage'));
    await cubit.load();
    final failure = cubit.state as KhatmahProgressFailure;
    expect(failure.plan, activePlan);
    expect(failure.pageNumber, 0);
    await cubit.close();
  });

  test('delayed in-flight failure releases the guard for retry', () async {
    final delayed = Completer<KhatmahReadingResult>();
    when(() => getActive()).thenAnswer((_) async => activePlan);
    when(
      () => recordReading(activePlan, 2, source: KhatmahReadingSource.digital),
    ).thenAnswer((_) => delayed.future);
    final cubit = buildCubit();
    await cubit.load();
    final first = cubit.recordDigitalPage(2);
    await cubit.recordDigitalPage(2);
    delayed.completeError(Exception('disk unavailable'));
    await first;
    expect(cubit.state, isA<KhatmahProgressFailure>());

    when(
      () => recordReading(activePlan, 2, source: KhatmahReadingSource.digital),
    ).thenAnswer(
      (_) async => KhatmahReadingResult(
        plan: activePlan.recordPage(2),
        newlyCompletedPages: const {2},
      ),
    );
    await cubit.retryLastProgress();
    verify(
      () => recordReading(activePlan, 2, source: KhatmahReadingSource.digital),
    ).called(2);
    await cubit.close();
  });

  test('pause and resume preserve the plan and restore active state', () async {
    final paused = activePlan.pause(at: DateTime(2026, 1, 2));
    final resumed = paused.resume(fromDate: DateTime(2026, 1, 3));
    when(() => getActive()).thenAnswer((_) async => activePlan);
    when(() => pauseResume.pause(activePlan)).thenAnswer((_) async => paused);
    when(() => pauseResume.resume(paused)).thenAnswer((_) async => resumed);
    final cubit = buildCubit();
    await cubit.load();
    await cubit.pause();
    expect(cubit.state, KhatmahPaused(plan: paused));
    when(() => getActive()).thenAnswer((_) async => paused);
    await cubit.resume();
    expect((cubit.state as KhatmahActive).plan, resumed);
    await cubit.close();
  });

  test(
    'schedule adjustment uses the schedule-only persistence command',
    () async {
      when(() => getActive()).thenAnswer((_) async => activePlan);
      when(
        () => updateSchedule(
          planId: activePlan.id,
          targetPagesPerDay: any(named: 'targetPagesPerDay'),
          targetDays: any(named: 'targetDays'),
          expectedEndDate: any(named: 'expectedEndDate'),
        ),
      ).thenAnswer((_) async => activePlan);
      final cubit = buildCubit();
      await cubit.load();
      await cubit.mildCompensation();
      verify(
        () => updateSchedule(
          planId: activePlan.id,
          targetPagesPerDay: 5,
          targetDays: any(named: 'targetDays'),
          expectedEndDate: any(named: 'expectedEndDate'),
        ),
      ).called(1);
      expect((cubit.state as KhatmahActive).plan.targetPagesPerDay, 5);
      await cubit.close();
    },
  );

  test('abandon deletes the plan and emits no-active state', () async {
    when(() => deleteKhatmah()).thenAnswer((_) async {});
    final cubit = buildCubit();
    await cubit.abandonPlan();
    verify(() => deleteKhatmah()).called(1);
    expect(cubit.state, const KhatmahNoActivePlan());
    await cubit.close();
  });
}
