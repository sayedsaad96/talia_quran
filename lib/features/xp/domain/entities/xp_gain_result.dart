import 'package:equatable/equatable.dart';
import '../../../../core/constants/xp_constants.dart';

class XpGainResult extends Equatable {
  const XpGainResult({
    required this.xpAdded,
    required this.totalXp,
    required this.leveledUp,
    required this.currentLevel,
    required this.progressToNextLevel,
  });

  const XpGainResult.zero()
      : xpAdded = 0,
        totalXp = 0,
        leveledUp = false,
        currentLevel = const XpLevel(
          name: 'مبتدئ', minXp: 0, icon: '🌱', colorHex: 0xFF6B7280,
        ),
        progressToNextLevel = 0.0;

  final int xpAdded;
  final int totalXp;
  final bool leveledUp;
  final XpLevel currentLevel;
  final double progressToNextLevel; // 0.0 → 1.0

  @override
  List<Object?> get props =>
      [xpAdded, totalXp, leveledUp, currentLevel.name, progressToNextLevel];
}
