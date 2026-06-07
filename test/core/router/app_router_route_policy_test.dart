import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/router/app_router.dart';

void main() {
  group('AppRouter route policy', () {
    test('guest users can open local-first memorization routes', () {
      const localRoutes = [
        AppRoutes.memorizationPlus,
        AppRoutes.memorizationPlusDailyPlan,
        AppRoutes.memorizationPlusCustomPlan,
        AppRoutes.memorizationPlusQuiz,
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

    test('remote parent dashboard remains protected', () {
      const protectedRoutes = [AppRoutes.parentDashboard];

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
