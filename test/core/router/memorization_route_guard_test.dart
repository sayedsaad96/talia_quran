import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';

/// Minimal repository fake that only answers [getMemorizationProfile]; every
/// other member is unused by the guards under test.
class _FakeMemoRepo implements MemorizationPlusRepository {
  _FakeMemoRepo(this._profile);

  final MemorizationProfile? _profile;

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async {
    final profile = _profile;
    if (profile == null) return const Left(CacheFailure('no profile'));
    return Right(profile);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lightweight [AuthCubit] stand-in that simply exposes a fixed state.
class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MemorizationProfile _profile(MemorizationPath path) => MemorizationProfile(
  schemaVersion: 1,
  selectedPath: path,
  guardianLinkStatus: GuardianLinkStatus.none,
  guardianOnboardingStatus: GuardianOnboardingStatus.completed,
  isParentGuardian: false,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

void main() {
  final getIt = GetIt.instance;

  void registerProfile(MemorizationProfile? profile) {
    if (getIt.isRegistered<MemorizationPlusRepository>()) {
      getIt.unregister<MemorizationPlusRepository>();
    }
    getIt.registerSingleton<MemorizationPlusRepository>(_FakeMemoRepo(profile));
  }

  void registerAuth(AuthState state) {
    if (getIt.isRegistered<AuthCubit>()) {
      getIt.unregister<AuthCubit>();
    }
    getIt.registerSingleton<AuthCubit>(_FakeAuthCubit(state));
  }

  tearDown(() async {
    await getIt.reset();
  });

  group('adultOnlyRedirect', () {
    test('redirects child profiles to the kids home', () async {
      registerProfile(_profile(MemorizationPath.child));
      expect(
        await MemorizationRouteGuard.adultOnlyRedirect(),
        AppRoutes.memorizationPlusKidsHome,
      );
    });

    test('allows adult profiles', () async {
      registerProfile(_profile(MemorizationPath.adult));
      expect(await MemorizationRouteGuard.adultOnlyRedirect(), isNull);
    });

    test('allows guests with no profile', () async {
      registerProfile(null);
      expect(await MemorizationRouteGuard.adultOnlyRedirect(), isNull);
    });
  });

  group('kidsOnlyRedirect', () {
    test('redirects adult profiles to the memorization hub', () async {
      registerProfile(_profile(MemorizationPath.adult));
      expect(
        await MemorizationRouteGuard.kidsOnlyRedirect(),
        AppRoutes.memorizationPlus,
      );
    });

    test('allows child profiles', () async {
      registerProfile(_profile(MemorizationPath.child));
      expect(await MemorizationRouteGuard.kidsOnlyRedirect(), isNull);
    });

    test('allows guests with no profile', () async {
      registerProfile(null);
      expect(await MemorizationRouteGuard.kidsOnlyRedirect(), isNull);
    });
  });

  group('parentDashboardRedirect', () {
    test('redirects anonymous users to login', () async {
      registerProfile(_profile(MemorizationPath.adult));
      registerAuth(const AuthUnauthenticated());
      expect(
        await MemorizationRouteGuard.parentDashboardRedirect(),
        AppRoutes.login,
      );
    });

    test('redirects authenticated child profiles to the kids home', () async {
      registerProfile(_profile(MemorizationPath.child));
      registerAuth(const AuthInitial());
      expect(
        await MemorizationRouteGuard.parentDashboardRedirect(),
        AppRoutes.memorizationPlusKidsHome,
      );
    });

    test('allows authenticated adult profiles', () async {
      registerProfile(_profile(MemorizationPath.adult));
      registerAuth(const AuthInitial());
      expect(await MemorizationRouteGuard.parentDashboardRedirect(), isNull);
    });
  });
}
