import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/quran/domain/entities/ayah_note.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/ayah_note_repository.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/ayah_notes_cubit.dart';
import 'package:talia_quran/features/quran/presentation/widgets/ayah_note_editor_sheet.dart';

void main() {
  late AccountDataBarrier barrier;

  setUp(() async {
    await getIt.reset();
    _FailingNotesRepository.writeAttempts = 0;
    SharedPreferences.setMockInitialValues({});
    barrier = AccountDataBarrier.forPreferences(
      await SharedPreferences.getInstance(),
    );
    getIt.registerFactory<AyahNotesCubit>(
      () => AyahNotesCubit(
        _FailingNotesRepository(),
        _QuranRepository(),
        barrier,
      ),
    );
  });

  tearDown(() => getIt.reset());

  testWidgets('save failure preserves edited note text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AyahNoteEditorSheet(surahId: 1, ayahNumber: 1)),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, 'saved note');

    await tester.enterText(field, 'edited but unsaved');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(field).controller!.text,
      'edited but unsaved',
    );
    expect(
      find.text("Couldn't save your note. Please try again."),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(_FailingNotesRepository.writeAttempts, 2);
  });

  testWidgets('invalidation clears displayed text and disables saving', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AyahNoteEditorSheet(surahId: 1, ayahNumber: 1)),
      ),
    );
    await tester.pumpAndSettle();

    barrier.invalidate();
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}

class _FailingNotesRepository implements AyahNoteRepository {
  static int writeAttempts = 0;
  final note = AyahNote(
    surahId: 1,
    ayahNumber: 1,
    body: 'saved note',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  @override
  Future<void> delete(int surahId, int ayahNumber) async {}

  @override
  Future<AyahNote?> get(int surahId, int ayahNumber) async => note;

  @override
  Future<List<AyahNote>> listAll() async => [note];

  @override
  Future<AyahNote> upsert(int surahId, int ayahNumber, String body) {
    writeAttempts++;
    return writeAttempts == 1
        ? Future.error(StateError('write failed'))
        : Future.value(note);
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
