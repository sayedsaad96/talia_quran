import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/memorization_entities.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

part 'family_dashboard_state.dart';

class FamilyDashboardCubit extends Cubit<FamilyDashboardState> {
  FamilyDashboardCubit(
    this._parentAccess,
    this._remoteLink,
    this._getFamilyDashboard,
  ) : super(const FamilyDashboardInitial());

  final ParentAccessUsecase _parentAccess;
  final ParentRemoteLinkUsecase _remoteLink;
  final GetFamilyDashboardUsecase _getFamilyDashboard;
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
      final settings = (await _parentAccess.getSettings())
          .getOrElse(() => const ParentSettings());
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
      final settings = (await _parentAccess.getSettings())
          .getOrElse(() => const ParentSettings());
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
    final result = await _getFamilyDashboard();
    result.fold(
      (failure) => emit(FamilyDashboardError(failure.message)),
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
      (_) async => refresh(
        feedback: const FamilyDashboardFeedback.childRemoved(),
      ),
    );
  }

  Future<void> updateLocalChildNickname(String nickname) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return;
    final newSettings = current.dashboard.settings.copyWith(
      localChildNickname: nickname.trim().isEmpty ? null : nickname.trim(),
    );
    final result = await _parentAccess.saveSettings(newSettings);
    await result.fold(
      (failure) async => emit(
        current.copyWith(
          feedback: FamilyDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      ),
      (_) async => refresh(
        feedback: const FamilyDashboardFeedback.nicknameSaved(),
      ),
    );
  }

  Future<void> resetAccess() async {
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
      (_) async => refresh(
        feedback: const FamilyDashboardFeedback.childLinked(),
      ),
    );
  }

  Future<void> addReward(String title, {String? childId}) async {
    final current = state;
    if (current is! FamilyDashboardLoaded) return;
    if (title.trim().isEmpty) return;

    if (childId != null) {
      // Remote reward for specific child
      final result = await _remoteLink.saveRemoteReward(childUserId: childId, title: title.trim());
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
        (_) async => refresh(
          feedback: const FamilyDashboardFeedback.rewardAdded(),
        ),
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
      (_) async => refresh(
        feedback: const FamilyDashboardFeedback.reminderSaved(),
      ),
    );
  }

  bool _isValidPin(String pin) =>
      pin.length == 4 && int.tryParse(pin) != null;
}
