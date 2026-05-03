import 'package:isar/isar.dart';
import '../../features/xp/data/models/xp_isar.dart';
import '../../features/xp/domain/entities/xp_gain_result.dart';
import '../constants/xp_constants.dart';

class XpService {
  XpService(this._isar);

  final Isar _isar;

  Future<XpGainResult> addXp(String eventKey) async {
    final points = XpConstants.rewards[eventKey] ?? 0;
    if (points == 0) return const XpGainResult.zero();

    return _isar.writeTxn(() async {
      final data = await _isar.xpIsars.get(1) ?? XpIsar();
      final oldLevel = _getLevel(data.totalXp);
      data.totalXp += points;
      final newLevel = _getLevel(data.totalXp);
      await _isar.xpIsars.put(data);

      return XpGainResult(
        xpAdded: points,
        totalXp: data.totalXp,
        leveledUp: newLevel.name != oldLevel.name,
        currentLevel: newLevel,
        progressToNextLevel: _getProgress(data.totalXp),
      );
    });
  }

  Future<int> getTotalXp() async {
    final data = await _isar.xpIsars.get(1);
    return data?.totalXp ?? 0;
  }

  XpLevel getCurrentLevel(int xp) => _getLevel(xp);

  XpLevel _getLevel(int xp) {
    final levels = XpConstants.levels;
    for (int i = levels.length - 1; i >= 0; i--) {
      if (xp >= levels[i].minXp) return levels[i];
    }
    return levels.first;
  }

  double _getProgress(int xp) {
    final levels = XpConstants.levels;
    final current = _getLevel(xp);
    final currentIdx = levels.indexWhere((l) => l.name == current.name);
    if (currentIdx >= levels.length - 1) return 1.0;
    final next = levels[currentIdx + 1];
    final range = next.minXp - current.minXp;
    final progress = xp - current.minXp;
    return (progress / range).clamp(0.0, 1.0);
  }
}
