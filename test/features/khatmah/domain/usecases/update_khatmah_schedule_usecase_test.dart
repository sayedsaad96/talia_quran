import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/repositories/khatmah_repository.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_schedule_usecase.dart';

class MockKhatmahRepository extends Mock implements KhatmahRepository {}

class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  late MockKhatmahRepository repository;
  late UpdateKhatmahScheduleUsecase usecase;

  final activePlan = KhatmahPlan(
    id: 'plan-1',
    title: 'Ramadan',
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 6, 1),
    completedPages: const {1, 100},
    status: KhatmahStatus.active,
  );

  setUpAll(() => registerFallbackValue(FakeKhatmahPlan()));

  setUp(() {
    repository = MockKhatmahRepository();
    usecase = UpdateKhatmahScheduleUsecase(repository);
  });

  test(
    'updates schedule metadata on the authoritative repository plan',
    () async {
      final newEnd = DateTime(2026, 4, 1);
      when(
        () => repository.getActivePlan(),
      ).thenAnswer((_) async => activePlan);
      when(() => repository.updatePlan(any())).thenAnswer((_) async {});

      final result = await usecase(
        planId: activePlan.id,
        targetPagesPerDay: 6,
        targetDays: 101,
        expectedEndDate: newEnd,
      );

      final persisted =
          verify(() => repository.updatePlan(captureAny())).captured.single
              as KhatmahPlan;
      expect(persisted.completedPages, const {1, 100});
      expect(persisted.status, KhatmahStatus.active);
      expect(persisted.targetPagesPerDay, 6);
      expect(persisted.expectedEndDate, newEnd);
      expect(result, persisted);
    },
  );

  test('rejects a schedule update for a mismatched plan id', () async {
    when(() => repository.getActivePlan()).thenAnswer((_) async => activePlan);

    await expectLater(
      usecase(
        planId: 'another-plan',
        targetPagesPerDay: 6,
        targetDays: 101,
        expectedEndDate: DateTime(2026, 4, 1),
      ),
      throwsA(isA<KhatmahProgressException>()),
    );
    verifyNever(() => repository.updatePlan(any()));
  });

  test('rejects a schedule update when no active plan exists', () async {
    when(() => repository.getActivePlan()).thenAnswer((_) async => null);

    await expectLater(
      usecase(
        planId: activePlan.id,
        targetPagesPerDay: 6,
        targetDays: 101,
        expectedEndDate: DateTime(2026, 4, 1),
      ),
      throwsA(isA<KhatmahProgressException>()),
    );
    verifyNever(() => repository.updatePlan(any()));
  });
}
