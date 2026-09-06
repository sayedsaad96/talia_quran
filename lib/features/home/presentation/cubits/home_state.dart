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

enum HomeKhatmahPlanState { none, active, paused }

class HomeLoaded extends HomeState {
  final UnifiedJourneyAction? heroAction;

  const HomeLoaded({
    required this.progress,
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
    this.totalXp = 0,
    this.activeKhatmah,
    this.khatmahError,
  });

  static const Object _khatmahSentinel = Object();

  HomeLoaded copyWith({
    OverallProgress? progress,
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
    int? totalXp,
    Object? activeKhatmah = _khatmahSentinel,
    Object? khatmahError = _khatmahSentinel,
  }) {
    return HomeLoaded(
      progress: progress ?? this.progress,
      greeting: greeting ?? this.greeting,
      dailyWirdPageDetail: dailyWirdPageDetail ?? this.dailyWirdPageDetail,
      customPlan: customPlan ?? this.customPlan,
      selectedTrack: selectedTrack ?? this.selectedTrack,
      isParentMode: isParentMode ?? this.isParentMode,
      isKids: isKids ?? this.isKids,
      lastRestorableLocation:
          lastRestorableLocation ?? this.lastRestorableLocation,
      activityCountsByDay: activityCountsByDay ?? this.activityCountsByDay,
      activityStartDate: activityStartDate ?? this.activityStartDate,
      coachRecommendation: coachRecommendation ?? this.coachRecommendation,
      heroAction: heroAction ?? this.heroAction,
      totalXp: totalXp ?? this.totalXp,
      activeKhatmah: identical(activeKhatmah, _khatmahSentinel)
          ? this.activeKhatmah
          : activeKhatmah as KhatmahPlan?,
      khatmahError: identical(khatmahError, _khatmahSentinel)
          ? this.khatmahError
          : khatmahError,
    );
  }

  final OverallProgress progress;
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
  final int totalXp;
  final KhatmahPlan? activeKhatmah;
  final Object? khatmahError;

  HomeKhatmahPlanState get khatmahPlanState {
    if (activeKhatmah == null) return HomeKhatmahPlanState.none;
    return switch (activeKhatmah!.status) {
      KhatmahStatus.active => HomeKhatmahPlanState.active,
      KhatmahStatus.paused => HomeKhatmahPlanState.paused,
      KhatmahStatus.completed => HomeKhatmahPlanState.none,
    };
  }

  bool get canContinueKhatmahReading =>
      khatmahPlanState == HomeKhatmahPlanState.active;

  @override
  List<Object?> get props => [
    progress,
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
    totalXp,
    activeKhatmah,
    khatmahError,
  ];
}

class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
