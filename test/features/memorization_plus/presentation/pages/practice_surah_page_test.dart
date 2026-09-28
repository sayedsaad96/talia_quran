import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/practice_surah_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/practice_surah_page.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/usecases/get_surahs_usecase.dart';

class _MockGetSurahs extends Mock implements GetSurahsUsecase {}

class _MockRepository extends Mock implements MemorizationPlusRepository {}

class _LoadedPracticeCubit extends PracticeSurahCubit {
  _LoadedPracticeCubit() : super(_MockGetSurahs(), _MockRepository());

  @override
  Future<void> load() async => emit(
    const PracticeSurahLoaded(
      selectedPath: 'forward',
      surahs: [
        Surah(
          id: 18,
          nameAr: 'الكهف',
          nameEn: 'Al-Kahf',
          ayahCount: 110,
          juz: 15,
          type: 'meccan',
          page: 293,
        ),
        Surah(
          id: 67,
          nameAr: 'الملك',
          nameEn: 'Al-Mulk',
          ayahCount: 30,
          juz: 29,
          type: 'meccan',
          page: 562,
        ),
      ],
    ),
  );
}

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerFactory<PracticeSurahCubit>(_LoadedPracticeCubit.new);
  });

  tearDown(() => getIt.reset());

  testWidgets('search filters surahs by name or number (M-U11)', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PracticeSurahPage(),
      ),
    );
    await tester.pump();

    expect(find.text('Al-Kahf'), findsOneWidget);
    expect(find.text('Al-Mulk'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('practice_surah_search')),
      'mul',
    );
    await tester.pump();
    expect(find.text('Al-Kahf'), findsNothing);
    expect(find.text('Al-Mulk'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('practice_surah_search')),
      '18',
    );
    await tester.pump();
    expect(find.text('Al-Kahf'), findsOneWidget);
    expect(find.text('Al-Mulk'), findsNothing);
  });
}
