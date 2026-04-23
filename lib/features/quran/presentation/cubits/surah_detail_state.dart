part of 'surah_detail_cubit.dart';

abstract class SurahDetailState extends Equatable {
  const SurahDetailState();
  @override
  List<Object?> get props => [];
}

class SurahDetailInitial extends SurahDetailState {
  const SurahDetailInitial();
}

class SurahDetailLoading extends SurahDetailState {
  const SurahDetailLoading();
}

class SurahDetailLoaded extends SurahDetailState {
  const SurahDetailLoaded({required this.detail});
  final SurahDetail detail;
  @override
  List<Object?> get props => [detail];
}

class SurahDetailError extends SurahDetailState {
  const SurahDetailError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
