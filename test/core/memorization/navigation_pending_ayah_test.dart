import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/pending_ayah_resolver.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart';

void main() {
  const resolver = PendingAyahResolver();
  final t = DateTime.utc(2026, 1, 1);

  group('PendingAyahResolver', () {
    test('continueDailyPlan uses first pending ayah from cached plan', () {
      final now = DateTime.now().toUtc();
      final target = resolver.resolve(
        PendingAyahResolverInput(
          surahId: 67,
          intent: PendingAyahIntent.continueDailyPlan,
          cachedDailyPlan: DailyPlan(
            generatedAt: now,
            surahId: 67,
            newAyahs: const [
              DailyPlanAyah(
                surahId: 67,
                ayahNumber: 7,
                ayahText: 'text',
                record: null,
              ),
            ],
            nearRevision: const [
              DailyPlanAyah(
                surahId: 67,
                ayahNumber: 1,
                ayahText: 'text',
                record: null,
              ),
            ],
            farRevision: const [],
            completedAyahNums: const [1, 2, 3, 4, 5, 6],
          ),
          reviewRecords: const [],
        ),
      );

      expect(target.startAyah, 7);
      expect(target.intent, PendingAyahIntent.continueDailyPlan);
    });

    test(
      'continueDailyPlan opens the first incomplete weak ayah across surahs',
      () {
        final now = DateTime.now().toUtc();
        final target = resolver.resolve(
          PendingAyahResolverInput(
            surahId: 67,
            intent: PendingAyahIntent.continueDailyPlan,
            cachedDailyPlan: DailyPlan(
              generatedAt: now,
              surahId: 67,
              newAyahs: const [
                DailyPlanAyah(
                  surahId: 67,
                  ayahNumber: 7,
                  ayahText: 'new',
                  record: null,
                ),
              ],
              weakRecovery: const [
                DailyPlanAyah(
                  surahId: 36,
                  ayahNumber: 2,
                  ayahText: 'completed weak',
                  record: null,
                ),
                DailyPlanAyah(
                  surahId: 36,
                  ayahNumber: 3,
                  ayahText: 'pending weak',
                  record: null,
                ),
              ],
              nearRevision: const [],
              farRevision: const [],
              completedAyahNums: const [],
              completedAyahKeys: const ['36:2'],
            ),
            reviewRecords: const [],
          ),
        );

        expect(target.surahId, 36);
        expect(target.startAyah, 3);
      },
    );

    test(
      'practiceSurah uses first unstarted ayah when surah ayah count known',
      () {
        final target = resolver.resolve(
          PendingAyahResolverInput(
            surahId: 2,
            intent: PendingAyahIntent.practiceSurah,
            surahAyahCount: 286,
            reviewRecords: [
              AyahReviewRecord(
                surahId: 2,
                ayahNumber: 1,
                strengthLevel: 6,
                intervalDays: 30,
                lastReviewedAt: t,
                nextReviewDate: t,
                totalReviews: 3,
                lastRating: PerformanceRating.excellent,
                createdByMode: ReviewRecordCreatedByMode.v2Session,
              ),
            ],
          ),
        );

        expect(target.startAyah, 2);
      },
    );

    test('reviewSession prefers first due ayah in surah', () {
      final now = DateTime.now().toUtc();
      final target = resolver.resolve(
        PendingAyahResolverInput(
          surahId: 67,
          intent: PendingAyahIntent.reviewSession,
          reviewRecords: [
            AyahReviewRecord(
              surahId: 67,
              ayahNumber: 5,
              strengthLevel: 3,
              intervalDays: 1,
              lastReviewedAt: now.subtract(const Duration(days: 2)),
              nextReviewDate: now.subtract(const Duration(days: 1)),
              totalReviews: 2,
              lastRating: PerformanceRating.average,
              createdByMode: ReviewRecordCreatedByMode.v2Session,
            ),
          ],
        ),
      );

      expect(target.startAyah, 5);
    });
  });

  group('MemorizationNavigationResolver pending ayah (B5)', () {
    test(
      'today plan location includes pending startAyah from cached plan',
      () async {
        final nav = MemorizationNavigationResolver(
          _FakeRepository(
            cachedPlan: DailyPlan(
              generatedAt: DateTime.utc(2026, 7, 8),
              surahId: 2,
              newAyahs: const [
                DailyPlanAyah(
                  surahId: 2,
                  ayahNumber: 4,
                  ayahText: 'text',
                  record: null,
                ),
              ],
              nearRevision: const [],
              farRevision: const [],
              completedAyahNums: const [1, 2, 3],
            ),
          ),
        );

        final targets = await nav.resolve();

        expect(targets.todayPlanLocation, contains('surahId=2'));
        expect(targets.todayPlanLocation, contains('startAyah=4'));
      },
    );

    test(
      'today plan location carries its learning intent and origin',
      () async {
        final nav = MemorizationNavigationResolver(
          _FakeRepository(
            cachedPlan: DailyPlan(
              generatedAt: DateTime.utc(2026, 7, 8),
              surahId: 2,
              newAyahs: const [
                DailyPlanAyah(
                  surahId: 2,
                  ayahNumber: 4,
                  ayahText: 'text',
                  record: null,
                ),
              ],
              nearRevision: const [],
              farRevision: const [],
              completedAyahNums: const [],
            ),
          ),
        );

        final targets = await nav.resolve();
        final query = Uri.parse(targets.todayPlanLocation).queryParameters;

        expect(query['intent'], 'memorize');
        expect(query['origin'], 'dailyPlan');
      },
    );

    test(
      'continuing the plan on a review item launches a review, not memorize (A2)',
      () async {
        final reviewed = AyahReviewRecord(
          surahId: 36,
          ayahNumber: 10,
          strengthLevel: 2,
          intervalDays: 1,
          lastReviewedAt: DateTime.utc(2026, 7, 6),
          nextReviewDate: DateTime.utc(2026, 7, 7),
          totalReviews: 3,
          lastRating: PerformanceRating.weak,
          createdByMode: ReviewRecordCreatedByMode.v2Session,
        );
        final nav = MemorizationNavigationResolver(
          _FakeRepository(
            cachedPlan: DailyPlan(
              generatedAt: DateTime.utc(2026, 7, 8),
              surahId: 2,
              newAyahs: const [
                DailyPlanAyah(
                  surahId: 2,
                  ayahNumber: 4,
                  ayahText: 'text',
                  record: null,
                ),
              ],
              weakRecovery: [
                DailyPlanAyah(
                  surahId: 36,
                  ayahNumber: 10,
                  ayahText: 'text',
                  record: reviewed,
                ),
              ],
              nearRevision: const [],
              farRevision: const [],
              completedAyahNums: const [],
            ),
          ),
        );

        final targets = await nav.resolve();
        final query = Uri.parse(targets.todayPlanLocation).queryParameters;

        expect(query['surahId'], '36');
        expect(query['startAyah'], '10');
        expect(query['intent'], 'review');
        expect(query['origin'], 'dailyPlan');
      },
    );

    test('memorize blocks follow the plan difficulty (M-U4)', () async {
      final nav = MemorizationNavigationResolver(
        _FakeRepository(
          cachedPlan: DailyPlan(
            generatedAt: DateTime.utc(2026, 7, 8),
            surahId: 67,
            newAyahs: [
              for (var ayah = 4; ayah <= 7; ayah++)
                DailyPlanAyah(
                  surahId: 67,
                  ayahNumber: ayah,
                  ayahText: 'text',
                  record: null,
                ),
            ],
            nearRevision: const [],
            farRevision: const [],
            completedAyahNums: const [],
          ),
          customPlan: CustomMemorizationPlan(
            name: 'p',
            startSurahId: 67,
            endSurahId: 114,
            newAyahsPerDay: 10,
            availableDaysPerWeek: 7,
            sessionMinutes: 60,
            difficulty: MemorizationDifficulty.easy,
            enableNearRevision: true,
            enableFarRevision: true,
            nearRevisionCount: 5,
            farRevisionCount: 3,
            startAyah: 1,
            createdAt: DateTime.utc(2026, 7, 1),
          ),
        ),
      );

      final targets = await nav.resolve();
      final query = Uri.parse(targets.todayPlanLocation).queryParameters;

      expect(query['intent'], 'memorize');
      expect(query['blockSize'], '3');
    });

    test("a memorize block never outgrows today's new ayahs (N3)", () async {
      final nav = MemorizationNavigationResolver(
        _FakeRepository(
          cachedPlan: DailyPlan(
            generatedAt: DateTime.utc(2026, 7, 8),
            surahId: 114,
            newAyahs: const [
              DailyPlanAyah(
                surahId: 114,
                ayahNumber: 1,
                ayahText: 'text',
                record: null,
              ),
              DailyPlanAyah(
                surahId: 114,
                ayahNumber: 2,
                ayahText: 'text',
                record: null,
              ),
            ],
            nearRevision: const [],
            farRevision: const [],
            completedAyahNums: const [],
          ),
          customPlan: CustomMemorizationPlan(
            name: 'p',
            startSurahId: 114,
            endSurahId: 114,
            newAyahsPerDay: 10,
            availableDaysPerWeek: 7,
            sessionMinutes: 60,
            difficulty: MemorizationDifficulty.easy,
            enableNearRevision: true,
            enableFarRevision: true,
            nearRevisionCount: 5,
            farRevisionCount: 3,
            startAyah: 1,
            createdAt: DateTime.utc(2026, 7, 1),
          ),
        ),
      );

      final targets = await nav.resolve();
      final query = Uri.parse(targets.todayPlanLocation).queryParameters;

      expect(query['startAyah'], '1');
      expect(query['blockSize'], '2');
    });

    test('completed daily plan does not open a V2 session at ayah 1', () async {
      final nav = MemorizationNavigationResolver(
        _FakeRepository(
          cachedPlan: DailyPlan(
            generatedAt: DateTime.utc(2026, 7, 8),
            surahId: 2,
            newAyahs: const [
              DailyPlanAyah(
                surahId: 2,
                ayahNumber: 1,
                ayahText: 'text',
                record: null,
              ),
            ],
            nearRevision: const [],
            farRevision: const [],
            completedAyahNums: const [1],
          ),
        ),
      );

      final targets = await nav.resolve();

      expect(targets.todayPlanLocation, AppRoutes.memorizationHub);
      expect(targets.todayPlanLocation, isNot(contains('startAyah=1')));
    });

    test(
      'practiceSurahSessionLocation resolves learning ayah for Hifz tile',
      () async {
        final nav = MemorizationNavigationResolver(_FakeRepository());

        final route = await nav.practiceSurahSessionLocation(
          114,
          surahAyahCount: 6,
        );

        expect(route, contains('surahId=114'));
        expect(route, contains('startAyah=1'));
      },
    );
  });
}

class _FakeRepository implements MemorizationPlusRepository {
  _FakeRepository({this.cachedPlan, this.customPlan});

  final DailyPlan? cachedPlan;
  final CustomMemorizationPlan? customPlan;

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      Right(cachedPlan);

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async => const Right([]);

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async =>
      const Left(CacheFailure('No profile'));

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async =>
      Right(customPlan);

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async =>
      const Right([]);

  @override
  Future<Either<Failure, ParentSettings>> getParentSettings() async =>
      const Right(ParentSettings());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> hasPendingCloudWork() async => false;
}
