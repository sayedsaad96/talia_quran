import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/talia_logger.dart';
import '../../features/certificate/domain/entities/certificate_award.dart';
import '../../features/hifz/data/datasources/hifz_local_datasource.dart';
import '../../features/hifz/domain/entities/hifz_entities.dart';
import '../../features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import '../../features/quran/data/datasources/quran_local_datasource.dart';

// Re-export so existing callers importing achievement_service.dart continue
// to receive CertificateAward and CertificateType without import changes.
export '../../features/certificate/domain/entities/certificate_award.dart';

/// Product policy (Sprint 9B — Shared Family / Device-Wide Achievements):
///
/// Certificates are shared across the Talia device/profile experience.
/// [AchievementService] intentionally combines memorized ayahs from Hifz
/// progress and **all** memorized Memorization Plus review records, regardless
/// of [ReviewRecordCreatedByMode]. This means every path that can mark an ayah
/// as memorized — adult MemPlus, Kids Mode, legacy Hifz, migrated records, and
/// pre-tagging `unknown` records — may contribute to Surah, Juz, Half-Quran,
/// and Full-Quran certificates.
///
/// This is intentional. Certificates reflect total memorization progress in
/// Talia, not only adult Smart Memorization progress. They represent a shared
/// family / device-wide achievement, preserving legacy certificates and treating
/// the Quran completion journey as a unified milestone.
///
/// **Do not add source filtering here** unless the certificate product policy
/// changes. Adult SRS source filters ([ReviewRecordFilters.isAdultCompatible]
/// and [ReviewRecordFilters.isAdultRetentionCompatible]) apply to Smart Coach,
/// Quiz, and Progress smart stats only — not to [AchievementService].
class AchievementService {
  AchievementService(this._prefs, this._hifzDs, this._memPlusDs, this._quranDs);

  final SharedPreferences _prefs;
  final HifzLocalDatasource _hifzDs;
  final MemorizationPlusLocalDatasource _memPlusDs;
  final QuranLocalDatasource _quranDs;

  static const _earnedKey = 'earned_certificates_v2';
  static const _newBadgeKey = 'has_new_certificate';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns all certificates that have been earned so far.
  List<CertificateAward> getEarnedCertificates() {
    final raw = _prefs.getString(_earnedKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CertificateAward.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    } catch (_) {
      return [];
    }
  }

  /// True when there are new (unseen) certificates.
  bool get hasNewCertificate => _prefs.getBool(_newBadgeKey) ?? false;

  /// Call this after the user opens the certificates section.
  void markCertificatesSeen() {
    _prefs.setBool(_newBadgeKey, false);
  }

