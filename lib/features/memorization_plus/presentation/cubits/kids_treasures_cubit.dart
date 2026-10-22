import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/kids_home_mission.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/services/kids_adventure_regions.dart';
import '../../domain/usecases/kids_home_missions_usecase.dart';
import '../../domain/usecases/parent_reward_usecases.dart';

/// The kids certificates earned so far (synchronous local read).
typedef KidsCertificatesLoader = List<CertificateAward> Function();

sealed class KidsTreasuresState extends Equatable {
  const KidsTreasuresState();

  @override
  List<Object?> get props => const [];
}

final class KidsTreasuresLoading extends KidsTreasuresState {
  const KidsTreasuresLoading();
}

final class KidsTreasuresLoaded extends KidsTreasuresState {
  const KidsTreasuresLoaded(
    this.regions,
    this.certificates, {
    this.rewards = const [],
    this.homeMissions = const [],
    this.homeMissionsPaused = false,
    this.guardianLinked = false,
    this.childName,
    this.rewardMessage,
    this.rewardMessageId = 0,
    this.milestoneProgress = const {},
    this.promiseUnlockedIds = const {},
  });

  final List<KidsRegionProgress> regions;
  final List<CertificateAward> certificates;

  /// The guardian's gifts for this child.
  final List<ParentReward> rewards;

  /// Every open mission from the guardian, not only the one the daily card
  /// has room for.
  final List<KidsHomeMission> homeMissions;

  /// The guardian turned home missions off; the list is replaced by a note.
  final bool homeMissionsPaused;

  /// A guardian follows this child from their own device.
  final bool guardianLinked;

  /// The nickname from kids setup, printed on the child's certificates.
  final String? childName;

  /// A cubit message code for a gift request that did not go through.
  final String? rewardMessage;

  /// Grows with every new [rewardMessage] so the same code shows again.
  final int rewardMessageId;

  /// Saved ayahs of the surah a still-locked gift waits for, by surah id.
  final Map<int, ({int done, int total})> milestoneProgress;

  /// Gifts that opened on this load because their surah was completed.
  final Set<String> promiseUnlockedIds;

  KidsTreasuresLoaded copyWith({
    List<ParentReward>? rewards,
    List<KidsHomeMission>? homeMissions,
    String? rewardMessage,
    int? rewardMessageId,
  }) => KidsTreasuresLoaded(
    regions,
    certificates,
    rewards: rewards ?? this.rewards,
    homeMissions: homeMissions ?? this.homeMissions,
    homeMissionsPaused: homeMissionsPaused,
    guardianLinked: guardianLinked,
    childName: childName,
    rewardMessage: rewardMessage,
    rewardMessageId: rewardMessageId ?? this.rewardMessageId,
    milestoneProgress: milestoneProgress,
    promiseUnlockedIds: promiseUnlockedIds,
  );

  @override
  List<Object?> get props => [
    regions,
    certificates,
    rewards,
    homeMissions,
    homeMissionsPaused,
    guardianLinked,
    childName,
    rewardMessage,
    rewardMessageId,
    milestoneProgress,
    promiseUnlockedIds,
  ];
}

final class KidsTreasuresError extends KidsTreasuresState {
  const KidsTreasuresError(this.message);

  /// A cubit message code, resolved in the UI.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Region progress, earned certificates and the guardian's gifts for the
/// kids «كنوزي» page.
class KidsTreasuresCubit extends Cubit<KidsTreasuresState> {
  KidsTreasuresCubit(
    this._memorizationRepository,
    this._quranRepository, {
    required this._certificatesLoader,
    this._rewards,
    this._homeMissions,
    this._homeMissionsEnabled,
    this._promiseEnabled,
  }) : super(const KidsTreasuresLoading());

  final MemorizationPlusRepository _memorizationRepository;
  final QuranRepository _quranRepository;
  final KidsCertificatesLoader _certificatesLoader;
  final ParentRewardUsecase? _rewards;
  final KidsHomeMissionsUsecase? _homeMissions;

  /// The guardian policy switch; missing means on.
  final bool Function()? _homeMissionsEnabled;

  /// The guardian-promise rollout switch; missing means off.
  final bool Function()? _promiseEnabled;
  final _requesting = <String>{};

  /// A failed read only hides the badge.
  Future<bool> _isGuardianLinked() async {
    try {
      final result = await _memorizationRepository.getMemorizationProfile();
      return result.fold<bool>(
        (_) => false,
        (profile) => profile.isGuardianLinked,
      );
    } catch (_) {
      return false;
    }
  }

