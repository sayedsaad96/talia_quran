import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

part 'parent_dashboard_state.dart';

class ParentDashboardCubit extends Cubit<ParentDashboardState> {
  ParentDashboardCubit(this._getDashboard, this._parentAccess, this._remoteLink)
    : super(const ParentDashboardInitial());

  final GetParentDashboardUsecase _getDashboard;
  final ParentAccessUsecase _parentAccess;
  final ParentRemoteLinkUsecase _remoteLink;
  int _feedbackEventId = 0;

  int _nextFeedbackEventId() => ++_feedbackEventId;

  Future<void> load({required int surahId}) async {
    emit(const ParentDashboardLoading());
    final settingsResult = await _parentAccess.getSettings();
    final settings = settingsResult.getOrElse(() => const ParentSettings());
    if (!settings.hasPin) {
      emit(ParentDashboardNeedsPin(settings: settings));
      return;
    }
    emit(ParentDashboardLocked(settings: settings, surahId: surahId));
  }

  Future<void> setPin(String pin, {required int surahId}) async {
    if (!_isValidPin(pin)) {
      final settings = (await _parentAccess.getSettings()).getOrElse(
        () => const ParentSettings(),
      );
      emit(
        ParentDashboardNeedsPin(
          settings: settings,
          feedback: const ParentDashboardFeedback.pinInvalid(),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      );
      return;
    }
    emit(const ParentDashboardLoading());
    final result = await _parentAccess.setPin(pin);
    await result.fold(
      (failure) async => emit(ParentDashboardError(failure.message)),
      (_) async => unlock(pin, surahId: surahId),
    );
  }

  Future<void> unlock(String pin, {required int surahId}) async {
    if (!_isValidPin(pin)) {
      final settings = (await _parentAccess.getSettings()).getOrElse(
        () => const ParentSettings(),
      );
      emit(
        ParentDashboardLocked(
          settings: settings,
          surahId: surahId,
          feedback: const ParentDashboardFeedback.pinInvalid(),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      );
      return;
    }
    emit(const ParentDashboardLoading());
    final verified = await _parentAccess.verifyPin(pin);
    final ok = verified.getOrElse(() => false);
    if (!ok) {
      final settings = (await _parentAccess.getSettings()).getOrElse(
        () => const ParentSettings(),
      );
      emit(
        ParentDashboardLocked(
          settings: settings,
          surahId: surahId,
          feedback: const ParentDashboardFeedback.pinIncorrect(),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      );
      return;
    }
    await refresh(surahId: surahId);
  }

  Future<void> refresh({
    required int surahId,
    ParentDashboardFeedback? feedback,
  }) async {
    final dashboardResult = await _getDashboard(
      GetParentDashboardParams(surahId: surahId),
    );
    final remoteResult = await _remoteLink.getRemoteChildren();
    dashboardResult.fold(
      (failure) => emit(ParentDashboardError(failure.message)),
      (dashboard) => emit(
        ParentDashboardLoaded(
          dashboard: dashboard,
          remoteChildren: remoteResult.getOrElse(() => const []),
          surahId: surahId,
          feedback: feedback,
          feedbackEventId: feedback != null ? _nextFeedbackEventId() : 0,
        ),
      ),
    );
  }

  Future<void> addReward(String title) async {
    final current = state;
    if (current is! ParentDashboardLoaded) return;
    final result = await _parentAccess.saveReward(title);
    result.fold(
      (failure) => emit(
        current.copyWith(
          feedback: ParentDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      ),
      (_) => refresh(
        surahId: current.surahId,
        feedback: const ParentDashboardFeedback.rewardAdded(),
      ),
    );
  }

  Future<void> updateReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final current = state;
    if (current is! ParentDashboardLoaded) return;
    final settings = current.dashboard.settings.copyWith(
      reminderEnabled: enabled,
      reminderHour: hour,
      reminderMinute: minute,
    );
    final result = await _parentAccess.saveSettings(settings);
    await result.fold(
      (failure) async => emit(
        current.copyWith(
          feedback: ParentDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      ),
      (_) async {
        final prefs = getIt<SharedPreferences>();
        await prefs.setBool(
          TaliaNotificationService.kidsReminderPreferenceKey,
          enabled,
        );
        await prefs.setInt(
          '${TaliaNotificationService.kidsReminderPreferenceKey}_hour',
          hour,
        );
        await prefs.setInt(
          '${TaliaNotificationService.kidsReminderPreferenceKey}_minute',
          minute,
        );
        final notificationService = getIt<TaliaNotificationService>();
        if (enabled) {
          await notificationService.scheduleKidsReviewReminder(
            hour: hour,
            minute: minute,
          );
        } else {
          await notificationService.cancelKidsReviewReminder();
        }
        await refresh(
          surahId: current.surahId,
          feedback: const ParentDashboardFeedback.reminderSaved(),
        );
      },
    );
  }

  Future<void> addRemoteReward(String childUserId, String title) async {
    final current = state;
    if (current is! ParentDashboardLoaded) return;
    final result = await _remoteLink.saveRemoteReward(
      childUserId: childUserId,
      title: title,
    );
    result.fold(
      (failure) => emit(
        current.copyWith(
          feedback: ParentDashboardFeedback.failure(failure.message),
          feedbackEventId: _nextFeedbackEventId(),
        ),
      ),
      (_) => refresh(
        surahId: current.surahId,
        feedback: const ParentDashboardFeedback.remoteRewardAdded(),
      ),
    );
  }

  Future<void> acceptRemoteToken(String token, {required int surahId}) async {
    // T054: Emit typed linking state so the UI can show targeted feedback.
    emit(ParentDashboardLinking(surahId: surahId));
    final result = await _remoteLink.acceptGuardianPairingCode(token);
    await result.fold(
      (failure) async => emit(ParentDashboardError(failure.message)),
      (_) async => refresh(
        surahId: surahId,
        feedback: const ParentDashboardFeedback.childLinked(),
      ),
    );
  }

  Future<void> disableParentMode({required int surahId}) async {
    // T054: Emit typed unlinking state so the UI can show targeted feedback.
    emit(ParentDashboardUnlinking(surahId: surahId));
    final result = await _parentAccess.setParentGuardianMode(false);
    await result.fold(
      (failure) async => emit(ParentDashboardError(failure.message)),
      (_) async => load(surahId: surahId),
    );
  }

  Future<void> resetAccess({required int surahId}) async {
    emit(const ParentDashboardLoading());
    await _parentAccess.reset();
    await load(surahId: surahId);
  }

  bool _isValidPin(String pin) => pin.length == 4 && int.tryParse(pin) != null;
}
