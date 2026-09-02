import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_scheduling_engine.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/create_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart';

import '../../../../helpers/bloc_test_helper.dart';

class MockCreateKhatmahUsecase extends Mock implements CreateKhatmahUsecase {}

class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  late MockCreateKhatmahUsecase mockCreateKhatmah;

  setUpAll(() {
    registerFallbackValue(FakeKhatmahPlan());
  });

  setUp(() {
    mockCreateKhatmah = MockCreateKhatmahUsecase();
  });

  KhatmahSetupCubit buildCubit() => KhatmahSetupCubit(mockCreateKhatmah);

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
        verify(() => mockCreateKhatmah(any(
              that: isA<KhatmahPlan>()
                  .having((p) => p.targetPagesPerDay, 'targetPagesPerDay', 4)
                  .having((p) => p.targetDays, 'targetDays', 151)
                  .having((p) => p.title, 'title', 'Khatmah'),
            ))).called(1);
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
              .having((p) => p.targetDays, 'targetDays',
                  KhatmahSchedulingEngine.calculateDaysFromPages(604, 10))
              .having((p) => p.title, 'title', 'Grandmother')
              .having((p) => p.dedication.isDedicated, 'isDedicated', true)
              .having((p) => p.dedication.recipientName, 'recipientName',
                  'Grandmother'),
        ),
      ],
      verify: (_) {
        verify(() => mockCreateKhatmah(any(
              that: isA<KhatmahPlan>()
                  .having((p) => p.title, 'title', 'Grandmother')
                  .having((p) => p.targetPagesPerDay, 'targetPagesPerDay', 10),
            ))).called(1);
      },
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
        isA<KhatmahSetupDone>().having(
          (s) => s.plan.title,
          'title',
          'Khatmah',
        ),
      ],
    );

    blocTest<KhatmahSetupCubit, KhatmahSetupState>(
      'emits [KhatmahSetupSaving, KhatmahSetupError] when createPlan throws',
      build: () {
        when(() => mockCreateKhatmah(any()))
            .thenThrow(Exception('Database error'));
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
  });
}
