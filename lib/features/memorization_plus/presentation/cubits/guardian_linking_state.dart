import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/memorization_entities.dart';

@immutable
abstract class GuardianLinkingState extends Equatable {
  const GuardianLinkingState();

  @override
  List<Object?> get props => [];
}

class GuardianLinkingInitial extends GuardianLinkingState {
  const GuardianLinkingInitial();
}

class GuardianLinkingLoading extends GuardianLinkingState {
  const GuardianLinkingLoading();
}

class GuardianLinkingRequired extends GuardianLinkingState {
  const GuardianLinkingRequired({required this.profile});
  final MemorizationProfile profile;

  @override
  List<Object?> get props => [profile];
}

class GuardianLinkingPending extends GuardianLinkingState {
  const GuardianLinkingPending({required this.session});
  final PairingSession session;

  @override
  List<Object?> get props => [session];
}

class GuardianLinkingExpired extends GuardianLinkingState {
  const GuardianLinkingExpired({required this.session});
  final PairingSession session;

  @override
  List<Object?> get props => [session];
}

class GuardianLinkingUsed extends GuardianLinkingState {
  const GuardianLinkingUsed({required this.session});
  final PairingSession session;

  @override
  List<Object?> get props => [session];
}

class GuardianLinkingLinked extends GuardianLinkingState {
  const GuardianLinkingLinked({required this.profile});
  final MemorizationProfile profile;

  @override
  List<Object?> get props => [profile];
}

class GuardianLinkingSkipped extends GuardianLinkingState {
  const GuardianLinkingSkipped({required this.profile});
  final MemorizationProfile profile;

  @override
  List<Object?> get props => [profile];
}

class GuardianLinkingBlocked extends GuardianLinkingState {
  const GuardianLinkingBlocked(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

enum GuardianLinkingErrorKind { failure, timeout }

class GuardianLinkingError extends GuardianLinkingState {
  const GuardianLinkingError(
    this.message, {
    this.kind = GuardianLinkingErrorKind.failure,
  });

  const GuardianLinkingError.timeout()
    : message = '',
      kind = GuardianLinkingErrorKind.timeout;

  final String message;
  final GuardianLinkingErrorKind kind;

  @override
  List<Object?> get props => [message, kind];
}
