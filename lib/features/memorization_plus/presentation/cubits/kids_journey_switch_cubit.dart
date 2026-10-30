import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/entities/kids_journey_path_definition.dart';
import '../../domain/entities/memorization_profile.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

enum JourneySwitchStatus { loading, ready, saving, error, stale, success }

class JourneySwitchState {
  const JourneySwitchState(this.status, {this.current, this.selected});
  final JourneySwitchStatus status;
  final KidsJourneyPathId? current, selected;
  bool get canSave =>
      status == JourneySwitchStatus.ready && selected != current;
}

class KidsJourneySwitchCubit extends Cubit<JourneySwitchState> {
  KidsJourneySwitchCubit(
    this._repository,
    this._access,
    this._owner,
    this._barrier,
  ) : super(const JourneySwitchState(JourneySwitchStatus.loading));
  final MemorizationPlusRepository _repository;
  final ParentAccessUsecase _access;
  final RecordOwnerProvider _owner;
  final AccountDataBarrier _barrier;
  late final String _ownerId;
  late final AccountDataLease _lease;
  bool _captured = false;
  MemorizationProfile? _authorizingProfile;
  @override
  void emit(JourneySwitchState state) {
    if (!isClosed) super.emit(state);
  }

  bool get isScopeValid => _valid();

  bool _valid() {
    try {
      if (isClosed || !_captured || _owner.currentOwnerId != _ownerId) {
        return false;
      }
      _lease.checkOwner(_ownerId);
      return true;
    } on AccountDataUnavailableException {
      return false;
    }
  }

  Future<void> load() async {
    if (state.status == JourneySwitchStatus.saving) return;
    emit(const JourneySwitchState(JourneySwitchStatus.loading));
    try {
      if (!_captured) {
        final ownerId = _owner.currentOwnerId;
        final lease = _barrier.capture();
        _ownerId = ownerId;
        _lease = lease;
        _captured = true;
      }
      if (!_valid()) return _stale();
      final profile = (await _repository.getMemorizationProfile()).fold(
        (_) => null,
        (p) => p,
      );
      if (!_valid()) return _stale();
      if (profile == null) return _error();
      if (!profile.isChild) return _stale();
      final path = (await _access.getKidsJourneyPath()).fold(
        (_) => null,
        (p) => p,
      );
      if (!_valid()) return _stale();
      if (path == null) return _error();
      emit(
        JourneySwitchState(
          JourneySwitchStatus.ready,
          current: path.id,
          selected: path.id,
        ),
      );
    } catch (_) {
      if (!_valid()) return _stale();
      _error();
    }
  }

  void select(KidsJourneyPathId id) {
    if (state.status == JourneySwitchStatus.ready) {
      emit(
        JourneySwitchState(
          JourneySwitchStatus.ready,
          current: state.current,
          selected: id,
        ),
      );
    }
  }

  Future<void> save(Future<bool> Function(bool linked) authorize) async {
    if (!state.canSave) return;
    if (!_valid()) return _stale();
    final current = state.current, selected = state.selected!;
    emit(
      JourneySwitchState(
        JourneySwitchStatus.saving,
        current: current,
        selected: selected,
      ),
    );
    try {
      final before = (await _repository.getMemorizationProfile()).fold(
        (_) => null,
        (p) => p,
      );
      if (!_valid()) return _stale();
      if (before == null) return _error(current, selected);
      if (!before.isChild) return _stale();
      _authorizingProfile = before;
      final authorized = await authorize(before.isGuardianLinked);
      if (!_valid()) return _stale();
      if (!authorized) {
        emit(
          JourneySwitchState(
            JourneySwitchStatus.ready,
            current: current,
            selected: selected,
          ),
        );
        return;
      }
      await _writeAfterProfileCheck(before, current, selected);
    } catch (_) {
      if (!_valid()) return _stale();
      _error(current, selected);
    }
  }

  Future<bool> canCreateGuardianPin() async {
    final before = _authorizingProfile;
    if (before == null || !_valid()) return false;
    try {
      final current = (await _repository.getMemorizationProfile()).fold(
        (_) => null,
        (profile) => profile,
      );
      return _valid() && current != null && _sameGuardian(before, current);
    } catch (_) {
      return false;
    }
  }

  Future<void> _writeAfterProfileCheck(
    MemorizationProfile before,
    KidsJourneyPathId? current,
    KidsJourneyPathId selected,
  ) async {
    final after = (await _repository.getMemorizationProfile()).fold(
      (_) => null,
      (p) => p,
    );
    if (!_valid()) return _stale();
    if (after == null) return _error(current, selected);
    if (!_sameGuardian(before, after)) return _stale();
    if (!_valid()) return _stale();
    final result = await _access.setKidsJourneyPath(selected);
    if (!_valid()) return _stale();
    if (result.isLeft()) return _error(current, selected);
    emit(
      JourneySwitchState(
        JourneySwitchStatus.success,
        current: selected,
        selected: selected,
      ),
    );
  }

  bool _sameGuardian(MemorizationProfile before, MemorizationProfile after) =>
      after.isChild &&
      before.guardianId == after.guardianId &&
      before.guardianLinkStatus == after.guardianLinkStatus;
  void _stale() => emit(const JourneySwitchState(JourneySwitchStatus.stale));
  void _error([KidsJourneyPathId? current, KidsJourneyPathId? selected]) =>
      emit(
        JourneySwitchState(
          JourneySwitchStatus.error,
          current: current,
          selected: selected,
        ),
      );
}
