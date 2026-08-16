import 'package:flutter/material.dart';
import '../../../../features/azkar/domain/entities/azkar_entities.dart';
import '../../../../features/certificate/domain/entities/certificate_award.dart';
import '../../../../features/progress/domain/entities/progress_entities.dart';
import '../../../../features/quran/domain/entities/quran_entities.dart';

/// Categories supported across the Social Share Card System
enum SocialShareCategory {
  quranAyah,
  azkar,
  dua,
  achievement,
  memorization,
  streak,
  progress,
  certificate;

  IconData get icon {
    switch (this) {
      case SocialShareCategory.quranAyah:
        return Icons.menu_book_rounded;
      case SocialShareCategory.azkar:
        return Icons.auto_awesome_rounded;
      case SocialShareCategory.dua:
        return Icons.favorite_rounded;
      case SocialShareCategory.achievement:
        return Icons.emoji_events_rounded;
      case SocialShareCategory.memorization:
        return Icons.psychology_rounded;
      case SocialShareCategory.streak:
        return Icons.local_fire_department_rounded;
      case SocialShareCategory.progress:
        return Icons.insights_rounded;
      case SocialShareCategory.certificate:
        return Icons.verified_rounded;
    }
  }
}

/// The active memorization path controls only the share-card presentation.
/// It is resolved from the existing memorization profile; no progress or
/// achievement rules are calculated by the renderer.
enum SocialShareAudience { adult, kids }

/// Formats for social media export
enum SocialShareFormat {
  portrait, // 1080x1350 (4:5)
  square,   // 1080x1080 (1:1)
  story;    // 1080x1920 (9:16)

  String get nameAr {
    switch (this) {
      case SocialShareFormat.portrait:
        return 'بطاقة (4:5)';
      case SocialShareFormat.square:
        return 'مربع (1:1)';
      case SocialShareFormat.story:
        return 'ستوري (9:16)';
    }
  }

  String get nameEn {
    switch (this) {
      case SocialShareFormat.portrait:
        return 'Post (4:5)';
      case SocialShareFormat.square:
        return 'Square (1:1)';
      case SocialShareFormat.story:
        return 'Story (9:16)';
    }
  }

  IconData get icon {
    switch (this) {
      case SocialShareFormat.portrait:
        return Icons.crop_portrait_rounded;
      case SocialShareFormat.square:
        return Icons.crop_square_rounded;
      case SocialShareFormat.story:
        return Icons.smartphone_rounded;
    }
  }

  /// A fixed logical canvas preserves the requested 1080px export width at
  /// the share renderer's 3x pixel ratio, independent of device size.
  Size get exportLogicalSize {
    switch (this) {
      case SocialShareFormat.portrait:
        return const Size(360, 450);
      case SocialShareFormat.square:
        return const Size(360, 360);
      case SocialShareFormat.story:
        return const Size(360, 640);
    }
  }
}

/// Rich, content-driven domain representation for Social Share Cards
class SocialShareData {
  /// The only official character asset currently shipped with the app.
  /// Contextual pose assets must not be referenced until they exist on disk.
  static const String masterCharacterAsset =
      'assets/images/character/Talia_Master_Character.png';

  final String content;
  final String? title;
  final String? subtitle;
  final SocialShareCategory category;
  final String? userName;
  final String? customBadge;

  // Metadata & specific share attributes
  final String? surahName;
  final int? ayahNumber;
  final int? juzNumber;
  final String? translation;
  final String? achievementId;
  final String? achievementIcon;
  final int? currentValue;
  final int? targetValue;
  final int? readPagesCount;
  final int? memorizedAyahsCount;
  final int? memorizedSurahsCount;
  final int? streakDays;
  final String? verificationCode;
  final bool showCharacter;
  final String? characterAssetPath;
  final SocialShareAudience audience;
  final bool? achievementUnlocked;

