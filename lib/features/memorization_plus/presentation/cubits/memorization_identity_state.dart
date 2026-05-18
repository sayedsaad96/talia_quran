part of 'memorization_identity_cubit.dart';

abstract class MemorizationIdentityState extends Equatable {
  const MemorizationIdentityState();

  @override
  List<Object?> get props => [];
}

class MemorizationIdentityInitial extends MemorizationIdentityState {
  const MemorizationIdentityInitial();
}

class MemorizationIdentityLoading extends MemorizationIdentityState {
  const MemorizationIdentityLoading();
}

class MemorizationIdentitySuccess extends MemorizationIdentityState {
  const MemorizationIdentitySuccess({required this.profile});

  final MemorizationProfile profile;

  @override
  List<Object?> get props => [profile];
}

class MemorizationIdentityError extends MemorizationIdentityState {
  const MemorizationIdentityError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
