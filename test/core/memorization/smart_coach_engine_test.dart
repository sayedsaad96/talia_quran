import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/memorization_snapshot.dart';
import 'package:talia_quran/core/memorization/smart_coach_engine.dart';
import 'package:talia_quran/core/memorization/smart_coach_recommendation.dart';
import 'package:talia_quran/features/hifz/domain/entities/hifz_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  const engine = SmartCoachEngine();

  group('SmartCoachEngine — adult MemPlus', () {
    test('prioritizes due near revision over daily plan progress', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          AyahReviewRecord(
            surahId: 67,
            ayahNumber: 1,
            strengthLevel: 3,
            intervalDays: 1,
            lastReviewedAt: now.subtract(const Duration(days: 2)),
            nextReviewDate: now.subtract(const Duration(days: 1)),
            totalReviews: 2,
            lastRating: PerformanceRating.average,
          ),
        ],
        cachedDailyPlan: DailyPlan(
          generatedAt: now,
          surahId: 67,
          newAyahs: const [],
          nearRevision: const [],
          farRevision: const [],
          completedAyahNums: const [2, 3],
        ),
      );

      final recommendation = engine.recommend(snapshot);

      expect(recommendation?.kind, SmartCoachRecommendationKind.reviewDueNear);
      expect(recommendation?.surahId, 67);
      expect(recommendation?.startAyah, 1);
      expect(recommendation?.route, contains('daily-plan'));
    });

    test('recommends weak due ayah via quiz route', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          AyahReviewRecord(
            surahId: 67,
            ayahNumber: 5,
            strengthLevel: 1,
            intervalDays: 1,
            lastReviewedAt: now.subtract(const Duration(days: 1)),
            nextReviewDate: now.subtract(const Duration(hours: 1)),
            totalReviews: 3,
            lastRating: PerformanceRating.weak,
          ),
          AyahReviewRecord(
            surahId: 67,
            ayahNumber: 1,
            strengthLevel: 3,
            intervalDays: 1,
            lastReviewedAt: now.subtract(const Duration(days: 2)),
            nextReviewDate: now.subtract(const Duration(days: 1)),
            totalReviews: 2,
            lastRating: PerformanceRating.average,
          ),
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(recommendation?.kind, SmartCoachRecommendationKind.reviewWeakAyah);
      expect(recommendation?.startAyah, 5);
      expect(recommendation?.route, contains('quiz'));
    });

    test('recommends continuing incomplete daily plan when nothing is due', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          AyahReviewRecord(
            surahId: 67,
            ayahNumber: 1,
            strengthLevel: 6,
            intervalDays: 30,
            lastReviewedAt: now,
            nextReviewDate: now.add(const Duration(days: 30)),
            totalReviews: 5,
            lastRating: PerformanceRating.excellent,
          ),
        ],
        cachedDailyPlan: DailyPlan(
          generatedAt: now,
          surahId: 67,
          newAyahs: const [
            DailyPlanAyah(
              surahId: 67,
              ayahNumber: 2,
              ayahText: 'text',
              record: null,
            ),
          ],
          // P0 hotfix: ayah 1 must be in a required section for
          // requiredCompletedCount to recognise its completion.
          nearRevision: const [
            DailyPlanAyah(
              surahId: 67,
              ayahNumber: 1,
              ayahText: 'text',
              record: null,
            ),
          ],
          farRevision: const [],
          completedAyahNums: const [1],
        ),
      );

      final recommendation = engine.recommend(snapshot);

      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.continueDailyPlan,
      );
      expect(recommendation?.completedCount, 1);
      expect(recommendation?.totalCount, 2);
    });

    // ── Objective 1: Exact-ayah quiz routing ──────────────────────────────

    test('weak due recommendation route includes exact ayahNumbers param', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          AyahReviewRecord(
            surahId: 67,
            ayahNumber: 5,
            strengthLevel: 1,
            intervalDays: 1,
            lastReviewedAt: now.subtract(const Duration(days: 1)),
            nextReviewDate: now.subtract(const Duration(hours: 1)),
            totalReviews: 3,
            lastRating: PerformanceRating.weak,
          ),
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(recommendation?.kind, SmartCoachRecommendationKind.reviewWeakAyah);
      expect(
        recommendation?.route,
        '/memorization-plus/quiz?surahId=67&ayahNumbers=5',
      );
    });

    test(
      'memorized-due recommendation route includes exact ayahNumbers param',
      () {
        final now = DateTime.now().toUtc();
        final snapshot = MemorizationSnapshot(
          profile: _adultProfile(),
          reviewRecords: [
            _memorizedDueRecord(now: now, ayahNumber: 7, strengthLevel: 6),
          ],
        );

        final recommendation = engine.recommend(snapshot);

        expect(
          recommendation?.kind,
          SmartCoachRecommendationKind.memorizedReviewDue,
        );
        expect(
          recommendation?.route,
          '/memorization-plus/quiz?surahId=67&ayahNumbers=7',
        );
      },
    );

    test('memorized-due recommendation includes correct surahId in route', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(now: now, surahId: 114, ayahNumber: 3),
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(recommendation?.surahId, 114);
      expect(recommendation?.route, contains('surahId=114'));
    });

    test('near/far due routes use daily-plan (not quiz)', () {
      final now = DateTime.now().toUtc();
      final nearSnapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [_dueRecord(now: now, ayahNumber: 1)],
      );
      final farSnapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _dueRecord(
            now: now,
            ayahNumber: 2,
            lastReviewedAt: now.subtract(const Duration(days: 10)),
          ),
        ],
      );

      expect(
        engine.recommend(nearSnapshot)?.route,
        contains('daily-plan'),
        reason: 'near revision uses daily-plan route',
      );
      expect(
        engine.recommend(farSnapshot)?.route,
        contains('daily-plan'),
        reason: 'far revision uses daily-plan route',
      );
    });

    test('hifz due route is exactly /hifz', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        hifzDueReviews: [
          AyahProgress(
            surahId: 1,
            ayahNumber: 3,
            status: AyahStatus.review,
            repetitions: 2,
            nextReviewDate: now.subtract(const Duration(days: 1)),
            lastReviewDate: now.subtract(const Duration(days: 3)),
          ),
        ],
      );

      expect(engine.recommend(snapshot)?.route, '/hifz');
    });

    test('kids route is exactly kids-home', () {
      final snapshot = MemorizationSnapshot(
        profile: _childProfile(),
        kidsSessionLogs: [
          KidsSessionLog(
            id: '1',
            surahId: 114,
            ayahNumber: 1,
            repeatsCompleted: 3,
            pointsEarned: 10,
            completedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );

      expect(engine.recommend(snapshot)?.route, contains('kids-home'));
    });

    // ── Objective 2: Explanation codes ────────────────────────────────────

    test('weak due recommendation has weakAyahDue explanation code', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          AyahReviewRecord(
            surahId: 67,
            ayahNumber: 5,
            strengthLevel: 1,
            intervalDays: 1,
            lastReviewedAt: now.subtract(const Duration(days: 1)),
            nextReviewDate: now.subtract(const Duration(hours: 1)),
            totalReviews: 3,
            lastRating: PerformanceRating.weak,
          ),
        ],
      );

      expect(
        engine.recommend(snapshot)?.explanationCode,
        SmartCoachExplanationCode.weakAyahDue,
      );
    });

    test(
      'memorized-due recommendation has memorizedRetentionDue explanation code',
      () {
        final now = DateTime.now().toUtc();
        final snapshot = MemorizationSnapshot(
          profile: _adultProfile(),
          reviewRecords: [_memorizedDueRecord(now: now)],
        );

        expect(
          engine.recommend(snapshot)?.explanationCode,
          SmartCoachExplanationCode.memorizedRetentionDue,
        );
      },
    );

    test(
      'continueDailyPlan recommendation has continueDailyPlan explanation code',
      () {
        final now = DateTime.now().toUtc();
        final snapshot = MemorizationSnapshot(
          profile: _adultProfile(),
          reviewRecords: [],
          cachedDailyPlan: DailyPlan(
            generatedAt: now,
            surahId: 67,
            newAyahs: const [
              DailyPlanAyah(
                surahId: 67,
                ayahNumber: 2,
                ayahText: 'text',
                record: null,
              ),
            ],
            // P0 hotfix: ayah 1 must be in a required section for
            // requiredCompletedCount to recognise its completion.
            nearRevision: const [
              DailyPlanAyah(
                surahId: 67,
                ayahNumber: 1,
                ayahText: 'text',
                record: null,
              ),
            ],
            farRevision: const [],
            completedAyahNums: const [1],
          ),
        );

        expect(
          engine.recommend(snapshot)?.explanationCode,
          SmartCoachExplanationCode.continueDailyPlan,
        );
      },
    );

    test(
      'kids mission recommendation has kidsMissionAvailable explanation code',
      () {
        final snapshot = MemorizationSnapshot(
          profile: _childProfile(),
          kidsSessionLogs: [
            KidsSessionLog(
              id: '1',
              surahId: 114,
              ayahNumber: 1,
              repeatsCompleted: 3,
              pointsEarned: 10,
              completedAt: DateTime.utc(2026, 1, 1),
            ),
          ],
        );

        expect(
          engine.recommend(snapshot)?.explanationCode,
          SmartCoachExplanationCode.kidsMissionAvailable,
        );
      },
    );

    test('explanationCode is optional/null when not set on recommendation', () {
      // SmartCoachRecommendation without explanationCode is still valid.
      const rec = SmartCoachRecommendation(
        kind: SmartCoachRecommendationKind.reviewDueNear,
        route: '/memorization-plus/daily-plan?surahId=67',
      );
      expect(rec.explanationCode, isNull);
    });

    // ── Objective 3: Tie-breakers ─────────────────────────────────────────

    test('weak due chooses lowest strength first', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _weakRecord(now: now, ayahNumber: 10, strengthLevel: 3),
          _weakRecord(now: now, ayahNumber: 20, strengthLevel: 1), // weakest
          _weakRecord(now: now, ayahNumber: 30, strengthLevel: 2),
        ],
      );

      expect(engine.recommend(snapshot)?.startAyah, 20);
    });

    test('weak due tie-breaks by oldest due date when strength is equal', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _weakRecord(
            now: now,
            ayahNumber: 10,
            strengthLevel: 1,
            nextReviewDate: now.subtract(const Duration(hours: 1)),
          ),
          _weakRecord(
            now: now,
            ayahNumber: 20,
            strengthLevel: 1,
            nextReviewDate: now.subtract(const Duration(days: 3)), // oldest
          ),
        ],
      );

      expect(engine.recommend(snapshot)?.startAyah, 20);
    });

    test('memorized-due chooses oldest due date first', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(
            now: now,
            ayahNumber: 5,
            nextReviewDate: now.subtract(const Duration(days: 2)),
          ),
          _memorizedDueRecord(
            now: now,
            ayahNumber: 6,
            nextReviewDate: now.subtract(const Duration(days: 3)), // oldest
          ),
        ],
      );

      expect(engine.recommend(snapshot)?.startAyah, 6);
    });

    test('memorized-due tie-breaks by lower strength when date is equal', () {
      final now = DateTime.now().toUtc();
      final sameDate = now.subtract(const Duration(days: 3));
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(
            now: now,
            ayahNumber: 5,
            strengthLevel: 8,
            nextReviewDate: sameDate,
          ),
          _memorizedDueRecord(
            now: now,
            ayahNumber: 6,
            strengthLevel: 6, // lower strength
            nextReviewDate: sameDate,
          ),
        ],
      );

      expect(engine.recommend(snapshot)?.startAyah, 6);
    });

    // ── Priority order regression ──────────────────────────────────────────

    test('recommends memorized-due ayah via quiz route', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(
            now: now,
            ayahNumber: 5,
            strengthLevel: 7,
            nextReviewDate: now.subtract(const Duration(days: 2)),
          ),
          _memorizedDueRecord(
            now: now,
            ayahNumber: 6,
            strengthLevel: 8,
            nextReviewDate: now.subtract(const Duration(days: 3)),
          ),
          _memorizedDueRecord(
            now: now,
            ayahNumber: 7,
            strengthLevel: 6,
            nextReviewDate: now.subtract(const Duration(days: 3)),
          ),
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.memorizedReviewDue,
      );
      // ayah 6: oldest date (days 3), and lowest strength among tied dates is ayah 7
      // Both 6 and 7 share days=3; ayah 7 has lower strength (6 < 8), so ayah 7 wins.
      expect(recommendation?.startAyah, 7);
      expect(recommendation?.route, contains('quiz'));
      expect(recommendation?.route, contains('ayahNumbers=7'));
    });

    test('prioritizes weak due ayah over memorized-due retention review', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(now: now, ayahNumber: 7),
          _dueRecord(
            now: now,
            ayahNumber: 5,
            strengthLevel: 1,
            lastRating: PerformanceRating.weak,
          ),
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(recommendation?.kind, SmartCoachRecommendationKind.reviewWeakAyah);
      expect(recommendation?.startAyah, 5);
    });

    test('prioritizes near due review over memorized-due retention review', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(now: now, ayahNumber: 7),
          _dueRecord(now: now, ayahNumber: 2),
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(recommendation?.kind, SmartCoachRecommendationKind.reviewDueNear);
      expect(recommendation?.startAyah, 2);
    });

    test('prioritizes far due review over memorized-due retention review', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(now: now, ayahNumber: 7),
          _dueRecord(
            now: now,
            ayahNumber: 3,
            lastReviewedAt: now.subtract(const Duration(days: 10)),
          ),
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(recommendation?.kind, SmartCoachRecommendationKind.reviewDueFar);
      expect(recommendation?.startAyah, 3);
    });

    test('prioritizes memorized-due over continuing daily plan', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [_memorizedDueRecord(now: now)],
        cachedDailyPlan: _dailyPlan(
          now: now,
          newAyahs: const [
            DailyPlanAyah(
              surahId: 67,
              ayahNumber: 2,
              ayahText: 'text',
              record: null,
            ),
          ],
          completedAyahNums: const [1],
        ),
      );

      final recommendation = engine.recommend(snapshot);

      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.memorizedReviewDue,
      );
    });

    test('prioritizes memorized-due over new ayahs in daily plan', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [_memorizedDueRecord(now: now)],
        cachedDailyPlan: _dailyPlan(
          now: now,
          newAyahs: const [
            DailyPlanAyah(
              surahId: 67,
              ayahNumber: 2,
              ayahText: 'text',
              record: null,
            ),
          ],
        ),
      );

      final recommendation = engine.recommend(snapshot);

      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.memorizedReviewDue,
      );
    });

    test('near/far priorities remain above memorized-due', () {
      final now = DateTime.now().toUtc();

      // Near > memorized-due
      final nearSnapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(now: now, ayahNumber: 7),
          _dueRecord(now: now, ayahNumber: 2),
        ],
      );
      expect(
        engine.recommend(nearSnapshot)?.kind,
        SmartCoachRecommendationKind.reviewDueNear,
      );

      // Far > memorized-due
      final farSnapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(now: now, ayahNumber: 7),
          _dueRecord(
            now: now,
            ayahNumber: 3,
            lastReviewedAt: now.subtract(const Duration(days: 10)),
          ),
        ],
      );
      expect(
        engine.recommend(farSnapshot)?.kind,
        SmartCoachRecommendationKind.reviewDueFar,
      );
    });

    test('memorized-due remains above continue/new/Hifz fallback', () {
      final now = DateTime.now().toUtc();

      // Above continueDailyPlan
      final continueSnapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [_memorizedDueRecord(now: now)],
        cachedDailyPlan: _dailyPlan(
          now: now,
          newAyahs: const [
            DailyPlanAyah(
              surahId: 67,
              ayahNumber: 2,
              ayahText: 'text',
              record: null,
            ),
          ],
          completedAyahNums: const [1],
        ),
      );
      expect(
        engine.recommend(continueSnapshot)?.kind,
        SmartCoachRecommendationKind.memorizedReviewDue,
        reason: 'memorized-due before continueDailyPlan',
      );

      // Above Hifz fallback
      final hifzSnapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [_memorizedDueRecord(now: now)],
        hifzDueReviews: [
          AyahProgress(
            surahId: 1,
            ayahNumber: 3,
            status: AyahStatus.review,
            repetitions: 2,
            nextReviewDate: now.subtract(const Duration(days: 1)),
            lastReviewDate: now.subtract(const Duration(days: 3)),
          ),
        ],
      );
      expect(
        engine.recommend(hifzSnapshot)?.kind,
        SmartCoachRecommendationKind.memorizedReviewDue,
        reason: 'memorized-due before hifzReviewDue',
      );
    });
  });

  group('SmartCoachEngine — fallbacks', () {
    test('uses hifz due reviews when MemPlus has no actionable items', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        hifzDueReviews: [
          AyahProgress(
            surahId: 1,
            ayahNumber: 3,
            status: AyahStatus.review,
            repetitions: 2,
            nextReviewDate: now.subtract(const Duration(days: 1)),
            lastReviewDate: now.subtract(const Duration(days: 3)),
          ),
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(recommendation?.kind, SmartCoachRecommendationKind.hifzReviewDue);
      expect(recommendation?.route, '/hifz');
    });

    test('prioritizes memorized-due over Hifz fallback', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [_memorizedDueRecord(now: now)],
        hifzDueReviews: [
          AyahProgress(
            surahId: 1,
            ayahNumber: 3,
            status: AyahStatus.review,
            repetitions: 2,
            nextReviewDate: now.subtract(const Duration(days: 1)),
            lastReviewDate: now.subtract(const Duration(days: 3)),
          ),
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.memorizedReviewDue,
      );
      expect(recommendation?.route, contains('quiz'));
    });

    test('returns kids mission for child profile', () {
      final snapshot = MemorizationSnapshot(
        profile: _childProfile(),
        kidsSessionLogs: [
          KidsSessionLog(
            id: '1',
            surahId: 114,
            ayahNumber: 1,
            repeatsCompleted: 3,
            pointsEarned: 10,
            completedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.kidsCurrentMission,
      );
      expect(recommendation?.route, contains('kids-home'));
      expect(recommendation?.route, contains('surahId=114'));
    });

    test('does not inspect adult memorized-due records for child profile', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _childProfile(),
        reviewRecords: [_memorizedDueRecord(now: now)],
      );

      final recommendation = engine.recommend(snapshot);

      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.kidsCurrentMission,
      );
      expect(
        recommendation?.kind,
        isNot(SmartCoachRecommendationKind.memorizedReviewDue),
      );
    });
  });

  // ── Sprint 8B: source-aware filtering ──────────────────────────────────────

  group('SmartCoachEngine — Sprint 8B source filtering', () {
    test('adult Smart Coach ignores kidsMode memorized-due record', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(
            now: now,
            ayahNumber: 1,
          ).copyWith(createdByMode: ReviewRecordCreatedByMode.kidsMode),
        ],
      );
      final recommendation = engine.recommend(snapshot);
      expect(
        recommendation?.kind,
        isNot(SmartCoachRecommendationKind.memorizedReviewDue),
      );
      expect(recommendation, isNull);
    });

    test('adult Smart Coach ignores hifz memorized-due record', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(
            now: now,
            ayahNumber: 1,
          ).copyWith(createdByMode: ReviewRecordCreatedByMode.hifz),
        ],
      );
      final recommendation = engine.recommend(snapshot);
      expect(
        recommendation?.kind,
        isNot(SmartCoachRecommendationKind.memorizedReviewDue),
      );
      expect(recommendation, isNull);
    });

    test('adult Smart Coach accepts adultMemPlus memorized-due record', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(
            now: now,
            ayahNumber: 3,
          ).copyWith(createdByMode: ReviewRecordCreatedByMode.adultMemPlus),
        ],
      );
      final recommendation = engine.recommend(snapshot);
      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.memorizedReviewDue,
      );
      expect(recommendation?.startAyah, 3);
    });

    test(
      'adult Smart Coach accepts unknown memorized-due record (backward compat)',
      () {
        final now = DateTime.now().toUtc();
        final snapshot = MemorizationSnapshot(
          profile: _adultProfile(),
          reviewRecords: [
            _memorizedDueRecord(
              now: now,
              ayahNumber: 5,
            ).copyWith(createdByMode: ReviewRecordCreatedByMode.unknown),
          ],
        );
        final recommendation = engine.recommend(snapshot);
        expect(
          recommendation?.kind,
          SmartCoachRecommendationKind.memorizedReviewDue,
        );
        expect(recommendation?.startAyah, 5);
      },
    );

    test(
      'adult Smart Coach accepts migration memorized-due record (backward compat)',
      () {
        final now = DateTime.now().toUtc();
        final snapshot = MemorizationSnapshot(
          profile: _adultProfile(),
          reviewRecords: [
            _memorizedDueRecord(
              now: now,
              ayahNumber: 7,
            ).copyWith(createdByMode: ReviewRecordCreatedByMode.migration),
          ],
        );
        final recommendation = engine.recommend(snapshot);
        expect(
          recommendation?.kind,
          SmartCoachRecommendationKind.memorizedReviewDue,
        );
        expect(recommendation?.startAyah, 7);
      },
    );

    test('kidsMode does not shadow adultMemPlus memorized-due record', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(
            now: now,
            ayahNumber: 1,
          ).copyWith(createdByMode: ReviewRecordCreatedByMode.kidsMode),
          _memorizedDueRecord(
            now: now,
            ayahNumber: 9,
          ).copyWith(createdByMode: ReviewRecordCreatedByMode.adultMemPlus),
        ],
      );
      final recommendation = engine.recommend(snapshot);
      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.memorizedReviewDue,
      );
      expect(recommendation?.startAyah, 9);
    });

    test('exact-ayah quiz route still embeds ayah number after Sprint 8B', () {
      final now = DateTime.now().toUtc();
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(
            now: now,
            ayahNumber: 11,
          ).copyWith(createdByMode: ReviewRecordCreatedByMode.adultMemPlus),
        ],
      );
      final recommendation = engine.recommend(snapshot);
      expect(recommendation?.route, contains('quiz'));
      expect(recommendation?.route, contains('11'));
    });

    test(
      'routes memorizedReviewDue to Daily Plan when retention is in cached plan',
      () {
        final now = DateTime.now().toUtc();
        final snapshot = MemorizationSnapshot(
          profile: _adultProfile(),
          reviewRecords: [
            _memorizedDueRecord(
              now: now,
              ayahNumber: 5,
            ).copyWith(createdByMode: ReviewRecordCreatedByMode.adultMemPlus),
          ],
          cachedDailyPlan: _dailyPlan(
            now: now,
            retentionReview: const [
              DailyPlanAyah(
                surahId: 67,
                ayahNumber: 5,
                ayahText: 'text',
                record: null,
              ),
            ],
          ),
        );
        final recommendation = engine.recommend(snapshot);
        expect(
          recommendation?.kind,
          SmartCoachRecommendationKind.memorizedReviewDue,
        );
        expect(recommendation?.route, contains('daily-plan'));
        expect(recommendation?.route, isNot(contains('quiz')));
      },
    );

    test(
      'routes memorizedReviewDue to Quiz when retention ayah is not in cached plan',
      () {
        final now = DateTime.now().toUtc();
        final snapshot = MemorizationSnapshot(
          profile: _adultProfile(),
          reviewRecords: [
            _memorizedDueRecord(
              now: now,
              ayahNumber: 5,
            ).copyWith(createdByMode: ReviewRecordCreatedByMode.adultMemPlus),
          ],
          cachedDailyPlan: _dailyPlan(now: now),
        );
        final recommendation = engine.recommend(snapshot);
        expect(recommendation?.route, contains('quiz'));
        expect(recommendation?.route, contains('5'));
      },
    );

    test(
      'unknown memorized-due still routes to Quiz when not in Daily Plan retention',
      () {
        final now = DateTime.now().toUtc();
        final snapshot = MemorizationSnapshot(
          profile: _adultProfile(),
          reviewRecords: [
            _memorizedDueRecord(
              now: now,
              ayahNumber: 2,
            ).copyWith(createdByMode: ReviewRecordCreatedByMode.unknown),
          ],
        );
        final recommendation = engine.recommend(snapshot);
        expect(
          recommendation?.kind,
          SmartCoachRecommendationKind.memorizedReviewDue,
        );
        expect(recommendation?.route, contains('quiz'));
      },
    );

    test(
      'kids profile still returns kids mission regardless of review records',
      () {
        final now = DateTime.now().toUtc();
        final snapshot = MemorizationSnapshot(
          profile: _childProfile(),
          reviewRecords: [
            _memorizedDueRecord(
              now: now,
              ayahNumber: 1,
            ).copyWith(createdByMode: ReviewRecordCreatedByMode.adultMemPlus),
          ],
          kidsSessionLogs: [
            KidsSessionLog(
              id: 'log-1',
              surahId: 36,
              ayahNumber: 1,
              repeatsCompleted: 3,
              pointsEarned: 10,
              completedAt: now,
            ),
          ],
        );
        final recommendation = engine.recommend(snapshot);
        expect(
          recommendation?.kind,
          SmartCoachRecommendationKind.kidsCurrentMission,
        );
        expect(recommendation?.surahId, 36);
      },
    );
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

