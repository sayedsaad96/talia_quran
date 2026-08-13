import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/practice_surah_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/usecases/get_surahs_usecase.dart';

class _FakeGetSurahs implements GetSurahsUsecase {
  _FakeGetSurahs(this.result);
  final Either<Failure, List<Surah>> result;

  @override
  Future<Either<Failure, List<Surah>>> call() async => result;
}

class _FakeMemPlusRepo implements MemorizationPlusRepository {
  _FakeMemPlusRepo(this.profile);
  final MemorizationProfile profile;

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async =>
      Right(profile);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Surah _surah(int id) => Surah(
      id: id,
      nameAr: 'سورة $id',
      nameEn: 'Surah $id',
      ayahCount: 10,
      juz: 1,
      type: 'meccan',
      page: id,
    );

void main() {
  test('load sorts ascending for adult forward path', () async {
    final cubit = PracticeSurahCubit(
      _FakeGetSurahs(Right([_surah(5), _surah(2), _surah(3)])),
      _FakeMemPlusRepo(
        MemorizationProfile.empty().copyWith(
          selectedPath: MemorizationPath.adult,
        ),
      ),
    );
    addTearDown(cubit.close);

    await cubit.load();

    final state = cubit.state;
    expect(state, isA<PracticeSurahLoaded>());
    final loaded = state as PracticeSurahLoaded;
    expect(loaded.surahs.map((s) => s.id), [2, 3, 5]);
    expect(loaded.selectedPath, 'forward');
  });

  test('load emits error when surahs fail', () async {
    final cubit = PracticeSurahCubit(
      _FakeGetSurahs(const Left(CacheFailure('boom'))),
      _FakeMemPlusRepo(MemorizationProfile.empty()),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state, isA<PracticeSurahError>());
  });
}