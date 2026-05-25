import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/entities/memorization_profile.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

part 'memorization_identity_state.dart';

class MemorizationIdentityCubit extends Cubit<MemorizationIdentityState> {
  MemorizationIdentityCubit({required MemorizationPlusRepository repository})
    : _repository = repository,
      super(const MemorizationIdentityInitial());

  final MemorizationPlusRepository _repository;

  Future<void> selectPath(MemorizationPath path) async {
    emit(const MemorizationIdentityLoading());
    final result = await _repository.selectMemorizationPath(path);
    result.fold(
      (failure) => emit(MemorizationIdentityError(message: failure.message)),
      (profile) => emit(MemorizationIdentitySuccess(profile: profile)),
    );
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

