import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/l10n/locale_cubit.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/parent_dashboard_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeParentAccess implements ParentAccessUsecase {
  _FakeParentAccess({
    this.pinValid = false,
    this.saveRewardResult = const Right([]),
  });

  final bool pinValid;
  final Either<Failure, List<ParentReward>> saveRewardResult;

  @override
  Future<Either<Failure, ParentSettings>> getSettings() async =>
      const Right(ParentSettings());

  @override
  Future<Either<Failure, bool>> verifyPin(String pin) async => Right(pinValid);

  @override
  Future<Either<Failure, List<ParentReward>>> saveReward(String title) async =>
      saveRewardResult;

  @override
  Future<Either<Failure, void>> saveSettings(ParentSettings settings) async =>
      const Right(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGetDashboard implements GetParentDashboardUsecase {
  _FakeGetDashboard({ParentDashboard? dashboard})
    : dashboard = dashboard ?? _testDashboard;

  final ParentDashboard dashboard;

  @override
  Future<Either<Failure, ParentDashboard>> call(
    GetParentDashboardParams params,
  ) async => Right(dashboard);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemoteLink implements ParentRemoteLinkUsecase {
  const _FakeRemoteLink({
    this.removeChildResult = const Right(null),
  });

  final Either<Failure, void> removeChildResult;

  @override
  Future<Either<Failure, List<RemoteChildSummary>>> getRemoteChildren() async =>
      const Right([]);

  @override
  Future<Either<Failure, MemorizationProfile>> acceptGuardianPairingCode(
    String token,
  ) async => Right(_testProfile);

  @override
  Future<Either<Failure, List<ParentReward>>> saveRemoteReward({
    required String childUserId,
    required String title,
  }) async => const Right([]);

  @override
  Future<Either<Failure, void>> removeChild(String childUserId) async =>
      removeChildResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _testDashboard = ParentDashboard(
  progress: KidsProgress.initial(),
  stages: [],
  logs: [],
  rewards: [],
  settings: ParentSettings(pinHash: '1234'),
);

final _testProfile = MemorizationProfile(
  schemaVersion: 1,
  selectedPath: MemorizationPath.child,
  guardianLinkStatus: GuardianLinkStatus.linked,
  guardianOnboardingStatus: GuardianOnboardingStatus.completed,
  guardianId: 'guardian-1',
  isParentGuardian: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('ParentDashboardCubit PIN feedback', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await getIt.reset();
      final prefs = await SharedPreferences.getInstance();
      getIt.registerSingleton<SharedPreferences>(prefs);
      getIt.registerLazySingleton<TaliaNotificationService>(
        TaliaNotificationService.new,
      );
      getIt.registerLazySingleton<NotificationScheduler>(
        () => NotificationScheduler(getIt<TaliaNotificationService>()),
      );
      getIt.registerLazySingleton<LocaleCubit>(
        () => LocaleCubit(getIt<SharedPreferences>()),
      );
    });

    tearDown(() async {
      await getIt.reset();
    });

    test('setPin with an invalid code emits a localizable pinInvalid notice '
        'instead of a hardcoded string', () async {
      final cubit = ParentDashboardCubit(
        _FakeGetDashboard(),
        _FakeParentAccess(),
        const _FakeRemoteLink(),
      );
      addTearDown(cubit.close);

      final assertion = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ParentDashboardNeedsPin>()
              .having(
                (s) => s.feedback?.type,
                'feedback type',
                ParentDashboardFeedbackType.pinInvalid,
              )
              .having((s) => s.feedbackEventId, 'feedbackEventId', 1),
        ]),
      );

      await cubit.setPin('12', surahId: 1);
      await assertion;
    });

    test('unlock with an invalid code emits a pinInvalid notice', () async {
      final cubit = ParentDashboardCubit(
        _FakeGetDashboard(),
        _FakeParentAccess(),
        const _FakeRemoteLink(),
      );
      addTearDown(cubit.close);

      final assertion = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ParentDashboardLocked>()
              .having(
                (s) => s.feedback?.type,
                'feedback type',
                ParentDashboardFeedbackType.pinInvalid,
              )
              .having((s) => s.feedbackEventId, 'feedbackEventId', 1),
        ]),
      );

      await cubit.unlock('1', surahId: 1);
      await assertion;
    });

    test('unlock with a wrong code emits a pinIncorrect notice', () async {
      final cubit = ParentDashboardCubit(
        _FakeGetDashboard(),
        _FakeParentAccess(pinValid: false),
        const _FakeRemoteLink(),
      );
      addTearDown(cubit.close);

      final assertion = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ParentDashboardLoading>(),
          isA<ParentDashboardLocked>()
              .having(
                (s) => s.feedback?.type,
                'feedback type',
                ParentDashboardFeedbackType.pinIncorrect,
              )
              .having((s) => s.feedbackEventId, 'feedbackEventId', 1),
        ]),
      );

      await cubit.unlock('1234', surahId: 1);
      await assertion;
    });

    test('repeated wrong PIN emits distinct feedbackEventId values', () async {
      final cubit = ParentDashboardCubit(
        _FakeGetDashboard(),
        _FakeParentAccess(pinValid: false),
        const _FakeRemoteLink(),
      );
      addTearDown(cubit.close);

      final assertion = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ParentDashboardLoading>(),
          isA<ParentDashboardLocked>()
              .having(
                (s) => s.feedback?.type,
                'feedback type',
                ParentDashboardFeedbackType.pinIncorrect,
              )
              .having((s) => s.feedbackEventId, 'feedbackEventId', 1),
          isA<ParentDashboardLoading>(),
          isA<ParentDashboardLocked>()
              .having(
                (s) => s.feedback?.type,
                'feedback type',
                ParentDashboardFeedbackType.pinIncorrect,
              )
              .having((s) => s.feedbackEventId, 'feedbackEventId', 2),
        ]),
      );

      await cubit.unlock('1234', surahId: 1);
      await cubit.unlock('1234', surahId: 1);
      await assertion;
    });

    test('reward success emits rewardAdded feedback', () async {
      final cubit = ParentDashboardCubit(
        _FakeGetDashboard(),
        _FakeParentAccess(),
        const _FakeRemoteLink(),
      );
      addTearDown(cubit.close);

      await cubit.refresh(surahId: 1);
      final assertion = expectLater(
        cubit.stream,
        emits(
          isA<ParentDashboardLoaded>()
              .having(
                (s) => s.feedback?.type,
                'feedback type',
                ParentDashboardFeedbackType.rewardAdded,
              )
              .having((s) => s.feedbackEventId, 'feedbackEventId', 1),
        ),
      );

      await cubit.addReward('Bonus star');
      await assertion;
    });

    test('child linked success emits childLinked feedback', () async {
      final cubit = ParentDashboardCubit(
        _FakeGetDashboard(),
        _FakeParentAccess(),
        const _FakeRemoteLink(),
      );
      addTearDown(cubit.close);

      final assertion = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ParentDashboardLinking>(),
          isA<ParentDashboardLoaded>()
              .having(
                (s) => s.feedback?.type,
                'feedback type',
                ParentDashboardFeedbackType.childLinked,
              )
              .having((s) => s.feedbackEventId, 'feedbackEventId', 1),
        ]),
      );

      await cubit.acceptRemoteToken('talia-kids-link:test', surahId: 1);
      await assertion;
    });

    test('remove child success emits childRemoved feedback', () async {
      final cubit = ParentDashboardCubit(
        _FakeGetDashboard(),
        _FakeParentAccess(),
        const _FakeRemoteLink(),
      );
      addTearDown(cubit.close);

      await cubit.refresh(surahId: 1);
      final assertion = expectLater(
        cubit.stream,
        emits(
          isA<ParentDashboardLoaded>()
              .having(
                (s) => s.feedback?.type,
                'feedback type',
                ParentDashboardFeedbackType.childRemoved,
              )
              .having((s) => s.feedbackEventId, 'feedbackEventId', 1),
        ),
      );

      await cubit.removeChild('child-1', surahId: 1);
      await assertion;
    });

    test('remove child failure emits failure feedback', () async {
      final cubit = ParentDashboardCubit(
        _FakeGetDashboard(),
        _FakeParentAccess(),
        const _FakeRemoteLink(
          removeChildResult: Left(CacheFailure('Unlink failed')),
        ),
      );
      addTearDown(cubit.close);

      await cubit.refresh(surahId: 1);
      final assertion = expectLater(
        cubit.stream,
        emits(
          isA<ParentDashboardLoaded>()
              .having(
                (s) => s.feedback?.type,
                'feedback type',
                ParentDashboardFeedbackType.failure,
              )
              .having(
                (s) => s.feedback?.message,
                'feedback message',
                'Unlink failed',
              )
              .having((s) => s.feedbackEventId, 'feedbackEventId', 1),
        ),
      );

      await cubit.removeChild('child-1', surahId: 1);
      await assertion;
    });

    test('reminder saved emits reminderSaved feedback', () async {
      final cubit = ParentDashboardCubit(
        _FakeGetDashboard(),
        _FakeParentAccess(),
        const _FakeRemoteLink(),
      );
      addTearDown(cubit.close);

      await cubit.refresh(surahId: 1);
      final assertion = expectLater(
        cubit.stream,
        emits(
          isA<ParentDashboardLoaded>()
              .having(
                (s) => s.feedback?.type,
                'feedback type',
                ParentDashboardFeedbackType.reminderSaved,
              )
              .having((s) => s.feedbackEventId, 'feedbackEventId', 1),
        ),
      );

      await cubit.updateReminder(enabled: true, hour: 18, minute: 30);
      await assertion;
    });

    test('operation failure emits failure feedback', () async {
      final cubit = ParentDashboardCubit(
        _FakeGetDashboard(),
        _FakeParentAccess(
          saveRewardResult: const Left(CacheFailure('Reward failed')),
        ),
        const _FakeRemoteLink(),
      );
      addTearDown(cubit.close);

      await cubit.refresh(surahId: 1);
      final assertion = expectLater(
        cubit.stream,
        emits(
          isA<ParentDashboardLoaded>()
              .having(
                (s) => s.feedback?.type,
                'feedback type',
                ParentDashboardFeedbackType.failure,
              )
              .having(
                (s) => s.feedback?.message,
                'feedback message',
                'Reward failed',
              )
              .having((s) => s.feedbackEventId, 'feedbackEventId', 1),
        ),
      );

      await cubit.addReward('Bonus star');
      await assertion;
    });
  });
}
