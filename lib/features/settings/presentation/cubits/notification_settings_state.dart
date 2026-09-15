import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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
    this.tahajjud = false,
    this.khatmahReminder = true,
    this.prayerNotifications = false,
    this.prayerFajr = true,
    this.prayerDhuhr = true,
    this.prayerAsr = true,
    this.prayerMaghrib = true,
    this.prayerIsha = true,
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
    this.tahajjudTime = const TimeOfDay(hour: 3, minute: 30),
    this.khatmahReminderTime = const TimeOfDay(hour: 17, minute: 0),
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
  final bool tahajjud;
  final bool khatmahReminder;

  // Prayer Times and individual prayer filters
  final bool prayerNotifications;
  final bool prayerFajr;
  final bool prayerDhuhr;
  final bool prayerAsr;
  final bool prayerMaghrib;
  final bool prayerIsha;

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
  final TimeOfDay tahajjudTime;
  final TimeOfDay khatmahReminderTime;

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
    if (tahajjud) count++;
    if (khatmahReminder) count++;
    return count;
  }

  /// Total number of customizable notification categories.
  int get totalCount => 10;

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
    bool? tahajjud,
    bool? khatmahReminder,
    bool? prayerNotifications,
    bool? prayerFajr,
    bool? prayerDhuhr,
    bool? prayerAsr,
    bool? prayerMaghrib,
    bool? prayerIsha,
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
    TimeOfDay? khatmahReminderTime,
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
      tahajjud: tahajjud ?? this.tahajjud,
      khatmahReminder: khatmahReminder ?? this.khatmahReminder,
      prayerNotifications: prayerNotifications ?? this.prayerNotifications,
      prayerFajr: prayerFajr ?? this.prayerFajr,
      prayerDhuhr: prayerDhuhr ?? this.prayerDhuhr,
      prayerAsr: prayerAsr ?? this.prayerAsr,
      prayerMaghrib: prayerMaghrib ?? this.prayerMaghrib,
      prayerIsha: prayerIsha ?? this.prayerIsha,
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
      tahajjudTime: tahajjudTime ?? this.tahajjudTime,
      khatmahReminderTime: khatmahReminderTime ?? this.khatmahReminderTime,
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
    tahajjud,
    khatmahReminder,
    prayerNotifications,
    prayerFajr,
    prayerDhuhr,
    prayerAsr,
    prayerMaghrib,
    prayerIsha,
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
    tahajjudTime,
    khatmahReminderTime,
  ];
}
