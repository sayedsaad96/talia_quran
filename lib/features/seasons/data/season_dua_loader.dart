import '../../azkar/data/datasources/azkar_local_datasource.dart';
import '../../azkar/domain/entities/azkar_entities.dart';

/// The only azkar records the season cards may show. Everything else a season
/// might want (takbeer, the Arafah dua, the iftar dua, virtues) is blocked
/// until it enters `azkar_release.json` through the religious review path; see
/// docs/superpowers/evidence/2026-10-26-seasons-azkar-inventory.md.
abstract final class SeasonLineIds {
  /// Prophetic duas (Tirmidhi), last ten nights only.
  static const lastTenDua = 'dp4';

  /// Dua when the Quran is completed (khatmah finished in Ramadan).
  static const khatmahDua = 'dk1';

  /// Eid al-Fitr card.
  static const eidFitrDua = 'dua_quran_2_127';

  /// Friday card.
  static const fridayDua = 'dua_quran_18_10';

  /// Hijri new year card.
  static const newYearDua = 'dua_quran_20_114';

  static const all = {
    lastTenDua,
    khatmahDua,
    eidFitrDua,
    fridayDua,
    newYearDua,
  };
}

/// An approved release record, verbatim, with the citation to show under it.
class ApprovedSeasonLine {
  const ApprovedSeasonLine({
    required this.id,
    required this.text,
    required this.citation,
  });

  final String id;
  final String text;
  final String citation;
}

typedef SeasonLineLoader = Future<ApprovedSeasonLine?> Function(String id);

/// Loads [id] from the bundled release file through the azkar datasource,
/// which only parses records that satisfy the release contract. Returns null
/// (so the line disappears, with no fallback text) when [id] is not an allowed
/// season line, is missing, is not approved, has no citation, or loading fails.
Future<ApprovedSeasonLine?> loadApprovedSeasonLine(
  String id,
  AzkarLocalDatasource datasource,
) async {
  if (!SeasonLineIds.all.contains(id)) return null;
  try {
    final records = await datasource.getAzkar(AzkarCategory.duas);
    for (final record in records) {
      if (record.id != id) continue;
      if (record.reviewStatus != ContentReviewStatus.approved) return null;
      final citation = (record.citation ?? record.reference).trim();
      if (record.text.trim().isEmpty || citation.isEmpty) return null;
      return ApprovedSeasonLine(
        id: record.id,
        text: record.text,
        citation: citation,
      );
    }
  } catch (_) {
    // Fails closed: no line.
  }
  return null;
}
