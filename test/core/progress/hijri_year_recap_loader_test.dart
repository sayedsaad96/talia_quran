import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/progress/hijri_year_recap_loader.dart';
import 'package:talia_quran/core/services/hijri_date_adjustment.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/repositories/khatmah_repository.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

void main() {
  late SharedPreferences prefs;
  late _Owner owner;
  late AccountDataBarrier barrier;
  late _History history;
  late HijriYearRecapLoader loader;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = _Owner('owner-a');
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    history = _History();
    loader = HijriYearRecapLoader(
      history,
      _Reviews(),
      _Streaks(),
      prefs,
      owner,
      barrier,
      HijriDateAdjustment(prefs),
      now: () => DateTime(2027, 6, 3),
    );
  });

  test(
    'dismissal persists only for the captured owner and Hijri year',
    () async {
      await loader.dismiss(1448);
      expect(
        prefs.getBool(HijriYearRecapLoader.dismissalKey('owner-a', 1448)),
        isTrue,
      );
      expect(
        prefs.getBool(HijriYearRecapLoader.dismissalKey('owner-a', 1449)),
        isNull,
      );
      expect(
        prefs.getBool(HijriYearRecapLoader.dismissalKey('owner-b', 1448)),
        isNull,
      );
      owner.currentOwnerId = 'owner-b';
      barrier.prepareOwner('owner-b');
      await barrier.markOwnerReady('owner-b');
      await loader.dismiss(1449);
      expect(
        prefs.getBool(HijriYearRecapLoader.dismissalKey('owner-b', 1449)),
        isTrue,
      );
      expect(
        prefs.getBool(HijriYearRecapLoader.dismissalKey('owner-a', 1449)),
        isNull,
      );
    },
  );

  test('outside the visibility window no store is read', () async {
    final outside = HijriYearRecapLoader(
      history,
      _Reviews(),
      _Streaks(),
      prefs,
      owner,
      barrier,
      HijriDateAdjustment(prefs),
      now: () => DateTime(2027, 1, 15),
    );
    final result = await outside.load();
    expect(result.recap.isVisible, isFalse);
    expect(history.started.isCompleted, isFalse);
  });

  test('invalidation while reading prevents later stores being read', () async {
    final loading = loader.load();
    final rejected = expectLater(
      loading,
      throwsA(isA<AccountDataUnavailableException>()),
    );
    await history.started.future;
    barrier.invalidate();
    history.result.complete([]);
    await rejected;
  });

  test('queued dismissal cannot write after a same-owner reset', () async {
    final release = Completer<void>();
    final entered = Completer<void>();
    final prior = barrier.run((_) async {
      entered.complete();
      await release.future;
    });
    final priorRejected = expectLater(
      prior,
      throwsA(isA<AccountDataUnavailableException>()),
    );
    await entered.future;
    final dismissal = loader.dismiss(1448);
    final dismissalRejected = expectLater(
      dismissal,
      throwsA(isA<AccountDataUnavailableException>()),
    );
    barrier.invalidate();
    release.complete();
    await Future.wait([priorRejected, dismissalRejected]);
    expect(
      prefs.getBool(HijriYearRecapLoader.dismissalKey('owner-a', 1448)),
      isNull,
    );
  });

  test('real Khatmah history read leaves the account barrier live', () async {
    final realLoader = HijriYearRecapLoader(
      KhatmahRepositoryImpl(KhatmahLocalDatasource(prefs)),
      _EmptyReviews(),
      _EmptyStreaks(),
      prefs,
      owner,
      barrier,
      HijriDateAdjustment(prefs),
      now: () => DateTime(2027, 6, 3),
    );

    final result = await realLoader.load().timeout(const Duration(seconds: 1));
    expect(result.recap.completedKhatmahs, isZero);

    var laterBarrierWorkRan = false;
    await barrier
        .run((_) async => laterBarrierWorkRan = true)
        .timeout(const Duration(seconds: 1));
    expect(laterBarrierWorkRan, isTrue);
  });
}

class _Owner implements RecordOwnerProvider {
  _Owner(this.currentOwnerId);
  @override
  String currentOwnerId;
  @override
  bool get isSignedIn => true;
}

class _History extends Fake implements KhatmahRepository {
  final started = Completer<void>();
  final result = Completer<List<KhatmahHistoryEntry>>();
  @override
  Future<List<KhatmahHistoryEntry>> getHistory() {
    started.complete();
    return result.future;
  }
}

class _Reviews extends Fake implements MemorizationPlusLocalDatasource {}

class _Streaks extends Fake implements StreakService {}

class _EmptyReviews extends Fake implements MemorizationPlusLocalDatasource {
  @override
  Future<List<AyahReviewRecordModel>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
    bool includeAllAudiences = false,
  }) async =>
      [];
}

class _EmptyStreaks extends Fake implements StreakService {
  @override
  Future<StreakEntity> getStreak() async => const StreakEntity(
    currentStreak: 0,
    longestStreak: 0,
  );

  @override
  Future<Map<String, int>> getActivityMap({int days = 365}) async => {};
}
