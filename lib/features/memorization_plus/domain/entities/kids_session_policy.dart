import 'package:equatable/equatable.dart';

enum MemorizationAudience { adult, kids }

enum KidsAgeBand { fiveToSeven, eightToTwelve }

enum KidsMissionType { dueReview, resume, newMemorization, linkedReview }

/// Age-band limits for kids missions.
///
/// There is deliberately no block-review or linked-review-length setting:
/// kids missions are single-ayah sessions (see `KidsModeCubit.load`), and a
/// policy value that no session honours would only mislead (N8, K16).
final class KidsSessionPolicy extends Equatable {
  const KidsSessionPolicy({
    required this.ageBand,
    required this.maxNewAyahs,
    required this.maxDueReviews,
    required this.maxSessionMinutes,
    required this.journeyStageSize,
    required this.guidanceAudioDefault,
    this.maxListenRepetitions = 1,
  });

  factory KidsSessionPolicy.forAge(int age) {
    if (age < 5 || age > 12) throw RangeError.range(age, 5, 12, 'age');
    if (age <= 7) {
      return const KidsSessionPolicy(
        ageBand: KidsAgeBand.fiveToSeven,
        maxNewAyahs: 1,
        maxDueReviews: 1,
        maxSessionMinutes: 6,
        journeyStageSize: 3,
        guidanceAudioDefault: true,
        // Pedagogically inverted on purpose: younger children need MORE
        // audio repetitions before recall, not fewer — their working memory
        // and auditory encoding are still developing.
        maxListenRepetitions: 3,
      );
    }
    return const KidsSessionPolicy(
      ageBand: KidsAgeBand.eightToTwelve,
      maxNewAyahs: 2,
      maxDueReviews: 3,
      maxSessionMinutes: 10,
      journeyStageSize: 5,
      guidanceAudioDefault: false,
      maxListenRepetitions: 2,
    );
  }

  /// Policy for a stored child age; a missing or out-of-range age falls back
  /// to the 8–12 band, the same default every kids surface already assumed.
  factory KidsSessionPolicy.forChildAge(int? age) =>
      KidsSessionPolicy.forAge(age != null && age >= 5 && age <= 12 ? age : 8);

  final KidsAgeBand ageBand;
  final int maxNewAyahs;
  final int maxDueReviews;
  final int maxSessionMinutes;
  final int journeyStageSize;
  final bool guidanceAudioDefault;

  /// Required listen repetitions before the child may record a recitation.
  /// Keeps the "listen → repeat → test" loop real instead of the previous
  /// hard-coded single listen for every age.
  final int maxListenRepetitions;

  @override
  List<Object?> get props => [
    ageBand,
    maxNewAyahs,
    maxDueReviews,
    maxSessionMinutes,
    journeyStageSize,
    guidanceAudioDefault,
    maxListenRepetitions,
  ];
}

final class KidsJourneyCursor extends Equatable {
  const KidsJourneyCursor({
    required this.activeSurahId,
    required this.nextAyah,
    this.pathId = juzAmmaReversePath,
  });

  static const juzAmmaReversePath = 'juz_amma_reverse';
  static const initial = KidsJourneyCursor(activeSurahId: 114, nextAyah: 1);

  final String pathId;
  final int activeSurahId;
  final int nextAyah;

  static int? nextJuzAmmaSurah(int completedSurahId) {
    if (completedSurahId < 78 || completedSurahId > 114) return null;
    return completedSurahId == 78 ? null : completedSurahId - 1;
  }

  KidsJourneyCursor copyWith({int? activeSurahId, int? nextAyah}) =>
      KidsJourneyCursor(
        pathId: pathId,
        activeSurahId: activeSurahId ?? this.activeSurahId,
        nextAyah: nextAyah ?? this.nextAyah,
      );

  @override
  List<Object?> get props => [pathId, activeSurahId, nextAyah];
}
