import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran_study/data/repositories/quran_study_repository_impl.dart';
import 'package:talia_quran/features/quran_study/domain/entities/study_entry.dart';

void main() {
  test(
    'missing, invalid reference and invalid bundle fail independently',
    () async {
      final repo = QuranStudyRepositoryImpl(
        canonicalAyahCounts: {1: 2},
        loadBundle: (_) async => null,
      );
      expect(
        (await repo.getAyahStudy(
          surahId: 1,
          ayahNumber: 1,
          kind: StudyKind.tafsir,
        )).status,
        StudyLoadStatus.unavailable,
      );
      expect(
        (await repo.getAyahStudy(
          surahId: 1,
          ayahNumber: 3,
          kind: StudyKind.tafsir,
        )).status,
        StudyLoadStatus.invalidReference,
      );
      final corrupt = QuranStudyRepositoryImpl(
        canonicalAyahCounts: {1: 2},
        loadBundle: (_) async => (bytes: [1], manifest: <String, Object?>{}),
      );
      expect(
        (await corrupt.getAyahStudy(
          surahId: 1,
          ayahNumber: 1,
          kind: StudyKind.tafsir,
        )).status,
        StudyLoadStatus.invalidBundle,
      );
    },
  );
}
