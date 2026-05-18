import 'package:equatable/equatable.dart';
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
      emit(const ParentDashboardError('أدخل رمزًا من 4 أرقام'));
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
      emit(const ParentDashboardError('أدخل رمزًا من 4 أرقام'));
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
          message: 'رمز غير صحيح',
        ),
      );
      return;
    }
    await refresh(surahId: surahId);
  }

  Future<void> refresh({required int surahId}) async {
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
        ),
      ),
    );
  }

  Future<void> addReward(String title) async {
    final current = state;
    if (current is! ParentDashboardLoaded) return;
    final result = await _parentAccess.saveReward(title);
    result.fold(
      (failure) => emit(current.copyWith(message: failure.message)),
      (_) => refresh(surahId: current.surahId),
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
      (failure) async => emit(current.copyWith(message: failure.message)),
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
        if (enabled) {
          await TaliaNotificationService.instance.scheduleKidsReviewReminder(
            hour: hour,
            minute: minute,
          );
        } else {
          await TaliaNotificationService.instance.cancelKidsReviewReminder();
        }
        await refresh(surahId: current.surahId);
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
      (failure) => emit(current.copyWith(message: failure.message)),
      (_) => refresh(surahId: current.surahId),
    );
  }

  Future<void> acceptRemoteToken(String token, {required int surahId}) async {
    // T054: Emit typed linking state so the UI can show targeted feedback.
    emit(ParentDashboardLinking(surahId: surahId));
    final result = await _remoteLink.acceptGuardianPairingCode(token);
    await result.fold(
      (failure) async => emit(ParentDashboardError(failure.message)),
      (_) async => refresh(surahId: surahId),
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
