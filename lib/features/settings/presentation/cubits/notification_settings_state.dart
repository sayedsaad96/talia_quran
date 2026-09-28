import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum NotificationSettingsFeedback { saveFailed, schedulingFailed }

class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.isLoading = false,
    this.hasSystemPermission = true,
    this.dailyReview = true,
    this.streakAlert = true,
    this.dailyAyah = true,
    this.morningAzkar = true,
    this.eveningAzkar = true,
    this.dailyDua = true,
    this.kidsReminder = false,
    this.fridayKahf = true,
    this.weeklyImpact = true,
    this.tahajjud = false,
    this.khatmahReminder = true,
    this.prayerNotifications = false,
    this.prayerAthan = false,
    this.prayerFajr = true,
    this.prayerDhuhr = true,
    this.prayerAsr = true,
    this.prayerMaghrib = true,
    this.prayerIsha = true,
    this.muezzinId = 'default',
    this.fajrMuezzinId = '',
    this.quietHoursEnabled = false,
    this.quietHoursStart = 23,
    this.quietHoursEnd = 4,
    this.smartReminder = false,
    this.dailyReviewTime = const TimeOfDay(hour: 20, minute: 0),
    this.streakAlertTime = const TimeOfDay(hour: 22, minute: 0),
    this.dailyAyahTime = const TimeOfDay(hour: 7, minute: 0),
    this.morningAzkarTime = const TimeOfDay(hour: 6, minute: 0),
    this.eveningAzkarTime = const TimeOfDay(hour: 18, minute: 0),
    this.dailyDuaTime = const TimeOfDay(hour: 9, minute: 0),
    this.kidsReminderTime = const TimeOfDay(hour: 18, minute: 30),
    this.fridayKahfTime = const TimeOfDay(hour: 9, minute: 0),
    this.weeklyImpactTime = const TimeOfDay(hour: 16, minute: 0),
    this.tahajjudTime = const TimeOfDay(hour: 3, minute: 30),
    this.khatmahReminderTime = const TimeOfDay(hour: 17, minute: 0),
    this.feedback,
    this.feedbackRevision = 0,
  });

  final bool isLoading;
  final bool hasSystemPermission;

  // 10 Notification Categories
  final bool dailyReview;
  final bool streakAlert;
  final bool dailyAyah;
  final bool morningAzkar;
  final bool eveningAzkar;
  final bool dailyDua;
  final bool kidsReminder;
  final bool fridayKahf;
  final bool weeklyImpact;
  final bool tahajjud;
  final bool khatmahReminder;

  // Prayer Times and individual prayer filters
  final bool prayerNotifications;
  final bool prayerAthan;
  final bool prayerFajr;
  final bool prayerDhuhr;
  final bool prayerAsr;
  final bool prayerMaghrib;
  final bool prayerIsha;
  final String muezzinId;
  final String fajrMuezzinId;

  final bool quietHoursEnabled;
  final int quietHoursStart;
  final int quietHoursEnd;
  final bool smartReminder;

  // Time schedules
  final TimeOfDay dailyReviewTime;
  final TimeOfDay streakAlertTime;
  final TimeOfDay dailyAyahTime;
  final TimeOfDay morningAzkarTime;
  final TimeOfDay eveningAzkarTime;
  final TimeOfDay dailyDuaTime;
  final TimeOfDay kidsReminderTime;
  final TimeOfDay fridayKahfTime;
  final TimeOfDay weeklyImpactTime;
  final TimeOfDay tahajjudTime;
  final TimeOfDay khatmahReminderTime;
  final NotificationSettingsFeedback? feedback;
  final int feedbackRevision;

  /// Counts the active reminders among the 10 main categories.
  int get enabledCount {
    var count = 0;
    if (dailyReview) count++;
    if (streakAlert) count++;
    if (dailyAyah) count++;
    if (morningAzkar) count++;
    if (eveningAzkar) count++;
    if (dailyDua) count++;
    if (kidsReminder) count++;
    if (fridayKahf) count++;
    if (weeklyImpact) count++;
    if (tahajjud) count++;
    if (khatmahReminder) count++;
    return count;
  }

  /// Total number of customizable notification categories.
  int get totalCount => 11;

  /// Returns true if system-level notifications are blocked by the OS.
  bool get isSystemPermissionBlocked => !hasSystemPermission;

  NotificationSettingsState copyWith({
    bool? isLoading,
    bool? hasSystemPermission,
    bool? dailyReview,
    bool? streakAlert,
    bool? dailyAyah,
    bool? morningAzkar,
    bool? eveningAzkar,
    bool? dailyDua,
    bool? kidsReminder,
    bool? fridayKahf,
    bool? weeklyImpact,
    bool? tahajjud,
    bool? khatmahReminder,
    bool? prayerNotifications,
    bool? prayerAthan,
    bool? prayerFajr,
    bool? prayerDhuhr,
    bool? prayerAsr,
    bool? prayerMaghrib,
    bool? prayerIsha,
    String? muezzinId,
    String? fajrMuezzinId,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool? smartReminder,
    TimeOfDay? dailyReviewTime,
    TimeOfDay? streakAlertTime,
    TimeOfDay? dailyAyahTime,
    TimeOfDay? morningAzkarTime,
    TimeOfDay? eveningAzkarTime,
    TimeOfDay? dailyDuaTime,
    TimeOfDay? kidsReminderTime,
    TimeOfDay? fridayKahfTime,
    TimeOfDay? tahajjudTime,
    TimeOfDay? weeklyImpactTime,
    TimeOfDay? khatmahReminderTime,
    NotificationSettingsFeedback? feedback,
    int? feedbackRevision,
  }) {
    return NotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      hasSystemPermission: hasSystemPermission ?? this.hasSystemPermission,
      dailyReview: dailyReview ?? this.dailyReview,
      streakAlert: streakAlert ?? this.streakAlert,
      dailyAyah: dailyAyah ?? this.dailyAyah,
      morningAzkar: morningAzkar ?? this.morningAzkar,
      eveningAzkar: eveningAzkar ?? this.eveningAzkar,
      dailyDua: dailyDua ?? this.dailyDua,
      kidsReminder: kidsReminder ?? this.kidsReminder,
      fridayKahf: fridayKahf ?? this.fridayKahf,
      weeklyImpact: weeklyImpact ?? this.weeklyImpact,
      tahajjud: tahajjud ?? this.tahajjud,
      khatmahReminder: khatmahReminder ?? this.khatmahReminder,
      prayerNotifications: prayerNotifications ?? this.prayerNotifications,
      prayerAthan: prayerAthan ?? this.prayerAthan,
      prayerFajr: prayerFajr ?? this.prayerFajr,
      prayerDhuhr: prayerDhuhr ?? this.prayerDhuhr,
      prayerAsr: prayerAsr ?? this.prayerAsr,
      prayerMaghrib: prayerMaghrib ?? this.prayerMaghrib,
      prayerIsha: prayerIsha ?? this.prayerIsha,
      muezzinId: muezzinId ?? this.muezzinId,
      fajrMuezzinId: fajrMuezzinId ?? this.fajrMuezzinId,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      smartReminder: smartReminder ?? this.smartReminder,
      dailyReviewTime: dailyReviewTime ?? this.dailyReviewTime,
      streakAlertTime: streakAlertTime ?? this.streakAlertTime,
      dailyAyahTime: dailyAyahTime ?? this.dailyAyahTime,
      morningAzkarTime: morningAzkarTime ?? this.morningAzkarTime,
      eveningAzkarTime: eveningAzkarTime ?? this.eveningAzkarTime,
      dailyDuaTime: dailyDuaTime ?? this.dailyDuaTime,
      kidsReminderTime: kidsReminderTime ?? this.kidsReminderTime,
      fridayKahfTime: fridayKahfTime ?? this.fridayKahfTime,
      weeklyImpactTime: weeklyImpactTime ?? this.weeklyImpactTime,
      tahajjudTime: tahajjudTime ?? this.tahajjudTime,
      khatmahReminderTime: khatmahReminderTime ?? this.khatmahReminderTime,
      feedback: feedback ?? this.feedback,
      feedbackRevision: feedbackRevision ?? this.feedbackRevision,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    hasSystemPermission,
    dailyReview,
    streakAlert,
    dailyAyah,
    morningAzkar,
    eveningAzkar,
    dailyDua,
    kidsReminder,
    fridayKahf,
    weeklyImpact,
    tahajjud,
    khatmahReminder,
    prayerNotifications,
    prayerAthan,
    prayerFajr,
    prayerDhuhr,
    prayerAsr,
    prayerMaghrib,
    prayerIsha,
    muezzinId,
    fajrMuezzinId,
    quietHoursEnabled,
    quietHoursStart,
    quietHoursEnd,
    smartReminder,
    dailyReviewTime,
    streakAlertTime,
    dailyAyahTime,
    morningAzkarTime,
    eveningAzkarTime,
    dailyDuaTime,
    kidsReminderTime,
    fridayKahfTime,
    weeklyImpactTime,
    tahajjudTime,
    khatmahReminderTime,
    feedback,
    feedbackRevision,
  ];
}
