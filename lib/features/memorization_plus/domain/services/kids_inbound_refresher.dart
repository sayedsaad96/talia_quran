import '../repositories/kids_inbound_repository.dart';

/// Pulls what the guardian sent (gifts, home missions, policy) for the kids
/// home. Opening the home and pull-to-refresh force a pull; app resume only
/// pulls when the last successful pull is older than [staleAfter].
class KidsInboundRefresher {
  KidsInboundRefresher(
    this._repository, {
    DateTime Function()? clock,
    this.staleAfter = const Duration(minutes: 5),
  }) : _clock = clock ?? DateTime.now;

  final KidsInboundRepository _repository;
  final DateTime Function() _clock;
  final Duration staleAfter;

  DateTime? _lastPulledAt;
  Future<bool>? _inFlight;

  /// True when a pull reached the server, so the caller should reload local
  /// state. Concurrent calls share the pull already in flight.
  Future<bool> refresh({bool force = false}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final last = _lastPulledAt;
    if (!force && last != null && _clock().difference(last) < staleAfter) {
      return Future.value(false);
    }
    final pull = _pull();
    _inFlight = pull;
    return pull.whenComplete(() => _inFlight = null);
  }

  Future<bool> _pull() async {
    try {
      final result = await _repository.pullKidsInboundFromCloud();
      if (result.isLeft()) return false;
      _lastPulledAt = _clock();
      return true;
    } catch (_) {
      return false;
    }
  }
}
