import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/hifz_entities.dart';
import '../repositories/hifz_repository.dart';

class GetHifzProgressUsecase implements UseCaseNoParams<List<SurahHifzProgress>> {
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
