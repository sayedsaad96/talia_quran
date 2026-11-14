import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/share_good/application/good_impact_indicator_controller.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/domain/entities/good_impact.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/domain/repositories/share_good_repository.dart';
import 'package:talia_quran/features/share_good/domain/services/good_impact_milestone_policy.dart';
import 'package:talia_quran/features/share_good/presentation/cubits/good_impact_cubit.dart';

class FakeAuth extends Cubit<AuthState> implements AuthCubit {
  FakeAuth(super.initialState);
  void change(AuthState state) => emit(state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeOwner implements RecordOwnerProvider {
  String id = 'a';
  @override
  String get currentOwnerId => id;
  @override
  bool get isSignedIn => true;
}

class MockXpService extends Mock implements XpService {}

class MockAchievementService extends Mock implements AchievementService {}

class FakeRepository implements ShareGoodRepository {
  int calls = 0;
  Completer<Either<ShareGoodFailure, GoodImpact>>? pending;
  late GoodImpact value;
  @override
  Future<Either<ShareGoodFailure, GoodImpact>> impact() {
    calls++;
    return pending?.future ?? Future.value(Right(value));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoodImpact impact({int responses = 0, int reach = 0, bool named = false}) =>
      GoodImpact(
        invites: const [],
        responses: responses,
        completions: 0,
        downstreamReach: reach,
        acknowledgements: named
            ? [
                NamedAcknowledgement(
                  target: const QuranPageInviteTarget(1),
                  visibleName: 'Private Name',
                  completedAt: DateTime.utc(2026),
                ),
              ]
            : const [],
        fetchedAt: DateTime.utc(2026),
      );
  test('milestones follow aggregate thresholds', () {
    const policy = GoodImpactMilestonePolicy();
    expect(policy.derive(impact()), isEmpty);
    expect(
      policy.derive(impact(responses: 10, reach: 15)),
      GoodImpactMilestone.values.toSet(),
    );
    expect(policy.derive(impact(responses: 4, reach: 1)), {
      GoodImpactMilestone.firstChainStarted,
      GoodImpactMilestone.fiveReach,
    });
  });
  late GoodImpactCubit cubit;
  late FakeRepository repo;
  late FakeAuth auth;
  late FakeOwner owner;
  late ShareGoodLocalStore store;
  late SharedPreferences prefs;
  DateTime now = DateTime.utc(2026);
  var enabled = true;
  var child = false;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = FakeOwner();
    final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    auth = FakeAuth(
      const AuthAuthenticated(
        user: AppUser(id: 'a', email: '', displayName: 'A'),
      ),
    );
    repo = FakeRepository()..value = impact(named: true);
    store = ShareGoodLocalStore(const FlutterSecureStorage(), prefs);
    now = DateTime.utc(2026);
    enabled = true;
    child = false;
    cubit = GoodImpactCubit(
      repository: repo,
      store: store,
      auth: auth,
      barrier: barrier,
      isAvailable: () => enabled,
      isChild: () async => child,
      clock: () => now,
    );
  });
  tearDown(() async {
    await cubit.close();
    await auth.close();
  });
  test('refreshing reached milestones never invokes reward services', () async {
    final xp = MockXpService();
    final achievements = MockAchievementService();
    getIt.pushNewScope();
    addTearDown(getIt.popScope);
    getIt.registerSingleton<XpService>(xp);
    getIt.registerSingleton<AchievementService>(achievements);
    repo.value = impact(responses: 10, reach: 15);

    await cubit.refresh();

    expect(repo.calls, 1);
    expect(
      (cubit.state as GoodImpactReady).milestones,
      GoodImpactMilestone.values.toSet(),
    );
    verifyZeroInteractions(xp);
    verifyZeroInteractions(achievements);
  });
  test(
    'acknowledgement clears dot and stores only hash scoped to owner',
    () async {
      await cubit.refresh();
      expect((cubit.state as GoodImpactReady).hasNew, isTrue);
      await cubit.markSeen();
      expect((cubit.state as GoodImpactReady).hasNew, isFalse);
      expect(store.impactSeen('a'), matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(store.impactSeen('b'), isNull);
      expect(
        prefs.getString('${ShareGoodLocalStore.impactPrefix}a'),
        isNot(contains('Private Name')),
      );
    },
  );
  test(
    'resume throttles successful calls and gates disabled, guest and child',
    () async {
      final controller = GoodImpactIndicatorController(cubit);
      await controller.onResume();
      await controller.onResume();
      expect(repo.calls, 1);
      now = now.add(const Duration(hours: 6));
      await controller.onResume();
      expect(repo.calls, 2);
      enabled = false;
      await controller.onResume();
      expect(cubit.state, isA<GoodImpactIdle>());
      enabled = true;
      child = true;
      await controller.onResume();
      expect(repo.calls, 2);
    },
  );
  test(
    'account switch clears state and rejects old in-flight response',
    () async {
      repo.pending = Completer();
      final request = cubit.refresh();
      await Future<void>.delayed(Duration.zero);
      auth.change(const AuthUnauthenticated());
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<GoodImpactIdle>());
      repo.pending!.complete(Right(impact(named: true)));
      await request;
      expect(cubit.state, isA<GoodImpactIdle>());
      expect(store.impactSeen('a'), isNull);
    },
  );
}
