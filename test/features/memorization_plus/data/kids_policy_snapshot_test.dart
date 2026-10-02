import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_local_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/parent_dashboard.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

class _UnusedQuranRepository implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreakReader implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _FakeProgressEventsBus implements ProgressEventsBus {
  @override
  void notify(ProgressChangedReason reason) {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopQueue implements CloudSyncQueue {
  @override
  Future<void> enqueue(String kind) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MemorizationPlusLocalDatasourceImpl datasource;
  late MemorizationKidsLocalService service;
  const provider = FixedRecordOwnerProvider('child-1');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    datasource = MemorizationPlusLocalDatasourceImpl(prefs, owner: provider);
    service = MemorizationKidsLocalService(
      datasource,
      _UnusedQuranRepository(),
      _FakeStreakReader(),
      _FakeProgressEventsBus(),
      _NoopQueue(),
      owner: provider,
    );
  });

  /// Policy written by a pull/CAS after the settings sheet took its snapshot.
  const current = ParentSettings(
    pinHash: 'h',
    kidsReduceMotion: true,
    maxDailySuggestions: 1,
    homeMissionsEnabled: false,
    sessionGoalMinutes: 10,
    policyVersion: 5,
    policySyncedVersion: 5,
    policyLinkConfirmed: true,
  );

  test(
    'a stale snapshot (older policyVersion) keeps the stored policy',
    () async {
      await datasource.saveParentSettings(
        ParentSettingsModel.fromEntity(current),
      );
      const snapshot = ParentSettings(pinHash: 'h', policyVersion: 2);

      await service.saveParentSettings(
        snapshot.copyWith(reminderEnabled: false),
      );

      final saved = await datasource.getParentSettings();
      expect(saved.reminderEnabled, isFalse, reason: 'the toggle still saves');
      expect(saved.kidsReduceMotion, isTrue);
      expect(saved.maxDailySuggestions, 1);
      expect(saved.homeMissionsEnabled, isFalse);
      expect(saved.sessionGoalMinutes, 10);
      expect(saved.policyVersion, 5);
      expect(saved.policySyncedVersion, 5);
      expect(saved.policyLinkConfirmed, isTrue);
    },
  );

  test(
    'an older policySyncedVersion alone also keeps the stored policy',
    () async {
      await datasource.saveParentSettings(
        ParentSettingsModel.fromEntity(current),
      );

      await service.saveParentSettings(
        current.copyWith(
          kidsReduceMotion: false,
          policyVersion: 6,
          policySyncedVersion: 4,
        ),
      );

      final saved = await datasource.getParentSettings();
      expect(saved.kidsReduceMotion, isTrue);
      expect(saved.policyVersion, 5);
    },
  );

  test('equal versions pass through (onboarding session goal write)', () async {
    await datasource.saveParentSettings(
      ParentSettingsModel.fromEntity(current),
    );

    await service.saveParentSettings(current.copyWith(sessionGoalMinutes: 6));

    expect((await datasource.getParentSettings()).sessionGoalMinutes, 6);
  });
}
