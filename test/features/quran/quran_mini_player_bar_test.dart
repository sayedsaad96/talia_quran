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
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/presentation/widgets/quran_mini_player_bar.dart';

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
    final reciterService = QuranReciterService(prefs);
    service = QuranContinuousPlayerService(
      quranRepository: StubRepo(),
      reciterService: reciterService,
    );
    cubit = QuranAudioPlayerCubit(service);
  });

  tearDown(() {
    cubit.close();
    service.dispose();
  });

  testWidgets('QuranMiniPlayerBar renders nothing when idle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: QuranMiniPlayerBar(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('QuranMiniPlayerBar renders content when audio state is playing', (
    tester,
  ) async {
    cubit.emit(
      const QuranAudioPlayerState(
        status: PlaybackStatus.playing,
        currentSurahId: 1,
        currentAyahNumber: 1,
        currentPageNumber: 1,
        reciter: QuranReciter.abdulbasit,
        scope: PlayScope.surah,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: QuranMiniPlayerBar(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}
