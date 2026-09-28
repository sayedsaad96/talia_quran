import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart';

const _testSettings = ParentSettings(pinHash: 'hash');

FamilyDashboard _dashboard() => const FamilyDashboard(
  children: [],
  settings: _testSettings,
);

class _FakeRepository implements MemorizationPlusRepository {
  _FakeRepository({
    Either<Failure, ParentSettings> settingsResult = const Right(
      _testSettings,
    ),
    Either<Failure, bool> verifyPinResult = const Right(true),
    Either<Failure, FamilyDashboard>? dashboardResult,
  }) : _settingsResult = settingsResult,
       _verifyPinResult = verifyPinResult,
       dashboardResult = dashboardResult ?? Right(_dashboard());

  final Either<Failure, ParentSettings> _settingsResult;
  final Either<Failure, bool> _verifyPinResult;
  Either<Failure, FamilyDashboard> dashboardResult;
  @override
  Future<Either<Failure, ParentSettings>> getParentSettings() async =>
      _settingsResult;

  @override
  Future<Either<Failure, bool>> verifyParentPin(String pin) async =>
      _verifyPinResult;

  @override
  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard() async =>
      dashboardResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FamilyDashboardCubit _buildCubit(_FakeRepository repository) =>
    FamilyDashboardCubit(
      ParentAccessUsecase(repository),
      ParentRemoteLinkUsecase(repository),
      GetFamilyDashboardUsecase(repository),
    );

Future<void> _unlockAndLoad(FamilyDashboardCubit cubit) async {
  await cubit.unlock('1234');
  expect(cubit.state, isA<FamilyDashboardLoaded>());
}

void main() {
  test('unlock loads the dashboard after PIN verification', () async {
    final cubit = _buildCubit(_FakeRepository());
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state, isA<FamilyDashboardLocked>());

    await _unlockAndLoad(cubit);
    final loaded = cubit.state as FamilyDashboardLoaded;
    expect(loaded.feedback, isNull);
  });

  test(
    'a failed refresh retains the loaded dashboard instead of evicting it',
    () async {
      final repository = _FakeRepository();
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      await cubit.load();
      await _unlockAndLoad(cubit);

      // The device goes offline: the next refresh must keep the retained
      // data and surface the failure as feedback — never bounce the parent
      // back to the PIN gate or blank the screen.
      repository.dashboardResult = const Left(CacheFailure('network failed'));
      await cubit.refresh();

      final state = cubit.state;
      expect(state, isA<FamilyDashboardLoaded>());
      final retained = state as FamilyDashboardLoaded;
      expect(retained.dashboard, _dashboard());
      expect(retained.feedback?.isError, isTrue);
    },
  );

  test(
    'refresh failure without prior data still emits the error state',
    () async {
      final repository = _FakeRepository(
        dashboardResult: const Left(CacheFailure('network failed')),
      );
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.unlock('1234');

      expect(cubit.state, isA<FamilyDashboardError>());
    },
  );
}
