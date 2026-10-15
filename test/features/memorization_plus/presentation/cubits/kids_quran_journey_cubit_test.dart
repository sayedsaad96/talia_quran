import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_quran_journey_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _MockRepo extends Mock implements MemorizationPlusRepository {}

class _MockQuran extends Mock implements QuranRepository {}

List<Surah> _surahs() => [
  for (var id = 1; id <= 114; id++)
    Surah(
      id: id,
      nameAr: 'ar$id',
      nameEn: 'en$id',
      ayahCount: 5,
      juz: 1 + (id % 30),
      type: 'meccan',
      page: id,
    ),
];

void main() {
  late _MockRepo repo;
  late _MockQuran quran;

  setUp(() {
    repo = _MockRepo();
    quran = _MockQuran();
    when(() => repo.getKidsJourneyPath()).thenAnswer(
      (_) async => Right(
        KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromFatiha),
      ),
    );
    when(
      () => repo.getKidsSessionLogs(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => repo.getAllReviewRecords(scope: ReviewRecordReadScope.kids),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => repo.getParentSettings(),
    ).thenAnswer((_) async => const Right(ParentSettings()));
    when(
      () => repo.getMemorizationProfile(),
    ).thenAnswer((_) async => Right(MemorizationProfile.empty()));
    when(() => quran.getSurahs()).thenAnswer((_) async => Right(_surahs()));
  });

  test('load emits Loaded with 114 houses and the current house', () async {
    final cubit = KidsQuranJourneyCubit(repo, quran);
    await cubit.load();
    final state = cubit.state;
    expect(state, isA<KidsQuranJourneyLoaded>());
    final loaded = state as KidsQuranJourneyLoaded;
    expect(loaded.houses, hasLength(114));
    expect(loaded.currentSurahId, 1);
    expect(loaded.surahNames[1], 'ar1');
    await cubit.close();
  });

  test('load emits Error when surahs cannot be read', () async {
    when(
      () => quran.getSurahs(),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    final cubit = KidsQuranJourneyCubit(repo, quran);
    await cubit.load();
    expect(cubit.state, isA<KidsQuranJourneyError>());
    await cubit.close();
  });
}
