import '../services/notification_service.dart' show NotificationResponseEvent;
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

    // The scheduled daily-ayah payload identifies an exact page. It must win
    // over the generic legacy action route so the notification opens the ayah
    // that was selected for that day.
    if (actionId == 'action_daily_ayah' &&
        payload != null &&
        payload.startsWith('/')) {
      return payload;
    }

    final mappedAction = mapNotificationAction(actionId);
    if (mappedAction != null) return mappedAction;

    if (payload != null && payload.startsWith('/')) return payload;
    return AppRoutes.home;
  }

  /// Resolves the go_router location for a raw notification response
  /// (foreground tap or cold-start pending launch).
  ///
  /// Retains the legacy precedence of [resolve] (scheduled daily-ayah target,
  /// then action-id mapping, then payload-as-route). Companion (`pc1`)
  /// payloads never start with '/', so they can never be mistaken for a
  /// route and fall through to [AppRoutes.home]; Companion action ids are
  /// deliberately absent from [mapNotificationAction] so the companion
  /// controller stays the single writer for those responses.
  static String routeForResponse(NotificationResponseEvent event) {
    return resolve(
      isFirstTime: false,
      payload: event.payload,
      actionId: event.actionId,
    );
  }

  static String? mapNotificationAction(String? actionId) {
    if (actionId == null || actionId.isEmpty) return null;
    return switch (actionId) {
      'action_review' => AppRoutes.memorizationHub,
      'action_streak' => AppRoutes.memorizationHub,
      'action_quran' => AppRoutes.quran,
      'action_daily_ayah' => AppRoutes.quranDaily,
      'action_share_daily_ayah' => '${AppRoutes.home}?dailyAyahAction=share',
      'action_morning_azkar' => '/azkar/morning',
      'action_evening_azkar' => '/azkar/evening',
      'action_daily_dua' => '/azkar/duas',
      'action_azkar' => AppRoutes.azkar,
      'action_kids_review' => AppRoutes.memorizationPlusKidsJourney,
      'action_read_kahf' => '/quran/surah/18',
      'action_khatmah' => AppRoutes.khatmahDashboard,
      'action_tahajjud' => '/azkar/duas',
      _ => null,
    };
  }
}
