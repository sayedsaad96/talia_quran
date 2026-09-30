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

/// The kids memorization path (K27): Al-Fatiha first — the surah a child
/// needs for prayer — then Juz Amma from An-Nas down to An-Naba.
///
/// The single source of the path's order: the setup picker, start-surah
/// validation, and the "next surah" of the mission resolver all read it.
abstract final class KidsJourneyPath {
  static const firstSurahId = 1;
  static const lastSurahId = 78;

  /// Every surah on the path, in the order the child memorizes them.
  static const List<int> surahIds = [
    firstSurahId,
    114, 113, 112, 111, 110, 109, 108, 107, 106, 105, 104, 103, 102, 101, //
    100, 99, 98, 97, 96, 95, 94, 93, 92, 91, 90, 89, 88, 87, 86, 85, 84, //
    83, 82, 81, 80, 79, lastSurahId,
  ];

  static bool contains(int surahId) =>
      surahId == firstSurahId || (surahId >= lastSurahId && surahId <= 114);

  /// The surah after [surahId] on a path that ends at [lastSurahId]; null at
  /// the end of the path or for a surah outside it.
  static int? nextAfter(int surahId, {int lastSurahId = lastSurahId}) {
    if (surahId == firstSurahId) return 114;
    if (surahId > lastSurahId && surahId <= 114) return surahId - 1;
    return null;
  }
}

final class KidsJourneyCursor extends Equatable {
  const KidsJourneyCursor({
    required this.activeSurahId,
    required this.nextAyah,
    this.pathId = fatihaThenJuzAmmaPath,
  });

  static const fatihaThenJuzAmmaPath = 'fatiha_then_juz_amma';
  static const initial = KidsJourneyCursor(
    activeSurahId: KidsJourneyPath.firstSurahId,
    nextAyah: 1,
  );

  final String pathId;
  final int activeSurahId;
  final int nextAyah;

  KidsJourneyCursor copyWith({int? activeSurahId, int? nextAyah}) =>
      KidsJourneyCursor(
        pathId: pathId,
        activeSurahId: activeSurahId ?? this.activeSurahId,
        nextAyah: nextAyah ?? this.nextAyah,
      );

  @override
  List<Object?> get props => [pathId, activeSurahId, nextAyah];
}
