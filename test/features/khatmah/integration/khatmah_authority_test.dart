import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/create_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';

class _Owner implements RecordOwnerProvider {
  _Owner(this.currentOwnerId);
  @override
  String currentOwnerId;
  @override
  bool get isSignedIn => currentOwnerId != 'local';
}

void main() {
  late KhatmahRepositoryImpl repository;
  late RecordKhatmahReadingUsecase record;
  late PauseResumeKhatmahUsecase pauseResume;
  final date = DateTime(2026, 9, 4);
  final plan = KhatmahPlan(
    id: 'p',
    title: 'P',
    completedPages: {1},
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 9, 1),
    expectedEndDate: DateTime(2027, 1, 29),
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = KhatmahRepositoryImpl(
      KhatmahLocalDatasource(await SharedPreferences.getInstance()),
    );
    record = RecordKhatmahReadingUsecase(repository);
    pauseResume = PauseResumeKhatmahUsecase(repository);
    await repository.createPlan(plan);
  });
  test('two stale clients preserve disjoint durable page additions', () async {
    final a = (await repository.getActivePlan())!;
    final b = (await repository.getActivePlan())!;
    await record(a, 2, source: KhatmahReadingSource.digital, readAt: date);
    await record(b, 3, source: KhatmahReadingSource.digital, readAt: date);
    expect((await repository.getActivePlan())!.completedPages, {1, 2, 3});
  });
  test('retained client cannot reload or resume a later owner plan', () async {
    final cubit = KhatmahCubit(
      GetActiveKhatmahUsecase(repository),
      record,
      pauseResume,
      DeleteKhatmahUsecase(repository),
    );
    await cubit.load();
    final prefs = await SharedPreferences.getInstance();
    await AccountDataBarrier.forPreferences(prefs).clear(() async {
      await prefs.remove('khatmah_active_plan');
    });
    await repository.createPlan(
      plan.copyWith(id: 'q', status: KhatmahStatus.paused),
    );
    await cubit.load();
    expect(await cubit.resume(), isNull);
    expect(cubit.state, isA<KhatmahProgressFailure>());
    expect((cubit.state as KhatmahProgressFailure).plan, isNull);
    expect((await repository.getActivePlan())!.status, KhatmahStatus.paused);
    await cubit.close();
  });
  test(
    'retained setup form cannot create under a later account generation',
    () async {
      await repository.deletePlan(expectedPlanId: 'p');
      final setup = KhatmahSetupCubit(CreateKhatmahUsecase(repository));
      await AccountDataBarrier.forPreferences(
        await SharedPreferences.getInstance(),
      ).clear(() async {});
      await setup.createPlan(pagesPerDay: 4);
      expect(await repository.getActivePlan(), isNull);
      expect(setup.state, isA<KhatmahSetupError>());
      await setup.close();
    },
  );
  test('retained setup abandonment cannot delete a later generation', () async {
    final setup = KhatmahSetupCubit(
      CreateKhatmahUsecase(repository),
      deleteKhatmah: DeleteKhatmahUsecase(repository),
    );
    await setup.createPlan(pagesPerDay: 4);
    expect(setup.state, isA<KhatmahSetupConflict>());
    final prefs = await SharedPreferences.getInstance();
    await AccountDataBarrier.forPreferences(prefs).clear(() async {
      await prefs.remove('khatmah_active_plan');
    });
    await repository.createPlan(plan.copyWith(title: 'New owner'));
    await setup.abandonExistingPlan();
    expect((await repository.getActivePlan())?.title, 'New owner');
    await setup.close();
  });
  for (final preserve in [false, true]) {
    test(
      'cold guest preserve=$preserve never inherits account Khatmah',
      () async {
        SharedPreferences.setMockInitialValues({
          'auth_last_signed_in_user_id': 'a',
          if (preserve) 'khatmah_owner': 'a',
          if (preserve) 'khatmah_active_plan': 'private-a',
        });
        final prefs = await SharedPreferences.getInstance();
        final barrier = AccountDataBarrier.forPreferences(prefs)
          ..owner = _Owner('local');
        final guest = KhatmahRepositoryImpl(KhatmahLocalDatasource(prefs));
        if (preserve) {
          await expectLater(
            guest.getActivePlan(),
            throwsA(isA<KhatmahProgressException>()),
          );
          expect(barrier.isReady, isFalse);
          expect(prefs.getString('khatmah_active_plan'), 'private-a');
        } else {
          await guest.createPlan(plan.copyWith(id: 'guest'));
          expect((await guest.getActivePlan())!.id, 'guest');
          expect(barrier.isReady, isTrue);
        }
      },
    );
  }
  test(
    'failed reset remains gated and explicit retry recovers fresh clients',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final barrier = AccountDataBarrier.forPreferences(prefs);
      final old = (await repository.getActivePlan())!;
      await expectLater(
        barrier.clear(() async {
          throw StateError('failed');
        }),
        throwsStateError,
      );
      await expectLater(
        repository.getActivePlan(),
        throwsA(isA<KhatmahProgressException>()),
      );
      await barrier.clear(() async {
        await prefs.remove('khatmah_active_plan');
      });
      await repository.createPlan(plan.copyWith(id: 'recovered'));
      await expectLater(
        record(old, 2, source: KhatmahReadingSource.digital),
        throwsA(isA<KhatmahProgressException>()),
      );
      expect((await repository.getActivePlan())!.id, 'recovered');
    },
  );
  test('retained dashboard pause preserves reader progress', () async {
    final dashboard = (await repository.getActivePlan())!;
    await record(
      dashboard,
      2,
      source: KhatmahReadingSource.digital,
      readAt: date,
    );
    await pauseResume.pause(dashboard, date);
    final saved = (await repository.getActivePlan())!;
    expect(saved.completedPages, {1, 2});
    expect(saved.status, KhatmahStatus.paused);
  });
  test('stale active reader cannot record through a durable pause', () async {
    final reader = (await repository.getActivePlan())!;
    await pauseResume.pause(reader, date);
    await expectLater(
      record(reader, 2, source: KhatmahReadingSource.digital, readAt: date),
      throwsA(isA<KhatmahProgressException>()),
    );
    expect((await repository.getActivePlan())!.completedPages, {1});
  });
  test('stale completion cannot archive or replace a replacement', () async {
    await repository.deletePlan(expectedPlanId: 'p');
    await repository.createPlan(plan.copyWith(id: 'q'));
    await expectLater(
      repository.completePlan(
        plan.copyWith(completedPages: {for (var p = 1; p <= 604; p++) p}),
      ),
      throwsA(isA<KhatmahProgressException>()),
    );
    expect((await repository.getActivePlan())!.id, 'q');
    expect(await repository.getHistory(), isEmpty);
  });
  test(
    'persisted completion issues one linked certificate across replay',
    () async {
      final result = await record(
        plan,
        604,
        source: KhatmahReadingSource.physical,
        readAt: date,
      );
      expect(result.historyEntry!.certificateId, 'khatmah-p');
      final replay = await repository.completePlan(result.plan);
      expect(replay.certificateId, 'khatmah-p');
      expect(await repository.getCompletedCount(), 1);
    },
  );
  test(
    'old persisted completion loses certificate authority after reset',
    () async {
      final current = (await repository.getActivePlan())!;
      final result = await record(
        current,
        604,
        source: KhatmahReadingSource.physical,
        readAt: date,
      );
      expect(result.isValidCompletion, isTrue);
      final prefs = await SharedPreferences.getInstance();
      await AccountDataBarrier.forPreferences(prefs).clear(() async {
        await prefs.remove('khatmah_active_plan');
        await prefs.remove('khatmah_history');
      });
      expect(result.isValidCompletion, isFalse);
      await expectLater(
        repository.completePlan(result.plan),
        throwsA(isA<KhatmahProgressException>()),
      );
      expect(await repository.getHistory(), isEmpty);
    },
  );
}
