import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/data_protection_status.dart';

class DataProtectionViewState {
  const DataProtectionViewState({
    this.status,
    this.loading = false,
    this.failed = false,
  });
  final DataProtectionStatus? status;
  final bool loading, failed;
}

class DataProtectionCubit extends Cubit<DataProtectionViewState> {
  DataProtectionCubit(this.readStatus, {Stream<void>? accountChanges})
    : super(const DataProtectionViewState()) {
    _accountSubscription = accountChanges?.listen((_) {
      _generation++;
      if (!isClosed) {
        emit(const DataProtectionViewState());
        unawaited(refresh());
      }
    });
  }
  StreamSubscription<void>? _accountSubscription;
  final Future<DataProtectionStatus> Function() readStatus;
  int _generation = 0;
  Future<void> refresh() async {
    final request = ++_generation;
    emit(DataProtectionViewState(status: state.status, loading: true));
    try {
      final status = await readStatus();
      if (!isClosed && request == _generation) {
        emit(DataProtectionViewState(status: status));
      }
    } catch (_) {
      if (!isClosed && request == _generation) {
        emit(const DataProtectionViewState(failed: true));
      }
    }
  }

  @override
  Future<void> close() {
    _generation++;
    unawaited(_accountSubscription?.cancel());
    return super.close();
  }
}
