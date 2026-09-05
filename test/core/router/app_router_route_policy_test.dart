import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit() : super(const AuthInitial());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AppRouter route policy', () {
    test(
      'owner-data failure redirects any current screen to recovery login',
      () {
        expect(
          AppRouter.redirectForAuth(
            const AuthOwnerDataFailure(),
            AppRoutes.home,
          ),
          AppRoutes.login,
        );
        expect(
          AppRouter.redirectForAuth(
            const AuthOwnerDataFailure(),
            AppRoutes.khatmahDashboard,
          ),
          AppRoutes.login,
        );
        expect(
          AppRouter.redirectForAuth(
            const AuthOwnerDataFailure(),
            AppRoutes.login,
          ),
          isNull,
        );
      },
    );

    test('guest users can open local-first memorization routes', () {
      const localRoutes = [
        AppRoutes.memorizationHub,
        AppRoutes.memorizationPlus,
        AppRoutes.memorizationPlusCustomPlan,
        AppRoutes.memorizationPlusKidsHome,
        AppRoutes.memorizationPlusKidsJourney,
        AppRoutes.memorizationPlusKids,
        AppRoutes.memorizationPlusKidsStage,
        AppRoutes.memorizationPlusKidsCompletion,
        AppRoutes.memorizationPlusGuardianLinking,
      ];

      for (final route in localRoutes) {
        expect(
          AppRouter.requiresAuthentication(route),
          isFalse,
          reason: '$route should be guest-accessible',
        );
        expect(
          AppRouter.isPublicLocation(route),
          isTrue,
          reason: '$route should be public',
        );
      }
    });

    test('production router registers the manual-grade destination', () async {
      final getIt = GetIt.instance;
      final authCubit = _FakeAuthCubit();
      getIt.registerSingleton<AuthCubit>(authCubit);

      addTearDown(() async {
        AppRouter.router.dispose();
        await getIt.unregister<AuthCubit>();
        await authCubit.close();
      });

      final match = AppRouter.router.configuration.findMatch(
        Uri.parse(AppRoutes.memorizationHub),
      );

      expect(match.error, isNull);
      expect(match.uri.path, AppRoutes.memorizationHub);
    });

    test('remote parent dashboard remains protected', () {
      const protectedRoutes = [AppRoutes.familyDashboard];

      for (final route in protectedRoutes) {
        expect(
          AppRouter.requiresAuthentication(route),
          isTrue,
          reason: '$route should require auth',
        );
      }
    });
  });
}
