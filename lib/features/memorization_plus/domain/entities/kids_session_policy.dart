import 'package:equatable/equatable.dart';

enum MemorizationAudience { adult, kids }

enum KidsAgeBand { fiveToSeven, eightToTwelve }

enum KidsMissionType { dueReview, resume, newMemorization, linkedReview }

final class KidsSessionPolicy extends Equatable {
  const KidsSessionPolicy({
    required this.ageBand,
    required this.maxNewAyahs,
    required this.maxDueReviews,
    required this.maxSessionMinutes,
    required this.journeyStageSize,
    required this.blockReviewRequired,
    required this.linkedReviewAyahs,
    required this.guidanceAudioDefault,
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
        blockReviewRequired: false,
        linkedReviewAyahs: 2,
        guidanceAudioDefault: true,
      );
    }
    return const KidsSessionPolicy(
      ageBand: KidsAgeBand.eightToTwelve,
      maxNewAyahs: 2,
      maxDueReviews: 3,
      maxSessionMinutes: 10,
      journeyStageSize: 5,
      blockReviewRequired: true,
      linkedReviewAyahs: 3,
      guidanceAudioDefault: false,
    );
  }

  final KidsAgeBand ageBand;
  final int maxNewAyahs;
  final int maxDueReviews;
  final int maxSessionMinutes;
  final int journeyStageSize;
  final bool blockReviewRequired;
  final int linkedReviewAyahs;
  final bool guidanceAudioDefault;

  @override
  List<Object?> get props => [
    ageBand,
    maxNewAyahs,
    maxDueReviews,
    maxSessionMinutes,
    journeyStageSize,
    blockReviewRequired,
    linkedReviewAyahs,
    guidanceAudioDefault,
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
