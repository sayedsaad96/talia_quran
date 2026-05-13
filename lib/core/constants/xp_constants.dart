class XpLevel {
  const XpLevel({
    required this.name,
    required this.minXp,
    required this.icon,
    required this.colorHex,
  });

  final String name;
  final int minXp;
  final String icon;
  final int colorHex;
}

class XpConstants {
  const XpConstants._();

  static const Map<String, int> rewards = {
    'ayah_memorized': 10,
    'page_completed': 50,
    'juz_completed': 500,
    'daily_review': 5,
    'perfect_quiz': 25,
    'streak_7': 100,
    'streak_30': 500,
    'first_ayah': 20,
    'recitation_perfect': 15,
    'recitation_good': 8,
  };

  static const List<XpLevel> levels = [
    XpLevel(name: 'مبتدئ', minXp: 0, icon: '🌱', colorHex: 0xFF6B7280),
    XpLevel(name: 'طالب', minXp: 100, icon: '📚', colorHex: 0xFF3B82F6),
    XpLevel(name: 'حافظ', minXp: 500, icon: '⭐', colorHex: 0xFF8B5CF6),
    XpLevel(name: 'شيخ', minXp: 2000, icon: '🏆', colorHex: 0xFFF59E0B),
    XpLevel(name: 'إمام', minXp: 10000, icon: '👑', colorHex: 0xFFEF4444),
  ];
}
