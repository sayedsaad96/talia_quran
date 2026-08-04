enum QuranReciter {
  alafasy(
    id: 'alafasy',
    nameAr: 'مشاري راشد العفاسي',
    nameEn: 'Mishary Rashid Alafasy',
    baseUrl: 'https://everyayah.com/data/Alafasy_128kbps/',
  ),
  abdulbasit(
    id: 'abdulbasit',
    nameAr: 'عبد الباسط عبد الصمد (مرتل)',
    nameEn: 'Abdul Basit (Murattal)',
    baseUrl: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/',
  ),
  sudais(
    id: 'sudais',
    nameAr: 'عبد الرحمن السديس',
    nameEn: 'Abdurrahmaan As-Sudais',
    baseUrl: 'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/',
  ),
  minshawi(
    id: 'minshawi',
    nameAr: 'محمد صديق المنشاوي (مرتل)',
    nameEn: 'Mohamed Siddiq El-Minshawi',
    baseUrl: 'https://everyayah.com/data/Minshawy_Murattal_128kbps/',
  ),
  husary(
    id: 'husary',
    nameAr: 'محمود خليل الحصري (مرتل)',
    nameEn: 'Mahmoud Khalil Al-Husary',
    baseUrl: 'https://everyayah.com/data/Mahmoud_Khussary_128kbps/',
  ),
  shuraim(
    id: 'shuraim',
    nameAr: 'سعود الشريم',
    nameEn: 'Saud Ash-Shuraim',
    baseUrl: 'https://everyayah.com/data/Saood_ash-Shuraym_128kbps/',
  );

  const QuranReciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.baseUrl,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String baseUrl;

  static QuranReciter fromId(String? id) {
    return QuranReciter.values.firstWhere(
      (r) => r.id == id,
      orElse: () => QuranReciter.alafasy,
    );
  }
}
