import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/active_invite_sessions.dart';
import '../../domain/entities/invite_activity_target.dart';
import '../../domain/entities/invite_types.dart';
import '../../domain/repositories/share_good_repository.dart';
import '../../domain/services/invite_target_labeler.dart';

sealed class InvitePreviewState extends Equatable {
  const InvitePreviewState();
  @override
  List<Object?> get props => [];
}

class InvitePreviewLoading extends InvitePreviewState {
  const InvitePreviewLoading();
}

class InvitePreviewReady extends InvitePreviewState {
  const InvitePreviewReady(this.session, this.label);
  final InviteSession session;
  final InviteTargetLabel label;
  @override
  List<Object?> get props => [session, label];
}

class InvitePreviewExpired extends InvitePreviewState {
  const InvitePreviewExpired(this.label, this.target);
  final InviteTargetLabel? label;
  final InviteActivityTarget? target;
  @override
  List<Object?> get props => [label, target];
}

class InvitePreviewInvalid extends InvitePreviewState {
  const InvitePreviewInvalid();
}

class InvitePreviewUnavailable extends InvitePreviewState {
  const InvitePreviewUnavailable(this.target);
  final InviteActivityTarget? target;
  @override
  List<Object?> get props => [target];
}

class InvitePreviewOffline extends InvitePreviewState {
  const InvitePreviewOffline();
}

class InvitePreviewKidsBlocked extends InvitePreviewState {
  const InvitePreviewKidsBlocked(this.target);
  final InviteActivityTarget? target;
  @override
  List<Object?> get props => [target];
}

class InvitePreviewCubit extends Cubit<InvitePreviewState> {
  InvitePreviewCubit({
    required this._repository,
    required this._labeler,
    required this._activeSessions,
    required this._isChild,
    required this._cachedSession,
    this.arabic = true,
  }) : super(const InvitePreviewLoading());
  final ShareGoodRepository _repository;
  final InviteTargetLabeler _labeler;
  final ActiveInviteSessions _activeSessions;
  final Future<bool> Function() _isChild;
  final Future<InviteSession?> Function(String) _cachedSession;
  final bool arabic;
  int _generation = 0;
  final _opened = <String>{};
  final _opening = <String, Future<Either<ShareGoodFailure, InviteSession>>>{};
  static final _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

  Future<void> load(String token) async {
    final generation = ++_generation;
    emit(const InvitePreviewLoading());
    if (!_tokenPattern.hasMatch(token)) {
      emit(const InvitePreviewInvalid());
      return;
    }
    try {
      if (await _isChild()) {
        InviteSession? cached;
        try {
          cached = await _cachedSession(token);
        } catch (_) {
          // A missing or inaccessible cache must still block child access.
        }
        if (!isClosed && generation == _generation) {
          emit(InvitePreviewKidsBlocked(cached?.snapshot.target));
        }
        return;
      }
      if (isClosed || generation != _generation) return;
      final resolved = await _repository.resolve(token);
      if (isClosed || generation != _generation) return;
      await resolved.fold(
        (failure) => _showFailure(failure, token, generation),
        (session) => _showSession(session, generation),
      );
    } catch (_) {
      if (!isClosed && generation == _generation) {
        emit(const InvitePreviewUnavailable(null));
      }
    }
  }

  Future<void> _showFailure(
    ShareGoodFailure failure,
    String token,
    int generation,
  ) async {
    if (failure == ShareGoodFailure.expired) {
      final cached = await _cachedSession(token);
      await _showExpired(cached?.snapshot.target, generation);
      return;
    }
    emit(switch (failure) {
      ShareGoodFailure.invalidInvite => const InvitePreviewInvalid(),
      ShareGoodFailure.network => const InvitePreviewOffline(),
      ShareGoodFailure.notEligible => const InvitePreviewKidsBlocked(null),
      _ => const InvitePreviewUnavailable(null),
    });
  }

