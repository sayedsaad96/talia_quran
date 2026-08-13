import 'app_router.dart';

/// Cold-start notification tap captured before the full router is ready.
class NotificationLaunchRequest {
  const NotificationLaunchRequest({this.payload, this.actionId});

  final String? payload;
  final String? actionId;
}

/// Resolves the first destination after the splash/init handoff.
///
/// First-time users always go to onboarding, even if a notification launched
/// the app. Returning users honor notification action buttons before the
/// notification body payload.
abstract final class LaunchDestination {
  static const firstTimePreferenceKey = 'isFirstTimeAppOpen';

  static String resolve({
    required bool isFirstTime,
    String? payload,
    String? actionId,
  }) {
    if (isFirstTime) return AppRoutes.onboarding;

    final mappedAction = mapNotificationAction(actionId);
    if (mappedAction != null) return mappedAction;

    if (payload != null && payload.startsWith('/')) return payload;
    return AppRoutes.home;
  }

  static String? mapNotificationAction(String? actionId) {
    if (actionId == null || actionId.isEmpty) return null;
    return switch (actionId) {
      'action_review' => AppRoutes.memorizationHub,
      'action_streak' => AppRoutes.memorizationHub,
      'action_quran' => AppRoutes.quran,
      'action_daily_ayah' => AppRoutes.quranDaily,
      'action_morning_azkar' => '/azkar/morning',
      'action_evening_azkar' => '/azkar/evening',
      'action_daily_dua' => '/azkar/duas',
      'action_azkar' => AppRoutes.azkar,
      'action_kids_review' => AppRoutes.memorizationPlusKidsJourney,
      _ => null,
    };
  }
}