  /// A name only personalizes certificates, so a failure just drops it.
  Future<String?> _loadChildName() async {
    try {
      final result = await _memorizationRepository.getParentSettings();
      final name = result
          .fold((_) => null, (settings) => settings.localChildNickname)
          ?.trim();
      return name == null || name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    emit(const KidsTreasuresLoading());
    try {
      final logsResult = await _memorizationRepository.getKidsSessionLogs();
      final surahsResult = await _quranRepository.getSurahs();
      final failure =
          logsResult.fold<String?>((f) => f.message, (_) => null) ??
          surahsResult.fold<String?>((f) => f.message, (_) => null);
      if (failure != null) {
        if (!isClosed) emit(KidsTreasuresError(failure));
        return;
      }
      final logs = logsResult.getOrElse(() => const []);
      final surahs = surahsResult.getOrElse(() => const []);
      final memorized = kidsMemorizedSurahIds(logs, {
        for (final surah in surahs) surah.id: surah.ayahCount,
      });
      final certificates = _certificatesLoader();
      var rewards = await _loadRewards();
      var promiseUnlockedIds = const <String>{};
      var milestoneProgress = const <int, ({int done, int total})>{};
      if (_promiseOn()) {
        final ayahCounts = {
          for (final surah in surahs) surah.id: surah.ayahCount,
        };
        promiseUnlockedIds = await _keepPromises(rewards, memorized);
        if (promiseUnlockedIds.isNotEmpty) rewards = await _loadRewards();
        milestoneProgress = _milestoneProgress(
          rewards,
          kidsMemorizedAyahCounts(logs, ayahCounts),
          ayahCounts,
        );
      }
      final paused = !_missionsEnabled();
      final missions = paused
          ? const <KidsHomeMission>[]
          : await _loadMissions();
      final guardianLinked = await _isGuardianLinked();
      final childName = await _loadChildName();
      if (isClosed) return;
      emit(
        KidsTreasuresLoaded(
          kidsRegionProgress(memorized),
          certificates,
          rewards: rewards,
          homeMissions: missions,
          homeMissionsPaused: paused,
          guardianLinked: guardianLinked,
          childName: childName,
          milestoneProgress: milestoneProgress,
          promiseUnlockedIds: promiseUnlockedIds,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(const KidsTreasuresError(CubitMessageCodes.errorUnknown));
      }
    }
  }

  bool _promiseOn() {
    try {
      return _promiseEnabled?.call() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens, locally and without a PIN, every locked gift whose surah is now
  /// memorized (the condition is the guardian's own promise, already met).
  /// Gifts without a surah, and the guardian's cloud-owned gifts (which never
  /// carry one), are left alone. A refused step just leaves the gift locked.
  Future<Set<String>> _keepPromises(
    List<ParentReward> rewards,
    Set<int> memorized,
  ) async {
    final unlock = _rewards;
    final opened = <String>{};
    if (unlock == null) return opened;
    for (final reward in rewards) {
      final surahId = reward.milestoneSurahId;
      if (reward.origin == ParentRewardOrigin.unknown ||
          reward.status != ParentRewardStatus.locked ||
          surahId == null ||
          !memorized.contains(surahId)) {
        continue;
      }
      try {
        final result = await unlock.unlock(reward.storageIdentity);
        if (result.isRight()) opened.add(reward.id);
      } catch (_) {
        // The gift stays locked; the next load tries again.
      }
    }
    return opened;
  }

  Map<int, ({int done, int total})> _milestoneProgress(
    List<ParentReward> rewards,
    Map<int, int> doneBySurah,
    Map<int, int> totalBySurah,
  ) => {
    for (final reward in rewards)
      if (reward.status == ParentRewardStatus.locked &&
          reward.milestoneSurahId != null &&
          (totalBySurah[reward.milestoneSurahId] ?? 0) > 0)
        reward.milestoneSurahId!: (
          done: doneBySurah[reward.milestoneSurahId] ?? 0,
          total: totalBySurah[reward.milestoneSurahId]!,
        ),
  };

  /// The child asks the guardian for an unlocked gift.
  Future<void> requestReward(String rewardId) async {
    final rewards = _rewards;
    if (rewards == null || !_requesting.add(rewardId)) return;
    try {
      final result = await rewards.request(rewardId);
      if (isClosed) return;
      final current = state;
      if (current is! KidsTreasuresLoaded) return;
      final refreshed = result.isRight() ? await _loadRewards() : null;
      if (isClosed) return;
      emit(
        result.fold(
          (failure) => current.copyWith(
            rewardMessage: failure.message,
            rewardMessageId: current.rewardMessageId + 1,
          ),
          (_) => current.copyWith(rewards: refreshed),
        ),
      );
    } finally {
      _requesting.remove(rewardId);
    }
  }

  /// The child says a home mission is done; the guardian then sees it.
  Future<void> reportHomeMission(String missionId) async {
    final missions = _homeMissions;
    if (missions == null || !_requesting.add('mission:$missionId')) return;
    try {
      final result = await missions.report(missionId);
      if (isClosed) return;
      final current = state;
      if (current is! KidsTreasuresLoaded) return;
      emit(
        result.fold(
          (failure) => current.copyWith(
            rewardMessage: failure.message,
            rewardMessageId: current.rewardMessageId + 1,
          ),
          (open) => current.copyWith(homeMissions: open),
        ),
      );
    } finally {
      _requesting.remove('mission:$missionId');
    }
  }

  bool _missionsEnabled() {
    try {
      return _homeMissionsEnabled?.call() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// A mission read failure hides that section, like the gifts.
  Future<List<KidsHomeMission>> _loadMissions() async {
    final missions = _homeMissions;
    if (missions == null) return const [];
    try {
      return (await missions.open()).getOrElse(() => const []);
    } catch (_) {
      return const [];
    }
  }

  /// A gift read failure hides the gifts section instead of the whole page.
  Future<List<ParentReward>> _loadRewards() async {
    final rewards = _rewards;
    if (rewards == null) return const [];
    try {
      return (await rewards.deviceRewards()).getOrElse(() => const []);
    } catch (_) {
      return const [];
    }
  }
}
