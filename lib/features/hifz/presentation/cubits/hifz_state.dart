part of 'hifz_cubit.dart';

abstract class HifzState extends Equatable {
  const HifzState();
  @override
  List<Object?> get props => [];
}

class HifzInitial extends HifzState {
  const HifzInitial();
}

class HifzLoading extends HifzState {
  const HifzLoading();
}

class HifzLoaded extends HifzState {
  const HifzLoaded({
    required this.surahs,
    required this.progressMap,
    required this.unlockedSurahIds,
    this.selectedPath,
  });
  final List<Surah> surahs;
  final Map<int, SurahHifzProgress> progressMap;
  final Set<int> unlockedSurahIds;
  final String? selectedPath;

  bool isSurahUnlocked(int surahId) => unlockedSurahIds.contains(surahId);

  @override
  List<Object?> get props {
    final unlockedIds = unlockedSurahIds.toList()..sort();
    return [surahs, progressMap, selectedPath, ...unlockedIds];
  }
}

class HifzError extends HifzState {
  const HifzError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
