import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/backup/backup_sections.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/sync/group_khatmah_environment.dart';
import 'package:talia_quran/features/group_khatmah/data/group_khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import '../features/group_khatmah/data/group_khatmah_test_support.dart';

void main() {
  test(
    'real audience guard permits durable writes and fences account changes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final owner = MutableOwner(ownerA);
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final personal = KhatmahRepositoryImpl(KhatmahLocalDatasource(prefs));
      final plan = KhatmahPlan(
        id: 'personal',
        title: 'My reading',
        completedPages: {1, 2},
        targetPagesPerDay: 4,
        targetDays: 151,
        startDate: DateTime(2026, 10, 23),
        expectedEndDate: DateTime(2027, 3, 23),
      );
      await personal.createPlan(plan);
      final personalBefore = {
        for (final key in prefs.getKeys().where(
          (key) => key.startsWith('khatmah_'),
        ))
          key: prefs.get(key),
      };
      final audienceChanges = StreamController<void>.broadcast(sync: true);
      final environment = GroupKhatmahAppEnvironment(
        barrier: barrier,
        flags: const ExperienceFlags(_enabled),
        audienceChanges: audienceChanges.stream,
        loadAdult: () async => true,
      );
      final remote = FakeRemote()
        ..groups[groupA] = fixture(groupA, ownerA, epochA);
      final repository = GroupKhatmahRepositoryImpl(
        preferences: prefs,
        owner: owner,
        remote: remote,
        wake: FakeWake(),
        environment: environment,
      );
      addTearDown(audienceChanges.close);
      addTearDown(environment.dispose);
      addTearDown(repository.dispose);
      await environment.start();
      expect((await repository.refreshMine()).isRight(), isTrue);
      expect((await repository.completeLocally(groupA, 1)).isRight(), isTrue);
      expect(await repository.hasPending(), isTrue);
      expect(environment.isAdult, isTrue);
      final oldCache = prefs.getString('group_khatmah_cache_v1|$ownerA');
      expect(oldCache, contains('complete_group_part'));
      expect(await personal.getActivePlan(), plan);
      expect({
        for (final key in personalBefore.keys) key: prefs.get(key),
      }, personalBefore);
      const cacheKey = 'group_khatmah_cache_v1|$ownerA';
      expect(BackupPreferencePolicy.backupKeyFor(cacheKey, ownerA), isNull);
      expect(BackupPreferencePolicy.restoreKeyFor(cacheKey, ownerA), isNull);

      barrier.prepareOwner(ownerB);
      owner.currentOwnerId = ownerB;
      expect(environment.isAdult, isFalse);
      expect(await repository.watchMine().first, isEmpty);
      await barrier.markOwnerReady(ownerB);
      await Future<void>.delayed(Duration.zero);
      expect(await repository.watchMine().first, isEmpty);
      expect(await repository.hasPending(), isFalse);
      expect((await repository.completeLocally(groupA, 1)).isLeft(), isTrue);
      expect(prefs.getString('group_khatmah_cache_v1|$ownerA'), oldCache);
      expect(prefs.getString('group_khatmah_cache_v1|$ownerB'), isNull);
    },
  );
}

bool _enabled(String _) => true;
