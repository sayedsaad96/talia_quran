import 'package:flutter/material.dart';

enum SocialShareCategory {
  quranAyah,
  azkar,
  dua,
  achievement,
  progress,
  certificate;

  String get defaultBadge {
    switch (this) {
      case SocialShareCategory.quranAyah:
        return 'آية قرآنية';
      case SocialShareCategory.azkar:
        return 'ذِكْر مبارك';
      case SocialShareCategory.dua:
        return 'دعاء مستجاب';
      case SocialShareCategory.achievement:
        return 'إنجاز جديد';
      case SocialShareCategory.progress:
        return 'حصاد اليوم';
      case SocialShareCategory.certificate:
        return 'شهادة إتمام';
    }
  }

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
      case SocialShareCategory.progress:
        return Icons.insights_rounded;
      case SocialShareCategory.certificate:
        return Icons.verified_rounded;
    }
  }
}

enum SocialShareFormat {
  portrait,
  square,
  story;

  String get displayName {
    switch (this) {
      case SocialShareFormat.portrait:
        return 'بطاقة (4:5)';
      case SocialShareFormat.square:
        return 'مربع (1:1)';
      case SocialShareFormat.story:
        return 'ستوري (9:16)';
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
}

class SocialShareData {
  final String content;
  final String? title;
  final String? subtitle;
  final SocialShareCategory category;
  final String? userName;
  final String? customBadge;

  const SocialShareData({
    required this.content,
    required this.category,
    this.title,
    this.subtitle,
    this.userName,
    this.customBadge,
  });

  String get badgeText => customBadge ?? category.defaultBadge;

  String toPlainShareText() {
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
    buffer.write('— تمت المشاركة عبر تطبيق تالية للقرآن الكريم');
    return buffer.toString();
  }
}
