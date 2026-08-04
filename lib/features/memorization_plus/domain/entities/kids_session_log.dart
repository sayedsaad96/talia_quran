import 'package:equatable/equatable.dart';

class KidsSessionLog extends Equatable {
  const KidsSessionLog({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.repeatsCompleted,
    required this.pointsEarned,
    required this.completedAt,
    this.syncedAt,
  });

  final String id;
  final int surahId;
  final int ayahNumber;
  final int repeatsCompleted;
  final int pointsEarned;
  final DateTime completedAt;
  final DateTime? syncedAt;

  bool get isSynced => syncedAt != null;

  KidsSessionLog copyWith({DateTime? syncedAt}) => KidsSessionLog(
    id: id,
    surahId: surahId,
    ayahNumber: ayahNumber,
    repeatsCompleted: repeatsCompleted,
    pointsEarned: pointsEarned,
    completedAt: completedAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );

  @override
  List<Object?> get props => [
    id,
    surahId,
    ayahNumber,
    repeatsCompleted,
    pointsEarned,
    completedAt,
    syncedAt,
  ];
}
