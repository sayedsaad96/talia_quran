import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:talia_quran/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:talia_quran/features/azkar/presentation/cubits/azkar_cubit.dart';

class _OneZikrRepo implements AzkarRepository {
  const _OneZikrRepo();

  static const zikr = Zikr(
    id: 'z1',
    text: 'ذكر',
    transliteration: '',
    translation: '',
    totalCount: 1,
    category: AzkarCategory.morning,
  );

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      const Right([zikr]);

  @override
  Future<Either<Failure, Map<AzkarCategory, List<Zikr>>>> getAllAzkar() async =>
      const Right({
        AzkarCategory.morning: [zikr],
      });
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  AzkarCubit build() {
    final cubit = AzkarCubit(GetAzkarUsecase(const _OneZikrRepo()), prefs);
    addTearDown(cubit.close);
    return cubit;
  }

  test('the tap that finishes the last zikr can be undone', () async {
    final cubit = build();
    await cubit.load(AzkarCategory.morning);

    await cubit.increment();

    final done = cubit.state as AzkarLoaded;
    expect(done.allDone, isTrue);
    expect(done.canUndoCompletion, isTrue);

    await cubit.decrementCurrent();

    final reopened = cubit.state as AzkarLoaded;
    expect(reopened.allDone, isFalse);
    expect(reopened.canUndoCompletion, isFalse);
    expect(reopened.current.currentCount, 0);
  });

  test('a wird that was already complete on entry offers no undo', () async {
    final first = build();
    await first.load(AzkarCategory.morning);
    await first.increment();

    final reopened = build();
    await reopened.load(AzkarCategory.morning);

    final state = reopened.state as AzkarLoaded;
    expect(state.allDone, isTrue);
    expect(state.canUndoCompletion, isFalse);
  });

  test('reset clears the undo offer', () async {
    final cubit = build();
    await cubit.load(AzkarCategory.morning);
    await cubit.increment();

    await cubit.reset();

    expect((cubit.state as AzkarLoaded).canUndoCompletion, isFalse);
  });
}
