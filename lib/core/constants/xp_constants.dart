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

  /// Production XP event keys. Only keys that are awarded at runtime belong here.
  /// Block completion = default V2 block (5 ayahs) × [ayah_memorized] rate.
  static const Map<String, int> rewards = {
    'ayah_memorized': 10,
    'v2_block_completed': 50,
  };

  static const List<XpLevel> levels = [
    XpLevel(name: 'مبتدئ', minXp: 0, icon: '🌱', colorHex: 0xFF6B7280),
    XpLevel(name: 'طالب', minXp: 100, icon: '📚', colorHex: 0xFF3B82F6),
    XpLevel(name: 'حافظ', minXp: 500, icon: '⭐', colorHex: 0xFF8B5CF6),
    XpLevel(name: 'شيخ', minXp: 2000, icon: '🏆', colorHex: 0xFFF59E0B),
    XpLevel(name: 'إمام', minXp: 10000, icon: '👑', colorHex: 0xFFEF4444),
  ];
}
