import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/surah_memorization_status.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/usecases/get_surahs_usecase.dart';
import 'package:talia_quran/features/quran/presentation/cubits/surah_list_cubit.dart';

class _MockGetSurahs extends Mock implements GetSurahsUsecase {}

class _MockMemorizationRepository extends Mock
    implements MemorizationPlusRepository {}

/// N17: the surah list shows which surahs the learner memorized.
void main() {
  const surahs = [
    Surah(
      id: 112,
      nameAr: 'الإخلاص',
      nameEn: 'Al-Ikhlas',
      ayahCount: 1,
      juz: 30,
      type: 'meccan',
      page: 604,
    ),
    Surah(
      id: 113,
      nameAr: 'الفلق',
      nameEn: 'Al-Falaq',
      ayahCount: 5,
      juz: 30,
      type: 'meccan',
      page: 604,
    ),
  ];

  late _MockGetSurahs getSurahs;
  late _MockMemorizationRepository repository;

  setUp(() {
    getSurahs = _MockGetSurahs();
    repository = _MockMemorizationRepository();
    when(() => getSurahs()).thenAnswer((_) async => const Right(surahs));
  });

  AyahReviewRecord memorized(int surah, int ayah) {
    final at = DateTime.utc(2026, 9, 1);
    return AyahReviewRecord(
      surahId: surah,
      ayahNumber: ayah,
      strengthLevel: 6,
      intervalDays: 9,
      lastReviewedAt: at,
      nextReviewDate: at.add(const Duration(days: 9)),
      totalReviews: 4,
      lastRating: PerformanceRating.excellent,
      createdByMode: ReviewRecordCreatedByMode.v2Session,
    );
  }

  test('loads each surah\'s memorization status after the list', () async {
    when(
      () => repository.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    ).thenAnswer((_) async => Right([memorized(112, 1), memorized(113, 1)]));
    final cubit = SurahListCubit(getSurahs, memorizationRepository: repository);

    await cubit.loadSurahs();

    final state = cubit.state as SurahListLoaded;
    expect(state.memorizationStatus, {
      112: SurahMemorizationStatus.memorized,
      113: SurahMemorizationStatus.inProgress,
    });
    await cubit.close();
  });

  test('a records failure leaves the list without badges', () async {
    when(
      () => repository.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    final cubit = SurahListCubit(getSurahs, memorizationRepository: repository);

    await cubit.loadSurahs();

    final state = cubit.state as SurahListLoaded;
    expect(state.surahs, surahs);
    expect(state.memorizationStatus, isEmpty);
    await cubit.close();
  });
}
