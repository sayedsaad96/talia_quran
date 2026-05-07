import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/talia_logger.dart';
import '../../features/hifz/data/datasources/hifz_local_datasource.dart';
import '../../features/hifz/domain/entities/hifz_entities.dart';
import '../../features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import '../../features/quran/data/datasources/quran_local_datasource.dart';

/// Model for a certificate that has been earned.
class CertificateAward {
  const CertificateAward({
    required this.id,
    required this.titleAr,
    required this.type,
    required this.earnedAt,
    this.juzNumber,
    this.surahId,
    this.surahNameAr,
  });

  final String id;
  final String titleAr;
  final CertificateType type;
  final DateTime earnedAt;
  final int? juzNumber;
  final int? surahId;
  final String? surahNameAr;

  Map<String, dynamic> toJson() => {
    'id': id,
    'titleAr': titleAr,
    'type': type.name,
    'earnedAt': earnedAt.toIso8601String(),
    'juzNumber': juzNumber,
    'surahId': surahId,
    'surahNameAr': surahNameAr,
  };

  factory CertificateAward.fromJson(Map<String, dynamic> json) =>
      CertificateAward(
        id: json['id'] as String,
        titleAr: json['titleAr'] as String,
        type: CertificateType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => CertificateType.surah,
        ),
        earnedAt: DateTime.parse(json['earnedAt'] as String),
        juzNumber: json['juzNumber'] as int?,
        surahId: json['surahId'] as int?,
        surahNameAr: json['surahNameAr'] as String?,
      );
}

enum CertificateType { juz, surah, halfQuran, fullQuran }

class AchievementService extends ChangeNotifier {
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
  Future<void> markCertificatesSeen() async {
    await _prefs.setBool(_newBadgeKey, false);
    notifyListeners();
  }

  /// Checks all memorization progress and returns any **newly** earned
  /// certificates.
  /// Call this after every successful ayah memorization in any memorization
  /// path.
  Future<List<CertificateAward>> checkAndUnlockCertificates() async {
    try {
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
          if (!_isAlreadyEarned(id)) {
            final award = CertificateAward(
              id: id,
              titleAr: 'شهادة حفظ الجزء ${_juzNames[juz - 1]}',
              type: CertificateType.juz,
              earnedAt: DateTime.now(),
              juzNumber: juz,
            );
            earned.add(award);
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
          if (!_isAlreadyEarned(id)) {
            final award = CertificateAward(
              id: id,
              titleAr: 'شهادة حفظ سورة ${surah.nameAr}',
              type: CertificateType.surah,
              earnedAt: DateTime.now(),
              surahId: surah.id,
              surahNameAr: surah.nameAr,
            );
            earned.add(award);
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
        final id = 'cert_half_quran';
        if (!_isAlreadyEarned(id)) {
          final award = CertificateAward(
            id: id,
            titleAr: 'شهادة حفظ نصف القرآن الكريم',
            type: CertificateType.halfQuran,
            earnedAt: DateTime.now(),
          );
          earned.add(award);
          await _saveEarned(award);
        }
      }

      // Full Quran (30 complete Juz)
      if (fullyMemorizedJuzCount == 30) {
        final id = 'cert_full_quran';
        if (!_isAlreadyEarned(id)) {
          final award = CertificateAward(
            id: id,
            titleAr: 'شهادة ختم القرآن الكريم كاملاً',
            type: CertificateType.fullQuran,
            earnedAt: DateTime.now(),
          );
          earned.add(award);
          await _saveEarned(award);
        }
      }

      if (earned.isNotEmpty) {
        await _prefs.setBool(_newBadgeKey, true);
        notifyListeners();
      }

      return earned;
    } catch (e, stack) {
      TaliaLogger.w('Achievement check failed', e, stack);
      return [];
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  bool _isAlreadyEarned(String id) {
    return getEarnedCertificates().any((c) => c.id == id);
  }

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
