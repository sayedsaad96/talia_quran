import '../../../../core/memorization/pending_ayah_resolver.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/router/app_router.dart';
import '../entities/memorization_entities.dart';
import '../repositories/memorization_plus_repository.dart';
import '../usecases/get_last_reviewed_surah_id_usecase.dart';

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

/// Resolves memorization entry routes (domain layer — may read repository).
class MemorizationNavigationResolver {
  const MemorizationNavigationResolver(
    this._repository, [
    PendingAyahResolver? pendingAyahResolver,
  ]) : _pendingAyahResolver = pendingAyahResolver ?? const PendingAyahResolver();

  final MemorizationPlusRepository _repository;
  final PendingAyahResolver _pendingAyahResolver;

  Future<MemorizationNavigationTargets> resolve() async {
    final profile = await _profile();
    final customPlan = await _customPlan();
    final cachedPlan = await _cachedPlan();
    final reviewRecords = await _reviewRecords(
      profile?.isChild == true
          ? ReviewRecordReadScope.kids
          : ReviewRecordReadScope.adult,
    );
    final cachedPlanSurahId = await _cachedPlanSurahId(customPlan, cachedPlan);
    final adultPlanSurahId =
        cachedPlanSurahId ?? await _activeAdultPlanSurahId(customPlan);
    final quizSurahId = await _reviewQuizSurahId(cachedPlanSurahId);
    final kidsSurahId = await _activeKidsSurahId();

    return MemorizationNavigationTargets(
      profile: profile,
      todayPlanLocation: _v2SessionLocation(
        surahId: adultPlanSurahId,
        intent: PendingAyahIntent.continueDailyPlan,
        cachedPlan: cachedPlan,
        reviewRecords: reviewRecords,
      ),
      reviewQuizLocation: _v2SessionLocation(
        surahId: quizSurahId,
        intent: PendingAyahIntent.reviewSession,
        cachedPlan: cachedPlan,
        reviewRecords: reviewRecords,
      ),
      kidsHomeLocation: _kidsHomeLocation(kidsSurahId),
      kidsJourneyLocation: _kidsJourneyLocation(kidsSurahId),
    );
  }

  Future<String> adultEntryLocation() async {
    final customPlan = await _customPlan();
    final cachedPlan = await _cachedPlan();
    final reviewRecords = await _reviewRecords(ReviewRecordReadScope.adult);
    final surahId =
        await _cachedPlanSurahId(customPlan, cachedPlan) ??
        await _activeAdultPlanSurahId(customPlan);
    return _v2SessionLocation(
      surahId: surahId,
      intent: PendingAyahIntent.continueDailyPlan,
      cachedPlan: cachedPlan,
      reviewRecords: reviewRecords,
    );
  }

  /// Resolves a V2 session URL for Hifz / practice-by-surah (B5).
  Future<String> practiceSurahSessionLocation(
    int surahId, {
    int? surahAyahCount,
  }) async {
    final cachedPlan = await _cachedPlan();
    final reviewRecords = await _reviewRecords(ReviewRecordReadScope.adult);
    return _v2SessionLocation(
      surahId: surahId,
      intent: PendingAyahIntent.practiceSurah,
      cachedPlan: cachedPlan,
      reviewRecords: reviewRecords,
      surahAyahCount: surahAyahCount,
    );
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
    return AppRoutes.familyDashboard;
  }

  Future<MemorizationProfile?> _profile() async {
    final result = await _repository.getMemorizationProfile();
    return result.fold((_) => null, (profile) => profile);
  }

  Future<int?> _activeAdultPlanSurahId([CustomMemorizationPlan? customPlan]) async {
    final plan = customPlan ?? await _customPlan();
    if (plan != null &&
        plan.isActive &&
        plan.targetUser == PlanTargetUser.adult) {
      final entrySurah = plan.startSurahId;
      if (_isValidSurahId(entrySurah)) return entrySurah;
    }

    return null;
  }

  Future<int?> _cachedPlanSurahId([
    CustomMemorizationPlan? customPlan,
    DailyPlan? cachedPlan,
  ]) async {
    final plan = cachedPlan ?? await _cachedPlan();
    final cachedSurahId = plan?.surahId;
    if (!_isValidSurahId(cachedSurahId)) return null;

    final activePlan = customPlan ?? await _customPlan();
    if (activePlan != null &&
        activePlan.isActive &&
        activePlan.targetUser == PlanTargetUser.adult) {
      final lo = activePlan.startSurahId <= activePlan.endSurahId
          ? activePlan.startSurahId
          : activePlan.endSurahId;
      final hi = activePlan.startSurahId <= activePlan.endSurahId
          ? activePlan.endSurahId
          : activePlan.startSurahId;
      final inRange = cachedSurahId! >= lo && cachedSurahId <= hi;
      if (!inRange) return null;
    }

    return cachedSurahId;
  }

  Future<int?> _reviewQuizSurahId(int? adultPlanSurahId) async {
    if (_isValidSurahId(adultPlanSurahId)) return adultPlanSurahId;

    final result = await GetLastReviewedSurahIdUseCase(
      _repository,
    )(ReviewRecordReadScope.adult);
    return result.fold((_) => null, (surahId) => surahId);
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

  Future<List<AyahReviewRecord>> _reviewRecords(
    ReviewRecordReadScope scope,
  ) async {
    final result = await _repository.getAllReviewRecords(scope: scope);
    return result.fold((_) => <AyahReviewRecord>[], (records) => records);
  }

  Future<CustomMemorizationPlan?> _customPlan() async {
    final result = await _repository.getCustomPlan();
    return result.fold((_) => null, (plan) => plan);
  }

  String _v2SessionLocation({
    required int? surahId,
    required PendingAyahIntent intent,
    required DailyPlan? cachedPlan,
    required List<AyahReviewRecord> reviewRecords,
    int? surahAyahCount,
  }) {
    if (!_isValidSurahId(surahId)) return AppRoutes.memorizationPlusCustomPlan;

    final target = _pendingAyahResolver.resolve(
      PendingAyahResolverInput(
        surahId: surahId!,
        intent: intent,
        cachedDailyPlan: cachedPlan,
        reviewRecords: reviewRecords,
        surahAyahCount: surahAyahCount,
      ),
    );

    return Uri(
      path: AppRoutes.memorizationV2Session,
      queryParameters: {
        'surahId': '${target.surahId}',
        'startAyah': '${target.startAyah}',
      },
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

  static String kidsHomeFallbackLocation(int surahId) =>
      _kidsHomeLocation(_isValidSurahId(surahId) ? surahId : 1);
}
