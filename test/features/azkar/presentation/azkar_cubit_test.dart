import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
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
}

class _EmptyAzkarRepository implements AzkarRepository {
  const _EmptyAzkarRepository();

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      const Right([]);
}
