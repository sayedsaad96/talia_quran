import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_daily_budget.dart';

void main() {
  group('KidsNextMissionResolver', () {
    test('due kids review takes priority over new memorization', () {
      final now = DateTime.utc(2026, 9, 1);
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 5,
            completedAyahs: [1],
            status: KidsJourneyStageStatus.current,
          ),
        ],
        resumableMission: const KidsNextMission(
          type: KidsMissionType.resume,
          surahId: 113,
          ayahNumbers: [2],
        ),
        reviewRecords: [
          AyahReviewRecord(
            surahId: 114,
            ayahNumber: 1,
            strengthLevel: 1,
            intervalDays: 1,
            lastReviewedAt: DateTime.utc(2026, 8, 30),
            nextReviewDate: DateTime.utc(2026, 8, 31),
            totalReviews: 1,
            lastRating: PerformanceRating.average,
            createdByMode: ReviewRecordCreatedByMode.kidsMode,
          ),
        ],
        now: now,
      );

      expect(mission?.type, KidsMissionType.dueReview);
      expect(mission?.surahId, 114);
      expect(mission?.ayahNumbers, const [1]);
    });

    test('exhausted daily review budget lets new memorization through', () {
      // A persistent STT false-negative loop (weak ratings never clear) must
      // not starve the child of new memorization forever: once the daily
      // review budget is spent, the pipeline falls through to fresh work.
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 5,
            completedAyahs: [1],
            status: KidsJourneyStageStatus.current,
          ),
        ],
        reviewRecords: [_dueReviewRecord(surahId: 114, ayahNumber: 1)],
        now: DateTime.utc(2026, 9, 1),
        budget: const KidsDailyBudget(
          dueReviewsCompletedToday: 3,
          maxDueReviewsPerDay: 3,
        ),
      );

      expect(mission?.type, KidsMissionType.newMemorization);
      expect(mission?.ayahNumbers, const [2]);
    });

    test('due reviews keep priority while the daily budget remains', () {
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 5,
            completedAyahs: [1],
            status: KidsJourneyStageStatus.current,
          ),
        ],
        reviewRecords: [_dueReviewRecord(surahId: 114, ayahNumber: 1)],
        now: DateTime.utc(2026, 9, 1),
        budget: const KidsDailyBudget(
          dueReviewsCompletedToday: 2,
          maxDueReviewsPerDay: 3,
        ),
      );

      expect(mission?.type, KidsMissionType.dueReview);
      expect(mission?.ayahNumbers, const [1]);
    });

    test('starts the next short surah after completing the current one', () {
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 6,
            completedAyahs: [1, 2, 3, 4, 5, 6],
            status: KidsJourneyStageStatus.completed,
          ),
        ],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
      );

      expect(mission?.type, KidsMissionType.newMemorization);
      expect(mission?.surahId, 113);
      expect(mission?.ayahNumbers, const [1]);
    });

    test('does not move beyond the configured Juz Amma boundary', () {
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 78,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 78,
            startAyah: 1,
            endAyah: 40,
            completedAyahs: [1],
            status: KidsJourneyStageStatus.completed,
          ),
        ],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
      );

      expect(mission, isNull);
    });
    test('resumes an interrupted session before linked or new work', () {
      const resume = KidsNextMission(
        type: KidsMissionType.resume,
        surahId: 113,
        ayahNumbers: [3],
      );

      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 3,
            completedAyahs: [1, 2, 3],
            status: KidsJourneyStageStatus.needsReview,
          ),
        ],
        resumableMission: resume,
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
      );

      expect(mission, resume);
    });

    test('stage with completion gaps skips to the first incomplete ayah', () {
      // K4: with ayahs 1 and 3 done, the count-based rule returned ayah 3 —
      // an already-memorized ayah. The gap-aware entity rule returns ayah 2.
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 5,
            completedAyahs: [1, 3],
            status: KidsJourneyStageStatus.current,
          ),
        ],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
      );

      expect(mission?.type, KidsMissionType.newMemorization);
      expect(mission?.surahId, 114);
      expect(mission?.ayahNumbers, const [2]);
    });

    test('nextAyahToStart skips gaps and wraps to the start when complete', () {
      // K4 single source of truth lives on the entity itself.
      const gapped = KidsJourneyStage(
        stageNumber: 1,
        surahId: 114,
        startAyah: 1,
        endAyah: 5,
        completedAyahs: [1, 3],
        status: KidsJourneyStageStatus.current,
      );
      expect(gapped.nextAyahToStart, 2);

      const complete = KidsJourneyStage(
        stageNumber: 1,
        surahId: 114,
        startAyah: 1,
        endAyah: 2,
        completedAyahs: [1, 2],
        status: KidsJourneyStageStatus.completed,
      );
      expect(complete.nextAyahToStart, 1);
    });

    test('resolveSkippingAyah keeps a due review ahead after completion', () {
      // K5: completing one ayah must not bury a due SRS review — the same
      // pipeline reruns with the ayah presumed completed.
      final mission = const KidsNextMissionResolver().resolveSkippingAyah(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 5,
            completedAyahs: [1],
            status: KidsJourneyStageStatus.current,
          ),
        ],
        reviewRecords: [_dueReviewRecord(surahId: 113, ayahNumber: 4)],
        now: DateTime.utc(2026, 9, 24),
        justCompletedSurahId: 114,
        justCompletedAyah: 1,
      );

      expect(mission?.type, KidsMissionType.dueReview);
      expect(mission?.surahId, 113);
      expect(mission?.startAyah, 4);
    });

    test('resolveSkippingAyah advances past the just-completed ayah', () {
      final mission = const KidsNextMissionResolver().resolveSkippingAyah(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 5,
            completedAyahs: [1, 2],
            status: KidsJourneyStageStatus.current,
          ),
        ],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 24),
        justCompletedSurahId: 114,
        justCompletedAyah: 2,
      );

      expect(mission?.type, KidsMissionType.newMemorization);
      expect(mission?.ayahNumbers, const [3]);
    });

    test(
      'resolveSkippingAyah advances to the next surah on stage completion',
      () {
        final mission = const KidsNextMissionResolver().resolveSkippingAyah(
          activeSurahId: 114,
          stages: const [
            KidsJourneyStage(
              stageNumber: 1,
              surahId: 114,
              startAyah: 1,
              endAyah: 6,
              completedAyahs: [1, 2, 3, 4, 5, 6],
              status: KidsJourneyStageStatus.completed,
            ),
          ],
          reviewRecords: const [],
          now: DateTime.utc(2026, 9, 24),
          justCompletedSurahId: 114,
          justCompletedAyah: 6,
        );

        expect(mission?.surahId, 113);
        expect(mission?.startAyah, 1);
      },
    );

    test('a reached new-ayah quota never offers new memorization (N3)', () {
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: [_currentStage],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
        budget: const KidsDailyBudget(
          newAyahsCompletedToday: 1,
          maxNewAyahsPerDay: 1,
        ),
      );

      expect(mission, isNull);
    });

    test('resume and due reviews stay available after the new-ayah quota', () {
      const quota = KidsDailyBudget(
        newAyahsCompletedToday: 1,
        maxNewAyahsPerDay: 1,
      );
      const resume = KidsNextMission(
        type: KidsMissionType.resume,
        surahId: 114,
        ayahNumbers: [2],
      );
      expect(
        const KidsNextMissionResolver().resolve(
          activeSurahId: 114,
          stages: [_currentStage],
          resumableMission: resume,
          reviewRecords: const [],
          now: DateTime.utc(2026, 9, 1),
          budget: quota,
        ),
        resume,
      );
      expect(
        const KidsNextMissionResolver()
            .resolve(
              activeSurahId: 114,
              stages: [_currentStage],
              reviewRecords: [_dueReviewRecord(surahId: 114, ayahNumber: 1)],
              now: DateTime.utc(2026, 9, 1),
              budget: quota,
            )
            ?.type,
        KidsMissionType.dueReview,
      );
    });

    test('a stale resume outside a locked path is never offered', () {
      // Al-Baqarah is not on the Juz Amma adventure (a session left over from
      // before the child's path was selected).
      const staleResume = KidsNextMission(
        type: KidsMissionType.resume,
        surahId: 2,
        ayahNumbers: [1],
      );
      const quota = KidsDailyBudget(
        newAyahsCompletedToday: 1,
        maxNewAyahsPerDay: 1,
      );

      expect(
        const KidsNextMissionResolver().resolve(
          activeSurahId: 114,
          stages: [_currentStage],
          resumableMission: staleResume,
          reviewRecords: const [],
          now: DateTime.utc(2026, 9, 1),
          budget: quota,
        ),
        isNull,
      );
      // Without a quota the child continues the path, not the stale surah.
      expect(
        const KidsNextMissionResolver()
            .resolve(
              activeSurahId: 114,
              stages: [_currentStage],
              resumableMission: staleResume,
              reviewRecords: const [],
              now: DateTime.utc(2026, 9, 1),
            )
            ?.surahId,
        114,
      );
    });

    test('a resume in any surah stays valid on a free Quran path', () {
      const resume = KidsNextMission(
        type: KidsMissionType.resume,
        surahId: 2,
        ayahNumbers: [1],
      );

      expect(
        const KidsNextMissionResolver().resolve(
          activeSurahId: 2,
          stages: const [],
          resumableMission: resume,
          reviewRecords: const [],
          now: DateTime.utc(2026, 9, 1),
          path: KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromFatiha),
        ),
        resume,
      );
    });

    test('a weak pass recorded today is not due again the same day (N5)', () {
      final now = DateTime(2026, 9, 1, 18);
      final mission = const KidsNextMissionResolver().resolveSkippingAyah(
        activeSurahId: 114,
        stages: [_currentStage],
        reviewRecords: [
          _weakRecord(ayahNumber: 1, reviewedAt: DateTime(2026, 9, 1, 17)),
        ],
        now: now,
        justCompletedSurahId: 114,
        justCompletedAyah: 1,
      );

      // A guardian-assisted pass is followed by the next ayah, not a replay.
      expect(mission?.type, KidsMissionType.newMemorization);
      expect(mission?.startAyah, 2);
    });

    test('a weak pass from a previous day is due before its SM-2 date', () {
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: [_currentStage],
        reviewRecords: [
          _weakRecord(ayahNumber: 1, reviewedAt: DateTime(2026, 8, 31, 17)),
        ],
        now: DateTime(2026, 9, 1, 9),
      );

      expect(mission?.type, KidsMissionType.dueReview);
      expect(mission?.startAyah, 1);
    });

    test('resolveSkippingAyah honours the daily review budget (N2)', () {
      final mission = const KidsNextMissionResolver().resolveSkippingAyah(
        activeSurahId: 114,
        stages: [_currentStage],
        reviewRecords: [_dueReviewRecord(surahId: 114, ayahNumber: 1)],
        now: DateTime.utc(2026, 9, 1),
        justCompletedSurahId: 114,
        justCompletedAyah: 2,
        budget: const KidsDailyBudget(
          dueReviewsCompletedToday: 3,
          maxDueReviewsPerDay: 3,
        ),
      );

      // Same answer the home screen gives once the review budget is spent.
      expect(mission?.type, KidsMissionType.newMemorization);
      expect(mission?.startAyah, 3);
    });
  });

  group('KidsDailyBudget.fromLogs', () {
    test('counts only today logs of new and due-review work', () {
      final now = DateTime(2026, 9, 1, 12);
      KidsSessionLog log(String id, DateTime at, KidsMissionType type) =>
          KidsSessionLog(
            id: id,
            surahId: 114,
            ayahNumber: 1,
            repeatsCompleted: 1,
            pointsEarned: 10,
            completedAt: at,
            missionType: type,
          );
      final budget = KidsDailyBudget.fromLogs(
        logs: [
          log('a', DateTime(2026, 9, 1, 8), KidsMissionType.newMemorization),
          log('b', DateTime(2026, 8, 31, 20), KidsMissionType.newMemorization),
          log('c', DateTime(2026, 9, 1, 9), KidsMissionType.dueReview),
          log('d', DateTime(2026, 9, 1, 10), KidsMissionType.linkedReview),
        ],
        policy: KidsSessionPolicy.forAge(6),
        now: now,
      );

      expect(budget.newAyahsCompletedToday, 1);
      expect(budget.dueReviewsCompletedToday, 1);
      expect(budget.newAyahLimitReached, isTrue); // age 6 → 1 new ayah
      expect(budget.dueReviewBudgetExhausted, isTrue); // age 6 → 1 review
    });

    test("sums only today's session time (K36)", () {
      KidsSessionLog timed(String id, DateTime at, int seconds) =>
          KidsSessionLog(
            id: id,
            surahId: 114,
            ayahNumber: 1,
            repeatsCompleted: 1,
            pointsEarned: 10,
            completedAt: at,
            durationSeconds: seconds,
          );
      final budget = KidsDailyBudget.fromLogs(
        logs: [
          timed('a', DateTime(2026, 9, 1, 8), 300),
          timed('b', DateTime(2026, 8, 31, 20), 900), // yesterday
          timed('c', DateTime(2026, 9, 1, 9), 120),
        ],
        policy: KidsSessionPolicy.forAge(6),
        now: DateTime(2026, 9, 1, 12),
      );

      expect(budget.sessionSecondsToday, 420);
      expect(budget.sessionGoalReached(7), isTrue);
      expect(budget.sessionGoalReached(8), isFalse);
      // No goal, or old logs with no recorded time, never trigger it.
      expect(budget.sessionGoalReached(0), isFalse);
      expect(KidsDailyBudget.unlimited.sessionGoalReached(6), isFalse);
    });

    test('a missing policy is unlimited (fail-open)', () {
      final budget = KidsDailyBudget.fromLogs(
        logs: const [],
        policy: null,
        now: DateTime(2026, 9, 1),
      );
      expect(budget.newAyahLimitReached, isFalse);
      expect(budget.dueReviewBudgetExhausted, isFalse);
    });
  });

  group('journey continuation (K17)', () {
    const finished114 = KidsJourneyStage(
      stageNumber: 1,
      surahId: 114,
      startAyah: 1,
      endAyah: 6,
      completedAyahs: [1, 2, 3, 4, 5, 6],
      status: KidsJourneyStageStatus.completed,
    );
    const finished113 = KidsJourneyStage(
      stageNumber: 1,
      surahId: 113,
      startAyah: 1,
      endAyah: 5,
      completedAyahs: [1, 2, 3, 4, 5],
      status: KidsJourneyStageStatus.completed,
    );
    const inProgress112 = KidsJourneyStage(
      stageNumber: 1,
      surahId: 112,
      startAyah: 1,
      endAyah: 4,
      completedAyahs: [1, 2],
      status: KidsJourneyStageStatus.current,
    );

    Future<List<KidsJourneyStage>?> Function(int) loader(
      Map<int, List<KidsJourneyStage>?> bySurah,
    ) =>
        (surahId) async => bySurah[surahId];

    test(
      'skips an already memorized next surah to the real frontier',
      () async {
        const resolver = KidsNextMissionResolver();
        final continuation = await resolver.findContinuation(
          activeSurahId: 114,
          stages: const [finished114],
          loadStages: loader({
            113: const [finished113],
            112: const [inProgress112],
          }),
        );

        final mission = resolver.resolve(
          activeSurahId: 114,
          stages: const [finished114],
          reviewRecords: const [],
          now: DateTime.utc(2026, 9, 1),
          continuation: continuation,
        );

        expect(mission?.type, KidsMissionType.newMemorization);
        expect(mission?.surahId, 112);
        expect(mission?.ayahNumbers, const [3]);
      },
    );

    test('is not needed while the active surah still has open work', () async {
      final continuation = await const KidsNextMissionResolver()
          .findContinuation(
            activeSurahId: 114,
            stages: const [_currentStage],
            loadStages: (_) async => fail('must not load other surahs'),
          );

      expect(continuation, isNull);
    });

    test('ends the journey when every remaining surah is memorized', () async {
      const resolver = KidsNextMissionResolver(lastJuzAmmaSurahId: 112);
      final continuation = await resolver.findContinuation(
        activeSurahId: 114,
        stages: const [finished114],
        loadStages: loader({
          113: const [finished113],
          112: const [
            KidsJourneyStage(
              stageNumber: 1,
              surahId: 112,
              startAyah: 1,
              endAyah: 4,
              completedAyahs: [1, 2, 3, 4],
              status: KidsJourneyStageStatus.completed,
            ),
          ],
        }),
      );

      final mission = resolver.resolve(
        activeSurahId: 114,
        stages: const [finished114],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
        continuation: continuation,
      );

      expect(continuation, isNotNull);
      expect(mission, isNull);
    });

    test('an unreadable next journey cannot invent unlocked work', () async {
      final continuation = await const KidsNextMissionResolver()
          .findContinuation(
            activeSurahId: 114,
            stages: const [finished114],
            loadStages: loader({113: null}),
          );

      expect(continuation, isNotNull);
      expect(continuation?.mission, isNull);
    });

    test('a current stage with every ayah completed is not reopened', () {
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 3,
            completedAyahs: [1, 2, 3],
            status: KidsJourneyStageStatus.current,
          ),
        ],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
        continuation: const KidsJourneyContinuation(
          KidsNextMission(
            type: KidsMissionType.newMemorization,
            surahId: 113,
            ayahNumbers: [1],
          ),
        ),
      );

      expect(mission?.surahId, 113);
    });
  });

  group('Al-Fatiha opens the journey (K27)', () {
    const finishedFatiha = KidsJourneyStage(
      stageNumber: 1,
      surahId: 1,
      startAyah: 1,
      endAyah: 7,
      completedAyahs: [1, 2, 3, 4, 5, 6, 7],
      status: KidsJourneyStageStatus.completed,
    );

    test('after Al-Fatiha the journey moves on to An-Nas', () {
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 1,
        stages: const [finishedFatiha],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
      );

      expect(mission?.type, KidsMissionType.newMemorization);
      expect(mission?.surahId, 114);
      expect(mission?.ayahNumbers, const [1]);
    });

    test('the look-ahead continues past Al-Fatiha', () async {
      const resolver = KidsNextMissionResolver();
      final continuation = await resolver.findContinuation(
        activeSurahId: 1,
        stages: const [finishedFatiha],
        loadStages: (surahId) async => surahId == 114
            ? const [
                KidsJourneyStage(
                  stageNumber: 1,
                  surahId: 114,
                  startAyah: 1,
                  endAyah: 6,
                  completedAyahs: [1],
                  status: KidsJourneyStageStatus.current,
                ),
              ]
            : null,
      );

      expect(continuation?.mission?.surahId, 114);
      expect(continuation?.mission?.ayahNumbers, const [2]);
    });
  });

  group('selected journey path', () {
    final quranFromNas = KidsJourneyPathDefinition.of(
      KidsJourneyPathId.quranFromNas,
    );
    final quranFromFatiha = KidsJourneyPathDefinition.of(
      KidsJourneyPathId.quranFromFatiha,
    );
    KidsJourneyStage done(int surahId) => KidsJourneyStage(
      stageNumber: 1,
      surahId: surahId,
      startAyah: 1,
      endAyah: 3,
      completedAyahs: const [1, 2, 3],
      status: KidsJourneyStageStatus.completed,
    );
    KidsJourneyStage open(int surahId) => KidsJourneyStage(
      stageNumber: 1,
      surahId: surahId,
      startAyah: 1,
      endAyah: 3,
      completedAyahs: const [1],
      status: KidsJourneyStageStatus.current,
    );

    test(
      'quran journey continues from 67 to 66 skipping a memorized 66',
      () async {
        const resolver = KidsNextMissionResolver();
        final loaded = <int>[];
        final continuation = await resolver.findContinuation(
          activeSurahId: 67,
          stages: [done(67)],
          path: quranFromNas,
          loadStages: (surahId) async {
            loaded.add(surahId);
            return switch (surahId) {
              66 => [done(66)],
              65 => [open(65)],
              _ => null,
            };
          },
        );

        expect(loaded, [66, 65]);
        expect(continuation?.mission?.type, KidsMissionType.newMemorization);
        expect(continuation?.mission?.surahId, 65);
        expect(continuation?.mission?.ayahNumbers, const [2]);
      },
    );

    test('quran journey from Fatiha: 1 -> 2', () async {
      const resolver = KidsNextMissionResolver();
      final continuation = await resolver.findContinuation(
        activeSurahId: 1,
        stages: [done(1)],
        path: quranFromFatiha,
        loadStages: (surahId) async => surahId == 2 ? [open(2)] : null,
      );
      final mission = resolver.resolve(
        activeSurahId: 1,
        stages: [done(1)],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
        path: quranFromFatiha,
      );

      expect(continuation?.mission?.surahId, 2);
      expect(mission?.surahId, 2);
      expect(mission?.ayahNumbers, const [1]);
    });

    test('adventure default is unchanged: 79 -> 78 then null', () async {
      const resolver = KidsNextMissionResolver();
      final mission = resolver.resolve(
        activeSurahId: 79,
        stages: [done(79)],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
      );
      final afterLast = resolver.resolve(
        activeSurahId: 78,
        stages: [done(78)],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
      );
      final continuation = await resolver.findContinuation(
        activeSurahId: 78,
        stages: [done(78)],
        loadStages: (_) async => fail('nothing follows An-Naba'),
      );

      expect(mission?.surahId, 78);
      expect(afterLast, isNull);
      expect(continuation?.mission, isNull);
    });

    test('due review of surah 67 still leads on the adventure path', () {
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: [open(114)],
        reviewRecords: [
          AyahReviewRecord(
            surahId: 67,
            ayahNumber: 1,
            strengthLevel: 1,
            intervalDays: 1,
            lastReviewedAt: DateTime.utc(2026, 8, 30),
            nextReviewDate: DateTime.utc(2026, 8, 31),
            totalReviews: 1,
            lastRating: PerformanceRating.average,
            createdByMode: ReviewRecordCreatedByMode.kidsMode,
          ),
        ],
        now: DateTime.utc(2026, 9, 1),
        path: KidsJourneyPathDefinition.adventure,
      );

      expect(mission?.type, KidsMissionType.dueReview);
      expect(mission?.surahId, 67);
      expect(mission?.ayahNumbers, const [1]);
    });
  });

  group('daily goal cap (K18)', () {
    const finished114 = KidsJourneyStage(
      stageNumber: 1,
      surahId: 114,
      startAyah: 1,
      endAyah: 6,
      completedAyahs: [1, 2, 3, 4, 5, 6],
      status: KidsJourneyStageStatus.completed,
    );
    const capped = KidsDailyBudget(
      newAyahsCompletedToday: 1,
      maxNewAyahsPerDay: 1,
    );

    test(
      'a finished surah on a capped day is a day end, not the journey end',
      () {
        const resolver = KidsNextMissionResolver();
        KidsNextMission? resolveWith(KidsDailyBudget budget) =>
            resolver.resolve(
              activeSurahId: 114,
              stages: const [finished114],
              reviewRecords: const [],
              now: DateTime.utc(2026, 9, 1),
              budget: budget,
              continuation: const KidsJourneyContinuation(
                KidsNextMission(
                  type: KidsMissionType.newMemorization,
                  surahId: 113,
                  ayahNumbers: [1],
                ),
              ),
            );

        final mission = resolveWith(capped);

        expect(mission, isNull);
        expect(
          resolver.dailyGoalCap(
            mission: mission,
            budget: capped,
            resolveWith: resolveWith,
          ),
          1,
        );
      },
    );

    test('a truly finished journey never reports a daily cap', () {
      const resolver = KidsNextMissionResolver();
      KidsNextMission? resolveWith(KidsDailyBudget budget) => resolver.resolve(
        activeSurahId: 114,
        stages: const [finished114],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
        budget: budget,
        continuation: const KidsJourneyContinuation(null),
      );

      expect(
        resolver.dailyGoalCap(
          mission: resolveWith(capped),
          budget: capped,
          resolveWith: resolveWith,
        ),
        isNull,
      );
    });
  });

  group('spent review budget (K19)', () {
    test('never loops the child on a linked stage review', () {
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 3,
            completedAyahs: [1, 2, 3],
            status: KidsJourneyStageStatus.needsReview,
          ),
          KidsJourneyStage(
            stageNumber: 2,
            surahId: 114,
            startAyah: 4,
            endAyah: 6,
            completedAyahs: [],
            status: KidsJourneyStageStatus.current,
          ),
        ],
        reviewRecords: [_dueReviewRecord(surahId: 114, ayahNumber: 3)],
        now: DateTime.utc(2026, 9, 2),
        budget: const KidsDailyBudget(
          dueReviewsCompletedToday: 3,
          maxDueReviewsPerDay: 3,
          maxNewAyahsPerDay: 2,
        ),
      );

      expect(mission?.type, KidsMissionType.newMemorization);
      expect(mission?.ayahNumbers, const [4]);
    });
  });

  group('validated remote next-surah hint', () {
    const finished = KidsJourneyStage(
      stageNumber: 1,
      surahId: 114,
      startAyah: 1,
      endAyah: 3,
      completedAyahs: [1, 2, 3],
      status: KidsJourneyStageStatus.completed,
    );
    const hintedOpen = KidsJourneyStage(
      stageNumber: 2,
      surahId: 67,
      startAyah: 1,
      endAyah: 5,
      completedAyahs: [1, 2, 3],
      status: KidsJourneyStageStatus.current,
    );

    Future<List<KidsJourneyStage>?> hintedStages(int surahId) async =>
        surahId == 67 ? const [hintedOpen] : null;

    test('uses a hinted surah only from its loaded current stage', () async {
      final mission = await const KidsNextMissionResolver()
          .resolveWithRemoteHint(
            activeSurahId: 114,
            stages: const [finished],
            reviewRecords: const [],
            now: DateTime.utc(2026, 9, 1),
            continuation: const KidsJourneyContinuation(null),
            hintedSurahId: 67,
            loadStages: hintedStages,
          );

      expect(mission?.type, KidsMissionType.newMemorization);
      expect(mission?.surahId, 67);
      expect(mission?.ayahNumbers, const [4]);
    });

    test('hint never displaces due review, resume, or continuation', () async {
      const resume = KidsNextMission(
        type: KidsMissionType.resume,
        surahId: 113,
        ayahNumbers: [2],
      );
      const continuation = KidsJourneyContinuation(
        KidsNextMission(
          type: KidsMissionType.newMemorization,
          surahId: 112,
          ayahNumbers: [3],
        ),
      );
      const resolver = KidsNextMissionResolver();

      final due = await resolver.resolveWithRemoteHint(
        activeSurahId: 114,
        stages: const [finished],
        reviewRecords: [_dueReviewRecord(surahId: 114, ayahNumber: 1)],
        now: DateTime.utc(2026, 9, 1),
        hintedSurahId: 67,
        loadStages: hintedStages,
      );
      final resumed = await resolver.resolveWithRemoteHint(
        activeSurahId: 114,
        stages: const [finished],
        resumableMission: resume,
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
        hintedSurahId: 67,
        loadStages: hintedStages,
      );
      final continued = await resolver.resolveWithRemoteHint(
        activeSurahId: 114,
        stages: const [finished],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
        continuation: continuation,
        hintedSurahId: 67,
        loadStages: hintedStages,
      );

      expect(due?.type, KidsMissionType.dueReview);
      expect(resumed, resume);
      expect(continued, continuation.mission);
    });

    test('hint can replace an untouched default but never a started gap at ayah one', () async {
      const resolver = KidsNextMissionResolver();
      const untouched = KidsJourneyStage(
        stageNumber: 1, surahId: 113, startAyah: 1, endAyah: 5,
        completedAyahs: [], status: KidsJourneyStageStatus.current,
      );
      final suggested = await resolver.resolveWithRemoteHint(
        activeSurahId: 113, stages: const [untouched], reviewRecords: const [],
        now: DateTime.utc(2026), hintedSurahId: 67, loadStages: hintedStages,
      );
      final started = await resolver.resolveWithRemoteHint(
        activeSurahId: 113, stages: [untouched.copyWithAddedCompletedAyah(2)],
        reviewRecords: const [], now: DateTime.utc(2026),
        hintedSurahId: 67, loadStages: hintedStages,
      );
      expect(suggested?.surahId, 67);
      expect(started?.surahId, 113);
      expect(started?.ayahNumbers, [1]);
    });

    test('hint cannot bypass the new-ayah cap or a locked target', () async {
      const resolver = KidsNextMissionResolver();
      final capped = await resolver.resolveWithRemoteHint(
        activeSurahId: 114,
        stages: const [finished],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
        budget: const KidsDailyBudget(
          newAyahsCompletedToday: 1,
          maxNewAyahsPerDay: 1,
        ),
        hintedSurahId: 67,
        loadStages: hintedStages,
      );
      final locked = await resolver.resolveWithRemoteHint(
        activeSurahId: 114,
        stages: const [finished],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
        continuation: const KidsJourneyContinuation(null),
        hintedSurahId: 67,
        loadStages: (_) async => const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 67,
            startAyah: 1,
            endAyah: 5,
            completedAyahs: [],
            status: KidsJourneyStageStatus.locked,
          ),
        ],
      );

      expect(capped, isNull);
      expect(locked, isNull);
    });

    test('skipping an ayah applies the same hint safety rules', () async {
      final mission = await const KidsNextMissionResolver()
          .resolveSkippingAyahWithRemoteHint(
            activeSurahId: 114,
            stages: const [finished],
            reviewRecords: const [],
            now: DateTime.utc(2026, 9, 1),
            justCompletedSurahId: 114,
            justCompletedAyah: 3,
            continuation: const KidsJourneyContinuation(null),
            hintedSurahId: 67,
            loadStages: hintedStages,
          );

      expect(mission?.surahId, 67);
      expect(mission?.ayahNumbers, const [4]);
    });
  });
}

