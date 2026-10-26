import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/experience/feature_preferences.dart';
import 'package:talia_quran/core/home_widget/home_widget_publisher.dart';
import 'package:talia_quran/core/home_widget/widget_snapshot.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/core/seasons/season_preferences.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/hifz/data/models/isar_ayah_progress.dart';
import 'package:talia_quran/features/seasons/data/season_flag_store.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/streak/data/models/daily_activity_isar.dart';
import 'package:talia_quran/features/streak/data/models/streak_isar.dart';
import 'package:talia_quran/features/xp/data/models/xp_isar.dart';
import '../helpers/isar_test_core.dart';


Future<void> _initializeIsarCoreForTests() => initializeIsarCoreForTests();

class _WidgetBridge implements HomeWidgetBridge {
  String? value;
  @override Future<void> save(String key, String? json) async { value = json; }
  @override Future<void> requestUpdate() async {}
  @override Future<void> scheduleUpdates(List<DateTime> times) async {}
  @override Future<void> cancelScheduledUpdates() async {}
  @override Future<void> setReceiverEnabled(bool enabled) async {}
}

class _SwitchableOwner implements RecordOwnerProvider {
  _SwitchableOwner(this.id);
  String id;
  @override
  String get currentOwnerId => id;
  @override
  bool get isSignedIn => true;
}

AyahReviewRecordModel _record({
  required int surahId,
  required int ayahNumber,
  required ReviewRecordCreatedByMode mode,
  int strengthLevel = 3,
}) {
  final now = DateTime.utc(2026, 8, 8);
  return AyahReviewRecordModel(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: 1,
    lastReviewedAt: now,
    nextReviewDate: now.add(const Duration(days: 1)),
    totalReviews: 1,
    lastRating: PerformanceRating.average,
    createdByMode: mode,
  );
}

