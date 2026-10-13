import 'package:equatable/equatable.dart';

import 'kids_session_policy.dart';

/// How the child reads, as the guardian describes it. Names are stored: never
/// rename or reorder a value.
enum KidsReadingAbility { unknown, independent, withHelp, notYetReading }

/// The guardian's answers about the child's learning support. Version 1
/// holds the reading answer only; unknown means today's behaviour.
class KidsLearningSupportProfile extends Equatable {
  const KidsLearningSupportProfile({this.reading = KidsReadingAbility.unknown});

  static const unknown = KidsLearningSupportProfile();
  static const currentVersion = 1;

  final KidsReadingAbility reading;

  Map<String, Object?> toJson() => {
    'v': currentVersion,
    'reading': reading.name,
  };

  /// Lenient: a missing, newer or malformed record reads as [unknown] for the
  /// fields it cannot read, never as a failure.
  factory KidsLearningSupportProfile.fromJson(Object? json) {
    if (json is! Map) return unknown;
    final reading = KidsReadingAbility.values
        .where((r) => r.name == json['reading'])
        .firstOrNull;
    return KidsLearningSupportProfile(
      reading: reading ?? KidsReadingAbility.unknown,
    );
  }

  @override
  List<Object?> get props => [reading];
}

/// What the profile changes in a session: only how early help is suggested.
/// The age policy (new ayahs, reviews, minutes, listens) passes through
/// untouched, so no profile can raise a limit or skip a step.
class KidsSupportPolicy extends Equatable {
  const KidsSupportPolicy({
    required this.sessionPolicy,
    this.proactiveHints = false,
  });

  final KidsSessionPolicy sessionPolicy;

  /// Suggest the phase's existing help before a miss, not only after one.
  final bool proactiveHints;

  @override
  List<Object?> get props => [sessionPolicy, proactiveHints];
}

KidsSupportPolicy resolveKidsSupportPolicy({
  required KidsSessionPolicy agePolicy,
  required KidsLearningSupportProfile profile,
}) => KidsSupportPolicy(
  sessionPolicy: agePolicy,
  proactiveHints: kidsSupportProactiveHints(profile),
);

/// A child who reads with help, or not yet, gets the phase's help suggested
/// before a miss. Unknown and independent keep today's behaviour.
bool kidsSupportProactiveHints(KidsLearningSupportProfile profile) =>
    profile.reading == KidsReadingAbility.withHelp ||
    profile.reading == KidsReadingAbility.notYetReading;
