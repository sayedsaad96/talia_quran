import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/router/launch_destination.dart';
import 'package:talia_quran/core/services/notification_service.dart'
    show NotificationResponseEvent;

/// Every static payload literal emitted by the notification layer
/// (notification_service.dart, notification_scheduler.dart,
/// milestone_notification.dart, daily_ayah_notification_target.dart).
const _notificationPayloads = <String, String>{
  'dailyReview': '/memorization',
  'streakAlert': '/memorization',
  'streakGentleNudge': '/memorization',
  'smartReminder': '/memorization',
  'morningAzkar': '/azkar/morning',
  'eveningAzkar': '/azkar/evening',
  'dailyDua': '/azkar/duas',
  'kidsReview': '/memorization-plus/kids-journey',
  'fridayKahf': '/quran/surah/18',
  'weeklyImpact': '/progress',
  'tahajjud': '/azkar/duas',
  'khatmahWithoutPlan': '/khatmah/dashboard',
  'khatmahWithPlan': '/quran/page/1?mode=khatmah',
  'dailyAyah': '/quran/page/1?dailyAyah=2-255',
  'prayerTimes': '/',
  'milestoneCelebration': '/progress',
  'streakMercy': '/',
  'prayerSerenity': '/',
};

/// Exact registered locations (mirrors AppRouter's GoRoute table).
const _exactRoutes = <String>{
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.childOnboarding,
  AppRoutes.home,
  AppRoutes.quran,
  AppRoutes.quranDaily,
  AppRoutes.quranSearch,
  AppRoutes.quranBookmarks,
  AppRoutes.hifz,
  AppRoutes.hifzPracticeSurah,
  AppRoutes.memorizationHub,
  AppRoutes.azkar,
  AppRoutes.progress,
  AppRoutes.settings,
  AppRoutes.privacyPolicy,
  AppRoutes.memorizationPlus,
  AppRoutes.memorizationPlusGuardianLinking,
  AppRoutes.memorizationPlusKidsJourney,
  AppRoutes.memorizationPlusKids,
  AppRoutes.memorizationPlusKidsHome,
  AppRoutes.memorizationPlusKidsQuran,
  AppRoutes.memorizationPlusKidsStage,
  AppRoutes.memorizationPlusKidsCompletion,
  AppRoutes.familyDashboard,
  AppRoutes.childDetail,
  AppRoutes.memorizationPlusCustomPlan,
  AppRoutes.memorizationPlusDailyPlan,
  AppRoutes.memorizationV2Session,
  AppRoutes.login,
  AppRoutes.updatePassword,
  AppRoutes.updatePasswordAlias,
  AppRoutes.certificate,
  AppRoutes.tutorialGuide,
  AppRoutes.khatmahSetup,
  AppRoutes.khatmahDashboard,
  AppRoutes.khatmDua,
  AppRoutes.khatmahCompletion,
  AppRoutes.khatmahHistory,
};

/// True when [location] resolves to a route that actually exists in
/// [AppRouter] — exact match, or one of the parameterized routes
/// (/quran/surah/:id, /quran/page/:n, /azkar/:category).
bool isRegisteredRoute(String location) {
  final path = Uri.parse(location).path;
  if (_exactRoutes.contains(path)) return true;
  if (RegExp(r'^/quran/surah/\d+$').hasMatch(path)) return true;
  if (RegExp(r'^/quran/page/\d+$').hasMatch(path)) return true;
  if (RegExp(r'^/azkar/[a-z-]+$').hasMatch(path)) return true;
  return false;
}

void main() {
  group('notification payload → registered route guard', () {
    test('every static notification payload matches a registered route', () {
      final offenders = <String>[];
      _notificationPayloads.forEach((name, payload) {
        if (!isRegisteredRoute(payload)) offenders.add('$name → $payload');
      });
      expect(offenders, isEmpty,
          reason: 'Notification payloads must navigate somewhere real. '
              'Invalid: $offenders');
    });

    test('every notification action button maps to a registered route', () {
      final actionIds = <String>[
        'action_review',
        'action_streak',
        'action_quran',
        'action_daily_ayah',
        'action_share_daily_ayah',
        'action_morning_azkar',
        'action_evening_azkar',
        'action_daily_dua',
        'action_azkar',
        'action_kids_review',
        'action_read_kahf',
        'action_khatmah',
        'action_tahajjud',
      ];
      final offenders = <String>[];
      for (final actionId in actionIds) {
        final route = LaunchDestination.mapNotificationAction(actionId);
        if (route == null) {
          offenders.add('$actionId → null');
        } else if (!isRegisteredRoute(route)) {
          offenders.add('$actionId → $route');
        }
      }
      expect(offenders, isEmpty,
          reason: 'Action buttons must map to existing routes. '
              'Invalid: $offenders');
    });

    test('LaunchDestination.resolve never returns an unregistered route', () {
      final events = <({String? payload, String? actionId})>[
        (payload: null, actionId: null),
        (payload: '', actionId: ''),
        ..._notificationPayloads.entries.map(
          (entry) => (payload: entry.value, actionId: null as String?),
        ),
      ];
      final offenders = <String>[];
      for (final event in events) {
        final route = LaunchDestination.resolve(
          isFirstTime: false,
          payload: event.payload,
          actionId: event.actionId,
        );
        if (!isRegisteredRoute(route)) offenders.add('$event → $route');
      }
      expect(offenders, isEmpty, reason: 'Invalid resolutions: $offenders');
    });

    test('unknown/garbage payloads fall back to home instead of crashing', () {
      expect(
        LaunchDestination.resolve(
          isFirstTime: false,
          payload: 'pc1|garbage',
          actionId: null,
        ),
        AppRoutes.home,
      );
      expect(
        LaunchDestination.resolve(
          isFirstTime: false,
          payload: 'not-a-route',
          actionId: null,
        ),
        AppRoutes.home,
      );
    });

    test('companion payloads never become routes (no double handling)', () {
      // A companion `pc1` payload must fall through to home in the legacy
      // resolution path; the companion controller is the single writer.
      final route = LaunchDestination.routeForResponse(
        const NotificationResponseEvent(payload: 'pc1|owner|2026-09-25|fajr|1|checkIn'),
      );
      expect(route, AppRoutes.home);
    });
  });
}
