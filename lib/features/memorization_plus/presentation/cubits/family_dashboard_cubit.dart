import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../auth/domain/services/account_password_verifier.dart';
import '../../domain/entities/kids_child_policy.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';
import '../../domain/usecases/parent_reward_usecases.dart';

part 'family_dashboard_state.dart';

class FamilyDashboardCubit extends Cubit<FamilyDashboardState> {
  FamilyDashboardCubit(
    this._parentAccess,
    this._remoteLink,
    this._getFamilyDashboard, {
    AccountPasswordVerifier? accountVerifier,
    ParentRewardUsecase? rewards,
    bool Function()? guardianSessionActive,
    Future<bool> Function()? pinOptional,
  }) : _accountVerifier = accountVerifier,
       _rewards = rewards,
       _guardianSessionActive = guardianSessionActive,
       _pinOptional = pinOptional,
       super(const FamilyDashboardInitial());

  /// True on the guardian's own (adult) phone: the dashboard opens without a
  /// PIN unless the guardian chose to lock it. The child's device always
  /// needs one. Missing means required, the safe side.
  final Future<bool> Function()? _pinOptional;

  Future<bool> _isPinOptional() async {
    try {
      return await _pinOptional?.call() ?? false;
    } catch (_) {
      return false;
    }
  }

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
  int _refreshGeneration = 0;

  int _nextFeedbackEventId() => ++_feedbackEventId;

  Future<void> load() async {
    emit(const FamilyDashboardLoading());
    final settingsResult = await _parentAccess.getSettings();
    final settings = settingsResult.getOrElse(() => const ParentSettings());
    if (!settings.hasPin) {
      if (await _isPinOptional()) {
        await refresh();
        return;
      }
      emit(const FamilyDashboardNeedsPin());
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
          ),
        ),
      );
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

  /// Change PIN: the old one is cleared and a new one is asked for (the
  /// guardian's phone may also continue without one).
  Future<void> resetAccess() async {
    if (state is! FamilyDashboardLoaded) return;
    await _resetPinAndReload();
  }

  /// Guardian's phone only: asks for a PIN that will lock the dashboard.
  Future<void> lockWithPin() async {
    if (state is! FamilyDashboardLoaded || !await _isPinOptional()) return;
    emit(const FamilyDashboardNeedsPin(canSkip: true));
  }

  /// Guardian's phone only: leaves PIN creation and opens the dashboard.
  Future<void> skipPin() async {
    final current = state;
    if (current is! FamilyDashboardNeedsPin || !current.canSkip) return;
    await refresh();
  }

  /// Guardian's phone only: removes the lock, from inside the unlocked
  /// dashboard (holding the locked phone is not enough).
  Future<void> removePinLock() async {
    if (state is! FamilyDashboardLoaded || !await _isPinOptional()) return;
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
    emit(FamilyDashboardNeedsPin(canSkip: await _isPinOptional()));
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

  Future<void> addReward(String title, {String? childId}) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return;
    if (title.trim().isEmpty) return;

    if (childId != null) {
      // Remote reward for specific child
      final result = await _remoteLink.saveRemoteReward(
        childUserId: childId,
        title: title.trim(),
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
      final result = await _parentAccess.saveReward(title.trim());
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

    final result = childId != null
        ? await _remoteLink.createRemoteHomeMission(
            childUserId: childId,
            title: trimmed,
          )
        : await _parentAccess.addLocalHomeMission(trimmed);
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

  bool _isValidPin(String pin) => pin.length == 4 && int.tryParse(pin) != null;
}
