import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/memorization/listening/listening_corpus.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../domain/entities/ayah_review_record.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

final class HandsFreeReviewMaterial {
  HandsFreeReviewMaterial({
    required this.corpus,
    required List<AyahReviewRecord> due,
    required this.isCurrent,
  }) : due = List.unmodifiable(due);
  final ListeningCorpus corpus;
  final List<AyahReviewRecord> due;
  final bool Function() isCurrent;
}

/// Account-bound reads only; no outcome, stats or SRS mutation capability.
final class HandsFreeReviewSource {
  const HandsFreeReviewSource(
    this.records,
    this.quran,
    this.owner,
    this.barrier,
    this.path,
  );
  final MemorizationPlusRepository records;
  final QuranRepository quran;
  final RecordOwnerProvider owner;
  final AccountDataBarrier barrier;
  final MemorizationPathResolver path;

  Future<HandsFreeReviewMaterial> load() async {
    final ownerId = owner.currentOwnerId;
    final lease = barrier.capture();
    bool current() {
      try {
        lease.checkOwner(ownerId);
        return true;
      } catch (_) {
        return false;
      }
    }

    void check() {
      if (!current()) throw const AccountDataUnavailableException();
    }

    check();
    final profile = await path.currentProfile();
    check();
    if (profile?.isAdult != true) throw const AccountDataUnavailableException();
    final result = await records.getAllReviewRecords(
      scope: ReviewRecordReadScope.adult,
    );
    check();
    final due = result.fold(
      (failure) => throw StateError('Review load failed'),
      (value) => value,
    );
    final texts = await _loadCorpus(due, check);
    return HandsFreeReviewMaterial(
      corpus: ListeningCorpus.fromTexts(texts),
      due: due,
      isCurrent: current,
    );
  }

  Future<Map<int, List<String>>> _loadCorpus(
    List<AyahReviewRecord> due,
    void Function() check,
  ) async {
    final texts = <int, List<String>>{};
    final surahs = due
        .map((r) => r.surahId)
        .where((id) => id >= 1 && id <= 114)
        .toSet();
    for (final id in surahs) {
      final detail = await quran.getSurahDetail(id);
      check();
      texts[id] = detail.fold(
        (failure) => throw StateError('Corpus load failed'),
        (value) => _textsOf(id, value),
      );
    }
    return texts;
  }

  List<String> _textsOf(int id, SurahDetail detail) {
    if (detail.surah.id != id ||
        detail.ayahs.isEmpty ||
        detail.ayahs.length != detail.surah.ayahCount) {
      throw StateError('Corpus surah contract mismatch');
    }
    for (var index = 0; index < detail.ayahs.length; index++) {
      final ayah = detail.ayahs[index];
      if (ayah.surahId != id ||
          ayah.numberInSurah != index + 1 ||
          ayah.text.isEmpty) {
        throw StateError('Corpus ayah contract mismatch');
      }
    }
    return [for (final ayah in detail.ayahs) ayah.text];
  }
}
