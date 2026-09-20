import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/router/launch_destination.dart';
import 'package:talia_quran/core/services/notification_service.dart';

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

    test(
      'opens Home with a one-time share request for the daily ayah action',
      () {
        final location = LaunchDestination.resolve(
          isFirstTime: false,
          actionId: 'action_share_daily_ayah',
        );

        expect(location, '${AppRoutes.home}?dailyAyahAction=share');
      },
    );

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
  group('LaunchDestination.routeForResponse', () {
    const pc1Payload = 'pc1|b3duZXItYQ|2026-09-16|asr|1789633200000|checkIn';

    test('never treats a pc1 payload as a go_router path', () {
      final route = LaunchDestination.routeForResponse(
        const NotificationResponseEvent(payload: pc1Payload),
      );

      expect(route, AppRoutes.home);
      expect(route, isNot(pc1Payload));
    });

    test('maps a legacy action id before the payload', () {
      final route = LaunchDestination.routeForResponse(
        const NotificationResponseEvent(
          payload: '/memorization',
          actionId: 'action_quran',
        ),
      );

      expect(route, AppRoutes.quran);
    });

    test('companion action ids stay unmapped (no double handling)', () {
      for (final actionId in const [
        'action_prayer_companion_confirm',
        'action_prayer_companion_pray_now',
        'action_prayer_companion_remind_later',
      ]) {
        final route = LaunchDestination.routeForResponse(
          NotificationResponseEvent(payload: pc1Payload, actionId: actionId),
        );

        expect(route, AppRoutes.home, reason: actionId);
        expect(route, isNot(pc1Payload), reason: actionId);
      }
    });

    test('uses the payload as a route when it starts with a slash', () {
      final route = LaunchDestination.routeForResponse(
        const NotificationResponseEvent(payload: '/azkar/morning'),
      );

      expect(route, '/azkar/morning');
    });

    test('keeps the scheduled ayah target precedence for daily ayah', () {
      final route = LaunchDestination.routeForResponse(
        const NotificationResponseEvent(
          payload: '/quran/page/28?dailyAyah=2-185',
          actionId: 'action_daily_ayah',
        ),
      );

      expect(route, '/quran/page/28?dailyAyah=2-185');
    });

    test('falls back to home when there is no target', () {
      final route = LaunchDestination.routeForResponse(
        const NotificationResponseEvent(),
      );

      expect(route, AppRoutes.home);
    });
  });
}
