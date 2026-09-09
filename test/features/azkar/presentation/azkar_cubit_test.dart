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
  });

  test('counts the first post-midnight tap once instead of carrying yesterday\'s count',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    var currentDate = DateTime(2026, 9, 8, 23, 59);
    final store = AzkarCompletionStore(preferences, now: () => currentDate);
    final usecase = GetAzkarUsecase(const _SingleZikrRepository());
    final firstCubit = AzkarCubit(usecase, preferences, store);
    addTearDown(firstCubit.close);

    await firstCubit.load(AzkarCategory.morning);
    firstCubit.increment();
    await Future<void>.delayed(Duration.zero);

    currentDate = DateTime(2026, 9, 9);
    firstCubit.increment();
    await Future<void>.delayed(Duration.zero);

    final reloadedCubit = AzkarCubit(usecase, preferences, store);
    addTearDown(reloadedCubit.close);
    await reloadedCubit.load(AzkarCategory.morning);

    final state = reloadedCubit.state as AzkarLoaded;
    expect(state.sessions.single.currentCount, 1);
    expect(state.allDone, isFalse);
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
    cubit.increment();
    cubit.increment();
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
}

class _EmptyAzkarRepository implements AzkarRepository {
  const _EmptyAzkarRepository();

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      const Right([]);
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
}
