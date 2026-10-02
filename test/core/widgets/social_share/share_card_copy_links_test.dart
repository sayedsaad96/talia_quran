import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_links.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_copy.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';

void main() {
  final ar = SocialShareCopy.forLanguage('ar');
  final en = SocialShareCopy.forLanguage('en');

  group('ShareCardLinks', () {
    test('builds a campaign URL per category on the landing page', () {
      expect(
        ShareCardLinks.forCategory(SocialShareCategory.quranAyah),
        'https://taliaapp.com/?utm_source=tc&utm_campaign=quranAyah',
      );
    });

    test('never carries anything but the two campaign parameters', () {
      for (final c in SocialShareCategory.values) {
        final uri = Uri.parse(ShareCardLinks.forCategory(c));
        expect(uri.host, 'taliaapp.com');
        expect(uri.queryParameters.keys.toSet(), {
          'utm_source',
          'utm_campaign',
        });
      }
    });
  });

  group('isAzkarWirdProgress', () {
    test('is true only for azkar with empty content', () {
      final wird = SocialShareData.azkarWird(
        categoryTitle: 'أذكار الصباح',
        completedCount: 3,
        totalCount: 10,
      );
      expect(wird.isAzkarWirdProgress, isTrue);
      const zikr = SocialShareData(
        content: 'سُبْحَانَ اللَّهِ',
        category: SocialShareCategory.azkar,
      );
      expect(zikr.isAzkarWirdProgress, isFalse);
      const dua = SocialShareData(
        content: '',
        category: SocialShareCategory.dua,
      );
      expect(dua.isAzkarWirdProgress, isFalse);
    });
  });

  group('SocialShareCopy card copy', () {
    test('wordmark is localized', () {
      expect(ar.wordmark, 'تالية القرآن');
      expect(en.wordmark, 'Talia Quran');
    });

    test('every category has a non-empty invitation in both languages', () {
      for (final c in SocialShareCategory.values) {
        final data = SocialShareData(content: 'x', category: c);
        expect(ar.invitation(data), isNotEmpty, reason: '$c ar');
        expect(en.invitation(data), isNotEmpty, reason: '$c en');
      }
    });

    test('invitations follow the approved copy table', () {
      SocialShareData d(SocialShareCategory c, {String content = 'x'}) =>
          SocialShareData(content: content, category: c);
      expect(
        ar.invitation(d(SocialShareCategory.quranAyah)),
        'شاركها… لعلّها تهدي قلبًا',
      );
      expect(ar.invitation(d(SocialShareCategory.dua)), 'ادعُ بها لمن تحب');
      expect(ar.invitation(d(SocialShareCategory.azkar)), 'ذكّر بها من تحب');
      expect(
        ar.invitation(d(SocialShareCategory.azkar, content: '')),
        'حافظ على أذكارك معي',
      );
      expect(ar.invitation(d(SocialShareCategory.streak)), 'ابدأ وِردك اليوم');
      expect(
        ar.invitation(d(SocialShareCategory.khatmah)),
        'ابدأ ختمتك القادمة',
      );
      expect(
        en.invitation(d(SocialShareCategory.quranAyah)),
        'Share it — it may guide a heart',
      );
      const kids = SocialShareData(
        content: 'x',
        category: SocialShareCategory.quranAyah,
        audience: SocialShareAudience.kids,
      );
      expect(ar.invitation(kids), 'بطلٌ صغير يحفظ القرآن');
    });

    test('eyebrows name the content type', () {
      expect(
        ar.eyebrow(
          const SocialShareData(
            content: 'x',
            category: SocialShareCategory.quranAyah,
          ),
        ),
        'آية قرآنية',
      );
      expect(
        ar.eyebrow(
          const SocialShareData(
            content: 'x',
            title: 'أذكار المساء',
            category: SocialShareCategory.azkar,
          ),
        ),
        'ذِكر، أذكار المساء',
      );
      expect(
        ar.eyebrow(
          SocialShareData.azkarWird(
            categoryTitle: 'أذكار الصباح',
            completedCount: 1,
            totalCount: 2,
          ),
        ),
        'أذكار الصباح',
      );
      expect(
        ar.eyebrow(
          const SocialShareData(
            content: 'x',
            category: SocialShareCategory.streak,
            audience: SocialShareAudience.kids,
          ),
        ),
        'أبطال تالية الصغار',
      );
    });

    test('watermark is the surah name or a category word, never content', () {
      expect(
        ar.watermark(
          const SocialShareData(
            content: 'نص',
            surahName: 'الإسراء',
            category: SocialShareCategory.quranAyah,
          ),
        ),
        'الإسراء',
      );
      expect(
        ar.watermark(
          const SocialShareData(
            content: 'نص',
            category: SocialShareCategory.dua,
          ),
        ),
        'دعاء',
      );
      expect(
        ar.watermark(
          const SocialShareData(
            content: '',
            category: SocialShareCategory.azkar,
          ),
        ),
        isNull,
      );
      expect(
        ar.watermark(
          const SocialShareData(
            content: 'x',
            category: SocialShareCategory.streak,
          ),
        ),
        isNull,
      );
    });

    test('ayah reference combines surah and ayah number', () {
      expect(ar.ayahReference('الإسراء', 9), 'سورة الإسراء، الآية 9');
      expect(en.ayahReference('Al-Isra', 9), 'Surah Al-Isra · Ayah 9');
      expect(ar.ayahReference(null, null), 'القرآن الكريم');
    });

    test('Arabic count words follow number agreement', () {
      expect(ar.streakHeroLabel(1), 'يوم مع القرآن');
      expect(ar.streakHeroLabel(2), 'يومان مع القرآن');
      expect(ar.streakHeroLabel(7), 'أيام مع القرآن');
      expect(ar.streakHeroLabel(45), 'يومًا مع القرآن');
      expect(ar.memorizedAyahsHeroLabel(250), 'آيةً في قلبي');
      expect(ar.surahsCompleted(2), '2 سورتان مكتملتان');
      expect(ar.surahsCompleted(12), '12 سورة مكتملة');
      expect(en.streakHeroLabel(1), 'day with the Quran');
      expect(en.streakHeroLabel(3), 'days with the Quran');
    });

    test('mood names are localized', () {
      expect(SocialShareMood.values.map(ar.moodName), [
        'تلقائي',
        'ليل',
        'نهار',
      ]);
      expect(SocialShareMood.values.map(en.moodName), ['Auto', 'Night', 'Day']);
    });
  });
}
