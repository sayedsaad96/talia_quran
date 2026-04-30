import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/quran_entities.dart';
import '../repositories/quran_repository.dart';

class GetSurahsUsecase implements UseCaseNoParams<List<Surah>> {
  GetSurahsUsecase(this._repository);
  final QuranRepository _repository;

  @override
  Future<Either<Failure, List<Surah>>> call() => _repository.getSurahs();
}

class GetSurahDetailUsecase implements UseCase<SurahDetail, int> {
  GetSurahDetailUsecase(this._repository);
  final QuranRepository _repository;

  @override
  Future<Either<Failure, SurahDetail>> call(int surahId) =>
      _repository.getSurahDetail(surahId);
}

class SearchSurahsUsecase implements UseCase<List<Surah>, String> {
  SearchSurahsUsecase(this._repository);
  final QuranRepository _repository;

  @override
  Future<Either<Failure, List<Surah>>> call(String query) =>
      _repository.searchSurahs(query);
}

class GetQuranPageUsecase implements UseCase<QuranPageDetail, int> {
  const GetQuranPageUsecase(this._repository);
  final QuranRepository _repository;

  @override
  Future<Either<Failure, QuranPageDetail>> call(int pageNumber) =>
      _repository.getQuranPage(pageNumber);
}
