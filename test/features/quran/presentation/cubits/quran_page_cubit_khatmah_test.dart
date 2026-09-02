import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_progress_usecase.dart';
import 'package:talia_quran/features/progress/domain/usecases/save_read_page_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_page_cubit.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_result.dart';

class MockQuranRepository extends Mock implements QuranRepository {}

class MockSaveReadPageUsecase extends Mock implements SaveReadPageUsecase {}

class MockStreakService extends Mock implements StreakService {}

class MockGetActiveKhatmahUsecase extends Mock
    implements GetActiveKhatmahUsecase {}

class MockUpdateKhatmahProgressUsecase extends Mock
    implements UpdateKhatmahProgressUsecase {}

class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  late MockQuranRepository mockRepo;
  late MockSaveReadPageUsecase mockSaveRead;
  late MockStreakService mockStreak;
  late MockGetActiveKhatmahUsecase mockGetActiveKhatmah;
  late MockUpdateKhatmahProgressUsecase mockUpdateKhatmahProgress;

  final testPlan = KhatmahPlan(
    id: 'test-khatmah',
    title: 'Test Khatmah',
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 6, 1),
    completedPages: {for (var page = 1; page <= 10; page++) page},
    status: KhatmahStatus.active,
  );

  const testPageDetail = QuranPageDetail(
    pageNumber: 11,
    surahs: [],
    ayahs: [],
  );

  setUpAll(() {
    registerFallbackValue(FakeKhatmahPlan());
  });

  setUp(() {
    mockRepo = MockQuranRepository();
    mockSaveRead = MockSaveReadPageUsecase();
    mockStreak = MockStreakService();
    mockGetActiveKhatmah = MockGetActiveKhatmahUsecase();
    mockUpdateKhatmahProgress = MockUpdateKhatmahProgressUsecase();

    when(() => mockRepo.getQuranPage(any()))
        .thenAnswer((_) async => const Right(testPageDetail));
    when(() => mockSaveRead(any())).thenAnswer((_) async => const Right(null));
    when(() => mockStreak.recordActivity()).thenAnswer(
      (_) async => const StreakResult.sameDay(),
    );
  });

  QuranPageCubit buildCubit() {
    return QuranPageCubit(
      mockRepo,
      mockSaveRead,
      mockStreak,
      mockUpdateKhatmahProgress,
      mockGetActiveKhatmah,
    );
  }

  group('QuranPageCubit.confirmRead mode isolation', () {
    test('in free mode (default) does NOT call khatmah usecases', () async {
      final cubit = buildCubit();
      await cubit.loadPage(11);

      await cubit.confirmRead(11);

      verify(() => mockSaveRead(11)).called(1);
      verify(() => mockStreak.recordActivity()).called(1);
      verifyNever(() => mockGetActiveKhatmah());
      verifyNever(() => mockUpdateKhatmahProgress(any(), any()));

      expect(cubit.state, isA<QuranPageLoaded>());
      expect((cubit.state as QuranPageLoaded).isReadConfirmed, isTrue);
    });

    test(
        'with explicit readerMode: QuranReaderMode.free does NOT call khatmah usecases',
        () async {
      final cubit = buildCubit();
      await cubit.loadPage(11);

      await cubit.confirmRead(11, readerMode: QuranReaderMode.free);

      verify(() => mockSaveRead(11)).called(1);
      verify(() => mockStreak.recordActivity()).called(1);
      verifyNever(() => mockGetActiveKhatmah());
      verifyNever(() => mockUpdateKhatmahProgress(any(), any()));

      expect((cubit.state as QuranPageLoaded).isReadConfirmed, isTrue);
    });

    test(
        'with readerMode: QuranReaderMode.khatmah calls getActive and updateProgress',
        () async {
      when(() => mockGetActiveKhatmah()).thenAnswer((_) async => testPlan);
      when(() => mockUpdateKhatmahProgress(testPlan, 11))
          .thenAnswer((_) async => testPlan.copyWith(currentPage: 11));

      final cubit = buildCubit();
      await cubit.loadPage(11);

      await cubit.confirmRead(11, readerMode: QuranReaderMode.khatmah);

      verify(() => mockSaveRead(11)).called(1);
      verify(() => mockStreak.recordActivity()).called(1);
      verify(() => mockGetActiveKhatmah()).called(1);
      verify(() => mockUpdateKhatmahProgress(testPlan, 11)).called(1);

      expect((cubit.state as QuranPageLoaded).isReadConfirmed, isTrue);
    });

    test(
        'with readerMode: QuranReaderMode.khatmah does not call updateProgress if active plan is null',
        () async {
      when(() => mockGetActiveKhatmah()).thenAnswer((_) async => null);

      final cubit = buildCubit();
      await cubit.loadPage(11);

      await cubit.confirmRead(11, readerMode: QuranReaderMode.khatmah);

      verify(() => mockSaveRead(11)).called(1);
      verify(() => mockStreak.recordActivity()).called(1);
      verify(() => mockGetActiveKhatmah()).called(1);
      verifyNever(() => mockUpdateKhatmahProgress(any(), any()));

      expect((cubit.state as QuranPageLoaded).isReadConfirmed, isTrue);
    });

    test('swallows exception if UpdateKhatmahProgress fails (non-critical)',
        () async {
      when(() => mockGetActiveKhatmah()).thenAnswer((_) async => testPlan);
      when(() => mockUpdateKhatmahProgress(testPlan, 11))
          .thenThrow(Exception('Khatmah storage error'));

      final cubit = buildCubit();
      await cubit.loadPage(11);

      await cubit.confirmRead(11, readerMode: QuranReaderMode.khatmah);

      verify(() => mockSaveRead(11)).called(1);
      verify(() => mockStreak.recordActivity()).called(1);
      verify(() => mockGetActiveKhatmah()).called(1);
      verify(() => mockUpdateKhatmahProgress(testPlan, 11)).called(1);

      expect((cubit.state as QuranPageLoaded).isReadConfirmed, isTrue);
      expect((cubit.state as QuranPageLoaded).readConfirmationError, isNull);
    });
  });
}
