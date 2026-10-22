import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../domain/entities/ayah_note.dart';
import '../../domain/repositories/ayah_note_repository.dart';
import '../../domain/repositories/quran_repository.dart';

class AyahNotesState extends Equatable {
  const AyahNotesState({
    this.notes = const [],
    this.editorNote,
    this.loading = false,
    this.available = true,
    this.saveFailed = false,
    this.editorLoadFailed = false,
    this.listFailed = false,
    this.navigationFailed = false,
  });

  final List<AyahNote> notes;
  final AyahNote? editorNote;
  final bool loading;
  final bool available;
  final bool saveFailed;
  final bool editorLoadFailed;
  final bool listFailed;
  final bool navigationFailed;

  AyahNotesState copyWith({
    List<AyahNote>? notes,
    AyahNote? editorNote,
    bool clearEditor = false,
    bool? loading,
    bool? available,
    bool? saveFailed,
    bool? editorLoadFailed,
    bool? listFailed,
    bool? navigationFailed,
  }) => AyahNotesState(
    notes: notes ?? this.notes,
    editorNote: clearEditor ? null : editorNote ?? this.editorNote,
    loading: loading ?? this.loading,
    available: available ?? this.available,
    saveFailed: saveFailed ?? this.saveFailed,
    editorLoadFailed: editorLoadFailed ?? this.editorLoadFailed,
    listFailed: listFailed ?? this.listFailed,
    navigationFailed: navigationFailed ?? this.navigationFailed,
  );

  @override
  List<Object?> get props => [
    notes,
    editorNote,
    loading,
    available,
    saveFailed,
    editorLoadFailed,
    listFailed,
    navigationFailed,
  ];
}

class AyahNotesCubit extends Cubit<AyahNotesState> {
  AyahNotesCubit(this._repository, this._quran, this._barrier)
    : super(const AyahNotesState()) {
    _changes = _barrier.changes.listen(_invalidate);
  }

  final AyahNoteRepository _repository;
  final QuranRepository _quran;
  final AccountDataBarrier _barrier;
  late final StreamSubscription<void> _changes;
  AccountDataLease? _editorLease;
  ({int surahId, int ayahNumber})? _editing;
  int _listRequest = 0;

  Future<void> loadList() async {
    final request = ++_listRequest;
    emit(
      state.copyWith(
        loading: true,
        available: true,
        listFailed: false,
        navigationFailed: false,
      ),
    );
    try {
      final lease = _barrier.capture();
      final notes = await _repository.listAll();
      lease.check();
      if (!isClosed && request == _listRequest) {
        emit(state.copyWith(notes: notes, loading: false, listFailed: false));
      }
    } on AccountDataUnavailableException {
      _invalidate(null);
    } catch (_) {
      if (!isClosed && request == _listRequest) {
        emit(state.copyWith(loading: false, listFailed: true));
      }
    }
  }

  Future<void> openEditor(int surahId, int ayahNumber) async {
    AccountDataLease? lease;
    try {
      lease = _barrier.capture();
      _editorLease = lease;
      _editing = (surahId: surahId, ayahNumber: ayahNumber);
      emit(
        state.copyWith(
          clearEditor: true,
          loading: true,
          available: true,
          saveFailed: false,
          editorLoadFailed: false,
          navigationFailed: false,
        ),
      );
      final note = await _repository.get(surahId, ayahNumber);
      lease.check();
      if (!isClosed && identical(_editorLease, lease)) {
        emit(
          state.copyWith(
            editorNote: note,
            clearEditor: note == null,
            loading: false,
          ),
        );
      }
    } on AccountDataUnavailableException {
      _invalidate(null);
    } catch (_) {
      if (!isClosed && identical(_editorLease, lease)) {
        emit(state.copyWith(loading: false, editorLoadFailed: true));
      }
    }
  }

  Future<bool> saveEditor(int surahId, int ayahNumber, String body) async {
    final lease = _editorLease;
    final editing = _editing;
    if (lease == null ||
        editing == null ||
        editing.surahId != surahId ||
        editing.ayahNumber != ayahNumber ||
        !state.available ||
        state.loading ||
        state.editorLoadFailed) {
      return false;
    }
    try {
      if (!isClosed) emit(state.copyWith(saveFailed: false));
      lease.check();
      if (body.trim().isEmpty) {
        await _repository.delete(surahId, ayahNumber);
      } else {
        await _repository.upsert(surahId, ayahNumber, body);
      }
      lease.check();
      return true;
    } on AccountDataUnavailableException {
      _invalidate(null);
      return false;
    } catch (_) {
      if (!isClosed) emit(state.copyWith(saveFailed: true));
      return false;
    }
  }

  Future<int?> pageFor(AyahNote note) async {
    try {
      final lease = _barrier.capture();
      final result = await _quran.getSurahDetail(note.surahId);
      lease.check();
      final page = result.fold((_) => null, (detail) {
        if (detail.surah.id != note.surahId) return null;
        final matches = detail.ayahs
            .where(
              (ayah) =>
                  ayah.surahId == note.surahId &&
                  ayah.numberInSurah == note.ayahNumber,
            )
            .toList(growable: false);
        return matches.length == 1 ? matches.single.page : null;
      });
      if (page != null && page >= 1 && page <= 604) return page;
      if (!isClosed) emit(state.copyWith(navigationFailed: true));
      return null;
    } on AccountDataUnavailableException {
      _invalidate(null);
      return null;
    } catch (_) {
      if (!isClosed) emit(state.copyWith(navigationFailed: true));
      return null;
    }
  }

  void _invalidate(void _) {
    _editorLease = null;
    _editing = null;
    if (!isClosed) {
      emit(const AyahNotesState(available: false));
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
