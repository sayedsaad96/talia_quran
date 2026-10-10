import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_tab_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/custom_plan_cubit.dart';
import '../../../../support/plan_details_fixture.dart';

void main() {
  late PlanDetailsFixtureHarness harness;
  late ProgressEventsBus events;
  late MemorizationPathResolver paths;
  late MemorizationTabCubit tab;
  setUp(() {
    harness = PlanDetailsFixtureHarness();
    events = ProgressEventsBus();
    paths = MemorizationPathResolver(harness.repository);
    when(() => harness.repository.getMemorizationProfile()).thenAnswer(
      (_) async => Right(
        MemorizationProfile.empty().copyWith(
          selectedPath: MemorizationPath.adult,
        ),
      ),
    );
    tab = MemorizationTabCubit(harness.repository, events, paths);
    registerFallbackValue(planDetailsFixture().plan);
  });
  tearDown(() async {
    await tab.close();
    await paths.dispose();
    events.dispose();
  });

  test(
    'adult saved plan opens directly, while absent or child plan keeps other options',
    () async {
      await tab.load();
      expect((tab.state as MemorizationTabLoaded).showPlan, isTrue);
      when(
        () => harness.repository.getCustomPlan(),
      ).thenAnswer((_) async => const Right(null));
      await tab.load();
      expect((tab.state as MemorizationTabLoaded).showPlan, isFalse);
      when(() => harness.repository.getCustomPlan()).thenAnswer(
        (_) async => Right(
          planDetailsFixture().plan.copyWith(targetUser: PlanTargetUser.child),
        ),
      );
      await tab.load();
      expect((tab.state as MemorizationTabLoaded).showPlan, isFalse);
    },
  );

  test('child path never opens an adult plan', () async {
    when(() => harness.repository.getMemorizationProfile()).thenAnswer(
      (_) async => Right(
        MemorizationProfile.empty().copyWith(
          selectedPath: MemorizationPath.child,
        ),
      ),
    );
    await tab.load();
    expect((tab.state as MemorizationTabLoaded).showPlan, isFalse);
    verifyNever(() => harness.repository.getCustomPlan());
  });

  test(
    'read failure shows an error rather than assuming there is no saved plan',
    () async {
      when(
        () => harness.repository.getCustomPlan(),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      await tab.load();
      expect(tab.state, isA<MemorizationTabError>());
    },
  );

  test(
    'retained tab refreshes after plan save, deletion and path change',
    () async {
      CustomMemorizationPlan? saved;
      when(
        () => harness.repository.getCustomPlan(),
      ).thenAnswer((_) async => Right(saved));
      when(() => harness.repository.saveCustomPlan(any())).thenAnswer((
        call,
      ) async {
        saved = call.positionalArguments.single as CustomMemorizationPlan;
        return const Right(null);
      });
      when(() => harness.repository.deleteCustomPlan()).thenAnswer((_) async {
        saved = null;
        return const Right(null);
      });
      final setup = CustomPlanCubit(harness.repository, events);
      await tab.load();
      expect((tab.state as MemorizationTabLoaded).showPlan, isFalse);
      await setup.savePlan(planDetailsFixture().plan);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect((tab.state as MemorizationTabLoaded).showPlan, isTrue);
      await setup.deletePlan();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect((tab.state as MemorizationTabLoaded).showPlan, isFalse);
      saved = planDetailsFixture().plan;
      paths.notifyChanged();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect((tab.state as MemorizationTabLoaded).showPlan, isTrue);
      await setup.close();
    },
  );

  test(
    'failed plan save does not tell the retained tab that a new plan exists',
    () async {
      when(
        () => harness.repository.saveCustomPlan(any()),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      var eventsSeen = 0;
      final subscription = events.changes.listen((reason) {
        if (reason == ProgressChangedReason.dailyPlan) eventsSeen++;
      });
      final setup = CustomPlanCubit(harness.repository, events);
      await setup.savePlan(planDetailsFixture().plan);
      await Future<void>.delayed(Duration.zero);
      expect(eventsSeen, 0);
      expect(setup.state, isA<CustomPlanError>());
      await subscription.cancel();
      await setup.close();
    },
  );
}
