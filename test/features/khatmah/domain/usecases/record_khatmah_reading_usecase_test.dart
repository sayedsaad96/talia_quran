import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/repositories/khatmah_repository.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart';

class _MockKhatmahRepository extends Mock implements KhatmahRepository {}

class _FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  late _MockKhatmahRepository repository;
  late RecordKhatmahReadingUsecase usecase;

  KhatmahPlan makePlan({
    KhatmahStatus status = KhatmahStatus.active,
    Iterable<int>? completedPages,
  }) {
    return KhatmahPlan(
      id: 'plan-1',
      title: 'Ramadan Khatmah',
      completedPages: completedPages ?? const <int>{},
      targetPagesPerDay: 4,
      targetDays: 151,
      startDate: DateTime(2026, 1, 1),
      expectedEndDate: DateTime(2026, 6, 1),
      status: status,
    );
  }

  setUpAll(() {
    registerFallbackValue(_FakeKhatmahPlan());
  });

  setUp(() {
    repository = _MockKhatmahRepository();
    usecase = RecordKhatmahReadingUsecase(repository);
    when(() => repository.updatePlan(any())).thenAnswer((_) async {});
  });

  test('digital reading records exactly the requested page', () async {
    final result = await usecase(
      makePlan(),
      100,
      source: KhatmahReadingSource.digital,
      readAt: DateTime(2026, 2, 1),
    );

    expect(result.plan.completedPages, {100});
    expect(result.newlyCompletedPages, {100});
    expect(result.historyEntry, isNull);
    verify(
      () => repository.updatePlan(
        any(
          that: isA<KhatmahPlan>()
              .having((plan) => plan.completedPages, 'completedPages', {100})
              .having(
                (plan) => plan.lastReadDate,
                'lastReadDate',
                DateTime(2026, 2, 1),
              ),
        ),
      ),
    ).called(1);
    verifyNever(() => repository.completePlan(any()));
  });

  test(
    'physical reading records the inclusive range from next unread page',
    () async {
      final result = await usecase(
        makePlan(completedPages: {1}),
        4,
        source: KhatmahReadingSource.physical,
      );

      expect(result.plan.completedPages, {1, 2, 3, 4});
      expect(result.newlyCompletedPages, {2, 3, 4});
    },
  );

  test('paused plans reject progress without persisting', () async {
    await expectLater(
      () => usecase(
        makePlan(status: KhatmahStatus.paused),
        1,
        source: KhatmahReadingSource.digital,
      ),
      throwsA(isA<KhatmahProgressException>()),
    );

    verifyNever(() => repository.updatePlan(any()));
  });

  test('rejects page numbers outside the Quran bounds', () async {
    await expectLater(
      () => usecase(makePlan(), 0, source: KhatmahReadingSource.digital),
      throwsA(isA<KhatmahProgressException>()),
    );
    await expectLater(
      () => usecase(makePlan(), 605, source: KhatmahReadingSource.digital),
      throwsA(isA<KhatmahProgressException>()),
    );
  });

  test('persists incomplete readings without completing the plan', () async {
    final result = await usecase(
      makePlan(),
      1,
      source: KhatmahReadingSource.digital,
    );

    expect(result.completed, isFalse);
    verify(() => repository.updatePlan(result.plan)).called(1);
    verifyNever(() => repository.completePlan(any()));
  });

  test(
    'returns the persisted history entry when final coverage completes',
    () async {
      final historyEntry = KhatmahHistoryEntry(
        id: 'plan-1',
        khatmahNumber: 1,
        title: 'Ramadan Khatmah',
        startDate: DateTime(2026, 1, 1),
        completedDate: DateTime(2026, 2, 1),
        totalDays: 32,
      );
      when(
        () => repository.completePlan(any()),
      ).thenAnswer((_) async => historyEntry);

      final result = await usecase(
        makePlan(completedPages: {for (var page = 1; page < 604; page++) page}),
        604,
        source: KhatmahReadingSource.digital,
      );

      expect(result.completed, isTrue);
      expect(result.historyEntry, historyEntry);
      expect(result.plan.status, KhatmahStatus.completed);
      verify(() => repository.completePlan(result.plan)).called(1);
    },
  );
}
