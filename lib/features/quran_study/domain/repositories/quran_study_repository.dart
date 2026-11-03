import '../entities/study_entry.dart';

abstract interface class QuranStudyRepository {
  Future<StudyLoadResult> getAyahStudy({
    required int surahId,
    required int ayahNumber,
    required StudyKind kind,
  });
}
