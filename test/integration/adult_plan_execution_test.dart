import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_custom_plan_service.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_daily_plan_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _Datasource extends Mock implements MemorizationPlusLocalDatasource {}

class _Quran extends Mock implements QuranRepository {}

/// Exercises the real save, daily generation, cache and launch collaborators.
class _PlanRepository extends Fake implements MemorizationPlusRepository {
  _PlanRepository(this.custom, this.daily);
  final MemorizationCustomPlanService custom;
  final MemorizationDailyPlanService daily;

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() =>
      custom.getCustomPlan();

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() =>
      daily.getCachedDailyPlan();

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async => const Right([]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Datasource datasource;
  late _Quran quran;
  late MemorizationCustomPlanService custom;
  late MemorizationDailyPlanService daily;
  late MemorizationNavigationResolver navigation;
  late ProgressEventsBus events;
  CustomMemorizationPlanModel? savedCustom;
  DailyPlanModel? savedDaily;

  final corpus =
      jsonDecode(File('assets/data/quran.json').readAsStringSync())
          as Map<String, dynamic>;
  final surahs =
      jsonDecode(File('assets/data/surahs.json').readAsStringSync())
          as List<dynamic>;

  SurahDetail detail(int id) {
    final metadata = surahs.cast<Map<String, dynamic>>().singleWhere(
      (row) => row['id'] == id,
    );
    return SurahDetail(
      surah: Surah(
        id: id,
        nameAr: metadata['nameAr'] as String,
        nameEn: metadata['nameEn'] as String,
        ayahCount: metadata['ayahCount'] as int,
        juz: metadata['juz'] as int,
        type: metadata['type'] as String,
        page: metadata['page'] as int,
      ),
      ayahs: [
        for (final row in corpus['$id'] as List<dynamic>)
          Ayah(
            number: row['global'] as int,
            surahId: row['chapter'] as int,
            text: row['text'] as String,
            numberInSurah: row['verse'] as int,
            page: row['page'] as int,
            juz: row['juz'] as int,
          ),
      ],
    );
  }

  CustomMemorizationPlan plan({
    int start = 67,
    int end = 67,
    int startAyah = 1,
    int count = 12,
    int minutes = 60,
  }) => CustomMemorizationPlan(
    name: 'execution',
    startSurahId: start,
    endSurahId: end,
    startAyah: startAyah,
    newAyahsPerDay: count,
    availableDaysPerWeek: 7,
    sessionMinutes: minutes,
    difficulty: MemorizationDifficulty.moderate,
    enableNearRevision: false,
    enableFarRevision: false,
    nearRevisionCount: 0,
    farRevisionCount: 0,
    createdAt: DateTime.now().toUtc(),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    datasource = _Datasource();
    quran = _Quran();
    events = ProgressEventsBus();
    savedCustom = null;
    savedDaily = null;
    registerFallbackValue(CustomMemorizationPlanModel.fromEntity(plan()));
    registerFallbackValue(
      DailyPlanModel.fromEntity(
        DailyPlan(
          generatedAt: DateTime.now().toUtc(),
          surahId: 67,
          newAyahs: const [],
          nearRevision: const [],
          farRevision: const [],
          completedAyahNums: const [],
        ),
      ),
    );
    when(() => datasource.getCustomPlan()).thenAnswer((_) async => savedCustom);
    when(() => datasource.saveCustomPlan(any())).thenAnswer((call) async {
      savedCustom =
          call.positionalArguments.single as CustomMemorizationPlanModel;
    });
    when(
      () => datasource.getCachedDailyPlan(),
    ).thenAnswer((_) async => savedDaily);
    when(() => datasource.saveDailyPlan(any())).thenAnswer((call) async {
      savedDaily = call.positionalArguments.single as DailyPlanModel;
    });
    when(() => datasource.clearDailyPlanCache()).thenAnswer((_) async {
      savedDaily = null;
    });
    when(
      () => datasource.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    ).thenAnswer((_) async => []);
    when(() => quran.getSurahDetail(any())).thenAnswer(
      (call) async => Right(detail(call.positionalArguments.single as int)),
    );
    custom = MemorizationCustomPlanService(datasource, prefs);
    daily = MemorizationDailyPlanService(datasource, quran, prefs, events);
    navigation = MemorizationNavigationResolver(_PlanRepository(custom, daily));
  });

  tearDown(() => events.dispose());

  Future<DailyPlan> generate(CustomMemorizationPlan settings) async {
    expect((await custom.saveCustomPlan(settings)).isRight(), isTrue);
    final result = await daily.getCachedDailyPlan();
    expect(result.isRight(), isTrue);
    return result.getOrElse(() => null)!;
  }

  test(
    'save and edit count/duration change the actual daily session range',
    () async {
      final first = await generate(plan());
      expect(first.newAyahs, hasLength(12));
      var uri = Uri.parse(await navigation.adultEntryLocation());
      expect(uri.queryParameters['blockSize'], '12');

      final shorter = await generate(plan(minutes: 16));
      expect(shorter.newAyahs, hasLength(4));
      uri = Uri.parse(await navigation.adultEntryLocation());
      expect(uri.queryParameters['blockSize'], '4');

      final smaller = await generate(plan(count: 2));
      expect(smaller.newAyahs, hasLength(2));
      uri = Uri.parse(await navigation.adultEntryLocation());
      expect(uri.queryParameters['blockSize'], '2');
    },
  );

