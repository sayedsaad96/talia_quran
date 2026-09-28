import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/memorization/listening/listening_corpus.dart';
import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/memorization/review_record_filters.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

/// Everything one listening round needs, loaded once per page visit.
final class ListeningQuizMaterial {
  const ListeningQuizMaterial({
    required this.corpus,
    required this.prompts,
    required this.surahs,
  });

  final ListeningCorpus corpus;

  /// Distinct adult ayahs the learner has reviewed at least once.
  final List<ListeningAyahRef> prompts;

  final Map<int, Surah> surahs;
}

/// Loads adult review records and the frozen Quran corpus. Read-only: never
/// writes review records. Any read failure fails the whole load (no partial
/// corpus → no guessed questions).
class ListeningQuizSource {
  ListeningQuizSource(this._memorization, this._quran);

  final MemorizationPlusRepository _memorization;
  final QuranRepository _quran;

  Future<Either<Failure, ListeningQuizMaterial>> load() async {
    Failure? failure;
    var records = const <AyahReviewRecord>[];
    (await _memorization.getAllReviewRecords(
      scope: ReviewRecordReadScope.adult,
    )).fold((f) => failure = f, (r) => records = r);
    if (failure != null) return Left(failure!);

    var surahList = const <Surah>[];
    (await _quran.getSurahs()).fold((f) => failure = f, (s) => surahList = s);
    if (failure != null) return Left(failure!);
    if (surahList.length != 114) return const Left(ParseFailure());

    final texts = <int, List<String>>{};
    for (final surah in surahList) {
      (await _quran.getSurahDetail(surah.id)).fold(
        (f) => failure = f,
        (detail) =>
            texts[surah.id] = [for (final ayah in detail.ayahs) ayah.text],
      );
      if (failure != null) return Left(failure!);
    }

    final prompts = <ListeningAyahRef>{
      for (final record in records)
        if (ReviewRecordFilters.isStarted(record))
          ListeningAyahRef(record.surahId, record.ayahNumber),
    }.toList();

    return Right(
      ListeningQuizMaterial(
        corpus: ListeningCorpus.fromTexts(texts),
        prompts: prompts,
        surahs: {for (final s in surahList) s.id: s},
      ),
    );
  }
}
