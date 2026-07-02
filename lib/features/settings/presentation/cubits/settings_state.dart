import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../memorization_plus/domain/entities/memorization_entities.dart';

@immutable
class SettingsState extends Equatable {
  const SettingsState({
    this.selectedTrack,
    this.selectedHifzPath,
    this.isParentMode = false,
    this.memorizationProfile,
    this.isLoading = false,
    this.errorMessage,
    this.showMemorizationPathResetSuccess = false,
    this.appVersion,
    this.appBuildNumber,
  });

  final String? selectedTrack;
  final String? selectedHifzPath;
  final bool isParentMode;
  final MemorizationProfile? memorizationProfile;
  final bool isLoading;
  final String? errorMessage;
  final bool showMemorizationPathResetSuccess;
  final String? appVersion;
  final String? appBuildNumber;

  bool get isAdultPath {
    return selectedTrack == 'adults' ||
        memorizationProfile?.selectedPath == MemorizationPath.adult;
  }

  bool get isKidsPath {
    return selectedTrack == 'kids' ||
        memorizationProfile?.selectedPath == MemorizationPath.child;
  }

  bool get shouldShowParentSection {
    return isAdultPath && isParentMode;
  }

  SettingsState copyWith({
    String? selectedTrack,
    String? selectedHifzPath,
    bool? isParentMode,
    MemorizationProfile? memorizationProfile,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? showMemorizationPathResetSuccess,
    String? appVersion,
    String? appBuildNumber,
  }) {
    return SettingsState(
      selectedTrack: selectedTrack ?? this.selectedTrack,
      selectedHifzPath: selectedHifzPath ?? this.selectedHifzPath,
      isParentMode: isParentMode ?? this.isParentMode,
      memorizationProfile: memorizationProfile ?? this.memorizationProfile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      showMemorizationPathResetSuccess:
          showMemorizationPathResetSuccess ??
          this.showMemorizationPathResetSuccess,
      appVersion: appVersion ?? this.appVersion,
      appBuildNumber: appBuildNumber ?? this.appBuildNumber,
    );
  }

  @override
  List<Object?> get props => [
    selectedTrack,
    selectedHifzPath,
    isParentMode,
    memorizationProfile,
    isLoading,
    errorMessage,
    showMemorizationPathResetSuccess,
    appVersion,
    appBuildNumber,
  ];
}
