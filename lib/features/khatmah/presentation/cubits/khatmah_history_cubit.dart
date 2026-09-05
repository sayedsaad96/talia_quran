import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/khatmah_history_entry.dart';
import '../../domain/usecases/get_khatmah_history_usecase.dart';

sealed class KhatmahHistoryState extends Equatable {
  const KhatmahHistoryState();

  @override
  List<Object?> get props => [];
}

class KhatmahHistoryInitial extends KhatmahHistoryState {
  const KhatmahHistoryInitial();
}

class KhatmahHistoryLoading extends KhatmahHistoryState {
  const KhatmahHistoryLoading();
}

class KhatmahHistoryEmpty extends KhatmahHistoryState {
  const KhatmahHistoryEmpty();
}

class KhatmahHistoryLoaded extends KhatmahHistoryState {
  const KhatmahHistoryLoaded(this.entries);

  final List<KhatmahHistoryEntry> entries;

  @override
  List<Object?> get props => [entries];
}

class KhatmahHistoryCorrupt extends KhatmahHistoryState {
  const KhatmahHistoryCorrupt(this.validEntries);

  final List<KhatmahHistoryEntry> validEntries;

  @override
  List<Object?> get props => [validEntries];
}

class KhatmahHistoryFailure extends KhatmahHistoryState {
  const KhatmahHistoryFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

class KhatmahHistoryCubit extends Cubit<KhatmahHistoryState> {
  KhatmahHistoryCubit(this._getHistory) : super(const KhatmahHistoryInitial()) {
    _changes = _getHistory.changes?.listen((_) {
      if (!isClosed) unawaited(load());
    });
  }

  final GetKhatmahHistoryUsecase _getHistory;
  StreamSubscription<void>? _changes;
  int _loadRevision = 0;

  Future<void> load() async {
    final revision = ++_loadRevision;
    emit(const KhatmahHistoryLoading());
    try {
      final entries = await _getHistory();
      if (isClosed || revision != _loadRevision) return;
      final awarded =
          entries
              .where((entry) => entry.certificate != null)
              .toList(growable: false)
            ..sort((a, b) => b.completedDate.compareTo(a.completedDate));
      emit(
        awarded.length != entries.length
            ? KhatmahHistoryCorrupt(awarded)
            : awarded.isEmpty
            ? const KhatmahHistoryEmpty()
            : KhatmahHistoryLoaded(awarded),
      );
    } catch (error) {
      if (!isClosed && revision == _loadRevision) {
        emit(KhatmahHistoryFailure(error));
      }
    }
  }

  @override
  Future<void> close() {
    _loadRevision++;
    unawaited(_changes?.cancel());
    return super.close();
  }
}
