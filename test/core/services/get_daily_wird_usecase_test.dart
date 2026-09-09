import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/core/services/get_daily_wird_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/custom_memorization_plan.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/progress/data/datasources/progress_local_datasource.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/usecases/get_surahs_usecase.dart';

class _MockGetCustomPlan extends Mock implements GetCustomPlanUsecase {}

class _MockGetSurahs extends Mock implements GetSurahsUsecase {}

class _MockGetKhatmah extends Mock implements GetActiveKhatmahUsecase {}

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
  late _MockGetKhatmah getKhatmah;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    getCustomPlan = _MockGetCustomPlan();
    getSurahs = _MockGetSurahs();
    getKhatmah = _MockGetKhatmah();
    when(() => getCustomPlan()).thenAnswer((_) async => const Right(null));
    when(() => getSurahs()).thenAnswer((_) async => const Right([]));
    when(() => getKhatmah()).thenAnswer((_) async => null);
  });

  Future<GetDailyWirdUsecase> build({
    String? lastLocation,
    List<int> pages = const [],
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (lastLocation != null) {
      await prefs.setString('last_restorable_location', lastLocation);
    }
    return GetDailyWirdUsecase(
      sessionService: AppSessionService(prefs),
      getCustomPlan: getCustomPlan,
      readPages: _FakePages(pages),
      getSurahs: getSurahs,
      getActiveKhatmah: getKhatmah,
      now: () => date ?? DateTime(2026, 9, 8),
    );
  }

  test('uses active khatmah daily start page first', () async {
    when(() => getKhatmah()).thenAnswer(
      (_) async => KhatmahPlan(
        id: 'k',
        title: 'Khatmah',
        targetPagesPerDay: 2,
        targetDays: 300,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 12, 1),
        dailyTargetDate: DateTime(2026, 9, 8),
        dailyTargetStartPage: 40,
        dailyTargetEndPage: 41,
      ),
    );
    final usecase = await build(lastLocation: '/quran/page/10');
    expect(await usecase(), 40);
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