const _currentStage = KidsJourneyStage(
  stageNumber: 1,
  surahId: 114,
  startAyah: 1,
  endAyah: 5,
  completedAyahs: [1],
  status: KidsJourneyStageStatus.current,
);

AyahReviewRecord _weakRecord({
  required int ayahNumber,
  required DateTime reviewedAt,
}) => AyahReviewRecord(
  surahId: 114,
  ayahNumber: ayahNumber,
  strengthLevel: 0,
  intervalDays: 1,
  lastReviewedAt: reviewedAt,
  nextReviewDate: reviewedAt.add(const Duration(days: 1)),
  totalReviews: 1,
  lastRating: PerformanceRating.weak,
  createdByMode: ReviewRecordCreatedByMode.kidsMode,
);

AyahReviewRecord _dueReviewRecord({
  required int surahId,
  required int ayahNumber,
}) => AyahReviewRecord(
  surahId: surahId,
  ayahNumber: ayahNumber,
  strengthLevel: 5,
  intervalDays: 1,
  lastReviewedAt: DateTime.utc(2026, 8, 30),
  nextReviewDate: DateTime.utc(2026, 9, 1),
  totalReviews: 2,
  lastRating: PerformanceRating.excellent,
  createdByMode: ReviewRecordCreatedByMode.kidsMode,
);
