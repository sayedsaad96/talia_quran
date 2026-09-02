import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';

class MockGetActiveKhatmahUsecase extends Mock
    implements GetActiveKhatmahUsecase {}

class MockRecordKhatmahReadingUsecase extends Mock
    implements RecordKhatmahReadingUsecase {}

class MockPauseResumeKhatmahUsecase extends Mock
    implements PauseResumeKhatmahUsecase {}

class MockDeleteKhatmahUsecase extends Mock implements DeleteKhatmahUsecase {}

class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  late MockGetActiveKhatmahUsecase getActive;
  late MockRecordKhatmahReadingUsecase recordReading;
  late MockPauseResumeKhatmahUsecase pauseResume;
  late MockDeleteKhatmahUsecase deleteKhatmah;

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

  KhatmahCubit buildCubit() =>
      KhatmahCubit(getActive, recordReading, pauseResume, deleteKhatmah);

  setUpAll(() => registerFallbackValue(FakeKhatmahPlan()));
  setUp(() {
    getActive = MockGetActiveKhatmahUsecase();
    recordReading = MockRecordKhatmahReadingUsecase();
    pauseResume = MockPauseResumeKhatmahUsecase();
    deleteKhatmah = MockDeleteKhatmahUsecase();
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
}
