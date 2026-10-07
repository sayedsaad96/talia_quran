import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/features/auth/domain/services/account_password_verifier.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_child_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_home_mission.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/family_dashboard_stream_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/parent_reward_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/parent_reward_usecases.dart';
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
  final remoteMissionCreates = <String>[];
  final remoteMissionAcks = <String>[];
  final localMissionAdds = <String>[];
  final localMissionAcks = <String>[];
  Either<Failure, List<KidsHomeMission>> missionResult = const Right([]);
  final localPolicySaves = <KidsChildPolicy>[];
  final remotePolicySaves = <String>[];
  Either<Failure, KidsChildPolicy> policyResult = const Right(
    KidsChildPolicy(version: 1),
  );
  int dashboardCalls = 0;
  final acceptedTokens = <String>[];
  Either<Failure, void> acceptResult = const Right(null);
  Completer<void>? acceptGate;
  final parentModeChanges = <bool>[];
  Either<Failure, void> revokeResult = const Right(null);
  final revoked = <String>[];

  @override
  Future<Either<Failure, void>> removeChild(String childUserId) async {
    revoked.add(childUserId);
    return revokeResult;
  }

  @override
  Future<Either<Failure, void>> acceptChildLinkToken(String token) async {
    acceptedTokens.add(token);
    await acceptGate?.future;
    return acceptResult;
  }

  @override
  Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
    bool value,
  ) async {
    parentModeChanges.add(value);
    return const Left(CacheFailure('not needed by these tests'));
  }

  @override
  Future<Either<Failure, KidsChildPolicy>> saveLocalChildPolicy(
    KidsChildPolicy policy,
  ) async {
    localPolicySaves.add(policy);
    return policyResult;
  }

  @override
  Future<Either<Failure, KidsChildPolicy>> saveRemoteChildPolicy({
    required String childUserId,
    required KidsChildPolicy policy,
  }) async {
    remotePolicySaves.add('$childUserId:v${policy.version}');
    return policyResult;
  }

  @override
  Future<Either<Failure, List<KidsHomeMission>>> createRemoteHomeMission({
    required String childUserId,
    required String title,
  }) async {
    remoteMissionCreates.add('$childUserId:$title');
    return missionResult;
  }

  @override
  Future<Either<Failure, List<KidsHomeMission>>> acknowledgeRemoteHomeMission(
    String missionId,
  ) async {
    remoteMissionAcks.add(missionId);
    return missionResult;
  }

  @override
  Future<Either<Failure, List<KidsHomeMission>>> addLocalHomeMission(
    String title,
  ) async {
    localMissionAdds.add(title);
    return missionResult;
  }

  @override
  Future<Either<Failure, List<KidsHomeMission>>> acknowledgeLocalHomeMission(
    String id,
  ) async {
    localMissionAcks.add(id);
    return missionResult;
  }

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
  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard() async {
    dashboardCalls++;
    return dashboardResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Each dashboard read is a stream the test drives by hand.
class _StreamingRepository extends _FakeRepository
    implements FamilyDashboardStreamRepository {
  final reads = <StreamController<Either<Failure, FamilyDashboard>>>[];

  @override
  Stream<Either<Failure, FamilyDashboard>> watchFamilyDashboard() {
    final controller = StreamController<Either<Failure, FamilyDashboard>>();
    reads.add(controller);
    return controller.stream;
  }
}

FamilyDashboard _withLinkedChild(String name, {required bool loading}) =>
    FamilyDashboard(
      settings: _testSettings,
      children: [
        FamilyChildEntry(
          childUserId: 'c1',
          displayName: name,
          isLocal: false,
          remoteSummary: RemoteChildSummary(
            childUserId: 'c1',
            displayName: name,
            progress: const KidsProgress.initial(),
            logs: const [],
            rewards: const [],
            detailsLoading: loading,
          ),
        ),
      ],
    );

bool _loading(FamilyDashboardState state) => (state as FamilyDashboardLoaded)
    .dashboard
    .children
    .single
    .remoteSummary!
    .detailsLoading;

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
  ParentRewardUsecase? rewards,
  bool Function()? guardianSessionActive,
  Future<bool> Function()? pinOptional,
}) => FamilyDashboardCubit(
  ParentAccessUsecase(repository),
  ParentRemoteLinkUsecase(repository),
  GetFamilyDashboardUsecase(repository),
  accountVerifier: verifier,
  rewards: rewards,
  guardianSessionActive: guardianSessionActive,
  pinOptional: pinOptional,
);

