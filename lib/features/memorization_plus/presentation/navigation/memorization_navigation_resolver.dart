import '../../../../core/router/app_router.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

class MemorizationNavigationTargets {
  const MemorizationNavigationTargets({
    required this.profile,
    required this.todayPlanLocation,
    required this.reviewQuizLocation,
    required this.kidsHomeLocation,
    required this.kidsJourneyLocation,
  });

  final MemorizationProfile? profile;
  final String todayPlanLocation;
  final String reviewQuizLocation;
  final String kidsHomeLocation;
  final String kidsJourneyLocation;
}

class MemorizationNavigationResolver {
  const MemorizationNavigationResolver(this._repository);

  final MemorizationPlusRepository _repository;

  Future<MemorizationNavigationTargets> resolve() async {
    final profile = await _profile();
    final cachedPlanSurahId = await _cachedPlanSurahId();
    final adultPlanSurahId =
        cachedPlanSurahId ?? await _activeAdultPlanSurahId();
    final quizSurahId = await _reviewQuizSurahId(cachedPlanSurahId);
    final kidsSurahId = await _activeKidsSurahId();

    return MemorizationNavigationTargets(
      profile: profile,
      todayPlanLocation: _dailyPlanLocation(adultPlanSurahId),
      reviewQuizLocation: _quizLocation(quizSurahId),
      kidsHomeLocation: _kidsHomeLocation(kidsSurahId),
      kidsJourneyLocation: _kidsJourneyLocation(kidsSurahId),
    );
  }

  Future<String> adultEntryLocation() async {
    final surahId =
        await _cachedPlanSurahId() ?? await _activeAdultPlanSurahId();
    return _dailyPlanLocation(surahId);
  }

  Future<String> childOnboardingLocation() async {
    final profile = await _profile();
    if (profile?.isChild == true) {
      final surahId = await _activeKidsSurahId();
      return _kidsHomeLocation(surahId);
    }
    return '${AppRoutes.memorizationPlus}?preferred=kids';
  }

  Future<String> guardianLinkedLocation() async {
    final surahId = await _activeKidsSurahId();
    return _kidsJourneyLocation(surahId);
  }

  Future<String> parentDashboardLocation() async {
    final surahId = await _activeKidsSurahId();
    if (!_isValidSurahId(surahId)) return AppRoutes.memorizationHub;
    return Uri(
      path: AppRoutes.parentDashboard,
      queryParameters: {'surahId': '$surahId'},
    ).toString();
  }

  Future<MemorizationProfile?> _profile() async {
    final result = await _repository.getMemorizationProfile();
    return result.fold((_) => null, (profile) => profile);
  }

  Future<int?> _activeAdultPlanSurahId() async {
    final customPlan = await _customPlan();
    if (customPlan != null &&
        customPlan.isActive &&
        customPlan.targetUser == PlanTargetUser.adult &&
        _isValidSurahId(customPlan.startSurahId)) {
      return customPlan.startSurahId;
    }

    return null;
  }

  Future<int?> _cachedPlanSurahId() async {
    final cachedPlan = await _cachedPlan();
    return _isValidSurahId(cachedPlan?.surahId) ? cachedPlan!.surahId : null;
  }

  Future<int?> _reviewQuizSurahId(int? adultPlanSurahId) async {
    if (_isValidSurahId(adultPlanSurahId)) return adultPlanSurahId;

    final recordsResult = await _repository.getAllReviewRecords();
    final records = recordsResult.fold((_) => <AyahReviewRecord>[], (records) {
      return records
          .where((record) => record.totalReviews > 0)
          .where((record) => _isValidSurahId(record.surahId))
          .toList()
        ..sort(
          (a, b) =>
              b.lastReviewedAt.toUtc().compareTo(a.lastReviewedAt.toUtc()),
        );
    });

    return records.isEmpty ? null : records.first.surahId;
  }

  Future<int?> _activeKidsSurahId() async {
    final logsResult = await _repository.getKidsSessionLogs();
    final logs = logsResult.fold((_) => <KidsSessionLog>[], (logs) {
      return logs.where((log) => _isValidSurahId(log.surahId)).toList()..sort(
        (a, b) => b.completedAt.toUtc().compareTo(a.completedAt.toUtc()),
      );
    });
    if (logs.isNotEmpty) return logs.first.surahId;

    final customPlan = await _customPlan();
    if (customPlan != null &&
        customPlan.isActive &&
        customPlan.targetUser == PlanTargetUser.child &&
        _isValidSurahId(customPlan.startSurahId)) {
      return customPlan.startSurahId;
    }

    return null;
  }

  Future<DailyPlan?> _cachedPlan() async {
    final result = await _repository.getCachedDailyPlan();
    return result.fold((_) => null, (plan) => plan);
  }

  Future<CustomMemorizationPlan?> _customPlan() async {
    final result = await _repository.getCustomPlan();
    return result.fold((_) => null, (plan) => plan);
  }

  static String _dailyPlanLocation(int? surahId) {
    if (!_isValidSurahId(surahId)) return AppRoutes.memorizationPlusCustomPlan;
    return Uri(
      path: AppRoutes.memorizationPlusDailyPlan,
      queryParameters: {'surahId': '$surahId'},
    ).toString();
  }

  static String _quizLocation(int? surahId) {
    if (!_isValidSurahId(surahId)) return AppRoutes.memorizationPlusCustomPlan;
    return Uri(
      path: AppRoutes.memorizationPlusQuiz,
      queryParameters: {'surahId': '$surahId'},
    ).toString();
  }

  static String _kidsHomeLocation(int? surahId) {
    if (!_isValidSurahId(surahId)) return AppRoutes.memorizationPlusKidsHome;
    return Uri(
      path: AppRoutes.memorizationPlusKidsHome,
      queryParameters: {'surahId': '$surahId'},
    ).toString();
  }

  static String _kidsJourneyLocation(int? surahId) {
    if (!_isValidSurahId(surahId)) return _kidsHomeLocation(null);
    return Uri(
      path: AppRoutes.memorizationPlusKidsJourney,
      queryParameters: {'surahId': '$surahId'},
    ).toString();
  }

  static bool _isValidSurahId(int? surahId) =>
      surahId != null && surahId >= 1 && surahId <= 114;

  /// Safe fallback when a kids screen cannot pop and must return home.
  static String kidsHomeFallbackLocation(int surahId) =>
      _kidsHomeLocation(_isValidSurahId(surahId) ? surahId : 1);
}
