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
    this.rewardMessage,
    this.rewardMessageId = 0,
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

  /// A cubit message code for a gift request that did not go through.
  final String? rewardMessage;

  /// Grows with every new [rewardMessage] so the same code shows again.
  final int rewardMessageId;

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
    rewardMessage: rewardMessage,
    rewardMessageId: rewardMessageId ?? this.rewardMessageId,
  );

  @override
  List<Object?> get props => [
    regions,
    certificates,
    rewards,
    homeMissions,
    homeMissionsPaused,
    rewardMessage,
    rewardMessageId,
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
    required KidsCertificatesLoader certificatesLoader,
    ParentRewardUsecase? rewards,
    KidsHomeMissionsUsecase? homeMissions,
    bool Function()? homeMissionsEnabled,
  }) : _certificatesLoader = certificatesLoader,
       _rewards = rewards,
       _homeMissions = homeMissions,
       _homeMissionsEnabled = homeMissionsEnabled,
       super(const KidsTreasuresLoading());

  final MemorizationPlusRepository _memorizationRepository;
  final QuranRepository _quranRepository;
  final KidsCertificatesLoader _certificatesLoader;
  final ParentRewardUsecase? _rewards;
  final KidsHomeMissionsUsecase? _homeMissions;

  /// The guardian policy switch; missing means on.
  final bool Function()? _homeMissionsEnabled;
  final _requesting = <String>{};

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
      final rewards = await _loadRewards();
      final paused = !_missionsEnabled();
      final missions = paused
          ? const <KidsHomeMission>[]
          : await _loadMissions();
      if (isClosed) return;
      emit(
        KidsTreasuresLoaded(
          kidsRegionProgress(memorized),
          certificates,
          rewards: rewards,
          homeMissions: missions,
          homeMissionsPaused: paused,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(const KidsTreasuresError(CubitMessageCodes.errorUnknown));
      }
    }
  }

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
