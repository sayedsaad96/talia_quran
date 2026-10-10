import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/plan_details_cubit.dart';
import '../../../../support/plan_details_fixture.dart';

void main() {
  late PlanDetailsFixtureHarness harness;
  late ProgressEventsBus events;
  late PlanDetailsCubit cubit;
  setUp(() {
    harness = PlanDetailsFixtureHarness();
    events = ProgressEventsBus();
    cubit = PlanDetailsCubit(harness.read, events);
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
    events.dispose();
  });

  test(
    'progress events reload once and closing cancels scheduled work',
    () async {
      var databaseReads = 0;
      when(() => harness.repository.getCustomPlan()).thenAnswer((_) async {
        databaseReads++;
        return Right(planDetailsFixture().plan);
      });
      await cubit.load();
      events.notify(ProgressChangedReason.reviewRecord);
      events.notify(ProgressChangedReason.dailyPlan);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(databaseReads, 2);
      events.notify(ProgressChangedReason.cloudPull);
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(databaseReads, 2);
    },
  );

  test('a slower old load cannot overwrite newer empty-plan state', () async {
    final older = Completer<Either<Failure, CustomMemorizationPlan?>>();
    var calls = 0;
    when(
      () => harness.repository.getCustomPlan(),
    ).thenAnswer((_) async => ++calls == 1 ? older.future : const Right(null));
    final first = cubit.load();
    await cubit.load();
    older.complete(Right(planDetailsFixture().plan));
    await first;
    expect(cubit.state, isA<PlanDetailsEmpty>());
  });

  test(
    'session start rechecks current plan and refuses a failed refresh',
    () async {
      await cubit.load();
      when(
        () => harness.repository.getCustomPlan(),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      expect(await cubit.sessionLocation(), isNull);
      expect(cubit.state, isA<PlanDetailsError>());
    },
  );
}
