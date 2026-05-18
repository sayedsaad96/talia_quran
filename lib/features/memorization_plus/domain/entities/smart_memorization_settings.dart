import 'package:equatable/equatable.dart';
import 'memorization_entities.dart'; // For CustomMemorizationPlan

class SmartMemorizationSettings extends Equatable {
  const SmartMemorizationSettings({
    this.dailySchedule,
    this.reviewDays = const [],
    this.ayahIsolationEnabled = false,
    this.customPlan,
  });

  final String? dailySchedule;
  final List<int> reviewDays;
  final bool ayahIsolationEnabled;
  final CustomMemorizationPlan? customPlan;

  SmartMemorizationSettings copyWith({
    String? dailySchedule,
    bool clearDailySchedule = false,
    List<int>? reviewDays,
    bool? ayahIsolationEnabled,
    CustomMemorizationPlan? customPlan,
    bool clearCustomPlan = false,
  }) => SmartMemorizationSettings(
    dailySchedule: clearDailySchedule
        ? null
        : (dailySchedule ?? this.dailySchedule),
    reviewDays: reviewDays ?? this.reviewDays,
    ayahIsolationEnabled: ayahIsolationEnabled ?? this.ayahIsolationEnabled,
    customPlan: clearCustomPlan ? null : (customPlan ?? this.customPlan),
  );

  @override
  List<Object?> get props => [
    dailySchedule,
    reviewDays,
    ayahIsolationEnabled,
    customPlan,
  ];
}