  const SocialShareData({
    required this.content,
    required this.category,
    this.title,
    this.subtitle,
    this.userName,
    this.customBadge,
    this.surahName,
    this.ayahNumber,
    this.juzNumber,
    this.translation,
    this.achievementId,
    this.achievementIcon,
    this.currentValue,
    this.targetValue,
    this.readPagesCount,
    this.memorizedAyahsCount,
    this.memorizedSurahsCount,
    this.streakDays,
    this.verificationCode,
    this.showCharacter = false,
    this.characterAssetPath,
    this.audience = SocialShareAudience.adult,
    this.achievementUnlocked,
  });

  /// Factory for Quran Verse share from authentic domain entities
  factory SocialShareData.quranAyah({
    required Ayah ayah,
    required String surahName,
    String? translation,
    String? userName,
    bool showCharacter = false,
  }) {
    return SocialShareData(
      content: ayah.text.trim(),
      category: SocialShareCategory.quranAyah,
      // Labels are supplied by the localized template.  Keep the trusted
      // Quran source text and reference as data rather than presentation copy.
      title: surahName,
      surahName: surahName,
      ayahNumber: ayah.numberInSurah,
      juzNumber: ayah.juz,
      translation: translation,
      userName: userName,
      showCharacter: showCharacter,
      characterAssetPath: masterCharacterAsset,
    );
  }

  /// Factory for sharing a bookmarked Quran verse using raw string data
  /// (e.g., from [BookmarkEntry] where only text, surah name, and number exist).
  factory SocialShareData.quranVerse({
    required String ayahText,
    required String surahName,
    required int ayahNumber,
    String? translation,
    String? userName,
  }) {
    return SocialShareData(
      content: ayahText.trim(),
      category: SocialShareCategory.quranAyah,
      title: surahName,
      surahName: surahName,
      ayahNumber: ayahNumber,
      translation: translation,
      userName: userName,
      characterAssetPath: masterCharacterAsset,
    );
  }

  /// Factory for Achievement share from actual domain model
  factory SocialShareData.achievement({
    required Achievement achievement,
    String? userName,
    String? localizedTitle,
    String? localizedDesc,
    bool showCharacter = false,
  }) {
    return SocialShareData(
      content: localizedDesc ?? achievement.descriptionKey,
      title: localizedTitle ?? achievement.titleKey,
      category: SocialShareCategory.achievement,
      achievementId: achievement.id,
      achievementIcon: achievement.icon,
      currentValue: achievement.currentValue,
      targetValue: achievement.targetValue,
      userName: userName,
      showCharacter: showCharacter,
      characterAssetPath: masterCharacterAsset,
      achievementUnlocked: achievement.isUnlocked,
    );
  }

  /// Factory for Dua / Azkar share from actual domain model
  factory SocialShareData.dua({
    required Zikr zikr,
    String? categoryTitle,
    String? userName,
    bool isDua = true,
    bool showCharacter = false,
  }) {
    return SocialShareData(
      content: zikr.text.trim(),
      title: categoryTitle,
      subtitle: zikr.reference.isNotEmpty ? zikr.reference.trim() : null,
      category: isDua ? SocialShareCategory.dua : SocialShareCategory.azkar,
      translation: zikr.translation.isNotEmpty ? zikr.translation : null,
      userName: userName,
      showCharacter: showCharacter,
      characterAssetPath: masterCharacterAsset,
    );
  }

  /// Factory for Memorization milestone
  factory SocialShareData.memorization({
    required int ayahsCount,
    required int surahsCount,
    String? milestoneTitle,
    String? subtitle,
    String? userName,
    int? targetAyahs,
    bool showCharacter = false,
  }) {
    return SocialShareData(
      content: '',
      title: milestoneTitle,
      subtitle: subtitle,
      category: SocialShareCategory.memorization,
      memorizedAyahsCount: ayahsCount,
      memorizedSurahsCount: surahsCount,
      targetValue: targetAyahs,
      currentValue: ayahsCount,
      userName: userName,
      showCharacter: showCharacter,
      characterAssetPath: masterCharacterAsset,
    );
  }

