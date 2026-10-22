import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/kids_legacy_split_recovery_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_legacy_resume_recovery.dart';

void main() {
  late MemorizationPlusLocalDatasourceImpl source;
  late AccountDataBarrier barrier;
  late KidsLegacySplitRecoveryRepositoryImpl repository;
  const owner = FixedRecordOwnerProvider('child-a');
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    source = MemorizationPlusLocalDatasourceImpl(prefs, owner: owner);
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    repository = KidsLegacySplitRecoveryRepositoryImpl(source, owner, barrier);
  });
  KidsLegacyResumeRecoveryTicket ticket({int count = 30}) =>
      KidsLegacyResumeRecoveryTicket(
        ownerId: owner.currentOwnerId,
        lease: barrier.capture(),
        surahId: 67,
        verifiedAyahCount: count,
        defaultStageSize: 3,
        checkpointAyah: 3,
      );

  test(
    'explicit choice persists once and a concurrent frozen winner stays',
    () async {
      final original = ticket();
      expect(
        (await repository.save(original, whole: false, stageSize: 4)).isRight(),
        isTrue,
      );
      expect((await source.getParentSettings()).kidsHouseSizesBySurah[67], 4);
      expect(
        (await repository.save(original, whole: false, stageSize: 2)).isRight(),
        isTrue,
      );
      expect((await source.getParentSettings()).kidsHouseSizesBySurah[67], 4);
    },
  );

  test(
    'same-owner reset invalidates a displayed choice before it can write',
    () async {
      final original = ticket();
      await barrier.clear(() async {});
      expect(
        (await repository.save(original, whole: false, stageSize: 4)).isLeft(),
        isTrue,
      );
      expect((await source.getParentSettings()).kidsHouseSizesBySurah, isEmpty);
    },
  );

  test(
    'whole-surah limit and invalid size never write a structural choice',
    () async {
      expect((await repository.save(ticket(), whole: true)).isLeft(), isTrue);
      expect(
        (await repository.save(ticket(), whole: false, stageSize: 11)).isLeft(),
        isTrue,
      );
      expect((await source.getParentSettings()).kidsHouseSizesBySurah, isEmpty);
      expect((await source.getParentSettings()).kidsWholeSurahIds, isEmpty);
    },
  );

  test(
    'a whole-surah winner cannot be overwritten by a delayed staged choice',
    () async {
      final original = ticket(count: 7);
      await source.updateKidsHouseSettings(
        (settings) => settings.copyWith(kidsWholeSurahIds: {67}),
      );
      await repository.save(original, whole: false, stageSize: 2);
      final settings = await source.getParentSettings();
      expect(settings.kidsWholeSurahIds, {67});
      expect(settings.kidsHouseSizesBySurah, isEmpty);
    },
  );
}