void main() {
  group('IS-2 account switch isolation', () {
    late Isar isar;
    late SharedPreferences prefs;
    late Directory dir;

    MemorizationPlusLocalDatasourceImpl datasourceFor(String ownerId) =>
        MemorizationPlusLocalDatasourceImpl(
          prefs,
          isar: isar,
          owner: FixedRecordOwnerProvider(ownerId),
        );

    setUp(() async {
      await _initializeIsarCoreForTests();
      SharedPreferences.setMockInitialValues({
        'mem_plus_reviews_migrated_to_isar_v1': true,
        'mem_plus_review_identity_keys_v1': true,
      });
      prefs = await SharedPreferences.getInstance();
      dir = await Directory.systemTemp.createTemp('talia_is2_');
      isar = await Isar.open(
        [
          IsarAyahProgressSchema,
          IsarAyahReviewRecordSchema,
          IsarV2SessionSchema,
          StreakIsarSchema,
          XpIsarSchema,
          DailyActivityIsarSchema,
          CloudSyncQueueItemSchema,
        ],
        directory: dir.path,
        name: 'is2_${DateTime.now().microsecondsSinceEpoch}',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await dir.exists()) await dir.delete(recursive: true);
      });
    });

    test('switching accounts leaves the arriving account with nothing',
        () async {
      await datasourceFor('user-a').saveReviewRecord(
        _record(
          surahId: 67,
          ayahNumber: 3,
          mode: ReviewRecordCreatedByMode.v2Session,
          strengthLevel: 6,
        ),
      );
      await CloudSyncQueue(
        isar,
        const FixedRecordOwnerProvider('user-a'),
      ).enqueue(CloudSyncQueueKind.productionPush);
      await prefs.setString('ayah_review_pull_cursor', '2026-08-01T00:00:00Z');
      await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'user-a');

      final switched = await AuthCubit.resolveOwnerChange(
        prefs: prefs,
        userId: 'user-b',
        onDepartingAccount:
            AccountDataReset(isar, prefs).clearAccountOwnedData,
      );

      expect(switched, isTrue);
      expect(await datasourceFor('user-b').getAllReviewRecords(), isEmpty);
      expect(await isar.isarAyahReviewRecords.where().count(), 0);
      expect(await isar.cloudSyncQueueItems.where().count(), 0);
      expect(prefs.getString('ayah_review_pull_cursor'), isNull);
      expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'user-b');
    });

    test('native widget is cleared before arriving owner is persisted', () async {
      final bridge = _WidgetBridge()..value = '{"schemaVersion":1,"dueReviewCount":77}';
      await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'user-a');
      final reset = AccountDataReset(isar, prefs, clearHomeWidget: () async {
        expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'user-a');
        await bridge.save(HomeWidgetPublisher.snapshotKey, null);
        await bridge.requestUpdate();
      });
      await AuthCubit.resolveOwnerChange(prefs: prefs, userId: 'user-b',
        onDepartingAccount: reset.clearAccountOwnedData);
      expect(bridge.value, isNull);
      expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'user-b');
    });

    test('real publisher as barrier participant wipes the widget on switch', () async {
      final bridge = _WidgetBridge();
      final owner = _SwitchableOwner('user-a');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final publisher = HomeWidgetPublisher(
        bridge: bridge,
        owner: owner,
        barrier: barrier,
        load: (lease, id) async => const WidgetSnapshot(dueReviewCount: 77),
      );
      await publisher.start();
      addTearDown(publisher.dispose);
      await publisher.refresh();
      expect(bridge.value, contains('77'));
      await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'user-a');

      final reset = AccountDataReset(
        isar,
        prefs,
        owner: owner,
        clearHomeWidget: publisher.clearForAccountTransition,
      );
      await AuthCubit.resolveOwnerChange(
        prefs: prefs,
        userId: 'user-b',
        onDepartingAccount: reset.clearAccountOwnedData,
      );
      owner.id = 'user-b';
      // Cleared before the arriving owner may publish anything.
      expect(bridge.value, isNull);
      expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'user-b');
    });

    test('the arriving account starts from a clean pull cursor', () async {
      await prefs.setString('ayah_review_pull_cursor', '2026-08-01T00:00:00Z');
      await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'user-a');

      await AuthCubit.resolveOwnerChange(
        prefs: prefs,
        userId: 'user-b',
        onDepartingAccount:
            AccountDataReset(isar, prefs).clearAccountOwnedData,
      );

      expect(prefs.getString('ayah_review_pull_cursor'), isNull);
      expect(prefs.getString('ayah_review_pull_cursor_pulled_at'), isNull);
    });

    test("owner A's feature and season choices do not reach owner B", () async {
      final owner = _SwitchableOwner('user-a');
      final features = FeaturePreferences(
        prefs,
        owner,
        ExperienceFlags((_) => true),
      );
      final seasons = SeasonPreferences(prefs, owner);
      final flags = SeasonFlagStore(prefs, owner);

      await features.setEnabled(ExperienceFeature.readerRepeat, false);
      await seasons.setMasterEnabled(false);
      await seasons.setSeasonEnabled(SeasonId.ashura, false);
      await seasons.setRemindersEnabled(true);
      await flags.set('shawwal_1448_2027-04-01', true);

      owner.id = 'user-b';
      expect(features.isEnabled(ExperienceFeature.readerRepeat), isTrue);
      expect(seasons.masterEnabled, isTrue);
      expect(seasons.isSeasonEnabled(SeasonId.ashura), isTrue);
      expect(seasons.remindersEnabled, isFalse);
      expect(flags.isSet('shawwal_1448_2027-04-01'), isFalse);
      expect(flags.namesWithPrefix('shawwal_'), isEmpty);

      // B's own choices do not leak back to A either.
      await seasons.setRemindersEnabled(false);
      await seasons.setMasterEnabled(true);
      owner.id = 'user-a';
      expect(features.isEnabled(ExperienceFeature.readerRepeat), isFalse);
      expect(seasons.masterEnabled, isFalse);
      expect(seasons.isSeasonEnabled(SeasonId.ashura), isFalse);
      expect(seasons.remindersEnabled, isTrue);
      expect(flags.isSet('shawwal_1448_2027-04-01'), isTrue);
    });

    test("the departing owner's choices are cleared on an account change", () async {
      final owner = _SwitchableOwner('user-a');
      final features = FeaturePreferences(
        prefs,
        owner,
        ExperienceFlags((_) => true),
      );
      final seasons = SeasonPreferences(prefs, owner);
      await features.setEnabled(ExperienceFeature.readerRepeat, false);
      await seasons.setRemindersEnabled(true);
      await SeasonFlagStore(prefs, owner).set('x', true);
      await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'user-a');

      await AuthCubit.resolveOwnerChange(
        prefs: prefs,
        userId: 'user-b',
        onDepartingAccount:
            AccountDataReset(isar, prefs).clearAccountOwnedData,
      );

      expect(
        prefs.getKeys().where(
          (k) =>
              k.startsWith('feature_pref_') ||
              k.startsWith('season_pref_') ||
              k.startsWith('season_flag_'),
        ),
        isEmpty,
      );
    });
  });
}