  /// Factory for Streak & Consistency milestone
  factory SocialShareData.streak({
    required int streakDays,
    int? longestStreak,
    String? userName,
    bool showCharacter = false,
  }) {
    return SocialShareData(
      content: '',
      title: null,
      subtitle: null,
      category: SocialShareCategory.streak,
      streakDays: streakDays,
      currentValue: streakDays,
      targetValue: longestStreak,
      userName: userName,
      showCharacter: showCharacter,
      characterAssetPath: masterCharacterAsset,
    );
  }

  /// Factory for Overall Progress summary
  factory SocialShareData.progress({
    required OverallProgress progress,
    String? userName,
    bool showCharacter = false,
  }) {
    return SocialShareData(
      content: '',
      title: null,
      category: SocialShareCategory.progress,
      readPagesCount: progress.readPagesCount,
      memorizedAyahsCount: progress.memorizedAyahs,
      memorizedSurahsCount: progress.memorizedSurahs,
      streakDays: progress.streakDays,
      userName: userName,
      showCharacter: showCharacter,
      characterAssetPath: masterCharacterAsset,
    );
  }

  /// Factory for Certificate share.  The award title itself is real Arabic
  /// domain data; every surrounding label is localized by the template.
  factory SocialShareData.certificate({
    required CertificateAward award,
    String? userName,
    bool showCharacter = false,
  }) {
    return SocialShareData(
      content: award.titleAr,
      category: SocialShareCategory.certificate,
      verificationCode: award.verificationCode,
      juzNumber: award.juzNumber,
      surahName: award.surahNameAr,
      userName: userName,
      showCharacter: showCharacter,
      characterAssetPath: masterCharacterAsset,
    );
  }

  String get badgeText => customBadge ?? '';

  String get effectiveCharacterAssetPath {
    if (characterAssetPath != null && characterAssetPath!.isNotEmpty) {
      return characterAssetPath!;
    }
    return defaultCharacterAssetFor(category);
  }

  static String defaultCharacterAssetFor(SocialShareCategory category) =>
      masterCharacterAsset;

  SocialShareData copyWith({
    SocialShareAudience? audience,
    bool? showCharacter,
  }) => SocialShareData(
    content: content,
    category: category,
    title: title,
    subtitle: subtitle,
    userName: userName,
    customBadge: customBadge,
    surahName: surahName,
    ayahNumber: ayahNumber,
    juzNumber: juzNumber,
    translation: translation,
    achievementId: achievementId,
    achievementIcon: achievementIcon,
    currentValue: currentValue,
    targetValue: targetValue,
    readPagesCount: readPagesCount,
    memorizedAyahsCount: memorizedAyahsCount,
    memorizedSurahsCount: memorizedSurahsCount,
    streakDays: streakDays,
    verificationCode: verificationCode,
    showCharacter: showCharacter ?? this.showCharacter,
    characterAssetPath: characterAssetPath,
    audience: audience ?? this.audience,
    achievementUnlocked: achievementUnlocked,
  );

  /// Plain-text fallback for channels without image support.  The footer is
  /// parameterized so callers can localize it from presentation code.
  String toPlainShareText({String? footer}) {
    final buffer = StringBuffer();
    if (title != null && title!.isNotEmpty) {
      buffer.writeln(title);
      buffer.writeln();
    }
    buffer.writeln(content);
    if (subtitle != null && subtitle!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(subtitle);
    }
    buffer.writeln();
    buffer.write(footer ?? '— تمت المشاركة عبر تطبيق تالية للقرآن الكريم');
    return buffer.toString();
  }
}

/// Alias for domain consistency
typedef ShareCardData = SocialShareData;
typedef ShareCardType = SocialShareCategory;
