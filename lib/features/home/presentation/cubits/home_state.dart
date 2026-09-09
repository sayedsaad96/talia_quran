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
    this.isRefreshing = false,
    this.todayChecklist,
    this.ayahOfDay,
    this.streakRisk,
    this.audioResume,
    this.alternativeActions = const [],
    this.occasion = HomeOccasion.none,
    this.hijriLabel = '',
    this.gregorianLabel = '',
    this.activeSlot,
    this.familyChildren = const [],
    this.prayerSnapshot,
    this.weeklyActiveDays = 0,
    this.weeklyActivityCount = 0,
    this.recentBookmarkRoute,
    this.heroMinutes = 0,
    this.continueRecitation,
    this.recentActivity = const [],
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
    bool? isRefreshing,
    TodayChecklist? todayChecklist,
    AyahOfDay? ayahOfDay,
    StreakRisk? streakRisk,
    AudioResumePosition? audioResume,
    List<UnifiedJourneyAction>? alternativeActions,
    HomeOccasion? occasion,
    String? hijriLabel,
    String? gregorianLabel,
    HomeSlotCandidate? activeSlot,
    List<FamilyChildEntry>? familyChildren,
    PrayerTimesSnapshot? prayerSnapshot,
    int? weeklyActiveDays,
    int? weeklyActivityCount,
    String? recentBookmarkRoute,
    int? heroMinutes,
    ContinueRecitation? continueRecitation,
    List<ActivityEvent>? recentActivity,
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
      isRefreshing: isRefreshing ?? this.isRefreshing,
      todayChecklist: todayChecklist ?? this.todayChecklist,
      ayahOfDay: ayahOfDay ?? this.ayahOfDay,
      streakRisk: streakRisk ?? this.streakRisk,
      audioResume: audioResume ?? this.audioResume,
      alternativeActions: alternativeActions ?? this.alternativeActions,
      occasion: occasion ?? this.occasion,
      hijriLabel: hijriLabel ?? this.hijriLabel,
      gregorianLabel: gregorianLabel ?? this.gregorianLabel,
      activeSlot: activeSlot ?? this.activeSlot,
      familyChildren: familyChildren ?? this.familyChildren,
      prayerSnapshot: prayerSnapshot ?? this.prayerSnapshot,
      weeklyActiveDays: weeklyActiveDays ?? this.weeklyActiveDays,
      weeklyActivityCount: weeklyActivityCount ?? this.weeklyActivityCount,
      recentBookmarkRoute: recentBookmarkRoute ?? this.recentBookmarkRoute,
      heroMinutes: heroMinutes ?? this.heroMinutes,
      continueRecitation: continueRecitation ?? this.continueRecitation,
      recentActivity: recentActivity ?? this.recentActivity,
    );
  }

  final OverallProgress progress;
  final String greeting;
  final QuranPageDetail? dailyWirdPageDetail;
  final CustomMemorizationPlan? customPlan;
  final MemorizationTrack? selectedTrack;
  final bool isParentMode;
  final bool isKids;
  final String? lastRestorableLocation;
  final Map<String, int> activityCountsByDay;
  final DateTime activityStartDate;
  final SmartCoachRecommendation? coachRecommendation;
  final int totalXp;
  final KhatmahPlan? activeKhatmah;
  final Object? khatmahError;
  final bool isRefreshing;
  final TodayChecklist? todayChecklist;
  final AyahOfDay? ayahOfDay;
  final StreakRisk? streakRisk;
  final AudioResumePosition? audioResume;
  final List<UnifiedJourneyAction> alternativeActions;
  final HomeOccasion occasion;
  final String hijriLabel;
  final String gregorianLabel;
  final HomeSlotCandidate? activeSlot;
  final List<FamilyChildEntry> familyChildren;
  final PrayerTimesSnapshot? prayerSnapshot;
  final int weeklyActiveDays;
  final int weeklyActivityCount;
  final String? recentBookmarkRoute;
  final int heroMinutes;
  final ContinueRecitation? continueRecitation;
  final List<ActivityEvent> recentActivity;

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

  bool get isFirstRun =>
      progress.readPagesCount == 0 &&
      progress.memorizedAyahs == 0 &&
      activeKhatmah == null &&
      customPlan == null &&
      lastRestorableLocation == null;

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
    isRefreshing,
    todayChecklist,
    ayahOfDay,
    streakRisk,
    audioResume,
    alternativeActions,
    occasion,
    hijriLabel,
    gregorianLabel,
    activeSlot,
    familyChildren,
    prayerSnapshot,
    weeklyActiveDays,
    weeklyActivityCount,
    recentBookmarkRoute,
    heroMinutes,
    continueRecitation,
    recentActivity,
  ];
}

class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
