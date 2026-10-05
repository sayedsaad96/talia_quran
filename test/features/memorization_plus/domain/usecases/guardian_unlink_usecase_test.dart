import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_parent_access_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_identity_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/guardian_unlink_usecase.dart';

class _MockIdentity extends Mock implements MemorizationIdentityRepository {}

ParentReward _gift(String id, ParentRewardStatus status) => ParentReward(
  id: id,
  title: 'Gift $id',
  status: status,
  createdAt: DateTime.utc(2026, 10),
);

void main() {
  group('UnlinkGuardianUsecase', () {
    late _MockIdentity identity;

    setUp(() => identity = _MockIdentity());

    test('passes the unlinked profile through', () async {
      final profile = MemorizationProfile.empty();
      when(
        () => identity.unlinkGuardian(),
      ).thenAnswer((_) async => Right(profile));

      final result = await UnlinkGuardianUsecase(identity)();

      expect(result, Right<Failure, MemorizationProfile>(profile));
    });

    test('any server failure becomes one clear message', () async {
      when(() => identity.unlinkGuardian()).thenAnswer(
        (_) async => const Left(
          NetworkFailure(CubitMessageCodes.guardianCloudUnavailable),
        ),
      );

      final result = await UnlinkGuardianUsecase(identity)();

      expect(
        result.fold((f) => f.message, (_) => null),
        CubitMessageCodes.guardianUnlinkFailed,
      );
    });
  });

  test('after unlinking only received gifts stay on the device', () {
    final kept = MemorizationParentAccessService.giftsKeptAfterUnlink([
      _gift('1', ParentRewardStatus.locked),
      _gift('2', ParentRewardStatus.unlocked),
      _gift('3', ParentRewardStatus.requested),
      _gift('4', ParentRewardStatus.claimed),
    ]);

    expect(kept.map((gift) => gift.id), ['4']);
  });
}
