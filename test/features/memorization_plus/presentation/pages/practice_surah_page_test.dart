import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/practice_surah_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/practice_surah_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/practice_surah_tile.dart';
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
  setUpAll(() {
    registerFallbackValue(ReviewRecordReadScope.adult);
  });

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

  testWidgets('whole-surah choice launches its explicit canonical range', (
    tester,
  ) async {
    final repository = _MockRepository();
    when(
      () => repository.getCachedDailyPlan(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repository.getAllReviewRecords(scope: any(named: 'scope')),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => repository.getCustomPlan(),
    ).thenAnswer((_) async => const Right(null));
    getIt.registerSingleton<MemorizationPlusRepository>(repository);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: PracticeSurahTile(
              surah: Surah(
                id: 67,
                nameAr: 'الملك',
                nameEn: 'Al-Mulk',
                ayahCount: 30,
                juz: 29,
                type: 'meccan',
                page: 562,
              ),
              isDark: false,
              primary: Colors.teal,
            ),
          ),
        ),
        GoRoute(
          path: '/memorization-v2/session',
          builder: (_, state) => Scaffold(
            body: Text(
              '${state.uri.queryParameters['startAyah']}:'
              '${state.uri.queryParameters['blockSize']}',
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(_app(router));

    await tester.tap(find.text('Al-Mulk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Choose your practice passage'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(find.text('1:30'), findsNothing);
    await tester.tap(find.text('Al-Mulk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('practice_choose_whole')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1:30'), findsOneWidget);
  });

  testWidgets('split choice accepts Arabic digits and keeps the chosen range', (
    tester,
  ) async {
    final repository = _MockRepository();
    when(
      () => repository.getCachedDailyPlan(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repository.getAllReviewRecords(scope: any(named: 'scope')),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => repository.getCustomPlan(),
    ).thenAnswer((_) async => const Right(null));
    getIt.registerSingleton<MemorizationPlusRepository>(repository);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: PracticeSurahTile(
              surah: Surah(
                id: 67,
                nameAr: 'الملك',
                nameEn: 'Al-Mulk',
                ayahCount: 30,
                juz: 29,
                type: 'meccan',
                page: 562,
              ),
              isDark: false,
              primary: Colors.teal,
            ),
          ),
        ),
        GoRoute(
          path: '/memorization-v2/session',
          builder: (_, state) => Scaffold(
            body: Text(
              '${state.uri.queryParameters['startAyah']}:'
              '${state.uri.queryParameters['blockSize']}',
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(_app(router, locale: const Locale('ar')));

    await tester.tap(find.text('الملك'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('practice_choose_split')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const Key('practice_start_ayah')), '٢٩');
    await tester.enterText(find.byKey(const Key('practice_ayah_count')), '٤');
    await tester.tap(find.byKey(const Key('practice_start_selected')));
    await tester.pump();
    expect(find.text('اختر آيات ضمن حدود السورة.'), findsOneWidget);
    expect(find.byKey(const Key('practice_start_ayah')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('practice_start_ayah')), '٣');
    await tester.enterText(find.byKey(const Key('practice_ayah_count')), '٤');
    await tester.tap(find.byKey(const Key('practice_start_selected')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('3:4'), findsOneWidget);
  });
}

Widget _app(GoRouter router, {Locale locale = const Locale('en')}) =>
    MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
