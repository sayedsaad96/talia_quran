import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/core/theme/app_colors.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/presentation/widgets/reader_docked_audio_bar.dart';
import 'package:talia_quran/features/quran/presentation/widgets/reader_footer.dart';
import 'package:talia_quran/features/quran/presentation/widgets/reader_top_bar.dart';

class StubRepo implements QuranRepository {
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async =>
      const Left(NotFoundFailure());

  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) async =>
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranContinuousPlayerService service;
  late QuranAudioPlayerCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = QuranContinuousPlayerService(
      quranRepository: StubRepo(),
      reciterService: QuranReciterService(prefs),
    );
    cubit = QuranAudioPlayerCubit(service);
  });

  tearDown(() {
    cubit.close();
    service.dispose();
  });

  Widget topBar({VoidCallback? onBack, VoidCallback? onOpenMenu}) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: ReaderTopBar(
            surahName: 'آل عمران',
            juzNumber: 3,
            pageNumber: 62,
            primary: AppColors.primary,
            bg: AppColors.parchmentLight,
            onBack: onBack ?? () {},
            onOpenMenu: onOpenMenu ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('ReaderTopBar fits a 360px screen without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(topBar());
    await tester.pumpAndSettle();

    expect(find.text('آل عمران'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReaderTopBar back and overflow callbacks fire', (tester) async {
    var backCount = 0;
    var menuCount = 0;
    await tester.pumpWidget(
      topBar(onBack: () => backCount++, onOpenMenu: () => menuCount++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pump();
    expect(menuCount, 1);

    await tester.tap(find.byTooltip('إغلاق القارئ'));
    await tester.pump();
    expect(backCount, 1);
  });

  testWidgets('ReaderTopBar shows pause state for the playing page', (
    tester,
  ) async {
    cubit.emit(
      const QuranAudioPlayerState(
        status: PlaybackStatus.playing,
        currentSurahId: 3,
        currentAyahNumber: 1,
        currentPageNumber: 62,
        reciter: QuranReciter.abdulbasit,
        scope: PlayScope.page,
      ),
    );
    await tester.pumpWidget(topBar());
    await tester.pump();

    expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);
  });

  testWidgets('ReaderFooter page pill opens navigation on tap', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReaderFooter(
            pageNumber: 62,
            hizbNumber: 5,
            accent: AppColors.primary,
            bg: AppColors.parchmentLight,
            showReadConfirmed: false,
            onPageTap: () => tapped++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('٦٢'));
    await tester.pump();
    expect(tapped, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReaderDockedAudioBar renders nothing when idle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: ReaderDockedAudioBar()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  testWidgets('ReaderDockedAudioBar renders controls when playing', (
    tester,
  ) async {
    cubit.emit(
      const QuranAudioPlayerState(
        status: PlaybackStatus.playing,
        currentSurahId: 1,
        currentAyahNumber: 2,
        currentPageNumber: 1,
        reciter: QuranReciter.abdulbasit,
        scope: PlayScope.page,
        hasNext: true,
        hasPrevious: true,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: ReaderDockedAudioBar()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
