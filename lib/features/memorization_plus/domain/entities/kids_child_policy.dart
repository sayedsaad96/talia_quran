import 'package:equatable/equatable.dart';

import 'parent_dashboard.dart';
import 'kids_remote_plan.dart';

/// Default and bounds for the guardian's daily-suggestions limit.
const int kKidsDefaultDailySuggestions = 3;
const int kKidsMinDailySuggestions = 1;
const int kKidsMaxDailySuggestions = 3;

/// Clamps a stored or remote daily-suggestions limit into 1..3.
int clampKidsMaxDailySuggestions(int raw) =>
    raw.clamp(kKidsMinDailySuggestions, kKidsMaxDailySuggestions);

/// A policy version is never negative; 0 means "never synced".
int clampKidsPolicyVersion(int raw) => raw < 0 ? 0 : raw;

/// Bounds for a guardian session goal; outside them means "no override".
const int kKidsMinSessionGoalMinutes = 1;
const int kKidsMaxSessionGoalMinutes = 60;

/// Keeps a session goal in 1..60; anything else becomes null (age-band
/// default).
int? sanitizeKidsSessionGoalMinutes(int? raw) =>
    raw == null ||
        raw < kKidsMinSessionGoalMinutes ||
        raw > kKidsMaxSessionGoalMinutes
    ? null
    : raw;

/// The guardian-set policy the kids path applies on this device.
final class KidsChildPolicy extends Equatable {
  const KidsChildPolicy({
    this.reduceMotion = false,
    this.maxDailySuggestions = kKidsDefaultDailySuggestions,
    this.homeMissionsEnabled = true,
    this.sessionGoalMinutes,
    this.version = 0,
    this.remotePlan = const KidsRemotePlan(),
  });

  factory KidsChildPolicy.fromSettings(ParentSettings s) => KidsChildPolicy(
    reduceMotion: s.kidsReduceMotion,
    maxDailySuggestions: clampKidsMaxDailySuggestions(s.maxDailySuggestions),
    homeMissionsEnabled: s.homeMissionsEnabled,
    sessionGoalMinutes: sanitizeKidsSessionGoalMinutes(s.sessionGoalMinutes),
    version: clampKidsPolicyVersion(s.policyVersion),
    remotePlan: s.remotePlan.sanitized(),
  );

  final bool reduceMotion;
  final int maxDailySuggestions;
  final bool homeMissionsEnabled;

  /// Null keeps the age-band default.
  final int? sessionGoalMinutes;
  final int version;
  final KidsRemotePlan remotePlan;

  KidsChildPolicy copyWith({
    bool? reduceMotion,
    int? maxDailySuggestions,
    bool? homeMissionsEnabled,
    int? sessionGoalMinutes,
    bool clearSessionGoalMinutes = false,
    int? version,
    KidsRemotePlan? remotePlan,
  }) => KidsChildPolicy(
    reduceMotion: reduceMotion ?? this.reduceMotion,
    maxDailySuggestions: maxDailySuggestions ?? this.maxDailySuggestions,
    homeMissionsEnabled: homeMissionsEnabled ?? this.homeMissionsEnabled,
    sessionGoalMinutes: clearSessionGoalMinutes
        ? null
        : (sessionGoalMinutes ?? this.sessionGoalMinutes),
    version: version ?? this.version,
    remotePlan: remotePlan ?? this.remotePlan,
  );

  /// Values clamped/sanitized into the policy limits (1..3 suggestions,
  /// 1..60 minutes or null, version >= 0).
  KidsChildPolicy sanitized() => KidsChildPolicy(
    reduceMotion: reduceMotion,
    maxDailySuggestions: clampKidsMaxDailySuggestions(maxDailySuggestions),
    homeMissionsEnabled: homeMissionsEnabled,
    sessionGoalMinutes: sanitizeKidsSessionGoalMinutes(sessionGoalMinutes),
    version: clampKidsPolicyVersion(version),
    remotePlan: remotePlan.sanitized(),
  );

  @override
  List<Object?> get props => [
    reduceMotion,
    maxDailySuggestions,
    homeMissionsEnabled,
    sessionGoalMinutes,
    version,
    remotePlan,
  ];
}
