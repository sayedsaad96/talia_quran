import 'package:equatable/equatable.dart';

final class SharePromptState extends Equatable {
  const SharePromptState({
    this.lastShownAt,
    this.dismissCount = 0,
    this.shownCount = 0,
    this.invitesCreated = 0,
    this.educationSeen = false,
  });
  final DateTime? lastShownAt;
  final int dismissCount, shownCount, invitesCreated;
  final bool educationSeen;
  @override
  List<Object?> get props => [
    lastShownAt,
    dismissCount,
    shownCount,
    invitesCreated,
    educationSeen,
  ];
}
