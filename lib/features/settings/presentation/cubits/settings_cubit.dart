import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository, this._prefs, this._pathResolver)
    : super(const SettingsState());

  final MemorizationPlusRepository _repository;
  final SharedPreferences _prefs;
  final MemorizationPathResolver _pathResolver;

  Future<void> load({bool showPathResetSuccess = false}) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        showMemorizationPathResetSuccess: false,
      ),
    );

    final profileResult = await _repository.getMemorizationProfile();
    final profile = profileResult.fold((_) => null, (profile) => profile);

    emit(
      SettingsState(
        memorizationProfile: profile,
        selectedTrack:
            profile?.legacyTrack?.name ?? _prefs.getString('mem_plus_track'),
        selectedHifzPath: _prefs.getString(AppConstants.kHifzPathMode),
        isParentMode:
            profile?.isParentGuardian ??
            _prefs.getBool('mem_plus_is_parent_mode') ??
            false,
        showMemorizationPathResetSuccess: showPathResetSuccess,
      ),
    );
  }

  Future<void> toggleParentMode(bool value) async {
    final result = await _repository.setParentGuardianMode(value);
    final failure = result.fold((failure) => failure, (_) => null);
    if (failure != null) {
      emit(
        state.copyWith(
          errorMessage: failure.message,
          showMemorizationPathResetSuccess: false,
        ),
      );
      return;
    }

    await load();
    emit(state.copyWith(isParentMode: value));
  }

  Future<void> resetMemorizationIdentity() async {
    final result = await _repository.resetMemorizationIdentity();
    final failure = result.fold((failure) => failure, (_) => null);
    if (failure != null) {
      emit(
        state.copyWith(
          errorMessage: failure.message,
          showMemorizationPathResetSuccess: false,
        ),
      );
      return;
    }

    _pathResolver.notifyChanged();
    await load(showPathResetSuccess: true);
  }

  void clearTransientMessages() {
    emit(
      state.copyWith(clearError: true, showMemorizationPathResetSuccess: false),
    );
  }
}