  /// Checks all memorization progress and returns any **newly** earned
  /// certificates.
  /// Call this after every successful ayah memorization in any memorization
  /// path.
  Future<List<CertificateAward>> checkAndUnlockCertificates() async {
    try {
      // Cache earned IDs once — avoids repeated JSON parsing across 144+ checks
      final alreadyEarnedIds = getEarnedCertificates().map((c) => c.id).toSet();

      final allProgress = await _hifzDs.getAllProgress();
      final memPlusRecords = await _memPlusDs.getAllReviewRecords();
      final surahs = await _quranDs.getSurahs();

      final earned = <CertificateAward>[];

      // ── Unified memorized ayah keys from legacy Hifz and MemorizationPlus ──
      final memorizedKeys = <String>{
        ...allProgress
            .where((p) => p.status == AyahStatus.memorized)
            .map((p) => p.key),
        ...memPlusRecords.where((r) => r.isMemorized).map((r) => r.key),
      };

      // ── 1. Juz certificates (Juz 1-30, accurate ayah-to-juz mapping) ───────
      final ayahsByJuz = await _quranDs.getAyahsGroupedByJuz();
      final ayahsBySurah = <int, List<dynamic>>{};
      for (final ayahs in ayahsByJuz.values) {
        for (final ayah in ayahs) {
          ayahsBySurah.putIfAbsent(ayah.surahId, () => []).add(ayah);
        }
      }

      for (int juz = 1; juz <= 30; juz++) {
        final ayahs = ayahsByJuz[juz] ?? const [];
        final isComplete =
            ayahs.isNotEmpty &&
            ayahs.every(
              (ayah) => memorizedKeys.contains(
                '${ayah.surahId}_${ayah.numberInSurah}',
              ),
            );

        if (isComplete) {
          final id = 'cert_juz_$juz';
          if (!alreadyEarnedIds.contains(id)) {
            final award = CertificateAward(
              id: id,
              titleAr: 'شهادة حفظ الجزء ${_juzNames[juz - 1]}',
              type: CertificateType.juz,
              earnedAt: DateTime.now(),
              juzNumber: juz,
            );
            earned.add(award);
            alreadyEarnedIds.add(id);
            await _saveEarned(award);
          }
        }
      }

      // ── 2. Surah certificates (all surahs, 100% completion only) ──────────
      for (final surah in surahs) {
        final ayahs = ayahsBySurah[surah.id];
        final isComplete = ayahs != null && ayahs.isNotEmpty
            ? ayahs.every(
                (ayah) => memorizedKeys.contains(
                  '${ayah.surahId}_${ayah.numberInSurah}',
                ),
              )
            : surah.ayahCount > 0 &&
                  List.generate(surah.ayahCount, (index) => index + 1).every(
                    (ayahNumber) =>
                        memorizedKeys.contains('${surah.id}_$ayahNumber'),
                  );

        if (isComplete) {
          final id = 'cert_surah_${surah.id}';
          if (!alreadyEarnedIds.contains(id)) {
            final award = CertificateAward(
              id: id,
              titleAr: 'شهادة حفظ سورة ${surah.nameAr}',
              type: CertificateType.surah,
              earnedAt: DateTime.now(),
              surahId: surah.id,
              surahNameAr: surah.nameAr,
              surahNameEn: surah.nameEn,
            );
            earned.add(award);
            alreadyEarnedIds.add(id);
            await _saveEarned(award);
          }
        }
      }

      // ── 3. Half and Full Quran certificates (100% threshold) ──────────────
      int fullyMemorizedJuzCount = 0;

      for (int juz = 1; juz <= 30; juz++) {
        final ayahs = ayahsByJuz[juz] ?? const [];
        if (ayahs.isNotEmpty &&
            ayahs.every(
              (ayah) => memorizedKeys.contains(
                '${ayah.surahId}_${ayah.numberInSurah}',
              ),
            )) {
          fullyMemorizedJuzCount++;
        }
      }

      // Half Quran (15+ complete Juz)
      if (fullyMemorizedJuzCount >= 15) {
        const id = 'cert_half_quran';
        if (!alreadyEarnedIds.contains(id)) {
          final award = CertificateAward(
            id: id,
            titleAr: 'شهادة حفظ نصف القرآن الكريم',
            type: CertificateType.halfQuran,
            earnedAt: DateTime.now(),
          );
          earned.add(award);
          alreadyEarnedIds.add(id);
          await _saveEarned(award);
        }
      }

      // Full Quran (30 complete Juz)
      if (fullyMemorizedJuzCount == 30) {
        const id = 'cert_full_quran';
        if (!alreadyEarnedIds.contains(id)) {
          final award = CertificateAward(
            id: id,
            titleAr: 'شهادة ختم القرآن الكريم كاملاً',
            type: CertificateType.fullQuran,
            earnedAt: DateTime.now(),
          );
          earned.add(award);
          alreadyEarnedIds.add(id);
          await _saveEarned(award);
        }
      }

      if (earned.isNotEmpty) {
        await _prefs.setBool(_newBadgeKey, true);
      }

      return earned;
    } catch (e, stack) {
      TaliaLogger.w('Achievement check failed', e, stack);
      return [];
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _saveEarned(CertificateAward award) async {
    final existing = getEarnedCertificates();
    existing.insert(0, award);
    await _prefs.setString(
      _earnedKey,
      jsonEncode(existing.map((c) => c.toJson()).toList()),
    );
  }

  static const List<String> _juzNames = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر',
    'الثالث عشر',
    'الرابع عشر',
    'الخامس عشر',
    'السادس عشر',
    'السابع عشر',
    'الثامن عشر',
    'التاسع عشر',
    'العشرون',
    'الحادي والعشرون',
    'الثاني والعشرون',
    'الثالث والعشرون',
    'الرابع والعشرون',
    'الخامس والعشرون',
    'السادس والعشرون',
    'السابع والعشرون',
    'الثامن والعشرون',
    'التاسع والعشرون',
    'الثلاثون',
  ];
}
