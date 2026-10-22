import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/features/quran/domain/entities/ayah_note.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/ayah_note_repository.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/ayah_notes_cubit.dart';

void main() {
  late _NotesRepository notes;
  late AccountDataBarrier barrier;
  late AyahNotesCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    barrier = AccountDataBarrier.forPreferences(
      await SharedPreferences.getInstance(),
    );
    notes = _NotesRepository();
    cubit = AyahNotesCubit(notes, _QuranRepository(), barrier);
  });

  tearDown(() => cubit.close());

  test(
    'invalidation clears editor authority and prevents a stale save',
    () async {
      await cubit.openEditor(1, 1);
      expect(cubit.state.editorNote?.body, 'saved');

      barrier.invalidate();

      expect(cubit.state.available, isFalse);
      expect(cubit.state.editorNote, isNull);
      expect(await cubit.saveEditor(1, 1, 'new text'), isFalse);
      expect(notes.upsertCalls, 0);
    },
  );

  test(
    'a failed editor load after invalidation cannot overwrite cleared state',
    () async {
      final pending = Completer<AyahNote?>();
      notes.getFuture = pending.future;

      final loading = cubit.openEditor(1, 1);
      barrier.invalidate();
      pending.completeError(StateError('read failed'));
      await loading;

      expect(cubit.state.available, isFalse);
      expect(cubit.state.editorNote, isNull);
      expect(cubit.state.saveFailed, isFalse);
    },
  );

  test('a delayed list result after invalidation is ignored', () async {
    final pending = Completer<List<AyahNote>>();
    notes.listFuture = pending.future;

    final loading = cubit.loadList();
    barrier.invalidate();
    pending.complete([notes.note]);
    await loading;

    expect(cubit.state.available, isFalse);
    expect(cubit.state.notes, isEmpty);
  });
}

class _NotesRepository implements AyahNoteRepository {
  final note = AyahNote(
    surahId: 1,
    ayahNumber: 1,
    body: 'saved',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  Future<AyahNote?>? getFuture;
  Future<List<AyahNote>>? listFuture;
  int upsertCalls = 0;

  @override
  Future<void> delete(int surahId, int ayahNumber) async {}

  @override
  Future<AyahNote?> get(int surahId, int ayahNumber) =>
      getFuture ?? Future.value(note);

  @override
  Future<List<AyahNote>> listAll() => listFuture ?? Future.value([note]);

  @override
  Future<AyahNote> upsert(int surahId, int ayahNumber, String body) async {
    upsertCalls++;
    return note;
  }
}

class _QuranRepository implements QuranRepository {
  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() =>
      throw UnimplementedError();
}
