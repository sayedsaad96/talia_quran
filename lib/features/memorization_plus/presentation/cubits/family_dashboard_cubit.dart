import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../auth/domain/services/account_password_verifier.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

part 'family_dashboard_state.dart';

class FamilyDashboardCubit extends Cubit<FamilyDashboardState> {
  FamilyDashboardCubit(
    this._parentAccess,
    this._remoteLink,
    this._getFamilyDashboard, {
    AccountPasswordVerifier? accountVerifier,
  }) : _accountVerifier = accountVerifier,
       super(const FamilyDashboardInitial());

  final ParentAccessUsecase _parentAccess;
  final ParentRemoteLinkUsecase _remoteLink;
  final GetFamilyDashboardUsecase _getFamilyDashboard;
  final AccountPasswordVerifier? _accountVerifier;

  /// Email of the signed-in guardian account that can recover a forgotten
  /// PIN, or null when recovery is not possible on this device.
  String? get recoveryAccountEmail => _accountVerifier?.currentEmail;
  int _feedbackEventId = 0;

  int _nextFeedbackEventId() => ++_feedbackEventId;

  Future<void> load() async {
    emit(const FamilyDashboardLoading());
    final settingsResult = await _parentAccess.getSettings();
    final settings = settingsResult.getOrElse(() => const ParentSettings());
    if (!settings.hasPin) {
      emit(const FamilyDashboardNeedsPin());
      return;
    }
    emit(FamilyDashboardLocked(settings: settings));
  }

  Future<void> setPin(String pin) async {
    if (!_isValidPin(pin)) {
      emit(
        FamilyDashboardNeedsPin(
          feedback: const FamilyDashboardFeedback.pinInvalid(),
          feedbackEventId: _nextFeedbackEventId(),
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

  Future<void> refresh({FamilyDashboardFeedback? feedback}) async {
    final previous = state;
    final result = await _getFamilyDashboard();
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

  Future<void> removeChild(String childUserId) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return;
    final result = await _remoteLink.removeChild(childUserId);
    await result.fold(
      (failure) async => emit(
        current.copyWith(
          feedback: FamilyDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      ),
      (_) async =>
          refresh(feedback: const FamilyDashboardFeedback.childRemoved()),
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

  Future<void> resetAccess() async {
    if (state is! FamilyDashboardLoaded) return;
    await _resetPinAndReload();
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
    await load();
  }

  Future<void> acceptRemoteToken(String token) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return;
    final result = await _remoteLink.acceptChildLinkToken(token);
    await result.fold(
      (failure) async => emit(
        current.copyWith(
          feedback: FamilyDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      ),
      (_) async =>
          refresh(feedback: const FamilyDashboardFeedback.childLinked()),
    );
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
