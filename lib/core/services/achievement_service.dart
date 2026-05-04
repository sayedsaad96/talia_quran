import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/hifz/data/datasources/hifz_local_datasource.dart';
import '../../features/hifz/domain/entities/hifz_entities.dart';
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

enum CertificateType { juz, surah }

/// Minimum memorization percentage required to earn a certificate.
const double kCertificateThreshold = 0.90;

/// Surahs that are eligible for individual certificates (>100 ayahs).
/// Determined dynamically by `AchievementService` from quran data.
const int kMinAyahsForSurahCertificate = 100;

class AchievementService extends ChangeNotifier {
  AchievementService(this._prefs, this._hifzDs, this._quranDs);

  final SharedPreferences _prefs;
  final HifzLocalDatasource _hifzDs;
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

  /// Checks all progress and returns any **newly** earned certificates.
  /// Call this after every successful ayah memorization.
  Future<List<CertificateAward>> checkAndUnlockCertificates() async {
    try {
      final allProgress = await _hifzDs.getAllProgress();
      final surahs = await _quranDs.getSurahs();

      final earned = <CertificateAward>[];

      // ── 1. Juz certificates (Juz 1-30, each ~20 pages ~200 ayahs) ──────────
      // Group progress by surah, then map surahs to juz
      final juzAyahCounts = <int, int>{};     // juz → total ayahs in that juz
      final juzMemorized = <int, int>{};       // juz → memorized count

      for (final surah in surahs) {
        final juz = surah.juz;
        juzAyahCounts[juz] = (juzAyahCounts[juz] ?? 0) + surah.ayahCount;
      }

      for (final p in allProgress) {
        if (p.status == AyahStatus.memorized) {
          // Find which juz this surah belongs to
          final surah = surahs.firstWhere(
            (s) => s.id == p.surahId,
            orElse: () => surahs.first,
          );
          final juz = surah.juz;
          juzMemorized[juz] = (juzMemorized[juz] ?? 0) + 1;
        }
      }

      for (int juz = 1; juz <= 30; juz++) {
        final total = juzAyahCounts[juz] ?? 200;
        final memorized = juzMemorized[juz] ?? 0;
        final percentage = total > 0 ? memorized / total : 0.0;

        if (percentage >= kCertificateThreshold) {
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

      // ── 2. Surah certificates (>100 ayahs only) ───────────────────────────
      final largeSurahs = surahs.where((s) => s.ayahCount > kMinAyahsForSurahCertificate);

      for (final surah in largeSurahs) {
        final surahProgress = allProgress.where((p) => p.surahId == surah.id).toList();
        final memorized = surahProgress
            .where((p) => p.status == AyahStatus.memorized)
            .length;
        final percentage = surah.ayahCount > 0 ? memorized / surah.ayahCount : 0.0;

        if (percentage >= kCertificateThreshold) {
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

      if (earned.isNotEmpty) {
        await _prefs.setBool(_newBadgeKey, true);
        notifyListeners();
      }

      return earned;
    } catch (e) {
      debugPrint('⚠️ AchievementService.checkAndUnlock failed: $e');
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
    'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس',
    'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر',
    'الحادي عشر', 'الثاني عشر', 'الثالث عشر', 'الرابع عشر', 'الخامس عشر',
    'السادس عشر', 'السابع عشر', 'الثامن عشر', 'التاسع عشر', 'العشرون',
    'الحادي والعشرون', 'الثاني والعشرون', 'الثالث والعشرون', 'الرابع والعشرون', 'الخامس والعشرون',
    'السادس والعشرون', 'السابع والعشرون', 'الثامن والعشرون', 'التاسع والعشرون', 'الثلاثون',
  ];
}
