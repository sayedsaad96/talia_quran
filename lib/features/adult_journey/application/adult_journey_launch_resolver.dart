import '../../../core/identity/account_data_barrier.dart';
import '../../../core/identity/record_owner_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/talia_logger.dart';
import '../domain/entities/adult_journey_suggestion.dart';

/// The memorization destinations resolved fresh at tap time. A projection of
/// `MemorizationNavigationTargets`, so this feature does not depend on the
/// whole navigation resolver.
class AdultMemorizationDestinations {
  const AdultMemorizationDestinations({
    required this.isChild,
    required this.todayPlanLocation,
    required this.reviewQuizLocation,
  });

  final bool isChild;
  final String todayPlanLocation;
  final String reviewQuizLocation;
}

/// Resolves where a suggestion leads at the moment it is tapped (Phase B,
/// spec §6). Memorize and review are re-resolved with the existing
/// `MemorizationNavigationResolver`, never taken from a card built earlier, and
/// their URIs are used as resolved: no `blockSize`, `origin` or `intent` is
/// added or rewritten. A resume reminder opens its section only, never the
/// stored session URL.
///
/// Returns null (no navigation) when the owner changed, the account barrier
/// moved during the lookup, or the current profile is a child.
class AdultJourneyLaunchResolver {
  AdultJourneyLaunchResolver({
    required RecordOwnerProvider owner,
    required AccountDataLease Function() captureLease,
    required Future<AdultMemorizationDestinations> Function()
    memorizationDestinations,
  }) : _owner = owner,
       _captureLease = captureLease,
       _memorization = memorizationDestinations;

  final RecordOwnerProvider _owner;
  final AccountDataLease Function() _captureLease;
  final Future<AdultMemorizationDestinations> Function() _memorization;

  Future<String?> resolve({
    required AdultJourneySuggestion suggestion,
    required String expectedOwnerId,
  }) async {
    if (_owner.currentOwnerId != expectedOwnerId) return null;
    switch (suggestion.launchKind) {
      case AdultJourneyLaunchKind.memorize:
      case AdultJourneyLaunchKind.review:
      case AdultJourneyLaunchKind.setupPlan:
        return _resolveMemorization(suggestion, expectedOwnerId);
      case AdultJourneyLaunchKind.resume:
        return _resumeSection(suggestion.resumeDestination);
      case AdultJourneyLaunchKind.reading:
      case AdultJourneyLaunchKind.khatmah:
      case AdultJourneyLaunchKind.azkar:
      case AdultJourneyLaunchKind.explore:
        // These routes come from the current Home load (page, khatmah) or are
        // fixed section constants; nothing account-owned is looked up here.
        return suggestion.action?.route ?? _section(suggestion.launchKind);
    }
  }

  Future<String?> _resolveMemorization(
    AdultJourneySuggestion suggestion,
    String ownerId,
  ) async {
    final AccountDataLease lease;
    try {
      lease = _captureLease();
    } on AccountDataUnavailableException {
      return null;
    }
    AdultMemorizationDestinations? targets;
    try {
      targets = await _memorization();
    } catch (error, stack) {
      TaliaLogger.w('Adult journey launch lookup failed', error, stack);
    }
    try {
      lease.check();
    } on AccountDataUnavailableException {
      return null;
    }
    if (_owner.currentOwnerId != ownerId) return null;
    // Lookup failed: the hub resolves its own targets safely.
    if (targets == null) return AppRoutes.memorizationHub;
    if (targets.isChild) return null;

    return switch (suggestion.launchKind) {
      AdultJourneyLaunchKind.review => _review(targets.reviewQuizLocation),
      // Without an active plan this already falls back to plan setup.
      AdultJourneyLaunchKind.memorize => targets.todayPlanLocation,
      _ => AppRoutes.memorizationPlusCustomPlan,
    };
  }

  /// With nothing memorized the review target falls back to plan creation;
  /// the hub explains that instead of opening the wrong screen.
  static String _review(String location) =>
      location == AppRoutes.memorizationPlusCustomPlan
      ? AppRoutes.memorizationHub
      : location;

  static String? _resumeSection(AdultResumeDestination? destination) {
    return switch (destination) {
      AdultResumeDestination.memorization => AppRoutes.memorizationHub,
      AdultResumeDestination.quran => AppRoutes.quran,
      AdultResumeDestination.azkar => AppRoutes.azkar,
      AdultResumeDestination.unknown || null => null,
    };
  }

  static String? _section(AdultJourneyLaunchKind kind) {
    return switch (kind) {
      AdultJourneyLaunchKind.reading ||
      AdultJourneyLaunchKind.khatmah ||
      AdultJourneyLaunchKind.explore => AppRoutes.quran,
      AdultJourneyLaunchKind.azkar => AppRoutes.azkar,
      _ => null,
    };
  }
}
