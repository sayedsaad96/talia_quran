import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_completion_store.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:talia_quran/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:talia_quran/features/azkar/presentation/cubits/azkar_cubit.dart';

void main() {
  test('an empty approved category is not reported as completed', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cubit = AzkarCubit(
      GetAzkarUsecase(const _EmptyAzkarRepository()),
      preferences,
    );
    addTearDown(cubit.close);

    await cubit.load(AzkarCategory.morning);

    final state = cubit.state as AzkarLoaded;
    expect(state.sessions, isEmpty);
    expect(state.allDone, isFalse);
    expect(state.currentIndex, 0);
  });

  test(
    'counts the first post-midnight tap once instead of carrying yesterday\'s count',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      var currentDate = DateTime(2026, 9, 8, 23, 59);
      final store = AzkarCompletionStore(preferences, now: () => currentDate);
      final usecase = GetAzkarUsecase(const _SingleZikrRepository());
      final firstCubit = AzkarCubit(usecase, preferences, store);
      addTearDown(firstCubit.close);

      await firstCubit.load(AzkarCategory.morning);
      await firstCubit.increment();
      await Future<void>.delayed(Duration.zero);

      currentDate = DateTime(2026, 9, 9);
      await firstCubit.increment();
      await Future<void>.delayed(Duration.zero);

      final reloadedCubit = AzkarCubit(usecase, preferences, store);
      addTearDown(reloadedCubit.close);
      await reloadedCubit.load(AzkarCategory.morning);

      final state = reloadedCubit.state as AzkarLoaded;
      expect(state.sessions.single.currentCount, 1);
      expect(state.allDone, isFalse);
    },
  );

  test('reopening a category resumes at the first unfinished dhikr', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final usecase = GetAzkarUsecase(const _TwoZikrRepository());
    final first = AzkarCubit(usecase, preferences);
    addTearDown(first.close);
    await first.load(AzkarCategory.evening);
    // The first dhikr needs one count; finishing it is saved for today.
    await first.increment(autoAdvance: false);
    await Future<void>.delayed(Duration.zero);

    final reopened = AzkarCubit(usecase, preferences);
    addTearDown(reopened.close);
    await reopened.load(AzkarCategory.evening);

    expect((reopened.state as AzkarLoaded).currentIndex, 1);
  });

  test('keeps each rapid counter tap', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cubit = AzkarCubit(
      GetAzkarUsecase(const _SingleZikrRepository()),
      preferences,
    );
    addTearDown(cubit.close);

    await cubit.load(AzkarCategory.morning);
    await cubit.increment();
    await cubit.increment();
    await Future<void>.delayed(Duration.zero);

    final state = cubit.state as AzkarLoaded;
    expect(state.sessions.single.currentCount, 2);
  });

  test('honors an immediate undo after a counter tap', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cubit = AzkarCubit(
      GetAzkarUsecase(const _SingleZikrRepository()),
      preferences,
    );
    addTearDown(cubit.close);

    await cubit.load(AzkarCategory.morning);
    final increment = cubit.increment();
    await cubit.decrementCurrent();
    await increment;

    final state = cubit.state as AzkarLoaded;
    expect(state.sessions.single.currentCount, 0);
  });

  test('autoAdvance: true advances currentIndex to next unfinished zikr when completed', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cubit = AzkarCubit(
      GetAzkarUsecase(const _TwoZikrRepository()),
      preferences,
    );
    addTearDown(cubit.close);

    await cubit.load(AzkarCategory.morning);
    expect((cubit.state as AzkarLoaded).currentIndex, 0);

    await cubit.increment(autoAdvance: true);
    // Wait for the auto-advance delay (350-400ms)
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final state = cubit.state as AzkarLoaded;
    expect(state.sessions[0].isDone, isTrue);
    expect(state.currentIndex, 1);
  });

  test('autoAdvance: false does NOT advance currentIndex when completed', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cubit = AzkarCubit(
      GetAzkarUsecase(const _TwoZikrRepository()),
      preferences,
    );
    addTearDown(cubit.close);

    await cubit.load(AzkarCategory.morning);
    expect((cubit.state as AzkarLoaded).currentIndex, 0);

    await cubit.increment(autoAdvance: false);
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final state = cubit.state as AzkarLoaded;
    expect(state.sessions[0].isDone, isTrue);
    expect(state.currentIndex, 0);
  });
}

class _EmptyAzkarRepository implements AzkarRepository {
  const _EmptyAzkarRepository();

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      const Right([]);

  @override
  Future<Either<Failure, Map<AzkarCategory, List<Zikr>>>> getAllAzkar() async =>
      const Right({});
}

class _SingleZikrRepository implements AzkarRepository {
  const _SingleZikrRepository();

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      Right([
        Zikr(
          id: 'one',
          text: 'ذكر',
          transliteration: 'dhikr',
          translation: 'remembrance',
          totalCount: 2,
          category: category,
        ),
      ]);

  @override
  Future<Either<Failure, Map<AzkarCategory, List<Zikr>>>> getAllAzkar() async {
    final result = await getAzkar(AzkarCategory.morning);
    return result.fold(
      (failure) => Left(failure),
      (items) => Right({
            for (final category in AzkarCategory.values) category: items,
          }),
    );
  }
}

class _TwoZikrRepository implements AzkarRepository {
  const _TwoZikrRepository();

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      Right([
        Zikr(
          id: 'one',
          text: 'ذكر 1',
          transliteration: 'dhikr 1',
          translation: 'remembrance 1',
          totalCount: 1,
          category: category,
        ),
        Zikr(
          id: 'two',
          text: 'ذكر 2',
          transliteration: 'dhikr 2',
          translation: 'remembrance 2',
          totalCount: 1,
          category: category,
        ),
      ]);

  @override
  Future<Either<Failure, Map<AzkarCategory, List<Zikr>>>> getAllAzkar() async {
    final result = await getAzkar(AzkarCategory.morning);
    return result.fold(
      (failure) => Left(failure),
      (items) => Right({
            for (final category in AzkarCategory.values) category: items,
          }),
    );
  }
}
