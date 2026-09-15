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
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

class MockTaliaNotificationService extends Mock
    implements TaliaNotificationService {}

class MockStreakReader extends Mock implements StreakReader {}

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
}
