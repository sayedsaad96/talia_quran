import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';

class FakeQuranRepo implements QuranRepository {
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async {
    if (surahId == 1) {
      return const Right(
        SurahDetail(
          surah: Surah(
            id: 1,
            nameAr: 'الفاتحة',
            nameEn: 'Al-Fatihah',
            type: 'meccan',
            ayahCount: 7,
            juz: 1,
            page: 1,
          ),
          ayahs: [
            Ayah(
              number: 1,
              surahId: 1,
              text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              numberInSurah: 1,
              juz: 1,
              page: 1,
            ),
          ],
        ),
      );
    }
    return const Left(NotFoundFailure());
  }

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

  late QuranContinuousPlayerService playerService;
  late QuranAudioPlayerCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final reciterService = QuranReciterService(prefs);
    final repo = FakeQuranRepo();

    playerService = QuranContinuousPlayerService(
      quranRepository: repo,
      reciterService: reciterService,
    );
    cubit = QuranAudioPlayerCubit(playerService);
  });

  tearDown(() {
    cubit.close();
    playerService.dispose();
  });

  test('initial state reflects service idle state', () {
    expect(cubit.state.status, PlaybackStatus.idle);
    expect(cubit.state.isIdle, isTrue);
    expect(cubit.state.hasActiveAudio, isFalse);
  });

  test('changeReciter updates state', () async {
    const newReciter = QuranReciter.minshawi;
    await cubit.changeReciter(newReciter);
    expect(cubit.state.reciter?.id, 'minshawi');
  });

  test('stop resets cubit state', () async {
    await cubit.stop();
    expect(cubit.state.status, PlaybackStatus.idle);
  });
}
