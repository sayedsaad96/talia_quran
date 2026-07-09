import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:talia_quran/core/memorization/v2/ayah_failure_tracker.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/session_adapters.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/v2_session_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_result.dart';
import 'package:talia_quran/features/xp/domain/entities/xp_gain_result.dart';

import 'session_resume_after_complete_test.mocks.dart';

@GenerateMocks([
  QuranRepository,
  MemorizationPlusRepository,
  ScheduleNextReviewUsecase,
  V2SessionLocalDatasource,
  XpService,
  StreakService,
  AchievementService,
  AudioPlayer,
  SpeechToText,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('session resume after complete (B8)', () {
    test('AppSessionService clear removes saved V2 session URL', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = AppSessionService(prefs);

      await service.saveLocation(
        '/memorization-v2/session?surahId=67&startAyah=3',
      );
      expect(service.getLastRestorableLocation(), isNotNull);

      await service.clearLastRestorableLocation();
      expect(service.getLastRestorableLocation(), isNull);
    });

    test(
      'MemorizationSessionCubit clears restorable URL on block complete',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final sessionService = AppSessionService(prefs);
        await sessionService.saveLocation(
          '/memorization-v2/session?surahId=1&startAyah=1',
        );

        final mockMemRepo = MockMemorizationPlusRepository();
        final mockLocalDatasource = MockV2SessionLocalDatasource();
        final mockXPService = MockXpService();
        final mockStreakService = MockStreakService();
        final mockAchievementService = MockAchievementService();

        when(mockLocalDatasource.clearSession(any)).thenAnswer((_) async {});
        when(
          mockXPService.addXp(any),
        ).thenAnswer((_) async => const XpGainResult.zero());
        when(
          mockStreakService.recordActivity(
            activityDelta: anyNamed('activityDelta'),
          ),
        ).thenAnswer((_) async => const StreakResult.sameDay());
        when(
          mockAchievementService.checkAndUnlockCertificates(),
        ).thenAnswer((_) async => []);

        final mockAudioPlayer = MockAudioPlayer();
        final mockSpeechToText = MockSpeechToText();
        when(
          mockAudioPlayer.playerStateStream,
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockSpeechToText.initialize(
            onError: anyNamed('onError'),
            onStatus: anyNamed('onStatus'),
          ),
        ).thenAnswer((_) async => true);

        final cubit = MemorizationSessionCubit(
          quranRepository: MockQuranRepository(),
          memorizationRepository: mockMemRepo,
          sessionEngine: V2SessionEngine(),
          reviewAdapter: V2SessionReviewAdapter(
            repository: mockMemRepo,
            scheduler: MockScheduleNextReviewUsecase(),
          ),
          progressAdapter: V2SessionProgressAdapter(
            datasource: mockLocalDatasource,
          ),
          gamificationAdapter: V2SessionGamificationAdapter(
            xpService: mockXPService,
            streakService: mockStreakService,
            achievementService: mockAchievementService,
          ),
          appSessionService: sessionService,
          audioPlayer: mockAudioPlayer,
          speechToText: mockSpeechToText,
        );

        const ayah = Ayah(
          surahId: 1,
          numberInSurah: 1,
          number: 1,
          juz: 1,
          page: 1,
          text: 'Ayah 1',
        );
        const finalState = V2SessionState(
          surahId: 1,
          blockAyahs: [ayah],
          currentAyahIndex: 0,
          phase: V2SessionPhase.completed,
          passedAyahNumbers: {1},
          hintTracker: V2HintTracker.empty,
          failureTracker: V2AyahFailureTracker.empty,
          blockReviewRequired: true,
        );

        await cubit.onBlockCompletedForTesting(finalState);
        await cubit.close();

        expect(sessionService.getLastRestorableLocation(), isNull);
        verify(mockLocalDatasource.clearSession(1)).called(1);
        expect(cubit.state, isA<MSCompleted>());
      },
    );
  });
}