  Future<void> _showSession(InviteSession session, int generation) async {
    final snapshot = session.snapshot;
    if (snapshot.status == InviteLifecycleStatus.revoked) {
      emit(const InvitePreviewInvalid());
      return;
    }
    if (snapshot.status == InviteLifecycleStatus.expired ||
        !snapshot.expiresAt.isAfter(DateTime.now())) {
      await _showExpired(snapshot.target, generation);
      return;
    }
    final result = await _labeler.label(snapshot.target, arabic: arabic);
    if (isClosed || generation != _generation) return;
    await result.fold(
      (_) async => emit(const InvitePreviewUnavailable(null)),
      (label) => _showReady(session, label, generation),
    );
  }

  Future<void> _showReady(
    InviteSession session,
    InviteTargetLabel label,
    int generation,
  ) async {
    if (session.serverStatus != null ||
        session.pendingStatus != null ||
        _opened.contains(session.token)) {
      emit(InvitePreviewReady(session, label));
      return;
    }
    final opened = await _open(session.token);
    if (isClosed || generation != _generation) return;
    await opened.fold((failure) async {
      if (failure == ShareGoodFailure.expired) {
        await _showExpired(session.snapshot.target, generation);
        return;
      }
      await _showFailure(failure, session.token, generation);
    }, (current) async => emit(InvitePreviewReady(current, label)));
  }

  Future<Either<ShareGoodFailure, InviteSession>> _open(String token) async {
    final pending = _opening[token] ??= _repository.advance(
      token,
      InviteParticipationStatus.opened,
    );
    try {
      final result = await pending;
      if (result.isRight()) _opened.add(token);
      return result;
    } finally {
      if (identical(_opening[token], pending)) {
        unawaited(_opening.remove(token));
      }
    }
  }

  Future<void> _showExpired(
    InviteActivityTarget? target,
    int generation,
  ) async {
    InviteTargetLabel? label;
    if (target != null) {
      final result = await _labeler.label(target, arabic: arabic);
      label = result.fold((_) => null, (value) => value);
      if (label == null) target = null;
    }
    if (!isClosed && generation == _generation) {
      emit(InvitePreviewExpired(label, target));
    }
  }

  Future<String?> startActivity() async {
    final current = state;
    final generation = _generation;
    if (current is! InvitePreviewReady) return null;
    try {
      final child = await _isChild();
      if (isClosed || generation != _generation) return null;
      if (child) {
        emit(const InvitePreviewKidsBlocked(null));
        return null;
      }
      final server = current.session.serverStatus?.index ?? -1;
      final pending = current.session.pendingStatus?.index ?? -1;
      if (server >= InviteParticipationStatus.completedPrivate.index ||
          pending >= InviteParticipationStatus.completedPrivate.index) {
        return _route(current.session.snapshot.target);
      }
      final result = await _repository.advance(
        current.session.token,
        InviteParticipationStatus.started,
      );
      if (isClosed || generation != _generation) return null;
      final failure = result.fold((value) => value, (_) => null);
      if (failure != null) {
        if (failure == ShareGoodFailure.expired) {
          await _showExpired(current.session.snapshot.target, generation);
        } else {
          await _showFailure(failure, current.session.token, generation);
        }
        return null;
      }
      return result.fold<String?>((_) => null, (session) {
        _activeSessions.activate(session);
        return _route(session.snapshot.target);
      });
    } catch (_) {
      return null;
    }
  }

  String startFresh() {
    final current = state;
    if (current is InvitePreviewExpired && current.target != null) {
      return _route(current.target!);
    }
    return '/';
  }

  String _route(InviteActivityTarget target) => switch (target) {
    QuranPageInviteTarget(:final pageNumber) => '/quran/page/$pageNumber',
    QuranSurahInviteTarget(:final surahId) => '/quran/surah/$surahId',
    QuranWirdInviteTarget(:final startPage) => '/quran/page/$startPage',
    AzkarCollectionInviteTarget(:final category) => '/azkar/${category.name}',
  };
}
