import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import 'guardian_linking_state.dart';

class GuardianLinkingCubit extends Cubit<GuardianLinkingState> {
  GuardianLinkingCubit(
    this._repository, {
    Duration initialLoadTimeout = const Duration(seconds: 12),
  }) : _initialLoadTimeout = initialLoadTimeout,
       super(const GuardianLinkingInitial());

  final MemorizationPlusRepository _repository;
  final Duration _initialLoadTimeout;
  int _loadRequestId = 0;

  Future<void> load() async {
    final requestId = ++_loadRequestId;
    emit(const GuardianLinkingLoading());
    try {
      await _refreshLinkStatus(
        emitPendingSession: true,
        canEmit: () => !isClosed && requestId == _loadRequestId,
      ).timeout(_initialLoadTimeout);
    } on TimeoutException {
      if (isClosed || requestId != _loadRequestId) return;
      _loadRequestId++;
      emit(const GuardianLinkingError.timeout());
    } catch (error) {
      if (isClosed || requestId != _loadRequestId) return;
      emit(GuardianLinkingError(error.toString()));
    }
  }

  Future<void> checkLinkStatus() async {
    await _refreshLinkStatus(emitPendingSession: false);
  }

  Future<void> _refreshLinkStatus({
    required bool emitPendingSession,
    bool Function()? canEmit,
  }) async {
    bool canUpdate() => canEmit?.call() ?? !isClosed;
    void emitIfActive(GuardianLinkingState state) {
      if (canUpdate()) emit(state);
    }

    final profileResult = await _repository.refreshChildGuardianLink();
    await profileResult.fold(
      (failure) async => emitIfActive(GuardianLinkingError(failure.message)),
      (profile) async {
        if (!canUpdate()) return;
        if (profile.isGuardianLinked) {
          emitIfActive(GuardianLinkingLinked(profile: profile));
          return;
        }
        final sessionResult = await _repository.refreshPairingSession();
        sessionResult.fold(
          (failure) => emitIfActive(GuardianLinkingError(failure.message)),
          (session) {
            if (!canUpdate()) return;
            if (session == null) {
              if (emitPendingSession) {
                emitIfActive(GuardianLinkingRequired(profile: profile));
              }
              return;
            }
            if (emitPendingSession ||
                session.status != PairingSessionStatus.pending) {
              _emitSession(session, profile, emitState: emitIfActive);
            }
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

  void _emitSession(
    PairingSession session,
    MemorizationProfile profile, {
    void Function(GuardianLinkingState state)? emitState,
  }) {
    final emitNext = emitState ?? emit;
    switch (session.status) {
      case PairingSessionStatus.pending:
        if (session.isExpired) {
          emitNext(GuardianLinkingExpired(session: session));
        } else {
          emitNext(GuardianLinkingPending(session: session));
        }
      case PairingSessionStatus.expired:
        emitNext(GuardianLinkingExpired(session: session));
      case PairingSessionStatus.used:
        emitNext(GuardianLinkingUsed(session: session));
      case PairingSessionStatus.completed:
        emitNext(GuardianLinkingLinked(profile: profile));
      case PairingSessionStatus.cancelled:
        emitNext(GuardianLinkingRequired(profile: profile));
    }
  }
}
