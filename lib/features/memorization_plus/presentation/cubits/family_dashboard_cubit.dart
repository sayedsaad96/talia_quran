import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../auth/domain/services/account_password_verifier.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../data/datasources/guardian_milestone_seen_store.dart';
import '../../domain/entities/kids_child_policy.dart';
import '../../domain/entities/kids_home_mission.dart';
import '../../domain/entities/kids_journey_path_definition.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/services/guardian_milestone_detector.dart';
import '../../domain/services/kids_progress_snapshot.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';
import '../../domain/usecases/parent_reward_usecases.dart';

part 'family_dashboard_state.dart';

class FamilyDashboardCubit extends Cubit<FamilyDashboardState> {
  FamilyDashboardCubit(
    this._parentAccess,
    this._remoteLink,
    this._getFamilyDashboard, {
    this._accountVerifier,
    this._rewards,
    this._guardianSessionActive,
    this._milestoneStore,
    this._milestonesEnabled,
    this._ayahCounts,
    this._localCertificates,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const FamilyDashboardInitial());

  /// «ما الجديد» (R1: in-app only, found on open and refresh, no background
  /// pull). Without the store, the switch, or the ayah counts nothing is
  /// detected and the store is never read.
  final GuardianMilestoneSeenStore? _milestoneStore;
  final bool Function()? _milestonesEnabled;

  /// Ayah count per surah, needed to know when a surah is complete.
  final Future<Map<int, int>> Function()? _ayahCounts;

  /// Certificates of the child on this device (a linked child's come with the
  /// dashboard).
  final List<CertificateAward> Function()? _localCertificates;
  final DateTime Function() _clock;

  /// True when the guardian already entered the PIN for a session on the
  /// child's device, so the dashboard opens without asking again.
  final bool Function()? _guardianSessionActive;

  final ParentAccessUsecase _parentAccess;
  final ParentRemoteLinkUsecase _remoteLink;
  final GetFamilyDashboardUsecase _getFamilyDashboard;
  final AccountPasswordVerifier? _accountVerifier;
  final ParentRewardUsecase? _rewards;

  /// Email of the signed-in guardian account that can recover a forgotten
  /// PIN, or null when recovery is not possible on this device.
  String? get recoveryAccountEmail => _accountVerifier?.currentEmail;
  int _feedbackEventId = 0;
  bool _addingHomeMission = false;
  int _refreshGeneration = 0;

  int _nextFeedbackEventId() => ++_feedbackEventId;

  Future<void> load() async {
    emit(const FamilyDashboardLoading());
    final settingsResult = await _parentAccess.getSettings();
    final settings = settingsResult.getOrElse(() => const ParentSettings());
    if (!settings.hasPin) {
      await refresh();
      return;
    }
    if (_guardianSessionActive?.call() ?? false) {
      await refresh();
      return;
    }
    emit(FamilyDashboardLocked(settings: settings));
  }

  Future<void> setPin(String pin) async {
    if (!_isValidPin(pin)) {
      final current = state;
      emit(
        FamilyDashboardNeedsPin(
          feedback: const FamilyDashboardFeedback.pinInvalid(),
          feedbackEventId: _nextFeedbackEventId(),
          canSkip: current is FamilyDashboardNeedsPin && current.canSkip,
        ),
      );
      return;
    }
    emit(const FamilyDashboardLoading());
    final result = await _parentAccess.setPin(pin);
    await result.fold(
      (failure) async => emit(FamilyDashboardError(failure.message)),
      (_) async => unlock(pin),
    );
  }

  Future<void> unlock(String pin) async {
    if (!_isValidPin(pin)) {
      final settings = (await _parentAccess.getSettings()).getOrElse(
        () => const ParentSettings(),
      );
      emit(
        FamilyDashboardLocked(
          settings: settings,
          feedback: const FamilyDashboardFeedback.pinInvalid(),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      );
      return;
    }
    emit(const FamilyDashboardLoading());
    final verified = await _parentAccess.verifyPin(pin);
    final ok = verified.getOrElse(() => false);
    if (!ok) {
      final settings = (await _parentAccess.getSettings()).getOrElse(
        () => const ParentSettings(),
      );
      emit(
        FamilyDashboardLocked(
          settings: settings,
          feedback: const FamilyDashboardFeedback.pinIncorrect(),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      );
      return;
    }
    await refresh();
  }

  /// The children show as soon as they are known; linked children's missions
  /// and policy fill in as they arrive. A newer refresh drops this one.
  Future<void> refresh({FamilyDashboardFeedback? feedback}) async {
    final generation = ++_refreshGeneration;
    final previous = state;
    var first = true;
    await for (final result in _getFamilyDashboard.watch()) {
      if (isClosed || generation != _refreshGeneration) return;
      if (first) {
        first = false;
        _applyRefresh(previous, result, feedback);
        continue;
      }
      final latest = state;
      if (latest is! FamilyDashboardLoaded) continue;
      result.fold(
        (_) {},
        (dashboard) => emit(
          FamilyDashboardLoaded(
            dashboard: dashboard,
            feedback: latest.feedback,
            feedbackEventId: latest.feedbackEventId,
            news: latest.news,
          ),
        ),
      );
    }
    if (isClosed || generation != _refreshGeneration) return;
    await _refreshNews(generation);
  }

  bool _newsEnabled() {
    try {
      return _milestoneStore != null && (_milestonesEnabled?.call() ?? false);
    } catch (_) {
      return false;
    }
  }

  /// Finds what is new for each child. A child never looked at before has
  /// everything it already has marked seen without being shown, so old
  /// progress does not arrive as a flood. A child whose data is incomplete
  /// (details still loading, certificates or ayah counts unreadable) is left
  /// alone, so it is not marked seen on partial data.
  Future<void> _refreshNews(int generation) async {
    final latest = state;
    if (latest is! FamilyDashboardLoaded) return;
    final store = _milestoneStore;
    if (store == null || !_newsEnabled()) {
      _emitNews(latest, const []);
      return;
    }
    final items = <GuardianNewsItem>[];
    final Map<int, int>? counts;
    try {
      counts = await _ayahCounts?.call();
    } catch (error, stack) {
      TaliaLogger.w('Milestone ayah counts unreadable', error, stack);
      _emitNews(latest, const []);
      return;
    }
    if (counts == null || counts.isEmpty) {
      _emitNews(latest, const []);
      return;
    }
    final now = _clock();
    // A linked child's policy carries no weekly goal, so every child is
    // measured against this device's weekly goal.
    final goal = latest.dashboard.settings.weeklyGoalSessions;
    for (final entry in latest.dashboard.children) {
      // One child failing must not hide the others.
      try {
        final summary = entry.remoteSummary;
        if (summary?.detailsLoading ?? false) continue;
        final logs = entry.isLocal ? entry.localData?.logs : summary?.logs;
        if (logs == null) continue;
        final certificates = entry.isLocal
            ? (_localCertificates?.call() ?? const <CertificateAward>[])
            : remoteKidsProgressSnapshot(summary!, now: now).certificates;
        final detected = detectGuardianMilestones(
          logs: logs,
          ayahCountBySurah: counts,
          certificates: certificates,
          weeklyGoalSessions: goal,
          now: now,
          rewards: entry.isLocal
              ? (entry.localData?.rewards ?? const [])
              : summary!.rewards,
        );
        final childKey = entry.isLocal ? 'local' : entry.childUserId;
        final fresh = await store.unseen(childKey, detected.map((m) => m.id));
        for (final milestone in detected) {
          if (!fresh.contains(milestone.id)) continue;
          items.add(
            GuardianNewsItem(
              childKey: childKey,
              child: entry,
              milestone: milestone,
            ),
          );
        }
      } catch (error, stack) {
        TaliaLogger.w('Guardian milestones not detected', error, stack);
      }
    }
    if (isClosed || generation != _refreshGeneration) return;
    final current = state;
    if (current is FamilyDashboardLoaded) _emitNews(current, items);
  }

  void _emitNews(FamilyDashboardLoaded current, List<GuardianNewsItem> news) {
    if (current.news == news) return;
    emit(
      current.copyWith(
        feedback: current.feedback,
        feedbackEventId: current.feedbackEventId,
        news: news,
      ),
    );
  }

  /// «تم»: everything shown now is remembered as seen.
  Future<void> dismissNews() async {
    final current = state;
    final store = _milestoneStore;
    if (current is! FamilyDashboardLoaded ||
        store == null ||
        current.news.isEmpty) {
      return;
    }
    final byChild = <String, List<String>>{};
    for (final item in current.news) {
      byChild.putIfAbsent(item.childKey, () => []).add(item.milestone.id);
    }
    _emitNews(current, const []);
    for (final entry in byChild.entries) {
      await store.markSeen(entry.key, entry.value);
    }
  }

  void _applyRefresh(
    FamilyDashboardState previous,
    Either<Failure, FamilyDashboard> result,
    FamilyDashboardFeedback? feedback,
  ) {
    result.fold(
      (failure) {
        // A transient refresh failure must not evict an already-loaded
        // dashboard: the retry path would force the parent back through the
        // PIN gate and blank the screen. Keep the retained data and surface
        // the failure as feedback instead.
        if (previous is FamilyDashboardLoaded) {
          emit(
            previous.copyWith(
              feedback: FamilyDashboardFeedback.failure(failure.message),
              feedbackEventId: _nextFeedbackEventId(),
            ),
          );
          return;
        }
        emit(FamilyDashboardError(failure.message));
      },
      (dashboard) => emit(
        FamilyDashboardLoaded(
          dashboard: dashboard,
          feedback: feedback,
          feedbackEventId: feedback != null ? _nextFeedbackEventId() : 0,
          news: previous is FamilyDashboardLoaded ? previous.news : const [],
        ),
      ),
    );
  }

  /// Ends a linked child's link from the guardian's side. True when the
  /// server took it; the child's device drops the link on its next refresh.
  Future<bool> removeChild(String childUserId) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return false;
    final result = await _remoteLink.removeChild(childUserId);
    if (isClosed) return result.isRight();
    return result.fold(
      (failure) {
        emit(
          current.copyWith(
            feedback: FamilyDashboardFeedback.failure(failure.message),
            feedbackEventId: _nextFeedbackEventId(),
          ),
        );
        return false;
      },
      (_) {
        unawaited(
          refresh(feedback: const FamilyDashboardFeedback.childRemoved()),
        );
        return true;
      },
    );
  }

  Future<void> updateLocalChildNickname(String nickname) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return;
    final name = ChildIdentityPolicy.normalizeNickname(nickname);
    if (name == null) {
      emit(
        current.copyWith(
          feedback: const FamilyDashboardFeedback.failure(
            CubitMessageCodes.childNicknameInvalid,
          ),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      );
      return;
    }
    final newSettings = current.dashboard.settings.copyWith(
      localChildNickname: name,
    );
    final result = await _parentAccess.saveSettings(newSettings);
    await result.fold(
      (failure) async => emit(
        current.copyWith(
          feedback: FamilyDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      ),
      (_) async =>
          refresh(feedback: const FamilyDashboardFeedback.nicknameSaved()),
    );
  }

  /// Replaces the PIN from inside the unlocked dashboard. The locked screen
  /// must never reach this: holding the device is not proof of being the
  /// guardian, so a locked reset goes through [resetForgottenPin].
  /// Guardian correction of a linked child's name and age. The child's device
  /// picks the change up on its next identity pull.
  Future<void> updateRemoteChildIdentity({
    required String childUserId,
    required String nickname,
    required int age,
  }) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return;
    final result = await _remoteLink.updateChildIdentity(
      childUserId: childUserId,
      nickname: nickname,
      age: age,
    );
    await result.fold(
      (failure) async => emit(
        current.copyWith(
          feedback: FamilyDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      ),
      (_) async =>
          refresh(feedback: const FamilyDashboardFeedback.childIdentitySaved()),
    );
  }

  /// Change PIN: the old one is cleared and a new one may be chosen.
  Future<void> resetAccess() async {
    if (state is! FamilyDashboardLoaded) return;
    await _resetPinAndReload();
  }

  /// Asks for a PIN that will lock the dashboard.
  Future<void> lockWithPin() async {
    if (state is! FamilyDashboardLoaded) return;
    emit(const FamilyDashboardNeedsPin(canSkip: true));
  }

  /// Opens the dashboard without creating or verifying a PIN.
  Future<void> skipPin() async {
    final current = state;
    if (current is! FamilyDashboardNeedsPin &&
        current is! FamilyDashboardLocked) {
      return;
    }
    await refresh();
  }

  /// Removes the lock from the dashboard.
  Future<void> removePinLock() async {
    if (state is! FamilyDashboardLoaded) return;
    emit(const FamilyDashboardLoading());
    await _parentAccess.reset();
    await refresh();
  }

  /// Forgotten-PIN recovery: the guardian proves ownership of the signed-in
  /// account with its password before the device PIN is cleared.
  Future<void> resetForgottenPin(String accountPassword) async {
    final current = state;
    if (current is! FamilyDashboardLocked) return;
    final verifier = _accountVerifier;
    final check = verifier == null
        ? AccountPasswordCheck.unavailable
        : await verifier.verify(accountPassword);
    if (isClosed) return;
    if (check != AccountPasswordCheck.verified) {
      emit(
        FamilyDashboardLocked(
          settings: current.settings,
          feedback: check == AccountPasswordCheck.incorrect
              ? const FamilyDashboardFeedback.accountPasswordIncorrect()
              : const FamilyDashboardFeedback.accountCheckUnavailable(),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      );
      return;
    }
    await _resetPinAndReload();
  }

  Future<void> _resetPinAndReload() async {
    emit(const FamilyDashboardLoading());
    await _parentAccess.reset();
    final settings = (await _parentAccess.getSettings()).getOrElse(
      () => const ParentSettings(),
    );
    // A reset that did not go through falls back to the normal gate.
    if (settings.hasPin) {
      await load();
      return;
    }
    emit(const FamilyDashboardNeedsPin(canSkip: true));
  }

  bool _linking = false;

  /// Links the child whose code the guardian scanned or typed. A second
  /// submit while one is running is ignored. The first link turns parent
  /// mode on, so the home and settings show the guardian tools without a
  /// separate toggle.
  Future<void> acceptRemoteToken(String token) async {
    final current = state;
    if (current is! FamilyDashboardLoaded || _linking) return;
    _linking = true;
    try {
      final result = await _remoteLink.acceptChildLinkToken(token);
      if (isClosed) return;
      await result.fold(
        (failure) async => emit(
          current.copyWith(
            feedback: FamilyDashboardFeedback.failure(failure.message),
            feedbackEventId: _nextFeedbackEventId(),
          ),
        ),
        (_) async {
          await _parentAccess.setParentGuardianMode(true);
          await refresh(feedback: const FamilyDashboardFeedback.childLinked());
        },
      );
    } finally {
      _linking = false;
    }
  }

  /// The linked-child transport gates milestone fields through the v2 flag.
  Future<void> addReward(
    String title, {
    String? childId,
    int? milestoneSurahId,
  }) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return;
    if (title.trim().isEmpty) return;

    if (childId != null) {
      // Remote reward for specific child
      final result = await _remoteLink.saveRemoteReward(
        childUserId: childId,
        title: title.trim(),
        milestoneSurahId: milestoneSurahId,
      );
      await result.fold(
        (failure) async => emit(
          current.copyWith(
            feedback: FamilyDashboardFeedback.failure(failure.message),
            feedbackEventId: _nextFeedbackEventId(),
          ),
        ),
        (_) async => refresh(
          feedback: const FamilyDashboardFeedback.remoteRewardAdded(),
        ),
      );
    } else {
      // Global/Local reward
      final result = await _parentAccess.saveReward(
        title.trim(),
        milestoneSurahId: milestoneSurahId,
      );
      await result.fold(
        (failure) async => emit(
          current.copyWith(
            feedback: FamilyDashboardFeedback.failure(failure.message),
            feedbackEventId: _nextFeedbackEventId(),
          ),
        ),
        (_) async =>
            refresh(feedback: const FamilyDashboardFeedback.rewardAdded()),
      );
    }
  }

  /// Opens a locked gift early: [childId] for a linked child, null for the
  /// child on this device.
  Future<void> unlockReward(String rewardId, {String? childId}) => _rewardStep(
    (rewards) => rewards.unlock(rewardId, childUserId: childId),
    const FamilyDashboardFeedback.rewardUnlocked(),
  );

  /// Confirms that a gift the child asked for was handed over.
  Future<void> approveReward(String rewardId, {String? childId}) => _rewardStep(
    (rewards) => rewards.approve(rewardId, childUserId: childId),
    const FamilyDashboardFeedback.rewardApproved(),
  );

  Future<void> _rewardStep(
    Future<Either<Failure, List<ParentReward>>> Function(ParentRewardUsecase)
    step,
    FamilyDashboardFeedback success,
  ) async {
    final rewards = _rewards;
    if (state is! FamilyDashboardLoaded || rewards == null) return;
    final result = await step(rewards);
    if (isClosed) return;
    await result.fold((failure) async {
      final latest = state;
      if (latest is! FamilyDashboardLoaded) return;
      emit(
        latest.copyWith(
          feedback: FamilyDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      );
    }, (_) async => refresh(feedback: success));
  }

  /// Assigns a home mission: remote (RPC) for a linked child, local otherwise.
  Future<void> addHomeMission(String title, {String? childId}) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return;
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    // The server has no idempotency key, so a repeated submit while the first
    // is still in flight would create the mission twice.
    if (_addingHomeMission) return;
    _addingHomeMission = true;

    final Either<Failure, List<KidsHomeMission>> result;
    try {
      result = childId != null
          ? await _remoteLink.createRemoteHomeMission(
              childUserId: childId,
              title: trimmed,
            )
          : await _parentAccess.addLocalHomeMission(trimmed);
    } finally {
      _addingHomeMission = false;
    }
    await result.fold(
      (failure) async => emit(
        current.copyWith(
          feedback: FamilyDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      ),
      (_) async => refresh(),
    );
  }

  /// Marks a reported home mission as seen by the guardian.
  Future<void> acknowledgeHomeMission(String id, {String? childId}) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return;

    final result = childId != null
        ? await _remoteLink.acknowledgeRemoteHomeMission(id)
        : await _parentAccess.acknowledgeLocalHomeMission(id);
    await result.fold(
      (failure) async => emit(
        current.copyWith(
          feedback: FamilyDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      ),
      (_) async => refresh(),
    );
  }

  /// Saves the child policy: the guardian's linked child (CAS with the
  /// version the dashboard read) when [childId] is set, otherwise this
  /// device's child. A conflict shows `kidsPolicyConflict` and reloads the
  /// dashboard so the fresh server values are displayed.
  Future<void> saveChildPolicy(
    KidsChildPolicy policy, {
    String? childId,
  }) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return;

    final result = childId != null
        ? await _remoteLink.saveRemoteChildPolicy(
            childUserId: childId,
            policy: policy,
          )
        : await _parentAccess.saveChildPolicy(policy);
    await result.fold((failure) async {
      if (failure is PolicyConflictFailure) {
        await refresh(
          feedback: FamilyDashboardFeedback.failure(failure.message),
        );
        return;
      }
      emit(
        current.copyWith(
          feedback: FamilyDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      );
    }, (_) async => refresh());
  }

  Future<void> saveSettings(ParentSettings settings) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return;
    final result = await _parentAccess.saveSettings(settings);
    await result.fold(
      (failure) async => emit(
        current.copyWith(
          feedback: FamilyDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      ),
      (_) async =>
          refresh(feedback: const FamilyDashboardFeedback.reminderSaved()),
    );
  }

  Future<bool> setKidsHouseSize(int? count) async {
    final current = state;
    if (current is! FamilyDashboardLoaded ||
        !current.dashboard.children.any((child) => child.isLocal)) {
      return false;
    }
    final outcome = await _parentAccess.setKidsAyahsPerHouse(count);
    if (isClosed) return false;
    return outcome.fold(
      (failure) {
        emit(
          current.copyWith(
            feedback: FamilyDashboardFeedback.failure(failure.message),
            feedbackEventId: _nextFeedbackEventId(),
          ),
        );
        return false;
      },
      (_) {
        unawaited(
          refresh(feedback: const FamilyDashboardFeedback.houseSizeSaved()),
        );
        return true;
      },
    );
  }

  Future<bool> setKidsJourneyPath(KidsJourneyPathId id) async {
    final current = state;
    if (current is! FamilyDashboardLoaded ||
        !current.dashboard.children.any((child) => child.isLocal)) {
      return false;
    }
    final outcome = await _parentAccess.setKidsJourneyPath(id);
    if (isClosed) return false;
    return outcome.fold(
      (failure) {
        emit(
          current.copyWith(
            feedback: FamilyDashboardFeedback.failure(failure.message),
            feedbackEventId: _nextFeedbackEventId(),
          ),
        );
        return false;
      },
      (_) {
        unawaited(refresh());
        return true;
      },
    );
  }

  /// Saves every local-child setting the guardian edited in the settings
  /// sheet, comparing [draft] with [original] (the snapshot the sheet
  /// opened with) so untouched values are not written. Whole-settings
  /// fields are applied to a fresh read, never to the snapshot, and run
  /// before the targeted writes (house size, path, policy), so no step rolls
  /// back another. Stops at the first failure; true when all saved.
  Future<bool> saveLocalChildSettings({
    required ParentSettings original,
    required ParentSettings draft,
    required KidsChildPolicy policy,
  }) async {
    final current = state;
    if (current is! FamilyDashboardLoaded ||
        !current.dashboard.children.any((child) => child.isLocal)) {
      return false;
    }
    final steps = <Future<Either<Failure, Object?>> Function()>[
      if (draft.kidsHifzV2Enabled != original.kidsHifzV2Enabled ||
          draft.reminderEnabled != original.reminderEnabled ||
          draft.reminderHour != original.reminderHour ||
          draft.reminderMinute != original.reminderMinute)
        () async {
          final fresh = await _parentAccess.getSettings();
          return fresh.fold(
            Left.new,
            (stored) => _parentAccess.saveSettings(
              stored.copyWith(
                kidsHifzV2Enabled: draft.kidsHifzV2Enabled,
                reminderEnabled: draft.reminderEnabled,
                reminderHour: draft.reminderHour,
                reminderMinute: draft.reminderMinute,
              ),
            ),
          );
        },
      if (draft.kidsAyahsPerHouse != original.kidsAyahsPerHouse)
        () => _parentAccess.setKidsAyahsPerHouse(draft.kidsAyahsPerHouse),
      if (KidsJourneyPathId.parse(draft.kidsJourneyPathId) !=
          KidsJourneyPathId.parse(original.kidsJourneyPathId))
        () => _parentAccess.setKidsJourneyPath(
          KidsJourneyPathId.parse(draft.kidsJourneyPathId),
        ),
      if (policy != KidsChildPolicy.fromSettings(original))
        () => _parentAccess.saveChildPolicy(policy),
    ];
    for (final step in steps) {
      final failure = (await step()).fold((f) => f, (_) => null);
      if (isClosed) return false;
      if (failure != null) {
        await refresh(
          feedback: FamilyDashboardFeedback.failure(failure.message),
        );
        return false;
      }
    }
    if (steps.isNotEmpty && !isClosed) {
      await refresh(feedback: const FamilyDashboardFeedback.settingsSaved());
    }
    return true;
  }

  bool _isValidPin(String pin) => pin.length == 4 && int.tryParse(pin) != null;
}
