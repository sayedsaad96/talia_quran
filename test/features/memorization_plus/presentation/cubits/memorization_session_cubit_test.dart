import 'dart:async';

// import 'package:bloc_test/bloc_test.dart'; // bloc_test is missing or unused
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:talia_quran/core/memorization/v2/session_adapters.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/services/audio_cache_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/v2_session_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';

import 'memorization_session_cubit_test.mocks.dart';

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
  AudioCacheService,
])
void main() {
  late MockQuranRepository mockQuranRepo;
  late MockMemorizationPlusRepository mockMemRepo;
  late V2SessionEngine realEngine;
  late MockScheduleNextReviewUsecase mockScheduler;
  late MockV2SessionLocalDatasource mockLocalDatasource;
  late MockXpService mockXPService;
  late MockStreakService mockStreakService;
  late MockAchievementService mockAchievementService;

  late V2SessionReviewAdapter realReviewAdapter;
  late V2SessionProgressAdapter realProgressAdapter;
  late V2SessionGamificationAdapter realGamificationAdapter;
  late MockAudioPlayer mockAudioPlayer;
  late MockSpeechToText mockSpeechToText;
  late MockAudioCacheService mockAudioCache;
  late MemorizationSessionCubit cubit;

  const defaultSurah = Surah(
    id: 1,
    nameAr: 'الفاتحة',
    nameEn: 'Al-Fatiha',
    ayahCount: 10,
    juz: 1,
    type: 'meccan',
    page: 1,
  );

  final defaultAyahs = List.generate(
    10,
    (index) => Ayah(
      surahId: 1,
      numberInSurah: index + 1,
      number: index + 1,
      juz: 1,
      page: 1,
      text: 'Ayah ${index + 1}',
    ),
  );

  setUp(() {
    mockQuranRepo = MockQuranRepository();
    mockMemRepo = MockMemorizationPlusRepository();
    realEngine = V2SessionEngine();
    mockScheduler = MockScheduleNextReviewUsecase();
    mockLocalDatasource = MockV2SessionLocalDatasource();
    mockXPService = MockXpService();
    mockStreakService = MockStreakService();
    mockAchievementService = MockAchievementService();

    realReviewAdapter = V2SessionReviewAdapter(
      repository: mockMemRepo,
      scheduler: mockScheduler,
    );
    realProgressAdapter = V2SessionProgressAdapter(
      datasource: mockLocalDatasource,
    );
    realGamificationAdapter = V2SessionGamificationAdapter(
      xpService: mockXPService,
      streakService: mockStreakService,
      achievementService: mockAchievementService,
    );
    mockAudioPlayer = MockAudioPlayer();
    mockSpeechToText = MockSpeechToText();
    mockAudioCache = MockAudioCacheService();

    when(
      mockAudioPlayer.playerStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockSpeechToText.initialize(
        onError: anyNamed('onError'),
        onStatus: anyNamed('onStatus'),
      ),
    ).thenAnswer((_) async => true);

    cubit = MemorizationSessionCubit(
      quranRepository: mockQuranRepo,
      memorizationRepository: mockMemRepo,
      sessionEngine: realEngine,
      reviewAdapter: realReviewAdapter,
      progressAdapter: realProgressAdapter,
      gamificationAdapter: realGamificationAdapter,
      audioPlayer: mockAudioPlayer,
      speechToText: mockSpeechToText,
      audioCacheService: mockAudioCache,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('startSession', () {
    test('emits MSActive when new session starts successfully', () async {
      when(
        mockMemRepo.getMemorizationProfile(),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      when(mockQuranRepo.getSurahDetail(1)).thenAnswer(
        (_) async =>
            Right(SurahDetail(surah: defaultSurah, ayahs: defaultAyahs)),
      );
      when(mockLocalDatasource.getSession(1)).thenAnswer((_) async => null);



      when(mockLocalDatasource.saveSession(any)).thenAnswer((_) async {});
      when(
        mockAudioCache.prefetchSession(
          surahId: 1,
          ayahNumbers: anyNamed('ayahNumbers'),
        ),
      ).thenAnswer((_) async {});

      await cubit.startSession(surahId: 1, startAyah: 1, blockSize: 5);

      expect(cubit.state, isA<MSActive>());
      final active = cubit.state as MSActive;
      expect(active.sessionState.phase, V2SessionPhase.learning);
    });
  });

  group('advanceToMemorizing', () {
    test('transitions to memorizing phase', () async {
      // Setup initial state
      when(
        mockMemRepo.getMemorizationProfile(),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      when(mockQuranRepo.getSurahDetail(1)).thenAnswer(
        (_) async =>
            Right(SurahDetail(surah: defaultSurah, ayahs: defaultAyahs)),
      );
      when(mockLocalDatasource.getSession(1)).thenAnswer((_) async => null);



      when(mockLocalDatasource.saveSession(any)).thenAnswer((_) async {});
      when(
        mockAudioCache.prefetchSession(
          surahId: 1,
          ayahNumbers: anyNamed('ayahNumbers'),
        ),
      ).thenAnswer((_) async {});

      await cubit.startSession(surahId: 1, startAyah: 1, blockSize: 5);

      await cubit.advanceToMemorizing();

      expect(cubit.state, isA<MSActive>());
      expect(
        (cubit.state as MSActive).sessionState.phase,
        V2SessionPhase.memorizing,
      );
    });
  });
}
