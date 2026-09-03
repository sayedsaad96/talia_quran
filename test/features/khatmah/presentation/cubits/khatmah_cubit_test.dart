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

  setUpAll(() {
    registerFallbackValue(FakeKhatmahPlan());
    registerFallbackValue(KhatmahReadingSource.digital);
  });
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
        KhatmahCompleted(
          plan: completed,
          historyEntry: history,
          newlyCompletedPages: const {604},
        ),
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

  test(
    'queues distinct pages and resolves each against the latest plan',
    () async {
      final firstWrite = Completer<KhatmahReadingResult>();
      final secondWrite = Completer<KhatmahReadingResult>();
      final firstUpdated = activePlan.recordPage(2);
      final secondUpdated = firstUpdated.recordPage(3);
      when(() => getActive()).thenAnswer((_) async => activePlan);
      when(
        () => recordReading(any(), any(), source: any(named: 'source')),
      ).thenAnswer((invocation) {
        final plan = invocation.positionalArguments[0] as KhatmahPlan;
        final page = invocation.positionalArguments[1] as int;
        expect(page, firstWrite.isCompleted ? 3 : 2);
        expect(plan, page == 2 ? activePlan : firstUpdated);
        return page == 2 ? firstWrite.future : secondWrite.future;
      });
      final cubit = buildCubit();
      await cubit.load();

      final first = cubit.recordDigitalPage(2);
      final second = cubit.recordDigitalPage(3);
      verify(
        () =>
            recordReading(activePlan, 2, source: KhatmahReadingSource.digital),
      ).called(1);

      firstWrite.complete(
        KhatmahReadingResult(
          plan: firstUpdated,
          newlyCompletedPages: const {2},
        ),
      );
      await Future<void>.delayed(Duration.zero);
      verify(
        () => recordReading(
          firstUpdated,
          3,
          source: KhatmahReadingSource.digital,
        ),
      ).called(1);
      secondWrite.complete(
        KhatmahReadingResult(
          plan: secondUpdated,
          newlyCompletedPages: const {3},
        ),
      );
      await Future.wait([first, second]);

      expect(
        (cubit.state as KhatmahActive).plan.completedPages,
        containsAll([2, 3]),
      );
      await cubit.close();
    },
  );

  test('failure does not poison queued work or a later retry', () async {
    final firstWrite = Completer<KhatmahReadingResult>();
    final queuedWrite = Completer<KhatmahReadingResult>();
    var calls = 0;
    when(() => getActive()).thenAnswer((_) async => activePlan);
    when(
      () => recordReading(any(), any(), source: any(named: 'source')),
    ).thenAnswer((invocation) {
      calls++;
      if (calls == 1) return firstWrite.future;
      if (calls == 2) return queuedWrite.future;
      final plan = invocation.positionalArguments[0] as KhatmahPlan;
      return Future.value(
        KhatmahReadingResult(
          plan: plan.recordPage(2),
          newlyCompletedPages: const {2},
        ),
      );
    });
    final cubit = buildCubit();
    await cubit.load();
    final failed = cubit.recordDigitalPage(2);
    final queued = cubit.recordDigitalPage(3);
    firstWrite.completeError(Exception('disk unavailable'));
    await Future<void>.delayed(Duration.zero);
    queuedWrite.complete(
      KhatmahReadingResult(
        plan: activePlan.recordPage(3),
        newlyCompletedPages: const {3},
      ),
    );
    await Future.wait([failed, queued]);
    await cubit.recordDigitalPage(2);

    expect(calls, 3);
    expect(
      (cubit.state as KhatmahActive).plan.completedPages,
      containsAll([2, 3]),
    );
    await cubit.close();
  });

  test('close drains accepted records in FIFO order before closing', () async {
    final page2Write = Completer<KhatmahReadingResult>();
    final page3Write = Completer<KhatmahReadingResult>();
    final page2Plan = activePlan.recordPage(2);
    final page3Plan = page2Plan.recordPage(3);
    when(() => getActive()).thenAnswer((_) async => activePlan);
    when(
      () => recordReading(any(), any(), source: any(named: 'source')),
    ).thenAnswer((invocation) {
      final plan = invocation.positionalArguments[0] as KhatmahPlan;
      final page = invocation.positionalArguments[1] as int;
      if (page == 2) {
        expect(plan, activePlan);
        return page2Write.future;
      }
      expect(page, 3);
      expect(plan, page2Plan);
      return page3Write.future;
    });
    final cubit = buildCubit();
    await cubit.load();

    final first = cubit.recordDigitalPage(2);
    final second = cubit.recordDigitalPage(3);
    final closing = cubit.close();
    await cubit.recordDigitalPage(4);
    verifyNever(
      () => recordReading(any(), 4, source: KhatmahReadingSource.digital),
    );

    page2Write.complete(
      KhatmahReadingResult(plan: page2Plan, newlyCompletedPages: const {2}),
    );
    await Future<void>.delayed(Duration.zero);
    verify(
      () => recordReading(page2Plan, 3, source: KhatmahReadingSource.digital),
    ).called(1);
    page3Write.complete(
      KhatmahReadingResult(plan: page3Plan, newlyCompletedPages: const {3}),
    );
    await Future.wait([first, second]);
    await closing;
    expect(cubit.isClosed, isTrue);
  });

  test(
    'later success retains an earlier failure and retries it against latest plan',
    () async {
      final page2Write = Completer<KhatmahReadingResult>();
      final page3Plan = activePlan.recordPage(3);
      final retryPlan = page3Plan.recordPage(2);
      var calls = 0;
      when(() => getActive()).thenAnswer((_) async => activePlan);
      when(
        () => recordReading(any(), any(), source: any(named: 'source')),
      ).thenAnswer((invocation) {
        calls++;
        final page = invocation.positionalArguments[1] as int;
        if (calls == 1) return page2Write.future;
        if (calls == 2) {
          expect(page, 3);
          return Future.value(
            KhatmahReadingResult(
              plan: page3Plan,
              newlyCompletedPages: const {3},
            ),
          );
        }
        expect(page, 2);
        expect(invocation.positionalArguments[0], page3Plan);
        return Future.value(
          KhatmahReadingResult(plan: retryPlan, newlyCompletedPages: const {2}),
        );
      });
      final cubit = buildCubit();
      await cubit.load();
      final failed = cubit.recordDigitalPage(2);
      final queued = cubit.recordDigitalPage(3);
      page2Write.completeError(Exception('disk unavailable'));
      await Future.wait([failed, queued]);

      expect(cubit.state, isA<KhatmahProgressFailure>());
      final failure = cubit.state as KhatmahProgressFailure;
      expect(failure.pageNumber, 2);
      expect(failure.plan, page3Plan);
      await cubit.retryLastProgress();
      expect(calls, 3);
      expect(cubit.state, isA<KhatmahActive>());
      expect(
        (cubit.state as KhatmahActive).plan.completedPages,
        containsAll([2, 3]),
      );
      await cubit.close();
    },
  );

  test('distinct failures remain available for subsequent retries', () async {
    final page2Write = Completer<KhatmahReadingResult>();
    final page3Write = Completer<KhatmahReadingResult>();
    final page2Plan = activePlan.recordPage(2);
    final page3Plan = page2Plan.recordPage(3);
    var calls = 0;
    when(() => getActive()).thenAnswer((_) async => activePlan);
    when(
      () => recordReading(any(), any(), source: any(named: 'source')),
    ).thenAnswer((invocation) {
      calls++;
      final page = invocation.positionalArguments[1] as int;
      if (calls == 1) return page2Write.future;
      if (calls == 2) return page3Write.future;
      if (calls == 3) {
        expect(page, 3);
        return Future.value(
          KhatmahReadingResult(plan: page3Plan, newlyCompletedPages: const {3}),
        );
      }
      expect(page, 2);
      return Future.value(
        KhatmahReadingResult(plan: page3Plan, newlyCompletedPages: const {2}),
      );
    });
    final cubit = buildCubit();
    await cubit.load();
    final page2 = cubit.recordDigitalPage(2);
    final page3 = cubit.recordDigitalPage(3);
    page2Write.completeError(Exception('page 2 failed'));
    await Future<void>.delayed(Duration.zero);
    page3Write.completeError(Exception('page 3 failed'));
    await Future.wait([page2, page3]);

    expect((cubit.state as KhatmahProgressFailure).pageNumber, 3);
    await cubit.retryLastProgress();
    expect((cubit.state as KhatmahProgressFailure).pageNumber, 2);
    await cubit.retryLastProgress();
    expect(calls, 4);
    expect(cubit.state, isA<KhatmahActive>());
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

  test(
    'load failure after pause retains the paused authoritative plan',
    () async {
      final paused = activePlan.pause(at: DateTime(2026, 1, 2));
      when(() => getActive()).thenAnswer((_) async => activePlan);
      when(() => pauseResume.pause(activePlan)).thenAnswer((_) async => paused);
      final cubit = buildCubit();
      await cubit.load();
      await cubit.pause();
      when(() => getActive()).thenThrow(Exception('offline'));
      await cubit.load();
      expect((cubit.state as KhatmahProgressFailure).plan, paused);
      await cubit.close();
    },
  );

  test(
    'load failure after resume retains the resumed authoritative plan',
    () async {
      final paused = activePlan.pause(at: DateTime(2026, 1, 2));
      final resumed = paused.resume(fromDate: DateTime(2026, 1, 3));
      when(() => getActive()).thenAnswer((_) async => activePlan);
      when(() => pauseResume.pause(activePlan)).thenAnswer((_) async => paused);
      when(() => pauseResume.resume(paused)).thenAnswer((_) async => resumed);
      final cubit = buildCubit();
      await cubit.load();
      await cubit.pause();
      when(() => getActive()).thenAnswer((_) async => paused);
      await cubit.resume();
      when(() => getActive()).thenThrow(Exception('offline'));
      await cubit.load();
      expect((cubit.state as KhatmahProgressFailure).plan, resumed);
      await cubit.close();
    },
  );

  test('delayed in-flight failure releases the guard for retry', () async {
    final delayed = Completer<KhatmahReadingResult>();
    when(() => getActive()).thenAnswer((_) async => activePlan);
    when(
      () => recordReading(activePlan, 2, source: KhatmahReadingSource.digital),
    ).thenAnswer((_) => delayed.future);
    final cubit = buildCubit();
    await cubit.load();
    final first = cubit.recordDigitalPage(2);
    final duplicate = cubit.recordDigitalPage(2);
    delayed.completeError(Exception('disk unavailable'));
    await Future.wait([first, duplicate]);
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
      final authoritative = activePlan.copyWith(
        targetPagesPerDay: 5,
        completedPages: {...activePlan.completedPages, 2},
      );
      when(
        () => updateSchedule(
          planId: activePlan.id,
          targetPagesPerDay: any(named: 'targetPagesPerDay'),
          targetDays: any(named: 'targetDays'),
          expectedEndDate: any(named: 'expectedEndDate'),
        ),
      ).thenAnswer((_) async => authoritative);
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
      expect((cubit.state as KhatmahActive).plan, authoritative);
      await cubit.close();
    },
  );

  test(
    'load failure after abandonment does not resurrect the old plan',
    () async {
      when(() => getActive()).thenAnswer((_) async => activePlan);
      when(() => deleteKhatmah()).thenAnswer((_) async {});
      final cubit = buildCubit();
      await cubit.load();
      await cubit.abandonPlan();
      when(() => getActive()).thenThrow(Exception('offline'));
      await cubit.load();
      expect((cubit.state as KhatmahProgressFailure).plan, isNull);
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
