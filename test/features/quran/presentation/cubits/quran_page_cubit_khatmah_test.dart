import 'package:dartz/dartz.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/features/progress/domain/usecases/save_read_page_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_page_cubit.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_result.dart';

class MockQuranRepository extends Mock implements QuranRepository {}

class MockSaveReadPageUsecase extends Mock implements SaveReadPageUsecase {}

class MockStreakService extends Mock implements StreakService {}

void main() {
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
}
