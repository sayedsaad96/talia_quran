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
  const HifzLoaded({required this.surahs, required this.progressMap, this.selectedPath});
  final List<Surah> surahs;
  final Map<int, SurahHifzProgress> progressMap;
  final String? selectedPath;

  @override
  List<Object?> get props => [surahs, progressMap, selectedPath];
}

class HifzError extends HifzState {
  const HifzError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
