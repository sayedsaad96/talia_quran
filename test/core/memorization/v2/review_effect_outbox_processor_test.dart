import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/v2/ayah_failure_tracker.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/review_effect_outbox_processor.dart';
import 'package:talia_quran/core/memorization/v2/review_outcome_committer.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_evidence_event.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/streak/data/models/daily_activity_isar.dart';
import 'package:talia_quran/features/streak/data/models/streak_isar.dart';
import 'package:talia_quran/features/xp/data/models/xp_isar.dart';

class _MockMemorizationRepository extends Mock
    implements MemorizationPlusRepository {
  @override
  Future<Either<Failure, bool>> markDailyPlanAyahCompleted({
    required int surahId,
    required int ayahNumber,
  }) =>
      super.noSuchMethod(
            Invocation.method(#markDailyPlanAyahCompleted, const [], {
              #surahId: surahId,
              #ayahNumber: ayahNumber,
            }),
            returnValue: Future.value(const Right<Failure, bool>(false)),
          )
          as Future<Either<Failure, bool>>;
}

class _MockAchievementService extends Mock implements AchievementService {
  @override
  Future<List<CertificateAward>> checkAndUnlockCertificatesStrict({
    required bool isKids,
  }) =>
      super.noSuchMethod(
            Invocation.method(#checkAndUnlockCertificatesStrict, const [], {
              #isKids: isKids,
            }),
            returnValue: Future.value(const <CertificateAward>[]),
          )
          as Future<List<CertificateAward>>;
}

bool _isarCoreInitialized = false;

Future<void> _initializeIsarCoreForTests() async {
  if (_isarCoreInitialized) return;
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final dllPath =
          '$localAppData\\Pub\\Cache\\hosted\\pub.dev\\isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
      if (File(dllPath).existsSync()) {
        await Isar.initializeIsarCore(libraries: {Abi.current(): dllPath});
        _isarCoreInitialized = true;
        return;
      }
    }
  }
  await Isar.initializeIsarCore();
  _isarCoreInitialized = true;
}

void main() {
  group('V2 review effect outbox', () {
    late Directory tempDir;
    late Isar isar;
    late _MockMemorizationRepository repository;
    late _MockAchievementService achievements;
    late V2ReviewOutcomeCommitter committer;
    late V2ReviewEffectOutboxProcessor processor;

    setUp(() async {
      await _initializeIsarCoreForTests();
      tempDir = await Directory.systemTemp.createTemp('talia_review_effect_');
      isar = await Isar.open(
        [
          IsarAyahReviewRecordSchema,
          IsarV2SessionSchema,
          IsarReviewEvidenceEventSchema,
          IsarReviewEffectOutboxSchema,
          XpIsarSchema,
          StreakIsarSchema,
          DailyActivityIsarSchema,
        ],
        directory: tempDir.path,
        name: 'review_effect_${DateTime.now().microsecondsSinceEpoch}',
      );
      repository = _MockMemorizationRepository();
      achievements = _MockAchievementService();
      committer = V2ReviewOutcomeCommitter(
        isar: isar,
        owner: const FixedRecordOwnerProvider('owner-a'),
        scheduler: const ScheduleNextReviewUsecase(),
        now: () => DateTime.utc(2026, 9, 8, 12),
        idGenerator: () => DateTime.now().microsecondsSinceEpoch.toString(),
      );
      processor = V2ReviewEffectOutboxProcessor(
        isar: isar,
        owner: const FixedRecordOwnerProvider('owner-a'),
        markDailyPlanCompleted: MarkDailyPlanAyahCompletedUsecase(repository),
        achievements: achievements,
        progressEvents: ProgressEventsBus(),
        now: () => DateTime.utc(2026, 9, 8, 12),
      );
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    Future<void> commitTerminalPass() async {
      await committer.commitAutomaticPass(
        previousState: _reciting,
        nextState: _completed,
        taskId: 'ayah:1:1',
        eventId: 'terminal-event',
      );
    }

    test('concurrent drains apply XP and streak exactly once', () async {
      when(
        achievements.checkAndUnlockCertificatesStrict(isKids: false),
      ).thenAnswer((_) async => const []);
      await commitTerminalPass();

      await Future.wait([
        processor.processPending(),
        processor.processPending(),
      ]);

      final xp = await isar.xpIsars.get(1);
      final streak = await isar.streakIsars.get(1);
      final effects = await isar.isarReviewEffectOutboxs.where().findAll();
      expect(xp?.totalXp, greaterThan(0));
      expect(streak?.currentStreak, 1);
      expect(
        effects.where((effect) => effect.effectType == 'xp').single.processedAt,
        isNotNull,
      );
      expect(
        effects
            .where((effect) => effect.effectType == 'streak')
            .single
            .processedAt,
        isNotNull,
      );
      verify(
        achievements.checkAndUnlockCertificatesStrict(isKids: false),
      ).called(1);
    });

    test('a certificate failure remains pending for a later retry', () async {
      when(
        achievements.checkAndUnlockCertificatesStrict(isKids: false),
      ).thenThrow(StateError('certificate store unavailable'));
      await commitTerminalPass();

      await processor.processPending();

      final certificate = (await isar.isarReviewEffectOutboxs.where().findAll())
          .singleWhere((effect) => effect.effectType == 'certificate');
      expect(certificate.processedAt, isNull);
      expect(certificate.attempts, 1);
      expect(certificate.lastErrorCode, 'effect_processing_failed');
    });
  });
}

const _ayah = Ayah(number: 1, surahId: 1, numberInSurah: 1, text: 'أ', page: 1);

const _reciting = V2SessionState(
  surahId: 1,
  blockAyahs: [_ayah],
  currentAyahIndex: 0,
  phase: V2SessionPhase.reciting,
  passedAyahNumbers: {},
  hintTracker: V2HintTracker.empty,
  failureTracker: V2AyahFailureTracker.empty,
  blockReviewRequired: false,
);

const _completed = V2SessionState(
  surahId: 1,
  blockAyahs: [_ayah],
  currentAyahIndex: 0,
  phase: V2SessionPhase.completed,
  passedAyahNumbers: {1},
  hintTracker: V2HintTracker.empty,
  failureTracker: V2AyahFailureTracker.empty,
  blockReviewRequired: false,
);
