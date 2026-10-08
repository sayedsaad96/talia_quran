import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/services/activity_event_recorder.dart';
import 'package:talia_quran/core/services/daily_reading_log_service.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/kids_streak_store.dart';
import 'package:talia_quran/features/progress/domain/usecases/save_read_page_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_page_cubit.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_result.dart';

class MockQuranRepository extends Mock implements QuranRepository {}

class MockSaveReadPageUsecase extends Mock implements SaveReadPageUsecase {}

class MockStreakService extends Mock implements StreakService {}

class MockKidsStreakStore extends Mock implements KidsStreakStore {}

class MockDailyReadingLog extends Mock implements DailyReadingLogService {}

class MockActivityRecorder extends Mock implements ActivityEventRecorder {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      ActivityEvent(
        occurredAt: DateTime(2026),
        kind: ActivityEventKind.reading,
        idempotencyKey: 'fallback',
      ),
    );
  });

  late MockQuranRepository repository;
  late MockSaveReadPageUsecase saveRead;
  late MockStreakService streak;
  const page = QuranPageDetail(pageNumber: 11, surahs: [], ayahs: []);

  setUp(() {
    repository = MockQuranRepository();
    saveRead = MockSaveReadPageUsecase();
    streak = MockStreakService();
    when(
      () => repository.getQuranPage(11),
    ).thenAnswer((_) async => const Right(page));
    when(
      () => streak.recordActivity(),
    ).thenAnswer((_) async => const StreakResult.sameDay());
  });

  test(
    'returns true only after ordinary Quran confirmation succeeds',
    () async {
      when(() => saveRead(11)).thenAnswer((_) async => const Right(null));
      final cubit = QuranPageCubit(repository, saveRead, streak);
      await cubit.loadPage(11);
      final confirmed = await cubit.confirmRead(11);
      expect(confirmed, isTrue);
      expect((cubit.state as QuranPageLoaded).isReadConfirmed, isTrue);
      await cubit.close();
    },
  );

  test('returns false and exposes the ordinary confirmation failure', () async {
    when(
      () => saveRead(11),
    ).thenAnswer((_) async => const Left(CacheFailure('save failed')));
    final cubit = QuranPageCubit(repository, saveRead, streak);
    await cubit.loadPage(11);
    final confirmed = await cubit.confirmRead(11);
    expect(confirmed, isFalse);
    expect(
      (cubit.state as QuranPageLoaded).readConfirmationError,
      'save failed',
    );
    await cubit.close();
  });

  test(
    'khatmah reading counts for the streak but never touches free reading (C1)',
    () async {
      final cubit = QuranPageCubit(repository, saveRead, streak);
      await cubit.loadPage(11);

      final confirmed = await cubit.confirmRead(
        11,
        recordOrdinaryReading: false,
      );

      expect(confirmed, isTrue);
      verify(() => streak.recordActivity()).called(1);
      // Free-reading stats, the reading log and the daily wird stay separate.
      verifyNever(() => saveRead(any()));
      await cubit.close();
    },
  );

  test(
    'a confirmation finishing after the next page loaded keeps that page',
    () async {
      const next = QuranPageDetail(pageNumber: 12, surahs: [], ayahs: []);
      when(
        () => repository.getQuranPage(12),
      ).thenAnswer((_) async => const Right(next));
      final save = Completer<Either<Failure, void>>();
      when(() => saveRead(11)).thenAnswer((_) => save.future);
      final cubit = QuranPageCubit(repository, saveRead, streak);
      await cubit.loadPage(11);

      final confirming = cubit.confirmRead(11);
      await cubit.loadPage(12);
      save.complete(const Right(null));

      expect(await confirming, isTrue);
      final state = cubit.state as QuranPageLoaded;
      expect(state.detail.pageNumber, 12);
      expect(state.isReadConfirmed, isFalse);
      await cubit.close();
    },
  );

  test('kids reading records only the kids track', () async {
    final kidsStreak = MockKidsStreakStore();
    final readingLog = MockDailyReadingLog();
    final recorder = MockActivityRecorder();
    when(() => kidsStreak.recordActivity()).thenAnswer((_) async {});
    final recorded = <ActivityEvent>[];
    when(() => recorder.record(any())).thenAnswer((invocation) async {
      recorded.add(invocation.positionalArguments.single as ActivityEvent);
    });
    final cubit = QuranPageCubit(
      repository,
      saveRead,
      streak,
      readingLog,
      recorder,
      kidsStreak,
    );
    await cubit.loadPage(11);

    expect(await cubit.confirmKidsRead(11), isTrue);

    expect((cubit.state as QuranPageLoaded).isReadConfirmed, isTrue);
    verify(() => kidsStreak.recordActivity()).called(1);
    verifyNever(() => streak.recordActivity());
    verifyNever(() => saveRead(any()));
    verifyZeroInteractions(readingLog);
    expect(recorded.single.isKids, isTrue);
    expect(recorded.single.pageNumber, 11);
    await cubit.close();
  });

  test('kids reading is refused before the page loads', () async {
    final cubit = QuranPageCubit(repository, saveRead, streak);

    expect(await cubit.confirmKidsRead(11), isFalse);
    await cubit.close();
  });

  test('a failed streak write never blocks khatmah confirmation', () async {
    when(() => streak.recordActivity()).thenThrow(StateError('isar'));
    final cubit = QuranPageCubit(repository, saveRead, streak);
    await cubit.loadPage(11);

    expect(await cubit.confirmRead(11, recordOrdinaryReading: false), isTrue);
    await cubit.close();
  });
}
