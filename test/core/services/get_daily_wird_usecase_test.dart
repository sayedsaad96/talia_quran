import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/core/services/get_daily_wird_usecase.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/custom_memorization_plan.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/progress/data/datasources/progress_local_datasource.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/usecases/get_surahs_usecase.dart';

class _MockGetCustomPlan extends Mock implements GetCustomPlanUsecase {}

class _MockGetSurahs extends Mock implements GetSurahsUsecase {}

class _FakePages implements ProgressLocalDatasource {
  _FakePages(this.pages);
  final List<int> pages;
  @override
  List<int> getReadPages() => pages;
  @override
  Future<void> saveReadPage(int pageNumber) async {}
}

void main() {
  late _MockGetCustomPlan getCustomPlan;
  late _MockGetSurahs getSurahs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    getCustomPlan = _MockGetCustomPlan();
    getSurahs = _MockGetSurahs();
    when(() => getCustomPlan()).thenAnswer((_) async => const Right(null));
    when(() => getSurahs()).thenAnswer((_) async => const Right([]));
  });

  Future<GetDailyWirdUsecase> build({
    String? lastLocation,
    List<int> pages = const [],
    DateTime? date,
    int? lastCompletedPage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (lastLocation != null) {
      await prefs.setString('last_restorable_location', lastLocation);
    }
    final session = AppSessionService(prefs);
    if (lastCompletedPage != null) {
      await session.saveDailyWirdLastCompletedPage(lastCompletedPage);
    }
    return GetDailyWirdUsecase(
      sessionService: session,
      getCustomPlan: getCustomPlan,
      readPages: _FakePages(pages),
      getSurahs: getSurahs,
      now: () => date ?? DateTime(2026, 9, 8),
    );
  }

  test('is completely independent of any active khatmah plan', () async {
    // The usecase has no khatmah dependency at all — this verifies the
    // isolation contract: wird page is resolved from reading history only.
    final usecase = await build(pages: [9]);
    expect(await usecase(), 10);
  });

  test('continues from lastCompletedWirdPage + 1 when available', () async {
    final usecase = await build(lastCompletedPage: 50);
    expect(await usecase(), 51);
  });

  test('clamps to page 604 when last completed is already the last page', () async {
    final usecase = await build(lastCompletedPage: 604);
    expect(await usecase(), 604);
  });

  test('does not let an unconfirmed reader location advance the daily wird', () async {
    final usecase = await build(
      lastLocation: '/quran/page/10',
      pages: [9],
    );

    expect(await usecase(), 10);
  });

  test('keeps the same daily target after its page is confirmed', () async {
    final pages = [9];
    final usecase = await build(pages: pages);

    expect(await usecase(), 10);
    pages
      ..clear()
      ..add(10);

    expect(await usecase(), 10);
  });

  test('uses custom plan surah page', () async {
    when(() => getCustomPlan()).thenAnswer(
      (_) async => Right(
        CustomMemorizationPlan(
          name: 'plan',
          startSurahId: 36,
          endSurahId: 36,
          newAyahsPerDay: 3,
          availableDaysPerWeek: 5,
          sessionMinutes: 20,
          difficulty: MemorizationDifficulty.easy,
          enableNearRevision: true,
          enableFarRevision: true,
          nearRevisionCount: 3,
          farRevisionCount: 5,
          startAyah: 1,
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
    );
    when(() => getSurahs()).thenAnswer(
      (_) async => const Right([
        Surah(
          id: 36,
          nameAr: 'يس',
          nameEn: 'Ya-Sin',
          ayahCount: 83,
          juz: 22,
          type: 'meccan',
          page: 440,
        ),
      ]),
    );
    final usecase = await build();
    expect(await usecase(), 440);
  });

  test('uses highest read page plus one, then page 1', () async {
    final withPages = await build(pages: [3, 12, 7]);
    expect(await withPages(), 13);
    final empty = await build(date: DateTime(2026, 9, 9));
    expect(await empty(), 1);
  });
}
