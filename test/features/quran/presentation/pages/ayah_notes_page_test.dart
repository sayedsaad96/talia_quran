import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:talia_quran/features/quran/presentation/pages/ayah_notes_page.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    final barrier = AccountDataBarrier.forPreferences(
      await SharedPreferences.getInstance(),
    );
    getIt.registerFactory<AyahNotesCubit>(
      () => AyahNotesCubit(_NotesRepository(), _QuranRepository(), barrier),
    );
  });

  tearDown(() => getIt.reset());

  testWidgets('opens the exact canonical page for the selected ayah', (
    tester,
  ) async {
    String? destination;
    final router = GoRouter(
      initialLocation: '/notes',
      routes: [
        GoRoute(path: '/notes', builder: (_, _) => const AyahNotesPage()),
        GoRoute(
          path: '/quran/page/:page',
          builder: (_, state) {
            destination = state.uri.toString();
            return const SizedBox();
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(destination, '/quran/page/42?targetSurah=2&targetAyah=255');
  });
}

class _NotesRepository implements AyahNoteRepository {
  final note = AyahNote(
    surahId: 2,
    ayahNumber: 255,
    body: 'private note',
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
  Future<AyahNote> upsert(int surahId, int ayahNumber, String body) async =>
      note;
}

class _QuranRepository implements QuranRepository {
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async =>
      const Right(
        SurahDetail(
          surah: Surah(
            id: 2,
            nameAr: 'البقرة',
            nameEn: 'Al-Baqarah',
            ayahCount: 286,
            juz: 1,
            type: 'meccan',
            page: 1,
          ),
          ayahs: [
            Ayah(
              number: 262,
              surahId: 2,
              text: 'text',
              numberInSurah: 255,
              page: 42,
            ),
          ],
        ),
      );

  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) =>
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
