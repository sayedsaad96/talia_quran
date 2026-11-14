import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/l10n/app_localizations_en.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';

class FakeNotifications extends Mock implements TaliaNotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(DateTime(2026)));
  final now = DateTime(2026, 11, 7, 12);
  InviteSession session({
    DateTime? start,
    DateTime? expires,
    InviteParticipationStatus status = InviteParticipationStatus.started,
  }) => InviteSession(
    token: 'secret',
    localSessionId: 'abcdefghijklmnopqrstuvwx',
    startedAt: start ?? now,
    serverStatus: status,
    snapshot: ResolvedInvite(
      token: 'secret',
      target: const QuranPageInviteTarget(1),
      moment: InviteMoment.beforeActivity,
      mode: InviteMode.personal,
      inviter: const InviterIdentity(mode: InviteIdentityMode.anonymous),
      status: InviteLifecycleStatus.active,
      expiresAt: expires ?? now.add(const Duration(hours: 4)),
    ),
  );
  DateTime? time(
    InviteSession value, {
    bool quiet = false,
    int from = 23,
    int to = 4,
  }) => inviteReminderTime(
    value,
    now: now,
    quietHours: quiet,
    quietStart: from,
    quietEnd: to,
  );
  test('uses later of one hour after start and two hours before expiry', () {
    expect(time(session()), now.add(const Duration(hours: 2)));
    expect(
      time(session(expires: now.add(const Duration(hours: 2)))),
      now.add(const Duration(hours: 1)),
    );
  });
  test('rejects completion and a quiet window beyond expiry', () {
    expect(
      time(session(status: InviteParticipationStatus.completedPrivate)),
      isNull,
    );
    expect(time(session(), quiet: true, from: 13, to: 17), isNull);
    expect(time(session(), quiet: true, from: 0, to: 0), isNull);
  });
  test('never schedules after fifteen-minute expiry margin', () {
    expect(
      time(session(expires: now.add(const Duration(minutes: 70)))),
      isNull,
    );
  });
  test('refresh after the due time does not reissue the reminder', () {
    final item = session(
      start: now.subtract(const Duration(hours: 5)),
      expires: now.add(const Duration(hours: 1)),
    );
    expect(time(item), isNull);
  });
  test(
    'permission or setting off prevents scheduling; payload is opaque',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = FakeNotifications();
      when(() => service.cancelInviteReminder()).thenAnswer((_) async {});
      when(
        () => service.areNotificationsGranted(),
      ).thenAnswer((_) async => false);
      final scheduler = NotificationScheduler(service);
      final item = session();
      await scheduler.scheduleInviteReminder(
        item,
        l10n: AppLocalizationsEn(),
        activityLabel: 'Page 1',
        available: true,
        adult: true,
        now: now,
      );
      verifyNever(
        () => service.scheduleInviteReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          at: any(named: 'at'),
          payload: any(named: 'payload'),
        ),
      );
      when(
        () => service.areNotificationsGranted(),
      ).thenAnswer((_) async => true);
      await prefs.setBool(
        TaliaNotificationService.inviteReminderPreferenceKey,
        false,
      );
      await scheduler.scheduleInviteReminder(
        item,
        l10n: AppLocalizationsEn(),
        activityLabel: 'Page 1',
        available: true,
        adult: true,
        now: now,
      );
      verifyNever(
        () => service.scheduleInviteReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          at: any(named: 'at'),
          payload: any(named: 'payload'),
        ),
      );
      await prefs.setBool(
        TaliaNotificationService.inviteReminderPreferenceKey,
        true,
      );
      when(
        () => service.scheduleInviteReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          at: any(named: 'at'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
      await scheduler.scheduleInviteReminder(
        item,
        l10n: AppLocalizationsEn(),
        activityLabel: 'Page 1',
        available: true,
        adult: true,
        now: now,
      );
      verify(
        () => service.scheduleInviteReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          at: any(named: 'at'),
          payload: 'sg1|abcdefghijklmnopqrstuvwx',
        ),
      ).called(1);
    },
  );
  test(
    'unavailable or child audience never reaches permission or schedule',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeNotifications();
      when(() => service.cancelInviteReminder()).thenAnswer((_) async {});
      final scheduler = NotificationScheduler(service);
      for (final gate in [(false, true), (true, false)]) {
        await scheduler.scheduleInviteReminder(
          session(),
          l10n: AppLocalizationsEn(),
          activityLabel: 'Page 1',
          available: gate.$1,
          adult: gate.$2,
          now: now,
        );
      }
      verifyNever(() => service.areNotificationsGranted());
      verifyNever(
        () => service.scheduleInviteReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          at: any(named: 'at'),
          payload: any(named: 'payload'),
        ),
      );
    },
  );
}
