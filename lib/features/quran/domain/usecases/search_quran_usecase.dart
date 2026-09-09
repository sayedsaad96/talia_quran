import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/quran_entities.dart';
import '../repositories/quran_repository.dart';

class QuranSearchResult {
  const QuranSearchResult({required this.surahs, required this.ayahs});

  const QuranSearchResult.empty() : surahs = const [], ayahs = const [];

  final List<Surah> surahs;
  final List<Ayah> ayahs;
}

class SearchQuranUsecase implements UseCase<QuranSearchResult, String> {
  const SearchQuranUsecase(this._repository);

  final QuranRepository _repository;

  @override
  Future<Either<Failure, QuranSearchResult>> call(String query) async {
    if (query.trim().isEmpty) {
      return const Right(QuranSearchResult.empty());
    }
    final surahsResult = await _repository.searchSurahs(query);
    final ayahsResult = await _repository.searchAyahs(query);
    return surahsResult.fold(Left.new, (surahs) {
      return ayahsResult.fold(Left.new, (ayahs) {
        return Right(QuranSearchResult(surahs: surahs, ayahs: ayahs));
      });
    });
  }
}