AyahReviewRecord _dueRecord({
  required DateTime now,
  int surahId = 67,
  int ayahNumber = 1,
  int strengthLevel = 3,
  DateTime? lastReviewedAt,
  DateTime? nextReviewDate,
  PerformanceRating? lastRating = PerformanceRating.average,
}) {
  return AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: 1,
    lastReviewedAt: lastReviewedAt ?? now.subtract(const Duration(days: 2)),
    nextReviewDate: nextReviewDate ?? now.subtract(const Duration(hours: 1)),
    totalReviews: 2,
    lastRating: lastRating,
  );
}

AyahReviewRecord _weakRecord({
  required DateTime now,
  int surahId = 67,
  int ayahNumber = 1,
  int strengthLevel = 1,
  DateTime? nextReviewDate,
}) {
  return AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: 1,
    lastReviewedAt: now.subtract(const Duration(days: 1)),
    nextReviewDate: nextReviewDate ?? now.subtract(const Duration(hours: 1)),
    totalReviews: 3,
    lastRating: PerformanceRating.weak,
  );
}

AyahReviewRecord _memorizedDueRecord({
  required DateTime now,
  int surahId = 67,
  int ayahNumber = 1,
  int strengthLevel = 6,
  int intervalDays = 30,
  DateTime? nextReviewDate,
}) {
  return AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: intervalDays,
    lastReviewedAt: now.subtract(const Duration(days: 45)),
    nextReviewDate: nextReviewDate ?? now.subtract(const Duration(days: 1)),
    totalReviews: 6,
    lastRating: PerformanceRating.excellent,
  );
}

DailyPlan _dailyPlan({
  required DateTime now,
  List<DailyPlanAyah> newAyahs = const [],
  List<DailyPlanAyah> retentionReview = const [],
  List<int> completedAyahNums = const [],
}) {
  return DailyPlan(
    generatedAt: now,
    surahId: 67,
    newAyahs: newAyahs,
    nearRevision: const [],
    farRevision: const [],
    completedAyahNums: completedAyahNums,
    retentionReview: retentionReview,
  );
}

MemorizationProfile _adultProfile() => MemorizationProfile(
  schemaVersion: 1,
  selectedPath: MemorizationPath.adult,
  guardianLinkStatus: GuardianLinkStatus.none,
  guardianOnboardingStatus: GuardianOnboardingStatus.completed,
  isParentGuardian: false,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

MemorizationProfile _childProfile() => MemorizationProfile(
  schemaVersion: 1,
  selectedPath: MemorizationPath.child,
  guardianLinkStatus: GuardianLinkStatus.none,
  guardianOnboardingStatus: GuardianOnboardingStatus.completed,
  isParentGuardian: false,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);
