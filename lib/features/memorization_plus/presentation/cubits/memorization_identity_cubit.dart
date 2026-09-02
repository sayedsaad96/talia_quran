import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

part 'memorization_identity_state.dart';

class MemorizationIdentityCubit extends Cubit<MemorizationIdentityState> {
  MemorizationIdentityCubit({
    required MemorizationPlusRepository repository,
    required MemorizationPathResolver pathResolver,
  }) : _repository = repository,
       _pathResolver = pathResolver,
       super(const MemorizationIdentityInitial());

  final MemorizationPlusRepository _repository;
  final MemorizationPathResolver _pathResolver;

  Future<void> selectPath(MemorizationPath path) async {
    emit(const MemorizationIdentityLoading());
    final result = await _repository.selectMemorizationPath(path);
    result.fold(
      (failure) => emit(MemorizationIdentityError(message: failure.message)),
      (profile) {
        _pathResolver.notifyChanged();
        emit(MemorizationIdentitySuccess(profile: profile));
      },
    );
  }

  Future<void> setupChild({
    required String nickname,
    required int age,
    required String pin,
    int reminderHour = 18,
    int reminderMinute = 30,
    int weeklyGoalSessions = 5,
    bool? guidanceAudioEnabled,
    int startingSurahId = 114,
  }) async {
    final trimmedName = nickname.trim();
    if (trimmedName.isEmpty ||
        age < 5 ||
        age > 12 ||
        pin.length != 4 ||
        int.tryParse(pin) == null ||
        reminderHour < 0 ||
        reminderHour > 23 ||
        reminderMinute < 0 ||
        reminderMinute > 59 ||
        weeklyGoalSessions < 1 ||
        weeklyGoalSessions > 7 ||
        startingSurahId < 78 ||
        startingSurahId > 114) {
      emit(const MemorizationIdentityError(message: 'Invalid child setup'));
      return;
    }

    emit(const MemorizationIdentityLoading());
    final selectedResult = await _repository.selectMemorizationPath(
      MemorizationPath.child,
    );
    final selectedFailure = selectedResult.fold(
      (failure) => failure,
      (_) => null,
    );
    if (selectedFailure != null) {
      emit(MemorizationIdentityError(message: selectedFailure.message));
      return;
    }

    final ageResult = await _repository.configureChildAge(age);
    final configuredProfile = ageResult.fold<MemorizationProfile?>((failure) {
      emit(MemorizationIdentityError(message: failure.message));
      return null;
    }, (profile) => profile);
    if (configuredProfile == null) return;

    final settingsResult = await _repository.getParentSettings();
    final settingsFailure = settingsResult.fold(
      (failure) => failure,
      (_) => null,
    );
    if (settingsFailure != null) {
      emit(MemorizationIdentityError(message: settingsFailure.message));
      return;
    }
    final policy = KidsSessionPolicy.forAge(age);
    final settings = settingsResult.getOrElse(() => const ParentSettings());
    final saveSettingsResult = await _repository.saveParentSettings(
      settings.copyWith(
        localChildNickname: trimmedName,
        reminderEnabled: true,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        weeklyGoalSessions: weeklyGoalSessions,
        guidanceAudioEnabled:
            guidanceAudioEnabled ?? policy.guidanceAudioDefault,
        sessionGoalMinutes: policy.maxSessionMinutes,
        startingSurahId: startingSurahId,
        kidsHifzV2Enabled: true,
      ),
    );
    final settingsSaveFailure = saveSettingsResult.fold(
      (failure) => failure,
      (_) => null,
    );
    if (settingsSaveFailure != null) {
      emit(MemorizationIdentityError(message: settingsSaveFailure.message));
      return;
    }

    final pinResult = await _repository.setParentPin(pin);
    final pinFailure = pinResult.fold((failure) => failure, (_) => null);
    if (pinFailure != null) {
      emit(MemorizationIdentityError(message: pinFailure.message));
      return;
    }

    _pathResolver.notifyChanged();
    emit(MemorizationIdentitySuccess(profile: configuredProfile));
  }

  Future<void> checkCurrentIdentity() async {
    emit(const MemorizationIdentityLoading());
    final result = await _repository.getMemorizationProfile();
    result.fold(
      (failure) => emit(MemorizationIdentityError(message: failure.message)),
      (profile) {
        if (profile.hasSelectedPath) {
          emit(MemorizationIdentitySuccess(profile: profile));
        } else {
          emit(const MemorizationIdentityInitial());
        }
      },
    );
  }
}
