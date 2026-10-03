import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/widgets/quick_navigation_sheet.dart';

class _EmptyQuranRepository implements QuranRepository {
  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) async =>
      const Left(NotFoundFailure());

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async =>
      const Left(NotFoundFailure());

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() async => const Right([]);

  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) async =>
      const Right([]);

  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) async =>
      const Right([]);
}

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<QuranRepository>(_EmptyQuranRepository());
  });

  tearDown(() => getIt.reset());

  testWidgets('Arabic page entry navigates using its Western numeric value', (
    tester,
  ) async {
    int? navigatedPage;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: QuickNavigationSheet(
            currentPage: 1,
            lastPage: null,
            onGoToPage: (page) => navigatedPage = page,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pageInput = find.byType(TextField).first;
    await tester.enterText(pageInput, '١٢٣');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(navigatedPage, 123);
  });
}
