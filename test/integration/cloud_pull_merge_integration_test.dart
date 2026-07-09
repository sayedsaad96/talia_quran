import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/memorization/remote_child_production_summary_builder.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/review_record_cloud_merge.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

bool _isarCoreInitialized = false;

Future<void> _initializeIsarCoreForTests() async {
  if (_isarCoreInitialized) return;

  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final dllPath =
          '$localAppData\\Pub\\Cache\\hosted\\pub.dev\\'
          'isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
      if (File(dllPath).existsSync()) {
        await Isar.initializeIsarCore(libraries: {Abi.current(): dllPath});
        _isarCoreInitialized = true;
        return;
      }
    }
  }

  await Isar.initializeIsarCore();
  _isarCoreInitialized = true;
}

void main() {
  group('cloud pull merge integration', () {
    late Isar isar;
    late MemorizationPlusLocalDatasourceImpl datasource;

    setUp(() async {
      await _initializeIsarCoreForTests();
      SharedPreferences.setMockInitialValues({
        ReviewRecordAudienceScope.prefsKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final dir = await Directory.systemTemp.createTemp(
        'talia_cloud_pull_merge_',
      );
      isar = await Isar.open(
        [IsarAyahReviewRecordSchema],
        directory: dir.path,
        name: 'cloud_pull_merge_${DateTime.now().microsecondsSinceEpoch}',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      datasource = MemorizationPlusLocalDatasourceImpl(prefs, isar: isar);
    });

    test('merges remote kids row without clobbering adult row', () async {
      const surahId = 67;
      const ayahNumber = 3;
      final now = DateTime.utc(2026, 7, 9, 9);
      final adult = AyahReviewRecordModel.fromEntity(
        _record(
          surahId: surahId,
          ayahNumber: ayahNumber,
          strengthLevel: 6,
          totalReviews: 8,
          reviewedAt: now,
          mode: ReviewRecordCreatedByMode.v2Session,
        ),
      );
      final localKids = AyahReviewRecordModel.fromEntity(
        _record(
          surahId: surahId,
          ayahNumber: ayahNumber,
          strengthLevel: 2,
          totalReviews: 2,
          reviewedAt: now.subtract(const Duration(days: 1)),
          mode: ReviewRecordCreatedByMode.kidsMode,
        ),
      );
      await datasource.saveReviewRecord(adult);
      await datasource.saveReviewRecord(localKids);

      final remoteKids =
          RemoteChildProductionSummaryBuilder.reviewRecordFromCloud(
            _cloudRow(
              surahId: surahId,
              ayahNumber: ayahNumber,
              strengthLevel: 4,
              totalReviews: 5,
              reviewedAt: now.add(const Duration(hours: 1)),
              mode: ReviewRecordCreatedByMode.kidsMode,
            ),
          );
      final localForScope = await datasource.getReviewRecord(
        surahId,
        ayahNumber,
        scope: ReviewRecordReadScope.kids,
      );
      final merged = ReviewRecordCloudMerge.merge(
        local: localForScope,
        remote: remoteKids,
      );
      await datasource.saveReviewRecord(
        AyahReviewRecordModel.fromEntity(merged),
      );

      final adultAfter = await datasource.getReviewRecord(
        surahId,
        ayahNumber,
        scope: ReviewRecordReadScope.adult,
      );
      final kidsAfter = await datasource.getReviewRecord(
        surahId,
        ayahNumber,
        scope: ReviewRecordReadScope.kids,
      );

      expect(adultAfter?.strengthLevel, 6);
      expect(adultAfter?.totalReviews, 8);
      expect(adultAfter?.createdByMode, ReviewRecordCreatedByMode.v2Session);

      expect(kidsAfter?.strengthLevel, 4);
      expect(kidsAfter?.totalReviews, 5);
      expect(kidsAfter?.createdByMode, ReviewRecordCreatedByMode.kidsMode);
    });
  });
}

AyahReviewRecord _record({
  required int surahId,
  required int ayahNumber,
  required int strengthLevel,
  required int totalReviews,
  required DateTime reviewedAt,
  required ReviewRecordCreatedByMode mode,
}) {
  return AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: strengthLevel,
    lastReviewedAt: reviewedAt,
    nextReviewDate: reviewedAt.add(Duration(days: strengthLevel)),
    totalReviews: totalReviews,
    lastRating: PerformanceRating.excellent,
    createdByMode: mode,
  );
}

Map<String, dynamic> _cloudRow({
  required int surahId,
  required int ayahNumber,
  required int strengthLevel,
  required int totalReviews,
  required DateTime reviewedAt,
  required ReviewRecordCreatedByMode mode,
}) {
  return {
    'surah_id': surahId,
    'ayah_number': ayahNumber,
    'strength_level': strengthLevel,
    'interval_days': strengthLevel,
    'last_reviewed_at': reviewedAt.toIso8601String(),
    'next_review_date': reviewedAt
        .add(Duration(days: strengthLevel))
        .toIso8601String(),
    'total_reviews': totalReviews,
    'last_rating': PerformanceRating.excellent.name,
    'ease_factor': 2.5,
    'lapses': 0,
    'review_state': ReviewState.review.name,
    'created_by_mode': mode.name,
  };
}
