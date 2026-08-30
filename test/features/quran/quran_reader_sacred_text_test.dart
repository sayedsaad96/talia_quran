import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/features/progress/domain/usecases/save_read_page_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_page_cubit.dart';
import 'package:talia_quran/features/quran/presentation/pages/quran_reader_page.dart';
import 'package:talia_quran/features/quran/presentation/widgets/app_quran_page_view.dart';

class _PageQuranRepository implements QuranRepository {
  const _PageQuranRepository(this.page);

  final QuranPageDetail page;

  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) async =>
      right(page);

  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) =>
      throw UnsupportedError('Not used by this widget test');

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() =>
      throw UnsupportedError('Not used by this widget test');

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) =>
      throw UnsupportedError('Not used by this widget test');

  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) =>
      throw UnsupportedError('Not used by this widget test');
}

class _UnusedSaveReadPageUsecase extends Fake implements SaveReadPageUsecase {}

class _UnusedStreakService extends Fake implements StreakService {}

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({
      'quran_long_press_hint_seen': true,
    });
  });

  tearDown(() => getIt.reset());

  testWidgets('ayah options display preserves surrounding whitespace', (
    tester,
  ) async {
    const sacredText = '  نَصٌّ مُقَدَّسٌ\n';
    const surah = Surah(
      id: 9,
      nameAr: 'التوبة',
      nameEn: 'At-Tawbah',
      ayahCount: 129,
      juz: 10,
      type: 'medinan',
      page: 187,
    );
    const ayah = Ayah(
      number: 1236,
      surahId: 9,
      text: sacredText,
      numberInSurah: 1,
      juz: 10,
      page: 187,
    );
    const page = QuranPageDetail(
      pageNumber: 187,
      ayahs: [ayah],
      surahs: [surah],
    );
    const repository = _PageQuranRepository(page);
    final prefs = await SharedPreferences.getInstance();
    getIt
      ..registerSingleton<SharedPreferences>(prefs)
      ..registerSingleton<AppSessionService>(AppSessionService(prefs))
      ..registerSingleton<QuranReciterService>(QuranReciterService(prefs))
      ..registerSingleton<QuranPageCubit>(
        QuranPageCubit(
          repository,
          _UnusedSaveReadPageUsecase(),
          _UnusedStreakService(),
        ),
      );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: QuranReaderPage(pageNumber: 187),
      ),
    );
    await tester.pump();

    final mushaf = tester.widget<AppQuranPageView>(
      find.byType(AppQuranPageView),
    );
    mushaf.onLongPress!(
      9,
      1,
      const LongPressStartDetails(globalPosition: Offset.zero),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(sacredText), findsOneWidget);
    expect(find.text(sacredText.trim()), findsNothing);
  });
}