Future<void> _unlockAndLoad(FamilyDashboardCubit cubit) async {
  await cubit.unlock('1234');
  expect(cubit.state, isA<FamilyDashboardLoaded>());
}

void main() {
  group('progressive refresh', () {
    late _StreamingRepository repository;
    late FamilyDashboardCubit cubit;

    setUp(() {
      repository = _StreamingRepository();
      cubit = _buildCubit(repository, guardianSessionActive: () => true);
    });

    tearDown(() async {
      for (final read in repository.reads) {
        await read.close();
      }
      await cubit.close();
    });

    test('children show first, details fill in, feedback shows once', () async {
      final done = cubit.refresh(
        feedback: const FamilyDashboardFeedback.rewardAdded(),
      );
      repository.reads.single.add(
        Right(_withLinkedChild('Maryam', loading: true)),
      );
      await pumpEventQueue();

      final first = cubit.state as FamilyDashboardLoaded;
      expect(_loading(first), isTrue);
      expect(first.feedback, const FamilyDashboardFeedback.rewardAdded());

      repository.reads.single.add(
        Right(_withLinkedChild('Maryam', loading: false)),
      );
      await repository.reads.single.close();
      await done;

      final last = cubit.state as FamilyDashboardLoaded;
      expect(_loading(last), isFalse);
      expect(last.feedbackEventId, first.feedbackEventId);
    });

    test('a later failure keeps the last dashboard', () async {
      final done = cubit.refresh();
      final read = repository.reads.single
        ..add(Right(_withLinkedChild('Maryam', loading: true)))
        ..add(const Left(NetworkFailure()));
      await read.close();
      await done;

      expect(_loading(cubit.state), isTrue);
    });

    test('a newer refresh drops the older one', () async {
      final older = cubit.refresh();
      final newer = cubit.refresh();
      final (olderRead, newerRead) = (repository.reads[0], repository.reads[1]);

      newerRead.add(Right(_withLinkedChild('New', loading: false)));
      await pumpEventQueue();
      olderRead.add(Right(_withLinkedChild('Old', loading: false)));
      await pumpEventQueue();

      expect(
        (cubit.state as FamilyDashboardLoaded)
            .dashboard
            .children
            .single
            .displayName,
        'New',
      );
      await newerRead.close();
      await (older, newer).wait;
      expect(olderRead.hasListener, isFalse);
    });
  });

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
    'a running guardian session opens without asking the PIN again',
    () async {
      final cubit = _buildCubit(
        _FakeRepository(),
        guardianSessionActive: () => true,
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state, isA<FamilyDashboardLoaded>());
    },
  );

  test('without a session the PIN gate stays', () async {
    final cubit = _buildCubit(
      _FakeRepository(),
      guardianSessionActive: () => false,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state, isA<FamilyDashboardLocked>());
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

  group('optional PIN on the guardian\'s phone', () {
    Future<bool> optional() async => true;

    test('without a PIN the dashboard opens directly', () async {
      final repository = _FakeRepository(
        settingsResult: const Right(ParentSettings()),
      );
      final cubit = _buildCubit(repository, pinOptional: optional);

      await cubit.load();

      expect(cubit.state, isA<FamilyDashboardLoaded>());
      await cubit.close();
    });

    test('the child device still asks for a PIN without the option', () async {
      final repository = _FakeRepository(
        settingsResult: const Right(ParentSettings()),
      );
      final cubit = _buildCubit(repository);

      await cubit.load();

      expect(cubit.state, const FamilyDashboardNeedsPin());
      await cubit.close();
    });

    test('locking asks for a PIN that can be skipped', () async {
      final repository = _FakeRepository(
        settingsResult: const Right(ParentSettings()),
      );
      final cubit = _buildCubit(repository, pinOptional: optional);
      await cubit.load();

      await cubit.lockWithPin();
      expect(cubit.state, const FamilyDashboardNeedsPin(canSkip: true));

      await cubit.skipPin();
      expect(cubit.state, isA<FamilyDashboardLoaded>());
      await cubit.close();
    });

    test('removing the lock clears the PIN and stays open', () async {
      final repository = _FakeRepository();
      final cubit = _buildCubit(repository, pinOptional: optional);
      await _unlockAndLoad(cubit);

      await cubit.removePinLock();

      expect(repository.resetCalls, 1);
      expect(cubit.state, isA<FamilyDashboardLoaded>());
      await cubit.close();
    });

    test('changing the PIN offers a new one or no lock', () async {
      final repository = _FakeRepository();
      final cubit = _buildCubit(repository, pinOptional: optional);
      await _unlockAndLoad(cubit);

      await cubit.resetAccess();

      expect(cubit.state, const FamilyDashboardNeedsPin(canSkip: true));
      await cubit.close();
    });

    test('without the option the lock cannot be removed or skipped', () async {
      final repository = _FakeRepository();
      final cubit = _buildCubit(repository);
      await _unlockAndLoad(cubit);

      await cubit.removePinLock();
      expect(repository.resetCalls, 0);

      await cubit.resetAccess();
      expect(cubit.state, const FamilyDashboardNeedsPin());
      await cubit.skipPin();
      expect(cubit.state, const FamilyDashboardNeedsPin());
      await cubit.close();
    });
  });

  group('removing a child', () {
    test('success revokes the link and reports it', () async {
      final repository = _FakeRepository();
      final cubit = _buildCubit(repository);
      await _unlockAndLoad(cubit);

      expect(await cubit.removeChild('c1'), isTrue);
      await pumpEventQueue();

      expect(repository.revoked, ['c1']);
      expect(
        (cubit.state as FamilyDashboardLoaded).feedback,
        const FamilyDashboardFeedback.childRemoved(),
      );
      await cubit.close();
    });

    test('a failure keeps the child and says why', () async {
      final repository = _FakeRepository()
        ..revokeResult = const Left(NetworkFailure());
      final cubit = _buildCubit(repository);
      await _unlockAndLoad(cubit);

      expect(await cubit.removeChild('c1'), isFalse);
      expect((cubit.state as FamilyDashboardLoaded).feedback?.isError, isTrue);
      await cubit.close();
    });
  });

  group('linking a child', () {
    test('success turns parent mode on and reloads with feedback', () async {
      final repository = _FakeRepository();
      final cubit = _buildCubit(repository);
      await _unlockAndLoad(cubit);

      await cubit.acceptRemoteToken('A1B2-C3D4-E5F6');

      expect(repository.acceptedTokens, ['A1B2-C3D4-E5F6']);
      expect(repository.parentModeChanges, [true]);
      expect(
        (cubit.state as FamilyDashboardLoaded).feedback,
        const FamilyDashboardFeedback.childLinked(),
      );
      await cubit.close();
    });

    test('a failure leaves parent mode alone and shows the reason', () async {
      final repository = _FakeRepository()
        ..acceptResult = const Left(
          ServerFailure(CubitMessageCodes.guardianLinkCodeInvalid),
        );
      final cubit = _buildCubit(repository);
      await _unlockAndLoad(cubit);

      await cubit.acceptRemoteToken('A1B2C3D4E5F6');

      expect(repository.parentModeChanges, isEmpty);
      expect(
        (cubit.state as FamilyDashboardLoaded).feedback,
        const FamilyDashboardFeedback.failure(
          CubitMessageCodes.guardianLinkCodeInvalid,
        ),
      );
      await cubit.close();
    });

    test('a second submit while linking is ignored', () async {
      final repository = _FakeRepository()..acceptGate = Completer<void>();
      final cubit = _buildCubit(repository);
      await _unlockAndLoad(cubit);

      final first = cubit.acceptRemoteToken('A1B2C3D4E5F6');
      await cubit.acceptRemoteToken('A1B2C3D4E5F6');
      repository.acceptGate!.complete();
      await first;

      expect(repository.acceptedTokens, hasLength(1));
      await cubit.close();
    });
  });

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

  group('home missions', () {
    Future<(_FakeRepository, FamilyDashboardCubit)> loaded() async {
      final repository = _FakeRepository();
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await _unlockAndLoad(cubit);
      return (repository, cubit);
    }

    test(
      'a remote child mission goes through the remote create call',
      () async {
        final (repository, cubit) = await loaded();

        await cubit.addHomeMission('رتّب غرفتك', childId: 'c1');

        expect(repository.remoteMissionCreates, ['c1:رتّب غرفتك']);
        expect(repository.localMissionAdds, isEmpty);
        expect((cubit.state as FamilyDashboardLoaded).feedback, isNull);
      },
    );

    test('without a child id the mission goes through the local API', () async {
      final (repository, cubit) = await loaded();

      await cubit.addHomeMission('  رتّب غرفتك ');

      expect(repository.localMissionAdds, ['رتّب غرفتك']);
      expect(repository.remoteMissionCreates, isEmpty);
    });

    test('a failed remote create surfaces failure feedback', () async {
      final (repository, cubit) = await loaded();
      repository.missionResult = const Left(NetworkFailure('rpc failed'));

      await cubit.addHomeMission('رتّب غرفتك', childId: 'c1');

      final feedback = (cubit.state as FamilyDashboardLoaded).feedback;
      expect(feedback?.type, FamilyDashboardFeedbackType.failure);
      expect(feedback?.message, 'rpc failed');
    });

    test('a failed local create surfaces failure feedback', () async {
      final (repository, cubit) = await loaded();
      repository.missionResult = const Left(
        ValidationFailure(CubitMessageCodes.kidsHomeMissionInvalidTitle),
      );

      await cubit.addHomeMission('x');

      expect(
        (cubit.state as FamilyDashboardLoaded).feedback?.message,
        CubitMessageCodes.kidsHomeMissionInvalidTitle,
      );
    });

    test('acknowledge routes remote and local by child id', () async {
      final (repository, cubit) = await loaded();

      await cubit.acknowledgeHomeMission('7', childId: 'c1');
      await cubit.acknowledgeHomeMission('local-1');

      expect(repository.remoteMissionAcks, ['7']);
      expect(repository.localMissionAcks, ['local-1']);
    });

    test('a failed acknowledge surfaces failure feedback', () async {
      final (repository, cubit) = await loaded();
      repository.missionResult = const Left(NetworkFailure('nope'));

      await cubit.acknowledgeHomeMission('7', childId: 'c1');

      expect(
        (cubit.state as FamilyDashboardLoaded).feedback?.type,
        FamilyDashboardFeedbackType.failure,
      );
    });
  });

  group('child policy', () {
    Future<(_FakeRepository, FamilyDashboardCubit)> loaded() async {
      final repository = _FakeRepository();
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await _unlockAndLoad(cubit);
      return (repository, cubit);
    }

    const edit = KidsChildPolicy(reduceMotion: true, version: 4);

    test('without a child id the edit goes through the device path', () async {
      final (repository, cubit) = await loaded();
      final before = repository.dashboardCalls;

      await cubit.saveChildPolicy(edit);

      expect(repository.localPolicySaves, [edit]);
      expect(repository.remotePolicySaves, isEmpty);
      expect(repository.dashboardCalls, before + 1);
    });

    test('a guardian edit uses the CAS with the summary version', () async {
      final (repository, cubit) = await loaded();

      await cubit.saveChildPolicy(edit, childId: 'c1');

      expect(repository.remotePolicySaves, ['c1:v4']);
      expect(repository.localPolicySaves, isEmpty);
    });

    test(
      'a conflict shows kidsPolicyConflict and reloads the dashboard',
      () async {
        final (repository, cubit) = await loaded();
        repository.policyResult = const Left(PolicyConflictFailure());
        final before = repository.dashboardCalls;

        await cubit.saveChildPolicy(edit, childId: 'c1');

        final state = cubit.state as FamilyDashboardLoaded;
        expect(state.feedback?.type, FamilyDashboardFeedbackType.failure);
        expect(state.feedback?.message, CubitMessageCodes.kidsPolicyConflict);
        expect(repository.dashboardCalls, before + 1);
      },
    );

    test('a network failure surfaces feedback without a reload', () async {
      final (repository, cubit) = await loaded();
      repository.policyResult = const Left(NetworkFailure());
      final before = repository.dashboardCalls;

      await cubit.saveChildPolicy(edit);

      final state = cubit.state as FamilyDashboardLoaded;
      expect(state.feedback?.message, CubitMessageCodes.errorNetwork);
      expect(repository.dashboardCalls, before);
    });
  });

  group('gift steps', () {
    Future<(_FakeRepository, _FakeRewardSteps, FamilyDashboardCubit)>
    loaded() async {
      final repository = _FakeRepository();
      final steps = _FakeRewardSteps();
      final cubit = _buildCubit(
        repository,
        rewards: ParentRewardUsecase(steps),
      );
      addTearDown(cubit.close);
      await cubit.load();
      await _unlockAndLoad(cubit);
      return (repository, steps, cubit);
    }

    test('unlocking a linked child gift goes remote and reloads', () async {
      final (repository, steps, cubit) = await loaded();
      final before = repository.dashboardCalls;

      await cubit.unlockReward('7', childId: 'child-1');

      expect(steps.calls, ['unlock:7:child-1']);
      expect(repository.dashboardCalls, before + 1);
      final state = cubit.state as FamilyDashboardLoaded;
      expect(state.feedback?.type, FamilyDashboardFeedbackType.rewardUnlocked);
    });

    test('approving a device child gift stays local', () async {
      final (_, steps, cubit) = await loaded();

      await cubit.approveReward('g1');

      expect(steps.calls, ['approve:g1:null']);
      final state = cubit.state as FamilyDashboardLoaded;
      expect(state.feedback?.type, FamilyDashboardFeedbackType.rewardApproved);
    });

    test('a refused step shows the failure without a reload', () async {
      final (repository, steps, cubit) = await loaded();
      steps.failure = const CacheFailure(
        CubitMessageCodes.parentRewardUnavailable,
      );
      final before = repository.dashboardCalls;

      await cubit.approveReward('g1');

      final state = cubit.state as FamilyDashboardLoaded;
      expect(state.feedback?.type, FamilyDashboardFeedbackType.failure);
      expect(
        state.feedback?.message,
        CubitMessageCodes.parentRewardUnavailable,
      );
      expect(repository.dashboardCalls, before);
    });

    test('gift steps are ignored while the dashboard is locked', () async {
      final steps = _FakeRewardSteps();
      final cubit = _buildCubit(
        _FakeRepository(),
        rewards: ParentRewardUsecase(steps),
      );
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.unlockReward('g1');

      expect(steps.calls, isEmpty);
    });
  });
}

class _FakeRewardSteps implements ParentRewardRepository {
  final calls = <String>[];
  Failure? failure;

  Future<Either<Failure, List<ParentReward>>> _record(String call) async {
    calls.add(call);
    return failure == null ? const Right([]) : Left(failure!);
  }

  @override
  Future<Either<Failure, List<ParentReward>>> unlockParentReward(
    String id, {
    String? childUserId,
  }) => _record('unlock:$id:$childUserId');

  @override
  Future<Either<Failure, List<ParentReward>>> approveParentReward(
    String id, {
    String? childUserId,
  }) => _record('approve:$id:$childUserId');

  @override
  Future<Either<Failure, List<ParentReward>>> getDeviceRewards() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<ParentReward>>> requestParentReward(String id) =>
      throw UnimplementedError();
}
