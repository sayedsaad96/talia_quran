import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/core/services/streak_risk_evaluator.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

class MockTaliaNotificationService extends Mock
    implements TaliaNotificationService {}

class MockStreakReader extends Mock implements StreakReader {}
class MockStreakService extends Mock implements StreakService {}

void main() {
  late MockTaliaNotificationService mockNotificationService;
  late MockStreakReader mockStreakReader;

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({
      TaliaNotificationService.streakAlertPreferenceKey: true,
      TaliaNotificationService.dailyReviewPreferenceKey: false,
      TaliaNotificationService.morningAzkarPreferenceKey: false,
      TaliaNotificationService.eveningAzkarPreferenceKey: false,
      TaliaNotificationService.dailyDuaPreferenceKey: false,
      TaliaNotificationService.dailyAyahPreferenceKey: false,
      TaliaNotificationService.kidsReminderPreferenceKey: false,
    });

    mockNotificationService = MockTaliaNotificationService();
    mockStreakReader = MockStreakReader();

    when(() => mockNotificationService.configureLocalTimezone())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelStreakAlert())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelStreakGentleNudge())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelSmartReminder())
        .thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleStreakGentleNudge(
        title: any(named: 'title'),
        body: any(named: 'body'),
        currentStreak: any(named: 'currentStreak'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleSmartReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockNotificationService.cancelFridayKahfReminder())
        .thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleFridayKahfReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleWeeklyImpactReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockNotificationService.cancelWeeklyImpactReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelTahajjudReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelKhatmahReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelPrayerTimesReminders())
        .thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleStreakProtectionAlert(
        title: any(named: 'title'),
        body: any(named: 'body'),
        currentStreak: any(named: 'currentStreak'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockNotificationService.cancelDailyReviewReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelDailyAyahReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelMorningAzkarReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelEveningAzkarReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelDailyDuaReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelKidsReviewReminder())
        .thenAnswer((_) async {});

    getIt.registerSingleton<StreakReader>(mockStreakReader);
  });

  tearDown(() => getIt.reset());

  test(
    'cancels streak alert if user already has activity today',
    () async {
      final now = DateTime.now();
      final streakWithActivityToday = StreakEntity(
        currentStreak: 5,
        longestStreak: 10,
        lastActivityDate: now,
      );

      when(() => mockStreakReader.getStreak())
          .thenAnswer((_) async => streakWithActivityToday);

      final scheduler = NotificationScheduler(
        mockNotificationService,
        streakRiskEvaluator: StreakRiskEvaluator(now: () => now),
      );

      final l10n = lookupAppLocalizations(const Locale('ar'));
      await scheduler.refreshNotifications(l10n);

      verify(() => mockNotificationService.cancelStreakAlert()).called(1);
      verifyNever(
        () => mockNotificationService.scheduleStreakProtectionAlert(
          title: any(named: 'title'),
          body: any(named: 'body'),
          currentStreak: any(named: 'currentStreak'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
    },
  );

  test(
    'schedules streak alert if user has active streak but no activity today',
    () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final streakAtRisk = StreakEntity(
        currentStreak: 5,
        longestStreak: 10,
        lastActivityDate: yesterday,
      );

      when(() => mockStreakReader.getStreak())
          .thenAnswer((_) async => streakAtRisk);

      final scheduler = NotificationScheduler(
        mockNotificationService,
        streakRiskEvaluator: StreakRiskEvaluator(now: () => now),
      );

      final l10n = lookupAppLocalizations(const Locale('ar'));
      await scheduler.refreshNotifications(l10n);

      verify(
        () => mockNotificationService.scheduleStreakProtectionAlert(
          title: any(named: 'title'),
          body: any(named: 'body'),
          currentStreak: 5,
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      ).called(1);
    },
  );

  test(
    'cancels streak alert if streak is zero even if enabled',
    () async {
      final now = DateTime.now();
      const zeroStreak = StreakEntity(
        currentStreak: 0,
        longestStreak: 0,
        lastActivityDate: null,
      );

      when(() => mockStreakReader.getStreak())
          .thenAnswer((_) async => zeroStreak);

      final scheduler = NotificationScheduler(
        mockNotificationService,
        streakRiskEvaluator: StreakRiskEvaluator(now: () => now),
      );

      final l10n = lookupAppLocalizations(const Locale('ar'));
      await scheduler.refreshNotifications(l10n);

      verify(() => mockNotificationService.cancelStreakAlert()).called(1);
      verifyNever(
        () => mockNotificationService.scheduleStreakProtectionAlert(
          title: any(named: 'title'),
          body: any(named: 'body'),
          currentStreak: any(named: 'currentStreak'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
    },
  );

  test(
    'schedules weekly impact with the activity days count from the last 7 days',
    () async {
      final now = DateTime.now();
      final streakIdle = StreakEntity(
        currentStreak: 0,
        longestStreak: 3,
        lastActivityDate: now.subtract(const Duration(days: 9)),
      );
      when(() => mockStreakReader.getStreak())
          .thenAnswer((_) async => streakIdle);

      final mockStreakService = MockStreakService();
      when(() => mockStreakService.getActivityMap(days: 7)).thenAnswer(
        (_) async => {
          '2025-09-15': 2,
          '2025-09-16': 0,
          '2025-09-17': 1,
          '2025-09-18': 0,
          '2025-09-19': 3,
          '2025-09-20': 0,
          '2025-09-21': 0,
        },
      );
      getIt.registerSingleton<StreakService>(mockStreakService);

      final scheduler = NotificationScheduler(
        mockNotificationService,
        streakRiskEvaluator: StreakRiskEvaluator(now: () => now),
      );

      final l10n = lookupAppLocalizations(const Locale('ar'));
      await scheduler.refreshNotifications(l10n);

      final captured = verify(
        () => mockNotificationService.scheduleWeeklyImpactReminder(
          title: captureAny(named: 'title'),
          body: captureAny(named: 'body'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      ).captured;
      expect(captured[0], equals('أثرك هذا الأسبوع 🌿'));
      expect(captured[1], contains('3 أيام'));
    },
  );

  test(
    'schedules the quiet weekly impact body when the week had no activity',
    () async {
      final now = DateTime.now();
      const streakIdle = StreakEntity(
        currentStreak: 0,
        longestStreak: 0,
        lastActivityDate: null,
      );
      when(() => mockStreakReader.getStreak())
          .thenAnswer((_) async => streakIdle);

      final mockStreakService = MockStreakService();
      when(() => mockStreakService.getActivityMap(days: 7)).thenAnswer(
        (_) async => {
          '2025-09-15': 0,
          '2025-09-16': 0,
          '2025-09-17': 0,
          '2025-09-18': 0,
          '2025-09-19': 0,
          '2025-09-20': 0,
          '2025-09-21': 0,
        },
      );
      getIt.registerSingleton<StreakService>(mockStreakService);

      final scheduler = NotificationScheduler(
        mockNotificationService,
        streakRiskEvaluator: StreakRiskEvaluator(now: () => now),
      );

      final l10n = lookupAppLocalizations(const Locale('ar'));
      await scheduler.refreshNotifications(l10n);

      final captured = verify(
        () => mockNotificationService.scheduleWeeklyImpactReminder(
          title: captureAny(named: 'title'),
          body: captureAny(named: 'body'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      ).captured;
      expect(captured[1], equals('أسبوع جديد يبدأ — وصفحة واحدة بتفرق 🌱'));
      verifyNever(() => mockNotificationService.cancelWeeklyImpactReminder());
    },
  );

  test(
    'cancels the weekly impact notification when it is disabled',
    () async {
      // SharedPreferences caches its instance, so mutate the live mock
      // instead of re-seeding initial values.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        TaliaNotificationService.weeklyImpactPreferenceKey,
        false,
      );
      await prefs.setBool(
        TaliaNotificationService.streakAlertPreferenceKey,
        false,
      );
      final now = DateTime.now();
      final scheduler = NotificationScheduler(
        mockNotificationService,
        streakRiskEvaluator: StreakRiskEvaluator(now: () => now),
      );

      final l10n = lookupAppLocalizations(const Locale('ar'));
      await scheduler.refreshNotifications(l10n);

      verify(() => mockNotificationService.cancelWeeklyImpactReminder())
          .called(1);
      verifyNever(
        () => mockNotificationService.scheduleWeeklyImpactReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
    },
  );
}
