part of 'home_cubit.dart';

@immutable
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
  final UnifiedJourneyAction? heroAction;

  const HomeLoaded({
    required this.progress,
    required this.hifzSurahProgress,
    required this.greeting,
    this.dailyWirdPageDetail,
    this.customPlan,
    this.selectedTrack,
    this.isParentMode = false,
    this.isKids = false,
    this.lastRestorableLocation,
    this.activityCountsByDay = const {},
    required this.activityStartDate,
    this.coachRecommendation,
    this.heroAction,
  });

  HomeLoaded copyWith({
    OverallProgress? progress,
    List<SurahHifzProgress>? hifzSurahProgress,
    String? greeting,
    QuranPageDetail? dailyWirdPageDetail,
    CustomMemorizationPlan? customPlan,
    MemorizationTrack? selectedTrack,
    bool? isParentMode,
    bool? isKids,
    String? lastRestorableLocation,
    Map<String, int>? activityCountsByDay,
    DateTime? activityStartDate,
    SmartCoachRecommendation? coachRecommendation,
    UnifiedJourneyAction? heroAction,
  }) {
    return HomeLoaded(
      progress: progress ?? this.progress,
      hifzSurahProgress: hifzSurahProgress ?? this.hifzSurahProgress,
      greeting: greeting ?? this.greeting,
      dailyWirdPageDetail: dailyWirdPageDetail ?? this.dailyWirdPageDetail,
      customPlan: customPlan ?? this.customPlan,
      selectedTrack: selectedTrack ?? this.selectedTrack,
      isParentMode: isParentMode ?? this.isParentMode,
      isKids: isKids ?? this.isKids,
      lastRestorableLocation: lastRestorableLocation ?? this.lastRestorableLocation,
      activityCountsByDay: activityCountsByDay ?? this.activityCountsByDay,
      activityStartDate: activityStartDate ?? this.activityStartDate,
      coachRecommendation: coachRecommendation ?? this.coachRecommendation,
      heroAction: heroAction ?? this.heroAction,
    );
  }

  final OverallProgress progress;
  final List<SurahHifzProgress> hifzSurahProgress;
  final String greeting; // 'morning' | 'afternoon' | 'evening' | 'night'
  final QuranPageDetail? dailyWirdPageDetail;
  final CustomMemorizationPlan? customPlan;
  final MemorizationTrack? selectedTrack;
  final bool isParentMode;

  /// Whether the active memorization profile is a child/kids path.
  final bool isKids;

  /// Last restorable GoRouter path, e.g. `/quran/page/42`.
  /// Null when the user has never read anything.
  final String? lastRestorableLocation;
  final Map<String, int> activityCountsByDay;
  final DateTime activityStartDate;
  final SmartCoachRecommendation? coachRecommendation;

  @override
  List<Object?> get props => [
    progress,
    hifzSurahProgress,
    greeting,
    dailyWirdPageDetail,
    customPlan,
    selectedTrack,
    isParentMode,
    isKids,
    lastRestorableLocation,
    activityCountsByDay,
    activityStartDate,
    coachRecommendation,
    heroAction,
  ];
}

class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
