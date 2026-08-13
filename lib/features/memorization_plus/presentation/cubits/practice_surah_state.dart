part of 'practice_surah_cubit.dart';

@immutable
abstract class PracticeSurahState extends Equatable {
  const PracticeSurahState();
  @override
  List<Object?> get props => [];
}

class PracticeSurahInitial extends PracticeSurahState {
  const PracticeSurahInitial();
}

class PracticeSurahLoading extends PracticeSurahState {
  const PracticeSurahLoading();
}

class PracticeSurahLoaded extends PracticeSurahState {
  const PracticeSurahLoaded({
    required this.surahs,
    this.selectedPath,
  });

  final List<Surah> surahs;
  final String? selectedPath;

  @override
  List<Object?> get props => [surahs, selectedPath];
}

class PracticeSurahError extends PracticeSurahState {
  const PracticeSurahError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}