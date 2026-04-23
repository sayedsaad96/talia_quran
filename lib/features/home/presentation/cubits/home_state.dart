part of 'home_cubit.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.progress,
    required this.hifzSurahProgress,
    required this.greeting,
    this.dailyWirdPageDetail,
    this.customPlan,
  });

  final OverallProgress progress;
  final List<SurahHifzProgress> hifzSurahProgress;
  final String greeting; // 'morning' | 'afternoon' | 'evening' | 'night'
  final QuranPageDetail? dailyWirdPageDetail;
  final CustomMemorizationPlan? customPlan;

  @override
  List<Object?> get props => [progress, hifzSurahProgress, greeting, dailyWirdPageDetail, customPlan];
}

class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
