import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/progress/hijri_year_recap.dart';
import '../../../../core/progress/hijri_year_recap_loader.dart';

final class HijriYearRecapState extends Equatable {
  const HijriYearRecapState._({this.recap, this.loading = false});
  const HijriYearRecapState.hidden() : this._();
  const HijriYearRecapState.loading() : this._(loading: true);
  const HijriYearRecapState.visible(HijriYearRecap recap)
    : this._(recap: recap);

  final HijriYearRecap? recap;
  final bool loading;
  bool get isVisible => recap != null;
  @override
  List<Object?> get props => [recap, loading];
}

/// Shared presentation state for the Home and Progress annual-recap cards.
/// The caller must gate feature/adult eligibility before calling [load].
final class HijriYearRecapCubit extends Cubit<HijriYearRecapState> {
  HijriYearRecapCubit(
    this._loader,
    this._barrier, {
    required this.readAdultEligibility,
  }) : super(const HijriYearRecapState.hidden()) {
    _subscription = _barrier.changes.listen((_) => _invalidate());
  }

  final HijriYearRecapSource _loader;
  final Future<bool> Function() readAdultEligibility;
  final AccountDataBarrier _barrier;
  late final StreamSubscription<void> _subscription;
  int _request = 0;

  Future<void> load({required bool enabled, required bool isAdult}) async {
    final request = ++_request;
    if (!enabled || !isAdult) return _hide();
    emit(const HijriYearRecapState.loading());
    try {
      final authority = _barrier.capture();
      final adult = await readAdultEligibility();
      authority.check();
      if (isClosed || request != _request) return;
      if (!adult) return _hide();
      final loaded = await _loader.load();
      if (isClosed || request != _request) return;
      if (!loaded.recap.isVisible || loaded.dismissed) return _hide();
      emit(HijriYearRecapState.visible(loaded.recap));
    } on AccountDataUnavailableException {
      _invalidate();
    } catch (_) {
      if (!isClosed && request == _request) _hide();
    }
  }

  Future<void> dismiss() async {
    final recap = state.recap;
    if (recap == null) return;
    final request = ++_request;
    try {
      await _loader.dismiss(recap.hijriYear);
      if (!isClosed && request == _request) _hide();
    } on AccountDataUnavailableException {
      _invalidate();
    } catch (_) {
      // A preference-write failure must not escape an optional UI action.
    }
  }

  void _invalidate() {
    _request++;
    _hide();
  }

  void _hide() {
    if (!isClosed) emit(const HijriYearRecapState.hidden());
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
