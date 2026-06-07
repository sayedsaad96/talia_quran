import '../../features/streak/domain/entities/streak_entity.dart';

abstract class StreakReader {
  Future<StreakEntity> getStreak();
}
