import '../../domain/entities/study_entry.dart';
import '../../domain/repositories/quran_study_repository.dart';
import '../datasources/approved_study_bundle_source.dart';

/// The caller supplies immutable bundled bytes and an independently bundled manifest.
/// A missing source is unavailable; malformed or unapproved content fails closed.
class QuranStudyRepositoryImpl implements QuranStudyRepository {
  QuranStudyRepositoryImpl({
    required this.canonicalAyahCounts,
    required this.loadBundle,
  });
  final Map<int, int> canonicalAyahCounts;
  final Future<({List<int> bytes, Map<String, Object?> manifest})?> Function(
    StudyKind kind,
  )
  loadBundle;
  @override
  Future<StudyLoadResult> getAyahStudy({
    required int surahId,
    required int ayahNumber,
    required StudyKind kind,
  }) async {
    final max = canonicalAyahCounts[surahId];
    if (max == null || ayahNumber < 1 || ayahNumber > max) {
      return StudyLoadResult(StudyLoadStatus.invalidReference);
    }
    try {
      final bundle = await loadBundle(kind);
      if (bundle == null) return StudyLoadResult(StudyLoadStatus.unavailable);
      final result = validateStudyBundle(
        bytes: bundle.bytes,
        manifestEntry: bundle.manifest,
        canonicalAyahCounts: canonicalAyahCounts,
      );
      if (!result.isValid || result.blocks.any((b) => b.kind != kind)) {
        return StudyLoadResult(StudyLoadStatus.invalidBundle);
      }
      final entries = result.blocks
          .where(
            (b) =>
                b.surahId == surahId &&
                b.fromAyah <= ayahNumber &&
                b.toAyah >= ayahNumber,
          )
          .toList();
      return StudyLoadResult(
        StudyLoadStatus.ready,
        entries: entries,
        source: result.source,
      );
    } catch (_) {
      return StudyLoadResult(StudyLoadStatus.invalidBundle);
    }
  }
}
