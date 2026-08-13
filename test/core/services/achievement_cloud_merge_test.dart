import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/quran/data/datasources/quran_local_datasource.dart';

class _FakeQuranDs extends Fake implements QuranLocalDatasource {}

void main() {
  test('mergeEarnedFromCloud adds missing adult certificates only once', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = AchievementService(
      prefs,
      MemorizationPlusLocalDatasourceImpl(prefs),
      _FakeQuranDs(),
      ProgressEventsBus(),
    );

    final remote = [
      CertificateAward(
        id: 'cert_juz_1',
        titleAr: 'جزء 1',
        type: CertificateType.juz,
        earnedAt: DateTime.utc(2026, 8, 1),
        juzNumber: 1,
      ),
    ];

    expect(await service.mergeEarnedFromCloud(remote, isKids: false), 1);
    expect(await service.mergeEarnedFromCloud(remote, isKids: false), 0);
    expect(service.getEarnedCertificates(isKids: false).single.id, 'cert_juz_1');
  });

  test('CertificateAward.fromCloudRow parses juz and surah ids', () {
    final juz = CertificateAward.fromCloudRow({
      'cert_id': 'cert_juz_3',
      'title_ar': 'جزء 3',
      'cert_type': 'juz',
      'earned_at': '2026-08-01T00:00:00Z',
    });
    expect(juz.juzNumber, 3);
    expect(juz.type, CertificateType.juz);

    final surah = CertificateAward.fromCloudRow({
      'cert_id': 'cert_surah_67',
      'title_ar': 'سورة الملك',
      'cert_type': 'surah',
      'earned_at': '2026-08-02T00:00:00Z',
    });
    expect(surah.surahId, 67);
  });
}