import 'package:equatable/equatable.dart';

import 'parent_dashboard.dart';

/// Default and bounds for the guardian's daily-suggestions limit.
const int kKidsDefaultDailySuggestions = 3;
const int kKidsMinDailySuggestions = 1;
const int kKidsMaxDailySuggestions = 3;

/// Clamps a stored or remote daily-suggestions limit into 1..3.
int clampKidsMaxDailySuggestions(int raw) =>
    raw.clamp(kKidsMinDailySuggestions, kKidsMaxDailySuggestions);

/// A policy version is never negative; 0 means "never synced".
int clampKidsPolicyVersion(int raw) => raw < 0 ? 0 : raw;

/// The guardian-set policy the kids path applies on this device.
final class KidsChildPolicy extends Equatable {
  const KidsChildPolicy({
    this.reduceMotion = false,
    this.maxDailySuggestions = kKidsDefaultDailySuggestions,
    this.homeMissionsEnabled = true,
    this.sessionGoalMinutes,
    this.version = 0,
  });

  factory KidsChildPolicy.fromSettings(ParentSettings s) => KidsChildPolicy(
    reduceMotion: s.kidsReduceMotion,
    maxDailySuggestions: clampKidsMaxDailySuggestions(s.maxDailySuggestions),
    homeMissionsEnabled: s.homeMissionsEnabled,
    sessionGoalMinutes: s.sessionGoalMinutes,
    version: clampKidsPolicyVersion(s.policyVersion),
  );

  final bool reduceMotion;
  final int maxDailySuggestions;
  final bool homeMissionsEnabled;

  /// Null keeps the age-band default.
  final int? sessionGoalMinutes;
  final int version;

  @override
  List<Object?> get props => [
    reduceMotion,
    maxDailySuggestions,
    homeMissionsEnabled,
    sessionGoalMinutes,
    version,
  ];
}
