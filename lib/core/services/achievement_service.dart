import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../memorization/progress_metrics.dart';
import '../memorization/progress_metrics_service.dart';
import '../memorization/quran_structure_maps.dart';
import '../progress/progress_changed_reason.dart';
import '../progress/progress_events_bus.dart';
import '../utils/talia_logger.dart';
import '../../features/certificate/domain/entities/certificate_award.dart';
import '../../features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../features/quran/data/datasources/quran_local_datasource.dart';

// Re-export so existing callers importing achievement_service.dart continue
// to receive CertificateAward and CertificateType without import changes.
export '../../features/certificate/domain/entities/certificate_award.dart';

/// Product policy (Sprint 9B — Shared Family / Device-Wide Achievements):
///
/// Certificates are shared across the Talia device/profile experience.
/// Eligibility is computed exclusively via [ProgressMetricsService] with
/// [ProgressAudience.certificates]: an ayah must reach `strengthLevel >= 6`
/// (true SRS memorized) from a production source (`v2Session`, `hifz`, or
/// `kidsMode`). Legacy ambiguous tags never unlock certificates.
class AchievementService {
  AchievementService(
    this._prefs,
    this._memPlusDs,
    this._quranDs,
    this._progressEvents, [
    this._memPlusRepository,
    this._metrics = const ProgressMetricsService(),
  ]);

  final SharedPreferences _prefs;
  final MemorizationPlusLocalDatasource _memPlusDs;
  final QuranLocalDatasource _quranDs;
  final ProgressEventsBus _progressEvents;
  // Optional: injected lazily to avoid a DI cycle with the repository, which
  // does not depend on this service. Used only for best-effort cloud sync of
  // newly-earned certificates so the parent dashboard can display them.
  final MemorizationPlusRepository? _memPlusRepository;
  final ProgressMetricsService _metrics;

  static const _earnedKeyAdult = 'earned_certificates_v2';
  static const _earnedKeyKids = 'earned_certificates_v2_kids';
  static const _newBadgeKeyAdult = 'has_new_certificate';
  static const _newBadgeKeyKids = 'has_new_certificate_kids';

  String _getEarnedKey(bool isKids) => isKids ? _earnedKeyKids : _earnedKeyAdult;
  String _getNewBadgeKey(bool isKids) => isKids ? _newBadgeKeyKids : _newBadgeKeyAdult;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns all certificates that have been earned so far for a specific path.
  List<CertificateAward> getEarnedCertificates({required bool isKids}) {
    final raw = _prefs.getString(_getEarnedKey(isKids));
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

  /// Returns all certificates across both paths (for cloud sync).
  List<CertificateAward> getAllEarnedCertificates() {
    final adultCerts = getEarnedCertificates(isKids: false);
    final kidsCerts = getEarnedCertificates(isKids: true);
    final all = [...adultCerts, ...kidsCerts];
    // Deduplicate by ID in case any legacy certificates were earned in both
    final uniqueCerts = <String, CertificateAward>{};
    for (final cert in all) {
      uniqueCerts[cert.id] = cert;
    }
    return uniqueCerts.values.toList()
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
  }

  /// True when there are new (unseen) certificates for the specified path.
  bool hasNewCertificate({required bool isKids}) {
    return _prefs.getBool(_getNewBadgeKey(isKids)) ?? false;
  }

  /// Call this after the user opens the certificates section for the path.
  void markCertificatesSeen({required bool isKids}) {
    _prefs.setBool(_getNewBadgeKey(isKids), false);
  }

  /// Checks all memorization progress and returns any **newly** earned
  /// certificates for the specified path.
  /// Call this after every successful ayah memorization in any memorization
  /// path.
  Future<List<CertificateAward>> checkAndUnlockCertificates({required bool isKids}) async {
    try {
      final alreadyEarnedIds = getEarnedCertificates(isKids: isKids).map((c) => c.id).toSet();

      final memPlusRecords = await _memPlusDs.getAllReviewRecords();
      final structure = await QuranStructureMaps.load(_quranDs);
      final surahs = await _quranDs.getSurahs();
      final surahAyahCounts = structure.surahAyahCounts;
      final ayahKeysByJuz = structure.ayahKeysByJuz;
      final ayahsByJuz = structure.ayahsByJuz;
      final ayahsBySurah = <int, List<dynamic>>{};
      for (final entry in ayahsByJuz.entries) {
        for (final ayah in entry.value) {
          ayahsBySurah.putIfAbsent(ayah.surahId, () => []).add(ayah);
        }
      }

      final audience = isKids ? ProgressAudience.kids : ProgressAudience.adult;

      final metrics = _metrics.calculate(
        records: memPlusRecords,
        now: DateTime.now().toUtc(),
        audience: audience,
        surahAyahCounts: surahAyahCounts,
        ayahKeysByJuz: ayahKeysByJuz,
        totalJuz: 30,
      );
      final memorizedKeys = metrics.memorizedKeys;

      final earned = <CertificateAward>[];

      // ── 1. Juz certificates (Juz 1-30, accurate ayah-to-juz mapping) ───────
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
              earnedAt: DateTime.now().toUtc(),
              juzNumber: juz,
            );
            earned.add(award);
            alreadyEarnedIds.add(id);
            await _saveEarned(award, isKids);
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
              earnedAt: DateTime.now().toUtc(),
              surahId: surah.id,
              surahNameAr: surah.nameAr,
              surahNameEn: surah.nameEn,
            );
            earned.add(award);
            alreadyEarnedIds.add(id);
            await _saveEarned(award, isKids);
          }
        }
      }

      // ── 3. Half and Full Quran certificates (100% threshold) ──────────────
      final fullyMemorizedJuzCount = metrics.memorizedJuz;

      if (fullyMemorizedJuzCount >= 15) {
        const id = 'cert_half_quran';
        if (!alreadyEarnedIds.contains(id)) {
          final award = CertificateAward(
            id: id,
            titleAr: 'شهادة حفظ نصف القرآن الكريم',
            type: CertificateType.halfQuran,
            earnedAt: DateTime.now().toUtc(),
          );
          earned.add(award);
          alreadyEarnedIds.add(id);
          await _saveEarned(award, isKids);
        }
      }

      if (fullyMemorizedJuzCount == 30) {
        const id = 'cert_full_quran';
        if (!alreadyEarnedIds.contains(id)) {
          final award = CertificateAward(
            id: id,
            titleAr: 'شهادة ختم القرآن الكريم كاملاً',
            type: CertificateType.fullQuran,
            earnedAt: DateTime.now().toUtc(),
          );
          earned.add(award);
          alreadyEarnedIds.add(id);
          await _saveEarned(award, isKids);
        }
      }

      if (earned.isNotEmpty) {
        await _prefs.setBool(_getNewBadgeKey(isKids), true);
      }

      return earned;
    } catch (e, stack) {
      TaliaLogger.w('Achievement check failed', e, stack);
      return [];
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _saveEarned(CertificateAward award, bool isKids) async {
    final existing = getEarnedCertificates(isKids: isKids);
    existing.insert(0, award);
    await _prefs.setString(
      _getEarnedKey(isKids),
      jsonEncode(existing.map((c) => c.toJson()).toList()),
    );
    _progressEvents.notify(ProgressChangedReason.certificate);
    final repository = _memPlusRepository;
    if (repository != null) {
      unawaited(repository.pushCertificatesToCloud([award]));
    }
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
