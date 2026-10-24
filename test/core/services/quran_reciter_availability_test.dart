import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/quran_audio_service.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';

void main() {
  const legacy = [
    ('alafasy', 'https://everyayah.com/data/Alafasy_128kbps/'),
    ('abdulbasit', 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/'),
    ('sudais', 'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/'),
    ('minshawi', 'https://everyayah.com/data/Minshawy_Murattal_128kbps/'),
    ('husary', 'https://everyayah.com/data/Mahmoud_Khussary_128kbps/'),
    ('shuraim', 'https://everyayah.com/data/Saood_ash-Shuraym_128kbps/'),
  ];
  const candidates = [
    ('maher', 'ماهر المعيقلي', 'Maher Al-Muaiqly', 'MaherAlMuaiqly128kbps'),
    (
      'yasser',
      'ياسر الدوسري',
      'Yasser Ad-Dussary',
      'Yasser_Ad-Dussary_128kbps',
    ),
    ('qatami', 'ناصر القطامي', 'Nasser Al-Qatami', 'Nasser_Alqatami_128kbps'),
    (
      'ajamy',
      'أحمد العجمي',
      'Ahmed Al-Ajamy',
      'ahmed_ibn_ali_al_ajamy_128kbps',
    ),
    (
      'shatri',
      'أبو بكر الشاطري',
      'Abu Bakr Ash-Shatri',
      'Abu_Bakr_Ash-Shaatree_128kbps',
    ),
    ('hudhaify', 'علي الحذيفي', 'Ali Al-Hudhaify', 'Hudhaify_128kbps'),
    ('ayyoub', 'محمد أيوب', 'Muhammad Ayyoub', 'Muhammad_Ayyoub_128kbps'),
    ('akhdar', 'إبراهيم الأخضر', 'Ibrahim Al-Akhdar', 'Ibrahim_Akhdar_32kbps'),
    ('fares', 'فارس عباد', 'Fares Abbad', 'Fares_Abbad_64kbps'),
    ('basfar', 'عبد الله بصفر', 'Abdullah Basfar', 'Abdullah_Basfar_192kbps'),
  ];

  test(
    'legacy order persists and owner-enabled candidates have frozen URLs',
    () {
      expect(QuranReciter.values, hasLength(16));
      expect(QuranReciter.availableValues, QuranReciter.values);
      for (var i = 0; i < legacy.length; i++) {
        final reciter = QuranReciter.values[i];
        expect(reciter.id, legacy[i].$1);
        expect(reciter.baseUrl, legacy[i].$2);
        expect(reciter.isAvailable, isTrue);
      }
      expect(
        () => QuranReciter.availableValues.add(QuranReciter.maher),
        throwsUnsupportedError,
      );
      for (var i = 0; i < candidates.length; i++) {
        final reciter = QuranReciter.values[i + 6];
        expect(
          (reciter.id, reciter.nameAr, reciter.nameEn),
          (candidates[i].$1, candidates[i].$2, candidates[i].$3),
        );
        expect(QuranReciter.fromId(reciter.id), reciter);
        expect(reciter.isAvailable, isTrue);
        expect(reciter.availability, ReciterAvailability.enabledByOwner);
        final base = 'https://everyayah.com/data/${candidates[i].$4}/';
        expect(reciter.baseUrl, base);
        expect(
          QuranAudioService.buildUrl(1, 1, reciter: reciter),
          '${base}001001.mp3',
        );
        expect(
          QuranAudioService.buildUrl(2, 255, reciter: reciter),
          '${base}002255.mp3',
        );
        expect(
          QuranAudioService.buildUrl(114, 6, reciter: reciter),
          '${base}114006.mp3',
        );
      }
    },
  );

  test(
    'saved new reciter loads and selection persists after recreation',
    () async {
      SharedPreferences.setMockInitialValues({
        'quran_selected_reciter_id': 'maher',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = QuranReciterService(prefs);
      expect(service.currentReciter.value, QuranReciter.maher);
      expect(prefs.getString('quran_selected_reciter_id'), 'maher');
      await service.setReciter(QuranReciter.basfar);
      expect(service.currentReciter.value, QuranReciter.basfar);
      expect(prefs.getString('quran_selected_reciter_id'), 'basfar');
      expect(
        QuranReciterService(prefs).currentReciter.value,
        QuranReciter.basfar,
      );
    },
  );
}
