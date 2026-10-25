import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/kids_quran_map_celebration_store.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_surah_house_summary_builder.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_quran_journey_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _MockRepo extends Mock implements MemorizationPlusRepository {}

class _MockQuran extends Mock implements QuranRepository {}

class _FakeCelebrationStore implements KidsQuranMapCelebrationStore {
  _FakeCelebrationStore(this.result);

  final Set<int> result;
  List<KidsSurahHouse>? lastHouses;

  @override
  Future<Set<int>> takeNewlyCompleted(List<KidsSurahHouse> houses) async {
    lastHouses = houses;
    return result;
  }
}

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
    expect(loaded.celebratedSurahIds, isEmpty); // no store, nothing celebrated
    await cubit.close();
  });

  test('the celebration store decides which surahs are celebrated', () async {
    final store = _FakeCelebrationStore({3});
    final cubit = KidsQuranJourneyCubit(repo, quran, celebrationStore: store);
    await cubit.load();
    final loaded = cubit.state as KidsQuranJourneyLoaded;
    expect(loaded.celebratedSurahIds, {3});
    expect(store.lastHouses, loaded.houses);
    await cubit.close();
  });

  test('a load whose progress reads failed never touches the store', () async {
    // Houses built without progress would record "nothing completed" and
    // later celebrate every finished surah at once.
    for (final failLogs in [true, false]) {
      if (failLogs) {
        when(
          () => repo.getKidsSessionLogs(),
        ).thenAnswer((_) async => const Left(CacheFailure()));
      } else {
        when(
          () => repo.getKidsSessionLogs(),
        ).thenAnswer((_) async => const Right(<KidsSessionLog>[]));
        when(
          () => repo.getAllReviewRecords(scope: ReviewRecordReadScope.kids),
        ).thenAnswer((_) async => const Left(CacheFailure()));
      }
      final store = _FakeCelebrationStore({3});
      final cubit = KidsQuranJourneyCubit(repo, quran, celebrationStore: store);
      await cubit.load();
      final loaded = cubit.state as KidsQuranJourneyLoaded;
      expect(loaded.celebratedSurahIds, isEmpty, reason: 'failLogs $failLogs');
      expect(store.lastHouses, isNull, reason: 'failLogs $failLogs');
      await cubit.close();
    }
  });

  test('a cubit closed mid-load does not consume the celebration', () async {
    final store = _FakeCelebrationStore({3});
    final cubit = KidsQuranJourneyCubit(repo, quran, celebrationStore: store);
    final loading = cubit.load();
    await cubit.close();
    await loading;
    expect(store.lastHouses, isNull);
  });

  test('a new child opens on the guardian starting surah', () async {
    when(
      () => repo.getParentSettings(),
    ).thenAnswer((_) async => const Right(ParentSettings(startingSurahId: 67)));
    final cubit = KidsQuranJourneyCubit(repo, quran);
    await cubit.load();
    expect((cubit.state as KidsQuranJourneyLoaded).currentSurahId, 67);
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
