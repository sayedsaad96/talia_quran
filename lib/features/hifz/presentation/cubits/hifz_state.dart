part of 'hifz_cubit.dart';

@immutable
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
    this.selectedPath,
  });
  final List<Surah> surahs;
  final String? selectedPath;

  bool isSurahUnlocked(int surahId) => true;

  @override
  List<Object?> get props => [surahs, selectedPath];
}

class HifzError extends HifzState {
  const HifzError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