  for (final descending in [false, true]) {
    test(
      'daily budget crosses surahs in ${descending ? 'descending' : 'ascending'} order',
      () async {
        final settings = plan(
          start: descending ? 114 : 112,
          end: descending ? 112 : 114,
          startAyah: descending ? 5 : 3,
          count: 8,
        );
        final generated = await generate(settings);
        final expected = descending
            ? [
                '114:5',
                '114:6',
                '113:1',
                '113:2',
                '113:3',
                '113:4',
                '113:5',
                '112:1',
              ]
            : [
                '112:3',
                '112:4',
                '113:1',
                '113:2',
                '113:3',
                '113:4',
                '113:5',
                '114:1',
              ];
        expect(
          generated.newAyahs.map((a) => '${a.surahId}:${a.ayahNumber}'),
          expected,
        );
        expect(generated.surahId, settings.startSurahId);
        var completed = generated;
        for (final ayah in generated.newAyahs.take(2)) {
          completed = completed.withCompleted(
            ayah.ayahNumber,
            ayahSurahId: ayah.surahId,
          );
        }
        expect((await daily.saveDailyPlan(completed)).isRight(), isTrue);
        final uri = Uri.parse(await navigation.adultEntryLocation());
        expect(uri.queryParameters['surahId'], '113');
        expect(uri.queryParameters['startAyah'], '1');
        expect(uri.queryParameters['blockSize'], '5');
        expect(completed.isAyahCompleted(113, 1), isFalse);
      },
    );
  }

  test(
    'session minutes reserve time for due reviews before new ayahs',
    () async {
      final now = DateTime.now().toUtc();
      final reviews = [
        for (final number in [29, 30])
          AyahReviewRecordModel.fromEntity(
            AyahReviewRecord(
              surahId: 67,
              ayahNumber: number,
              strengthLevel: 3,
              intervalDays: 1,
              lastReviewedAt: now.subtract(const Duration(days: 1)),
              nextReviewDate: now.subtract(const Duration(hours: 1)),
              totalReviews: 2,
              lastRating: PerformanceRating.average,
              createdByMode: ReviewRecordCreatedByMode.v2Session,
            ),
          ),
      ];
      when(
        () =>
            datasource.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
      ).thenAnswer((_) async => reviews);
      final generated = await generate(
        plan(
          minutes: 40,
        ).copyWith(enableNearRevision: true, nearRevisionCount: 2),
      );
      expect(generated.nearRevision, hasLength(2));
      expect(generated.newAyahs, hasLength(9));
      var uri = Uri.parse(await navigation.adultEntryLocation());
      expect(uri.queryParameters['intent'], 'review');
      expect(uri.queryParameters['startAyah'], '29');
      savedDaily = DailyPlanModel.fromEntity(
        generated
            .withCompleted(29, ayahSurahId: 67)
            .withCompleted(30, ayahSurahId: 67),
      );
      uri = Uri.parse(await navigation.adultEntryLocation());
      expect(uri.queryParameters['intent'], 'memorize');
      expect(uri.queryParameters['blockSize'], '9');
    },
  );

  test(
    'an empty rest-day assignment never launches fallback memorization',
    () async {
      await generate(plan());
      savedDaily = DailyPlanModel.fromEntity(
        DailyPlan(
          generatedAt: DateTime.now().toUtc(),
          surahId: 67,
          newAyahs: const [],
          nearRevision: const [],
          farRevision: const [],
          completedAyahNums: const [],
          isReviewDay: true,
        ),
      );
      expect(await navigation.adultEntryLocation(), AppRoutes.memorizationHub);
    },
  );

  test(
    'a failed daily generation never opens a fixed fallback block',
    () async {
      expect((await custom.saveCustomPlan(plan())).isRight(), isTrue);
      when(
        () => quran.getSurahDetail(67),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      expect(await navigation.adultEntryLocation(), AppRoutes.memorizationHub);
      expect(savedDaily, isNull);
    },
  );

  test('completed daily assignment does not reopen new memorization', () async {
    final generated = await generate(plan(count: 2));
    savedDaily = DailyPlanModel.fromEntity(
      generated
          .withCompleted(1, ayahSurahId: 67)
          .withCompleted(2, ayahSurahId: 67),
    );
    expect(await navigation.adultEntryLocation(), AppRoutes.memorizationHub);
  });

  test('budget never crosses the configured end surah', () async {
    final generated = await generate(
      plan(start: 112, end: 113, count: 20, minutes: 120),
    );
    expect(generated.newAyahs, hasLength(9));
    expect(generated.newAyahs.last.surahId, 113);
    expect(generated.newAyahs.last.ayahNumber, 5);
  });

  test(
    'canonical load failure preserves an existing cached daily plan',
    () async {
      final existing = await generate(plan(start: 112, end: 114, count: 8));
      when(
        () => quran.getSurahDetail(113),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      final result = await daily.generateDailyPlan(
        surahId: 112,
        newAyahsPerDay: 8,
      );
      expect(result.isLeft(), isTrue);
      expect(savedDaily, DailyPlanModel.fromEntity(existing));
    },
  );

  test(
    'missing canonical ayah fails before persisting a generated plan',
    () async {
      final existing = await generate(plan(start: 112, end: 114, count: 8));
      final canonical = detail(113);
      when(() => quran.getSurahDetail(113)).thenAnswer(
        (_) async => Right(
          SurahDetail(
            surah: canonical.surah,
            ayahs: canonical.ayahs.skip(1).toList(),
          ),
        ),
      );
      final result = await daily.generateDailyPlan(
        surahId: 112,
        newAyahsPerDay: 8,
      );
      expect(result.isLeft(), isTrue);
      expect(savedDaily, DailyPlanModel.fromEntity(existing));
    },
  );
}
