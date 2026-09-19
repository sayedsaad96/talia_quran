import 'dart:ui' show Locale;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/launch_destination.dart';
import '../../../core/services/notification_scheduler.dart';
import '../../../core/services/notification_service.dart';
import '../domain/entities/prayer_companion.dart';
import '../notifications/prayer_companion_notification_intent.dart';
import 'prayer_companion_usecases.dart';

/// The route Talia should navigate to after handling a notification response.
class PrayerCompanionResponseOutcome {
  const PrayerCompanionResponseOutcome({required this.route});

  final String route;
}

/// Bridges raw notification responses into Companion commands.
///
/// Companion actions are persisted ONLY while Talia is open (foreground
/// response or cold-start pending launch after DI is ready). There is no
/// hidden background handler: a killed-app action is written once during
/// startup, then the route is resolved.
class PrayerCompanionController {
  const PrayerCompanionController({
    required ApplyPrayerCompanionCommand applyCommand,
    required NotificationScheduler scheduler,
    required Locale Function() locale,
    Future<DateTime?> Function()? nextPrayerAt,
  }) : _applyCommand = applyCommand,
       _scheduler = scheduler,
       _locale = locale,
       _nextPrayerAt = nextPrayerAt;

  final ApplyPrayerCompanionCommand _applyCommand;
  final NotificationScheduler _scheduler;
  final Locale Function() _locale;
  final Future<DateTime?> Function()? _nextPrayerAt;

  static const _commandByActionId = <String, PrayerCompanionCommand>{
    'action_prayer_companion_confirm': PrayerCompanionCommand.confirm,
    'action_prayer_companion_pray_now': PrayerCompanionCommand.prayNow,
    'action_prayer_companion_remind_later': PrayerCompanionCommand.remindLater,
  };

  /// Only the three Companion action buttons mutate state. A null/empty or
  /// unknown action id is a body tap and never returns a command.
  static PrayerCompanionCommand? commandForActionId(String? actionId) {
    if (actionId == null || actionId.isEmpty) return null;
    return _commandByActionId[actionId];
  }

  /// Applies [command] from an in-app surface: persists FIRST, then
  /// force-refreshes local notifications so superseded check-in/follow-up
  /// events are cancelled and new follow-ups scheduled.
  Future<PrayerCompanionRecord> applyInApp(
    PrayerOccurrence occurrence,
    PrayerCompanionCommand command,
  ) async {
    final saved = await _applyCommand(
      occurrence: occurrence,
      command: command,
      now: DateTime.now(),
      nextPrayerAt: await _nextPrayerAt?.call(),
    );
    await _scheduler.refreshNotifications(
      lookupAppLocalizations(_locale()),
      force: true,
    );
    return saved;
  }

  /// Handles a raw notification response.
  ///
  /// A Companion action id plus a valid `pc1` payload persists the matching
  /// command and always resolves to Home. A body tap, an unknown action id,
  /// or an invalid/garbage payload mutates nothing and falls back to the
  /// legacy route resolution (which never treats `pc1` payloads as routes).
  Future<PrayerCompanionResponseOutcome> handle(
    NotificationResponseEvent event,
  ) async {
    final intent = PrayerCompanionNotificationIntent.tryParse(event.payload);
    final command = commandForActionId(event.actionId);
    if (intent == null || command == null) {
      return PrayerCompanionResponseOutcome(
        route: LaunchDestination.routeForResponse(event),
      );
    }
    await applyInApp(intent.occurrence, command);
    return const PrayerCompanionResponseOutcome(route: AppRoutes.home);
  }
}
