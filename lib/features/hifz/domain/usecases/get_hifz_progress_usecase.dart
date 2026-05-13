import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/usecase.dart';
import '../hifz_unlock_rules.dart';
import '../entities/hifz_entities.dart';
import '../repositories/hifz_repository.dart';

class GetHifzProgressUsecase
    implements UseCaseNoParams<List<SurahHifzProgress>> {
  GetHifzProgressUsecase(this._repository);
  final HifzRepository _repository;

  @override
  Future<Either<Failure, List<SurahHifzProgress>>> call() =>
      _repository.getAllSurahProgress();
}

class SaveAyahProgressUsecase implements UseCase<void, AyahProgress> {
  SaveAyahProgressUsecase(this._repository);
  final HifzRepository _repository;

  @override
  Future<Either<Failure, void>> call(AyahProgress progress) =>
      _repository.saveAyahProgress(progress);
}

class GetDueReviewsUsecase implements UseCaseNoParams<List<AyahProgress>> {
  GetDueReviewsUsecase(this._repository);
  final HifzRepository _repository;

  @override
  Future<Either<Failure, List<AyahProgress>>> call() =>
      _repository.getDueReviews();
}

class GetProgressForSurahUsecase implements UseCase<List<AyahProgress>, int> {
  GetProgressForSurahUsecase(this._repository);
  final HifzRepository _repository;

  @override
  Future<Either<Failure, List<AyahProgress>>> call(int surahId) =>
      _repository.getProgressForSurah(surahId);
}

class GetHifzPathUsecase implements UseCaseNoParams<String?> {
  GetHifzPathUsecase(this._repository);
  final HifzRepository _repository;

  @override
  Future<Either<Failure, String?>> call() async {
    return _repository.getHifzPath();
  }
}

class SaveHifzPathUsecase implements UseCase<void, String> {
  SaveHifzPathUsecase(this._repository);
  final HifzRepository _repository;

  @override
  Future<Either<Failure, void>> call(String params) =>
      _repository.saveHifzPath(params);
}

class GenerateHifzSegmentsUsecase {
  const GenerateHifzSegmentsUsecase();

  List<HifzSegment> call({required int surahId, required int totalAyahs}) {
    return generateHifzSegments(surahId: surahId, totalAyahs: totalAyahs);
  }
}

class CheckNextAyahUnlockUsecase {
  const CheckNextAyahUnlockUsecase();

  bool call({
    required int currentAyah,
    required int totalAyahs,
    required List<HifzSegment> segments,
    required Set<String> passedSegmentKeys,
  }) {
    return canUnlockNextAyah(
      currentAyah: currentAyah,
      totalAyahs: totalAyahs,
      segments: segments,
      passedSegmentKeys: passedSegmentKeys,
    );
  }
}

class GetNextRequiredReviewCheckpointUsecase {
  const GetNextRequiredReviewCheckpointUsecase();

  HifzSegment? call({
    required List<HifzSegment> segments,
    required Set<String> passedSegmentKeys,
    required Map<int, AyahProgress> progressMap,
  }) {
    return getNextRequiredCheckpoint(
      segments: segments,
      passedSegmentKeys: passedSegmentKeys,
      progressMap: progressMap,
    );
  }
}

class GetPassedCheckpointKeysUsecase implements UseCase<Set<String>, int> {
  GetPassedCheckpointKeysUsecase(this._repository);
  final HifzRepository _repository;

  @override
  Future<Either<Failure, Set<String>>> call(int surahId) =>
      _repository.getPassedCheckpointKeys(surahId);
}

class MarkCheckpointReviewPassedUsecase implements UseCase<void, HifzSegment> {
  MarkCheckpointReviewPassedUsecase(this._repository);
  final HifzRepository _repository;

  @override
  Future<Either<Failure, void>> call(HifzSegment segment) =>
      _repository.markCheckpointPassed(segment);
}
