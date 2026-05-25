import 'package:equatable/equatable.dart';
import 'memorization_entities.dart';

enum MemorizationPath { adult, child }

enum GuardianLinkStatus { none, pending, linked }

enum GuardianOnboardingStatus { required, skipped, completed }

class MemorizationProfile extends Equatable {
  const MemorizationProfile({
    required this.schemaVersion,
    required this.selectedPath,
    required this.guardianLinkStatus,
    required this.guardianOnboardingStatus,
    required this.isParentGuardian,
    required this.createdAt,
    required this.updatedAt,
    this.linkedChildId,
    this.guardianId,
  });

  factory MemorizationProfile.empty() {
    // UTC: profile timestamps must match the UTC policy used everywhere else.
    final now = DateTime.now().toUtc();
    return MemorizationProfile(
      schemaVersion: 1,
      selectedPath: null,
      guardianLinkStatus: GuardianLinkStatus.none,
      guardianOnboardingStatus: GuardianOnboardingStatus.required,
      isParentGuardian: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  final int schemaVersion;
  final MemorizationPath? selectedPath;
  final GuardianLinkStatus guardianLinkStatus;
  final GuardianOnboardingStatus guardianOnboardingStatus;
  final bool isParentGuardian;
  final String? linkedChildId;
  final String? guardianId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasSelectedPath => selectedPath != null;
  bool get isAdult => selectedPath == MemorizationPath.adult;
  bool get isChild => selectedPath == MemorizationPath.child;
  bool get isGuardianLinked => guardianLinkStatus == GuardianLinkStatus.linked;

  MemorizationTrack? get legacyTrack => isAdult
      ? MemorizationTrack.adults
      : (isChild ? MemorizationTrack.kids : null);
  String? get hifzPathValue =>
      isAdult ? 'forward' : (isChild ? 'backward' : null);
  bool get needsGuardianOnboarding =>
      isChild &&
      guardianOnboardingStatus == GuardianOnboardingStatus.required &&
      guardianLinkStatus != GuardianLinkStatus.linked;

  MemorizationProfile copyWith({
    int? schemaVersion,
    MemorizationPath? selectedPath,
    bool clearSelectedPath = false,
    GuardianLinkStatus? guardianLinkStatus,
    GuardianOnboardingStatus? guardianOnboardingStatus,
    bool? isParentGuardian,
    String? linkedChildId,
    bool clearLinkedChildId = false,
    String? guardianId,
    bool clearGuardianId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MemorizationProfile(
    schemaVersion: schemaVersion ?? this.schemaVersion,
    selectedPath: clearSelectedPath
        ? null
        : (selectedPath ?? this.selectedPath),
    guardianLinkStatus: guardianLinkStatus ?? this.guardianLinkStatus,
    guardianOnboardingStatus:
        guardianOnboardingStatus ?? this.guardianOnboardingStatus,
    isParentGuardian: isParentGuardian ?? this.isParentGuardian,
    linkedChildId: clearLinkedChildId
        ? null
        : (linkedChildId ?? this.linkedChildId),
    guardianId: clearGuardianId ? null : (guardianId ?? this.guardianId),
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? DateTime.now().toUtc(),
  );

  @override
  List<Object?> get props => [
    schemaVersion,
    selectedPath,
    guardianLinkStatus,
    guardianOnboardingStatus,
    isParentGuardian,
    linkedChildId,
    guardianId,
    createdAt,
    updatedAt,
  ];
}
