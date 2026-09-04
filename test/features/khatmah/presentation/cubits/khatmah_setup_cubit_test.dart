import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_scheduling_engine.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/create_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart';

import '../../../../helpers/bloc_test_helper.dart';

class MockCreateKhatmahUsecase extends Mock implements CreateKhatmahUsecase {}

class MockDeleteKhatmahUsecase extends Mock implements DeleteKhatmahUsecase {}

class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  late MockCreateKhatmahUsecase mockCreateKhatmah;
  late MockDeleteKhatmahUsecase mockDeleteKhatmah;

  setUpAll(() {
    registerFallbackValue(FakeKhatmahPlan());
  });

  setUp(() {
    mockCreateKhatmah = MockCreateKhatmahUsecase();
    mockDeleteKhatmah = MockDeleteKhatmahUsecase();
  });

  KhatmahSetupCubit buildCubit() =>
      KhatmahSetupCubit(mockCreateKhatmah, deleteKhatmah: mockDeleteKhatmah);

  test(
    'pending setup save settles safely after owned cubit disposal',
    () async {
      final save = Completer<void>();
      when(() => mockCreateKhatmah(any())).thenAnswer((_) => save.future);
      final cubit = buildCubit();
      final pending = cubit.createPlan(pagesPerDay: 4);
      await cubit.close();
      save.complete();
      await expectLater(pending, completes);
      expect(cubit.state, isA<KhatmahSetupSaving>());
    },
  );

  group('KhatmahSetupCubit Initial State', () {
    test('initial state is KhatmahSetupIdle', () {
      final cubit = buildCubit();
      expect(cubit.state, equals(const KhatmahSetupIdle()));
      cubit.close();
    });
  });

  group('createPlan()', () {
    blocTest<KhatmahSetupCubit, KhatmahSetupState>(
      'creates default plan and emits [KhatmahSetupSaving, KhatmahSetupDone]',
      build: () {
        when(() => mockCreateKhatmah(any())).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.createPlan(pagesPerDay: 4),
      expect: () => [
        const KhatmahSetupSaving(),
        isA<KhatmahSetupDone>().having(
          (s) => s.plan,
          'plan',
          isA<KhatmahPlan>()
              .having((p) => p.targetPagesPerDay, 'targetPagesPerDay', 4)
              .having((p) => p.targetDays, 'targetDays', 151)
              .having((p) => p.title, 'title', 'Khatmah')
              .having((p) => p.dedication.isDedicated, 'isDedicated', false)
              .having((p) => p.currentPage, 'currentPage', 0)
              .having((p) => p.startPage, 'startPage', 1)
              .having((p) => p.status, 'status', KhatmahStatus.active),
        ),
      ],
      verify: (_) {
        verify(
          () => mockCreateKhatmah(
            any(
              that: isA<KhatmahPlan>()
                  .having((p) => p.targetPagesPerDay, 'targetPagesPerDay', 4)
                  .having((p) => p.targetDays, 'targetDays', 151)
                  .having((p) => p.title, 'title', 'Khatmah'),
            ),
          ),
        ).called(1);
      },
    );

    blocTest<KhatmahSetupCubit, KhatmahSetupState>(
      'creates plan with dedication and sets recipient name as title',
      build: () {
        when(() => mockCreateKhatmah(any())).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.createPlan(
        pagesPerDay: 10,
        dedication: const KhatmahDedication(
          isDedicated: true,
          recipientName: 'Grandmother',
          relationship: 'Grandmother',
          condition: DedicationCondition.deceased,
        ),
      ),
      expect: () => [
        const KhatmahSetupSaving(),
        isA<KhatmahSetupDone>().having(
          (s) => s.plan,
          'plan',
          isA<KhatmahPlan>()
              .having((p) => p.targetPagesPerDay, 'targetPagesPerDay', 10)
              .having(
                (p) => p.targetDays,
                'targetDays',
                KhatmahSchedulingEngine.calculateDaysFromPages(604, 10),
              )
              .having((p) => p.title, 'title', 'Grandmother')
              .having((p) => p.dedication.isDedicated, 'isDedicated', true)
              .having(
                (p) => p.dedication.recipientName,
                'recipientName',
                'Grandmother',
              ),
        ),
      ],
      verify: (_) {
        verify(
          () => mockCreateKhatmah(
            any(
              that: isA<KhatmahPlan>()
                  .having((p) => p.title, 'title', 'Grandmother')
                  .having((p) => p.targetPagesPerDay, 'targetPagesPerDay', 10),
            ),
          ),
        ).called(1);
      },
    );

    blocTest<KhatmahSetupCubit, KhatmahSetupState>(
      'preserves living dedication data when creating a plan',
      build: () {
        when(() => mockCreateKhatmah(any())).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.createPlan(
        pagesPerDay: 10,
        dedication: const KhatmahDedication(
          isDedicated: true,
          recipientName: 'Father',
          relationship: 'Father',
          condition: DedicationCondition.alive,
        ),
      ),
      expect: () => [
        const KhatmahSetupSaving(),
        isA<KhatmahSetupDone>().having(
          (state) => state.plan.dedication.condition,
          'dedication condition',
          DedicationCondition.alive,
        ),
      ],
    );

    blocTest<KhatmahSetupCubit, KhatmahSetupState>(
      'defaults title to Khatmah when dedication is dedicated but recipientName is null or empty',
      build: () {
        when(() => mockCreateKhatmah(any())).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.createPlan(
        pagesPerDay: 20,
        dedication: const KhatmahDedication(
          isDedicated: true,
          recipientName: '',
        ),
      ),
      expect: () => [
        const KhatmahSetupSaving(),
        isA<KhatmahSetupDone>().having((s) => s.plan.title, 'title', 'Khatmah'),
      ],
    );

    blocTest<KhatmahSetupCubit, KhatmahSetupState>(
      'emits [KhatmahSetupSaving, KhatmahSetupError] when createPlan throws',
      build: () {
        when(
          () => mockCreateKhatmah(any()),
        ).thenThrow(Exception('Database error'));
        return buildCubit();
      },
      act: (cubit) => cubit.createPlan(pagesPerDay: 4),
      expect: () => [
        const KhatmahSetupSaving(),
        isA<KhatmahSetupError>().having(
          (s) => s.message,
          'message',
          contains('Database error'),
        ),
      ],
      verify: (_) {
        verify(() => mockCreateKhatmah(any())).called(1);
      },
    );

    blocTest<KhatmahSetupCubit, KhatmahSetupState>(
      'emits conflict with the existing paused plan instead of a generic error',
      build: () {
        final existingPlan = KhatmahPlan(
          id: 'paused-plan',
          title: 'Paused Khatmah',
          targetPagesPerDay: 4,
          targetDays: 151,
          startDate: DateTime(2026, 1, 1),
          expectedEndDate: DateTime(2026, 6, 1),
          status: KhatmahStatus.paused,
        );
        when(
          () => mockCreateKhatmah(any()),
        ).thenThrow(KhatmahPlanAlreadyExistsException(existingPlan));
        return buildCubit();
      },
      act: (cubit) => cubit.createPlan(pagesPerDay: 4),
      expect: () => [
        const KhatmahSetupSaving(),
        isA<KhatmahSetupConflict>()
            .having((state) => state.existingPlan.id, 'plan id', 'paused-plan')
            .having(
              (state) => state.existingPlan.status,
              'plan status',
              KhatmahStatus.paused,
            ),
      ],
    );

    blocTest<KhatmahSetupCubit, KhatmahSetupState>(
      'abandons a conflicted plan only after an explicit request, then returns to idle',
      build: () {
        final existingPlan = KhatmahPlan(
          id: 'active-plan',
          title: 'Existing Khatmah',
          targetPagesPerDay: 4,
          targetDays: 151,
          startDate: DateTime(2026, 1, 1),
          expectedEndDate: DateTime(2026, 6, 1),
        );
        when(
          () => mockCreateKhatmah(any()),
        ).thenThrow(KhatmahPlanAlreadyExistsException(existingPlan));
        when(
          () => mockDeleteKhatmah(expectedPlanId: 'active-plan'),
        ).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.createPlan(pagesPerDay: 4);
        await cubit.abandonExistingPlan();
      },
      expect: () => [
        const KhatmahSetupSaving(),
        isA<KhatmahSetupConflict>(),
        isA<KhatmahSetupConflict>().having(
          (state) => state.isAbandoning,
          'is abandoning',
          isTrue,
        ),
        const KhatmahSetupIdle(),
      ],
      verify: (_) => verify(
        () => mockDeleteKhatmah(expectedPlanId: 'active-plan'),
      ).called(1),
    );

    test(
      'deduplicates abandonment and preserves conflict when deletion fails',
      () async {
        final existingPlan = KhatmahPlan(
          id: 'conflicted-plan',
          title: 'Existing Khatmah',
          targetPagesPerDay: 4,
          targetDays: 151,
          startDate: DateTime(2026, 1, 1),
          expectedEndDate: DateTime(2026, 6, 1),
        );
        when(
          () => mockCreateKhatmah(any()),
        ).thenThrow(KhatmahPlanAlreadyExistsException(existingPlan));
        when(
          () => mockDeleteKhatmah(expectedPlanId: existingPlan.id),
        ).thenThrow(Exception('delete failed'));
        final cubit = buildCubit();
        await cubit.createPlan(pagesPerDay: 4);

        final first = cubit.abandonExistingPlan();
        final second = cubit.abandonExistingPlan();
        expect(identical(first, second), isTrue);
        await first;

        expect(cubit.state, isA<KhatmahSetupConflict>());
        final conflict = cubit.state as KhatmahSetupConflict;
        expect(conflict.existingPlan, existingPlan);
        expect(conflict.errorMessage, contains('delete failed'));
        verify(
          () => mockDeleteKhatmah(expectedPlanId: existingPlan.id),
        ).called(1);
        when(
          () => mockDeleteKhatmah(expectedPlanId: existingPlan.id),
        ).thenAnswer((_) async {});
        await cubit.abandonExistingPlan();
        expect(cubit.state, isA<KhatmahSetupIdle>());
        await cubit.close();
      },
    );
  });
}
