import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/features/progress/domain/usecases/save_read_page_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_page_cubit.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_result.dart';

class _Repository extends Mock implements QuranRepository {}

class _SaveRead extends Mock implements SaveReadPageUsecase {}

class _Streak extends Mock implements StreakService {}

class _Player extends Mock implements AudioPlayer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const page1 = QuranPageDetail(pageNumber: 1, surahs: [], ayahs: []);
  const page2 = QuranPageDetail(pageNumber: 2, surahs: [], ayahs: []);

  test('older page load must not replace the newer page', () async {
    final repository = _Repository();
    final first = Completer<Either<Failure, QuranPageDetail>>();
    final second = Completer<Either<Failure, QuranPageDetail>>();
    when(() => repository.getQuranPage(1)).thenAnswer((_) => first.future);
    when(() => repository.getQuranPage(2)).thenAnswer((_) => second.future);
    final cubit = QuranPageCubit(repository, _SaveRead(), _Streak());
    final load1 = cubit.loadPage(1);
    final load2 = cubit.loadPage(2);
    second.complete(const Right(page2));
    await load2;
    first.complete(const Right(page1));
    await load1;
    expect((cubit.state as QuranPageLoaded).detail.pageNumber, 2);
    await cubit.close();
  });

  test('a read confirmation must belong to the displayed page', () async {
    final repository = _Repository();
    final save = _SaveRead();
    final streak = _Streak();
    when(
      () => repository.getQuranPage(1),
    ).thenAnswer((_) async => const Right(page1));
    when(() => save(2)).thenAnswer((_) async => const Right(null));
    when(
      () => streak.recordActivity(),
    ).thenAnswer((_) async => const StreakResult.sameDay());
    final cubit = QuranPageCubit(repository, save, streak);
    await cubit.loadPage(1);
    expect(await cubit.confirmRead(2), isFalse);
    verifyNever(() => save(2));
    await cubit.close();
  });

  test('stop while a surah lookup is pending must not restart audio', () async {
    // Required to initialize the in-memory preferences used by this test.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    final repository = _Repository();
    final detail = Completer<Either<Failure, SurahDetail>>();
    final player = _Player();
    final reciter = QuranReciterService(await SharedPreferences.getInstance());
    when(() => repository.getSurahDetail(1)).thenAnswer((_) => detail.future);
    when(
      () => player.currentIndexStream,
    ).thenAnswer((_) => const Stream<int?>.empty());
    when(
      () => player.playerStateStream,
    ).thenAnswer((_) => const Stream<PlayerState>.empty());
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    final service = QuranContinuousPlayerService(
      quranRepository: repository,
      reciterService: reciter,
      player: player,
    );
    final play = service.playSurah(1);
    await service.stop();
    detail.complete(
      const Right(
        SurahDetail(
          surah: Surah(
            id: 1,
            nameAr: 'x',
            nameEn: 'x',
            type: 'meccan',
            ayahCount: 0,
            juz: 1,
            page: 1,
          ),
          ayahs: [],
        ),
      ),
    );
    await play;
    expect(service.state.status, PlaybackStatus.idle);
    service.dispose();
  });
}
