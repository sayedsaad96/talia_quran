import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/router/launch_destination.dart';

void main() {
  group('LaunchDestination.resolve', () {
    test('sends first-time users to onboarding even with a notification', () {
      final location = LaunchDestination.resolve(
        isFirstTime: true,
        payload: '/memorization',
        actionId: 'action_quran',
      );

      expect(location, AppRoutes.onboarding);
    });

    test('maps cold-start action buttons instead of the body payload', () {
      final location = LaunchDestination.resolve(
        isFirstTime: false,
        payload: '/memorization',
        actionId: 'action_quran',
      );

      expect(location, AppRoutes.quran);
    });

    test('uses the notification body payload when no action is tapped', () {
      final location = LaunchDestination.resolve(
        isFirstTime: false,
        payload: '/azkar/morning',
      );

      expect(location, '/azkar/morning');
    });

    test('opens Home with a one-time share request for the daily ayah action', () {
      final location = LaunchDestination.resolve(
        isFirstTime: false,
        actionId: 'action_share_daily_ayah',
      );

      expect(location, '${AppRoutes.home}?dailyAyahAction=share');
    });

    test('keeps the scheduled ayah target when its read action is tapped', () {
      final location = LaunchDestination.resolve(
        isFirstTime: false,
        payload: '/quran/page/28?dailyAyah=2-185',
        actionId: 'action_daily_ayah',
      );

      expect(location, '/quran/page/28?dailyAyah=2-185');
    });

    test('falls back to home when there is no launch target', () {
      final location = LaunchDestination.resolve(isFirstTime: false);

      expect(location, AppRoutes.home);
    });
  });
}
