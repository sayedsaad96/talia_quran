enum QuranReciter {
  alafasy(
    id: 'alafasy',
    nameAr: 'مشاري راشد العفاسي',
    nameEn: 'Mishary Rashid Alafasy',
    baseUrl: 'https://everyayah.com/data/Alafasy_128kbps/',
    availability: ReciterAvailability.legacyEnabled,
  ),
  abdulbasit(
    id: 'abdulbasit',
    nameAr: 'عبد الباسط عبد الصمد (مرتل)',
    nameEn: 'Abdul Basit (Murattal)',
    baseUrl: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/',
    availability: ReciterAvailability.legacyEnabled,
  ),
  sudais(
    id: 'sudais',
    nameAr: 'عبد الرحمن السديس',
    nameEn: 'Abdurrahmaan As-Sudais',
    baseUrl: 'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/',
    availability: ReciterAvailability.legacyEnabled,
  ),
  minshawi(
    id: 'minshawi',
    nameAr: 'محمد صديق المنشاوي (مرتل)',
    nameEn: 'Mohamed Siddiq El-Minshawi',
    baseUrl: 'https://everyayah.com/data/Minshawy_Murattal_128kbps/',
    availability: ReciterAvailability.legacyEnabled,
  ),
  husary(
    id: 'husary',
    nameAr: 'محمود خليل الحصري (مرتل)',
    nameEn: 'Mahmoud Khalil Al-Husary',
    baseUrl: 'https://everyayah.com/data/Mahmoud_Khussary_128kbps/',
    availability: ReciterAvailability.legacyEnabled,
  ),
  shuraim(
    id: 'shuraim',
    nameAr: 'سعود الشريم',
    nameEn: 'Saud Ash-Shuraim',
    baseUrl: 'https://everyayah.com/data/Saood_ash-Shuraym_128kbps/',
    availability: ReciterAvailability.legacyEnabled,
  ),
  maher(
    id: 'maher',
    nameAr: 'ماهر المعيقلي',
    nameEn: 'Maher Al-Muaiqly',
    baseUrl: 'https://everyayah.com/data/MaherAlMuaiqly128kbps/',
    availability: ReciterAvailability.enabledByOwner,
  ),
  yasser(
    id: 'yasser',
    nameAr: 'ياسر الدوسري',
    nameEn: 'Yasser Ad-Dussary',
    baseUrl: 'https://everyayah.com/data/Yasser_Ad-Dussary_128kbps/',
    availability: ReciterAvailability.enabledByOwner,
  ),
  qatami(
    id: 'qatami',
    nameAr: 'ناصر القطامي',
    nameEn: 'Nasser Al-Qatami',
    baseUrl: 'https://everyayah.com/data/Nasser_Alqatami_128kbps/',
    availability: ReciterAvailability.enabledByOwner,
  ),
  ajamy(
    id: 'ajamy',
    nameAr: 'أحمد العجمي',
    nameEn: 'Ahmed Al-Ajamy',
    baseUrl: 'https://everyayah.com/data/ahmed_ibn_ali_al_ajamy_128kbps/',
    availability: ReciterAvailability.enabledByOwner,
  ),
  shatri(
    id: 'shatri',
    nameAr: 'أبو بكر الشاطري',
    nameEn: 'Abu Bakr Ash-Shatri',
    baseUrl: 'https://everyayah.com/data/Abu_Bakr_Ash-Shaatree_128kbps/',
    availability: ReciterAvailability.enabledByOwner,
  ),
  hudhaify(
    id: 'hudhaify',
    nameAr: 'علي الحذيفي',
    nameEn: 'Ali Al-Hudhaify',
    baseUrl: 'https://everyayah.com/data/Hudhaify_128kbps/',
    availability: ReciterAvailability.enabledByOwner,
  ),
  ayyoub(
    id: 'ayyoub',
    nameAr: 'محمد أيوب',
    nameEn: 'Muhammad Ayyoub',
    baseUrl: 'https://everyayah.com/data/Muhammad_Ayyoub_128kbps/',
    availability: ReciterAvailability.enabledByOwner,
  ),
  akhdar(
    id: 'akhdar',
    nameAr: 'إبراهيم الأخضر',
    nameEn: 'Ibrahim Al-Akhdar',
    baseUrl: 'https://everyayah.com/data/Ibrahim_Akhdar_32kbps/',
    availability: ReciterAvailability.enabledByOwner,
  ),
  fares(
    id: 'fares',
    nameAr: 'فارس عباد',
    nameEn: 'Fares Abbad',
    baseUrl: 'https://everyayah.com/data/Fares_Abbad_64kbps/',
    availability: ReciterAvailability.enabledByOwner,
  ),
  basfar(
    id: 'basfar',
    nameAr: 'عبد الله بصفر',
    nameEn: 'Abdullah Basfar',
    baseUrl: 'https://everyayah.com/data/Abdullah_Basfar_192kbps/',
    availability: ReciterAvailability.enabledByOwner,
  );

  const QuranReciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required String baseUrl,
    this.availability = ReciterAvailability.blockedPendingReview,
    // Keep the constructor URL label while guarding the public getter.
    // ignore: prefer_initializing_formals
  }) : _baseUrl = baseUrl;

  final String id;
  final String nameAr;
  final String nameEn;
  final String _baseUrl;
  final ReciterAvailability availability;

  bool get isAvailable =>
      availability == ReciterAvailability.legacyEnabled ||
      availability == ReciterAvailability.enabledByOwner;

  void requireAvailable() {
    if (!isAvailable) throw ReciterUnavailableException(this);
  }

  String get baseUrl {
    requireAvailable();
    return _baseUrl;
  }

  static final List<QuranReciter> availableValues = List.unmodifiable(
    QuranReciter.values.where((reciter) => reciter.isAvailable),
  );

  static QuranReciter fromId(String? id) {
    return QuranReciter.values.firstWhere(
      (r) => r.id == id,
      orElse: () => QuranReciter.alafasy,
    );
  }
}

enum ReciterAvailability {
  legacyEnabled,

  /// Owner-authorized runtime access; source and rights reviews are separate.
  enabledByOwner,
  blockedPendingReview,
}

class ReciterUnavailableException implements Exception {
  const ReciterUnavailableException(this.reciter);

  final QuranReciter reciter;

  @override
  String toString() => 'Reciter unavailable: ${reciter.id}';
}
