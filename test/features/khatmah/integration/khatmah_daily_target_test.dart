import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_plan_model.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_schedule_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';

class _FailingSaveDatasource extends KhatmahLocalDatasource {
  _FailingSaveDatasource(super.prefs);
  bool rejectWrite = false;

  @override
  Future<void> savePlan(KhatmahPlanModel plan) async {
    if (rejectWrite) throw const KhatmahStorageException('Disk unavailable');
    await super.savePlan(plan);
  }
}

void main() {
  late KhatmahRepositoryImpl repository;
  late RecordKhatmahReadingUsecase record;
  late KhatmahPlan plan;
  late DateTime today;

  KhatmahCubit cubit() => KhatmahCubit(
    GetActiveKhatmahUsecase(repository),
    record,
    PauseResumeKhatmahUsecase(repository),
    DeleteKhatmahUsecase(repository),
    updateSchedule: UpdateKhatmahScheduleUsecase(repository),
    now: () => today,
  );

  setUp(() async {
    today = DateTime(2026, 9, 3, 12);
    SharedPreferences.setMockInitialValues({});
    repository = KhatmahRepositoryImpl(
      KhatmahLocalDatasource(await SharedPreferences.getInstance()),
    );
    record = RecordKhatmahReadingUsecase(repository);
    plan = KhatmahPlan(
      id: 'daily',
      title: 'Daily',
      targetPagesPerDay: 4,
      targetDays: 151,
      startDate: today,
      expectedEndDate: today,
    );
    await repository.createPlan(plan);
  });

  test(
    'partial reading persists original target through JSON and reload',
    () async {
      await record(
        plan,
        1,
        source: KhatmahReadingSource.digital,
        readAt: today,
      );
      final reloaded = (await repository.getActivePlan())!;
      final json = KhatmahPlanModel.fromEntity(reloaded).toJson();
      expect(json['dailyTargetStartPage'], 1);
      expect(json['dailyTargetEndPage'], 4);
      final restored = KhatmahPlanModel.fromJson(json).toEntity();
      expect(KhatmahPlanModel.fromEntity(restored).toJson(), json);
      final reader = cubit();
      addTearDown(reader.close);
      await reader.load();
      expect((reader.state as KhatmahActive).wirdStartPage, 1);
      expect((reader.state as KhatmahActive).wirdEndPage, 4);
    },
  );

  test(
    'full target reload, extra reading and schedule adjustment stay complete',
    () async {
      final reader = cubit();
      addTearDown(reader.close);
      await reader.load();
      expect(await reader.recordPhysicalThroughPage(4), isTrue);
      expect(reader.state, isA<KhatmahWirdCompleted>());
      await reader.load();
      expect(reader.state, isA<KhatmahWirdCompleted>());
      expect(await reader.recordDigitalPage(5), isTrue);
      expect(reader.state, isA<KhatmahWirdCompleted>());
      await reader.mildCompensation();
      expect(reader.state, isA<KhatmahWirdCompleted>());
      expect((await repository.getActivePlan())!.targetPagesPerDay, 5);
      await reader.pause();
      expect(reader.state, isA<KhatmahPaused>());
      await reader.resume();
      expect(reader.state, isA<KhatmahWirdCompleted>());
    },
  );

  test('sparse coverage cannot complete a daily target with holes', () async {
    final reader = cubit();
    addTearDown(reader.close);
    await reader.load();
    await reader.recordDigitalPage(4);
    expect(reader.state, isA<KhatmahActive>());
    expect((reader.state as KhatmahActive).wirdEndPage, 4);
    await reader.recordDigitalPage(1);
    await reader.load();
    expect((reader.state as KhatmahActive).wirdStartPage, 1);
    expect((reader.state as KhatmahActive).wirdEndPage, 4);
  });

  test(
    'new date derives target from next unread and duplicate keeps anchor',
    () async {
      final first = await record(
        plan,
        2,
        source: KhatmahReadingSource.physical,
        readAt: DateTime(2026, 9, 3, 23, 59),
      );
      final second = await record(
        first.plan,
        3,
        source: KhatmahReadingSource.digital,
        readAt: DateTime(2026, 9, 4, 0, 1),
      );
      final duplicate = await record(
        second.plan,
        3,
        source: KhatmahReadingSource.digital,
        readAt: DateTime(2026, 9, 4, 12),
      );
      final json = KhatmahPlanModel.fromEntity(duplicate.plan).toJson();
      expect(json['dailyTargetDate'], '2026-09-04T00:00:00.000');
      expect(json['dailyTargetStartPage'], 3);
      expect(json['dailyTargetEndPage'], 6);
      expect(duplicate.newlyCompletedPages, isEmpty);
    },
  );

  test(
    'history counts crossed local dates instead of full 24-hour intervals',
    () async {
      final completion = plan.copyWith(
        startDate: DateTime(2026, 4, 23, 23, 50),
        lastReadDate: DateTime(2026, 4, 24, 1, 10),
        completedPages: {for (var p = 1; p <= 604; p++) p},
      );
      final history = await repository.completePlan(completion);
      expect(history.totalDays, 2);
    },
  );

  test(
    'clock rollover reload creates next target only on the next date',
    () async {
      final reader = cubit();
      addTearDown(reader.close);
      await reader.load();
      await reader.recordPhysicalThroughPage(4);
      expect(reader.state, isA<KhatmahWirdCompleted>());
      today = DateTime(2026, 9, 4, 0, 1);
      await reader.load();
      expect((reader.state as KhatmahActive).wirdStartPage, 5);
      expect((reader.state as KhatmahActive).wirdEndPage, 8);
      await reader.recordDigitalPage(5);
      await reader.load();
      expect((reader.state as KhatmahActive).wirdStartPage, 5);
      expect((reader.state as KhatmahActive).wirdEndPage, 8);
    },
  );

  test('failed persistence publishes neither coverage nor an anchor', () async {
    final failing = _FailingSaveDatasource(
      await SharedPreferences.getInstance(),
    );
    repository = KhatmahRepositoryImpl(failing);
    record = RecordKhatmahReadingUsecase(repository);
    final reader = cubit();
    addTearDown(reader.close);
    await reader.load();
    failing.rejectWrite = true;
    expect(await reader.recordPhysicalThroughPage(4), isFalse);
    expect(reader.state, isA<KhatmahProgressFailure>());
    final persisted = (await repository.getActivePlan())!;
    expect(persisted.completedPages, isEmpty);
    expect(persisted.dailyTargetDate, isNull);
    await reader.load();
    expect((reader.state as KhatmahActive).wirdStartPage, 1);
    failing.rejectWrite = false;
    await reader.recordPhysicalThroughPage(4);
    expect(reader.state, isA<KhatmahWirdCompleted>());
  });

  test(
    'legacy same-day coverage cannot fabricate earlier daily activity',
    () async {
      final legacyJson =
          KhatmahPlanModel.fromEntity(
              plan.copyWith(completedPages: {1, 2, 3, 4}, lastReadDate: today),
            ).toJson()
            ..remove('dailyTargetDate')
            ..remove('dailyTargetStartPage')
            ..remove('dailyTargetEndPage');
      await repository.updatePlan(
        KhatmahPlanModel.fromJson(legacyJson).toEntity(),
      );
      final reader = cubit();
      addTearDown(reader.close);
      await reader.load();
      expect((reader.state as KhatmahActive).wirdStartPage, 5);
      expect((reader.state as KhatmahActive).wirdEndPage, 8);
    },
  );

  test('partial target survives a same-day schedule change', () async {
    final reader = cubit();
    addTearDown(reader.close);
    await reader.load();
    await reader.recordDigitalPage(1);
    await reader.mildCompensation(3);
    await reader.load();
    final state = reader.state as KhatmahActive;
    expect(state.plan.targetPagesPerDay, 7);
    expect(state.wirdStartPage, 1);
    expect(state.wirdEndPage, 4);
  });
}
