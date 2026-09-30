import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/features/auth/domain/services/account_password_verifier.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart';

const _testSettings = ParentSettings(pinHash: 'hash');

FamilyDashboard _dashboard() =>
    const FamilyDashboard(children: [], settings: _testSettings);

class _FakeRepository implements MemorizationPlusRepository {
  _FakeRepository({
    Either<Failure, ParentSettings> settingsResult = const Right(_testSettings),
    Either<Failure, bool> verifyPinResult = const Right(true),
    Either<Failure, FamilyDashboard>? dashboardResult,
  }) : _settingsResult = settingsResult,
       _verifyPinResult = verifyPinResult,
       dashboardResult = dashboardResult ?? Right(_dashboard());

  Either<Failure, ParentSettings> _settingsResult;
  final Either<Failure, bool> _verifyPinResult;
  Either<Failure, FamilyDashboard> dashboardResult;
  int resetCalls = 0;
  final identityUpdates = <String>[];
  Either<Failure, void> identityResult = const Right(null);
  final savedSettings = <ParentSettings>[];

  @override
  Future<Either<Failure, void>> updateLinkedChildIdentity({
    required String childUserId,
    required String nickname,
    required int age,
  }) async {
    identityUpdates.add('$childUserId:$nickname:$age');
    return identityResult;
  }

  @override
  Future<Either<Failure, void>> saveParentSettings(
    ParentSettings settings,
  ) async {
    savedSettings.add(settings);
    return const Right(null);
  }

  @override
  Future<Either<Failure, ParentSettings>> getParentSettings() async =>
      _settingsResult;

  @override
  Future<Either<Failure, void>> resetParentAccess() async {
    resetCalls++;
    _settingsResult = const Right(ParentSettings());
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> verifyParentPin(String pin) async =>
      _verifyPinResult;

  @override
  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard() async =>
      dashboardResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeVerifier implements AccountPasswordVerifier {
  _FakeVerifier(this.result);

  final AccountPasswordCheck result;
  final checkedPasswords = <String>[];

  @override
  String? get currentEmail => 'parent@example.com';

  @override
  Future<AccountPasswordCheck> verify(String password) async {
    checkedPasswords.add(password);
    return result;
  }
}

FamilyDashboardCubit _buildCubit(
  _FakeRepository repository, {
  AccountPasswordVerifier? verifier,
}) => FamilyDashboardCubit(
  ParentAccessUsecase(repository),
  ParentRemoteLinkUsecase(repository),
  GetFamilyDashboardUsecase(repository),
  accountVerifier: verifier,
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

  group('PIN reset is guarded', () {
    test('resetAccess from the locked screen does not clear the PIN', () async {
      final repository = _FakeRepository();
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state, isA<FamilyDashboardLocked>());

      await cubit.resetAccess();

      expect(repository.resetCalls, 0);
      expect(cubit.state, isA<FamilyDashboardLocked>());
    });

    test(
      'resetAccess from the unlocked dashboard asks for a new PIN',
      () async {
        final repository = _FakeRepository();
        final cubit = _buildCubit(repository);
        addTearDown(cubit.close);

        await cubit.load();
        await _unlockAndLoad(cubit);
        await cubit.resetAccess();

        expect(repository.resetCalls, 1);
        expect(cubit.state, isA<FamilyDashboardNeedsPin>());
      },
    );

    test('forgotten PIN with a wrong account password stays locked', () async {
      final repository = _FakeRepository();
      final verifier = _FakeVerifier(AccountPasswordCheck.incorrect);
      final cubit = _buildCubit(repository, verifier: verifier);
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.resetForgottenPin('guess');

      expect(verifier.checkedPasswords, ['guess']);
      expect(repository.resetCalls, 0);
      final state = cubit.state as FamilyDashboardLocked;
      expect(
        state.feedback?.type,
        FamilyDashboardFeedbackType.accountPasswordIncorrect,
      );
      expect(state.feedbackEventId, greaterThan(0));
    });

    test(
      'forgotten PIN cannot be reset when the account check is unavailable',
      () async {
        final repository = _FakeRepository();
        final cubit = _buildCubit(repository);
        addTearDown(cubit.close);

        await cubit.load();
        await cubit.resetForgottenPin('secret');

        expect(repository.resetCalls, 0);
        expect(
          (cubit.state as FamilyDashboardLocked).feedback?.type,
          FamilyDashboardFeedbackType.accountCheckUnavailable,
        );
      },
    );

    test(
      'forgotten PIN with the verified account password asks for a new PIN',
      () async {
        final repository = _FakeRepository();
        final cubit = _buildCubit(
          repository,
          verifier: _FakeVerifier(AccountPasswordCheck.verified),
        );
        addTearDown(cubit.close);

        await cubit.load();
        await cubit.resetForgottenPin('secret');

        expect(repository.resetCalls, 1);
        expect(cubit.state, isA<FamilyDashboardNeedsPin>());
      },
    );
  });

  group('child identity', () {
    test('saving a linked child identity refreshes with feedback', () async {
      final repository = _FakeRepository();
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await _unlockAndLoad(cubit);

      await cubit.updateRemoteChildIdentity(
        childUserId: 'child-1',
        nickname: 'Maryam',
        age: 9,
      );

      expect(repository.identityUpdates, ['child-1:Maryam:9']);
      final state = cubit.state as FamilyDashboardLoaded;
      expect(
        state.feedback?.type,
        FamilyDashboardFeedbackType.childIdentitySaved,
      );
    });

    test(
      'a rejected identity update keeps the dashboard and explains',
      () async {
        final repository = _FakeRepository()
          ..identityResult = const Left(
            ServerFailure(CubitMessageCodes.guardianChildNotLinked),
          );
        final cubit = _buildCubit(repository);
        addTearDown(cubit.close);
        await cubit.load();
        await _unlockAndLoad(cubit);

        await cubit.updateRemoteChildIdentity(
          childUserId: 'child-1',
          nickname: 'Maryam',
          age: 9,
        );

        final state = cubit.state as FamilyDashboardLoaded;
        expect(state.feedback?.type, FamilyDashboardFeedbackType.failure);
        expect(
          state.feedback?.message,
          CubitMessageCodes.guardianChildNotLinked,
        );
      },
    );

    test('an invalid local nickname is rejected before saving', () async {
      final repository = _FakeRepository();
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await _unlockAndLoad(cubit);

      await cubit.updateLocalChildNickname('a' * 51);

      expect(repository.savedSettings, isEmpty);
      expect(
        (cubit.state as FamilyDashboardLoaded).feedback?.message,
        CubitMessageCodes.childNicknameInvalid,
      );
    });

    test('a local nickname is saved normalized', () async {
      final repository = _FakeRepository();
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await _unlockAndLoad(cubit);

      await cubit.updateLocalChildNickname('  Maryam   Ali ');

      expect(repository.savedSettings.single.localChildNickname, 'Maryam Ali');
    });
  });
}
