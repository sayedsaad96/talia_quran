import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/datasources/share_good_local_store.dart';
import '../../domain/entities/good_impact.dart';
import '../../domain/repositories/share_good_repository.dart';
import '../../domain/services/good_impact_milestone_policy.dart';

sealed class GoodImpactState extends Equatable {
  const GoodImpactState();
  @override
  List<Object?> get props => [];
}

class GoodImpactIdle extends GoodImpactState {
  const GoodImpactIdle();
}

class GoodImpactLoading extends GoodImpactState {
  const GoodImpactLoading();
}

class GoodImpactUnavailable extends GoodImpactState {
  const GoodImpactUnavailable();
}

class GoodImpactReady extends GoodImpactState {
  const GoodImpactReady({
    required this.ownerId,
    required this.impact,
    required this.milestones,
    required this.hasNew,
    required this.fingerprint,
  });
  final String ownerId;
  final GoodImpact impact;
  final Set<GoodImpactMilestone> milestones;
  final bool hasNew;
  final String fingerprint;
  @override
  List<Object?> get props => [ownerId, impact, milestones, hasNew, fingerprint];
}

class GoodImpactCubit extends Cubit<GoodImpactState> {
  GoodImpactCubit({
    required this.repository,
    required this.store,
    required this.auth,
    required this.barrier,
    required this.isAvailable,
    required this.isChild,
    DateTime Function()? clock,
    Stream<void>? audienceChanges,
  }) : clock = clock ?? DateTime.now,
       super(const GoodImpactIdle()) {
    _owner = _currentOwner();
    _authChanges = auth.stream.listen((_) => _checkAuthority());
    _barrierChanges = barrier.changes.listen(
      (_) => _checkAuthority(force: true),
    );
    _audienceChanges = audienceChanges?.listen(
      (_) => _checkAuthority(force: true),
    );
  }
  final ShareGoodRepository repository;
  final ShareGoodLocalStore store;
  final AuthCubit auth;
  final AccountDataBarrier barrier;
  final bool Function() isAvailable;
  final Future<bool> Function() isChild;
  final DateTime Function() clock;
  late final StreamSubscription<AuthState> _authChanges;
  late final StreamSubscription<void> _barrierChanges;
  StreamSubscription<void>? _audienceChanges;
  String? _owner;
  DateTime? _lastSuccess;
  int _generation = 0;
  Future<void>? _inFlight;

  String? _currentOwner() => switch (auth.state) {
    AuthAuthenticated(:final user) => user.id,
    _ => null,
  };
  void _checkAuthority({bool force = false}) {
    final owner = _currentOwner();
    if (!force && owner == _owner) return;
    _owner = owner;
    _generation++;
    _lastSuccess = null;
    _inFlight = null;
    if (!isClosed) emit(const GoodImpactIdle());
  }

  Future<void> refresh({bool force = false}) {
    _checkAuthority();
    final owner = _currentOwner();
    if (!isAvailable() || owner == null) {
      _generation++;
      _lastSuccess = null;
      if (!isClosed) emit(const GoodImpactIdle());
      return Future.value();
    }
    if (_inFlight != null) return _inFlight!;
    final last = _lastSuccess;
    if (!force &&
        last != null &&
        clock().difference(last) < const Duration(hours: 6)) {
      return Future.value();
    }
    final generation = _generation;
    final request = _load(owner, generation);
    _inFlight = request;
    return request.whenComplete(() {
      if (identical(_inFlight, request)) _inFlight = null;
    });
  }

  Future<void> _load(String owner, int generation) async {
    try {
      final lease = barrier.capture();
      lease.checkOwner(owner);
      if (await isChild()) {
        if (_valid(owner, generation)) emit(const GoodImpactIdle());
        return;
      }
      lease.checkOwner(owner);
      if (!_valid(owner, generation)) return;
      if (state is! GoodImpactReady) emit(const GoodImpactLoading());
      final result = await repository.impact();
      lease.checkOwner(owner);
      if (!_valid(owner, generation)) return;
      result.fold((_) => emit(const GoodImpactUnavailable()), (impact) {
        final milestones = const GoodImpactMilestonePolicy().derive(impact);
        final fingerprint = _fingerprint(impact, milestones);
        final hasContent =
            milestones.isNotEmpty || impact.acknowledgements.isNotEmpty;
        _lastSuccess = clock();
        emit(
          GoodImpactReady(
            ownerId: owner,
            impact: impact,
            milestones: milestones,
            hasNew: hasContent && store.impactSeen(owner) != fingerprint,
            fingerprint: fingerprint,
          ),
        );
      });
    } catch (_) {
      if (_valid(owner, generation)) emit(const GoodImpactUnavailable());
    }
  }

  bool _valid(String owner, int generation) =>
      !isClosed &&
      generation == _generation &&
      isAvailable() &&
      _currentOwner() == owner &&
      barrier.isReady;

  bool isCurrent(GoodImpactReady value) => _valid(value.ownerId, _generation);

  Future<void> markSeen() async {
    final current = state;
    if (current is! GoodImpactReady || !_valid(current.ownerId, _generation)) {
      return;
    }
    final generation = _generation;
    try {
      final lease = barrier.capture()..checkOwner(current.ownerId);
      if (!await barrier.run((active) {
        active.checkOwner(current.ownerId);
        return store.setImpactSeen(current.ownerId, current.fingerprint);
      }, authority: lease)) {
        return;
      }
      lease.checkOwner(current.ownerId);
      if (_valid(current.ownerId, generation) && identical(state, current)) {
        emit(
          GoodImpactReady(
            ownerId: current.ownerId,
            impact: current.impact,
            milestones: current.milestones,
            hasNew: false,
            fingerprint: current.fingerprint,
          ),
        );
      }
    } catch (_) {
      /* A stale owner never receives the acknowledgement. */
    }
  }

  static String _fingerprint(
    GoodImpact impact,
    Set<GoodImpactMilestone> milestones,
  ) {
    final entries =
        impact.acknowledgements
            .map(
              (a) => jsonEncode([
                a.target.toJson(),
                a.visibleName,
                a.completedAt.toUtc().toIso8601String(),
              ]),
            )
            .toList()
          ..sort();
    final names = milestones.map((m) => m.name).toList()..sort();
    return sha256.convert(utf8.encode(jsonEncode([names, entries]))).toString();
  }

  @override
  Future<void> close() async {
    await _authChanges.cancel();
    await _barrierChanges.cancel();
    await _audienceChanges?.cancel();
    return super.close();
  }
}
