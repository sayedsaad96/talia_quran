import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import 'guardian_linking_state.dart';

class GuardianLinkingCubit extends Cubit<GuardianLinkingState> {
  GuardianLinkingCubit(this._repository)
    : super(const GuardianLinkingInitial());

  final MemorizationPlusRepository _repository;

  Future<void> load() async {
    emit(const GuardianLinkingLoading());
    final profileResult = await _repository.refreshChildGuardianLink();
    await profileResult.fold(
      (failure) async => emit(GuardianLinkingError(failure.message)),
      (profile) async {
        if (profile.isGuardianLinked) {
          emit(GuardianLinkingLinked(profile: profile));
          return;
        }
        final sessionResult = await _repository.refreshPairingSession();
        sessionResult.fold(
          (failure) => emit(GuardianLinkingError(failure.message)),
          (session) {
            if (session == null) {
              emit(GuardianLinkingRequired(profile: profile));
              return;
            }
            _emitSession(session, profile);
          },
        );
      },
    );
  }

  Future<void> continueWithoutGuardian() async {
    emit(const GuardianLinkingLoading());
    final result = await _repository.continueWithoutGuardian();
    result.fold(
      (failure) => emit(GuardianLinkingError(failure.message)),
      (profile) => emit(GuardianLinkingSkipped(profile: profile)),
    );
  }

  Future<void> createPairingSession() async {
    emit(const GuardianLinkingLoading());
    final result = await _repository.createGuardianPairingSession();
    result.fold(
      (failure) => emit(GuardianLinkingBlocked(failure.message)),
      (session) => emit(GuardianLinkingPending(session: session)),
    );
  }

  Future<void> acceptCode(String codeOrQrData) async {
    emit(const GuardianLinkingLoading());
    final result = await _repository.acceptGuardianPairingCode(codeOrQrData);
    result.fold(
      (failure) => emit(GuardianLinkingError(failure.message)),
      (profile) => emit(GuardianLinkingLinked(profile: profile)),
    );
  }

  void _emitSession(PairingSession session, MemorizationProfile profile) {
    switch (session.status) {
      case PairingSessionStatus.pending:
        if (session.isExpired) {
          emit(GuardianLinkingExpired(session: session));
        } else {
          emit(GuardianLinkingPending(session: session));
        }
      case PairingSessionStatus.expired:
        emit(GuardianLinkingExpired(session: session));
      case PairingSessionStatus.used:
        emit(GuardianLinkingUsed(session: session));
      case PairingSessionStatus.completed:
        emit(GuardianLinkingLinked(profile: profile));
      case PairingSessionStatus.cancelled:
        emit(GuardianLinkingRequired(profile: profile));
    }
  }
}
