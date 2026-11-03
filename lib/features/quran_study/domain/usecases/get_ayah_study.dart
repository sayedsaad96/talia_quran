import '../entities/study_entry.dart';
import '../repositories/quran_study_repository.dart';

class GetAyahStudy {
  const GetAyahStudy(this.repository);
  final QuranStudyRepository repository;
  Future<StudyLoadResult> call({
    required int surahId,
    required int ayahNumber,
    required StudyKind kind,
  }) => repository.getAyahStudy(
    surahId: surahId,
    ayahNumber: ayahNumber,
    kind: kind,
  );
}
