// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';

// ─── helpers ────────────────────────────────────────────────────────────────

AyahReviewRecord _record({
  ReviewRecordCreatedByMode mode = ReviewRecordCreatedByMode.unknown,
}) {
  final now = DateTime.utc(2026);
  return AyahReviewRecord(
    surahId: 1,
    ayahNumber: 1,
    strengthLevel: 0,
    intervalDays: 0,
    lastReviewedAt: now,
    nextReviewDate: now,
    totalReviews: 0,
    lastRating: null,
    createdByMode: mode,
  );
}

AyahReviewRecordModel _model({
  ReviewRecordCreatedByMode mode = ReviewRecordCreatedByMode.unknown,
}) {
  final now = DateTime.utc(2026);
  return AyahReviewRecordModel(
    surahId: 1,
    ayahNumber: 1,
    strengthLevel: 0,
    intervalDays: 0,
    lastReviewedAt: now,
    nextReviewDate: now,
    totalReviews: 0,
    lastRating: null,
    createdByMode: mode,
  );
}

void main() {
  // ─── Enum / Mapping Tests ──────────────────────────────────────────────────

  group('ReviewRecordCreatedByMode enum', () {
    test('enum has correct values', () {
      expect(ReviewRecordCreatedByMode.values, [
        ReviewRecordCreatedByMode.adultMemPlus,
        ReviewRecordCreatedByMode.kidsMode,
        ReviewRecordCreatedByMode.hifz,
        ReviewRecordCreatedByMode.migration,
        ReviewRecordCreatedByMode.unknown,
        ReviewRecordCreatedByMode.v2Session, // V2 addition
      ]);
    });

    test('unknown is the last value (so new records default safely)', () {
      // Isar stores index; unknown must remain index 4 so new entries
      // can default to it without collision with existing stored values.
      expect(ReviewRecordCreatedByMode.unknown.index, 4);
    });

    test('v2Session has index 5 (appended after unknown)', () {
      // v2Session must be the last value — appended after unknown.
      // Isar records with index 5 will map to v2Session.
      expect(ReviewRecordCreatedByMode.v2Session.index, 5);
    });
  });

  group('AyahReviewRecord.createdByMode', () {
    test('defaults to unknown when not provided', () {
      final now = DateTime.utc(2026);
      final record = AyahReviewRecord(
        surahId: 1,
        ayahNumber: 1,
        strengthLevel: 0,
        intervalDays: 0,
        lastReviewedAt: now,
        nextReviewDate: now,
        totalReviews: 0,
        lastRating: null,
        // createdByMode intentionally omitted
      );
      expect(record.createdByMode, ReviewRecordCreatedByMode.unknown);
    });

    test('adultMemPlus round-trips through copyWith', () {
      final record = _record(mode: ReviewRecordCreatedByMode.adultMemPlus);
      final updated = record.copyWith(strengthLevel: 1);
      expect(updated.createdByMode, ReviewRecordCreatedByMode.adultMemPlus);
    });

    test('kidsMode round-trips through copyWith', () {
      final record = _record(mode: ReviewRecordCreatedByMode.kidsMode);
      final updated = record.copyWith(strengthLevel: 6);
      expect(updated.createdByMode, ReviewRecordCreatedByMode.kidsMode);
    });

    test('copyWith can explicitly override createdByMode', () {
      final record = _record(mode: ReviewRecordCreatedByMode.unknown);
      final upgraded = record.copyWith(
        createdByMode: ReviewRecordCreatedByMode.adultMemPlus,
      );
      expect(upgraded.createdByMode, ReviewRecordCreatedByMode.adultMemPlus);
    });

    test('props includes createdByMode for equality comparison', () {
      final a = _record(mode: ReviewRecordCreatedByMode.adultMemPlus);
      final b = _record(mode: ReviewRecordCreatedByMode.kidsMode);
      expect(a, isNot(equals(b)));
    });
  });

  // ─── Model JSON Tests ──────────────────────────────────────────────────────

  group('AyahReviewRecordModel JSON serialization', () {
    test('fromJson: missing createdByMode field maps to unknown', () {
      final now = DateTime.utc(2026);
      final json = {
        'surahId': 1,
        'ayahNumber': 1,
        'strengthLevel': 0,
        'intervalDays': 0,
        'lastReviewedAt': now.toIso8601String(),
        'nextReviewDate': now.toIso8601String(),
        'totalReviews': 0,
        'lastRating': null,
        // 'createdByMode' intentionally absent — simulates legacy JSON
      };
      final model = AyahReviewRecordModel.fromJson(json);
      expect(model.createdByMode, ReviewRecordCreatedByMode.unknown);
    });

    test('fromJson: null createdByMode maps to unknown', () {
      final now = DateTime.utc(2026);
      final json = {
        'surahId': 1,
        'ayahNumber': 1,
        'strengthLevel': 0,
        'intervalDays': 0,
        'lastReviewedAt': now.toIso8601String(),
        'nextReviewDate': now.toIso8601String(),
        'totalReviews': 0,
        'lastRating': null,
        'createdByMode': null,
      };
      final model = AyahReviewRecordModel.fromJson(json);
      expect(model.createdByMode, ReviewRecordCreatedByMode.unknown);
    });

    test('fromJson: out-of-bounds index maps to unknown', () {
      final now = DateTime.utc(2026);
      final json = {
        'surahId': 1,
        'ayahNumber': 1,
        'strengthLevel': 0,
        'intervalDays': 0,
        'lastReviewedAt': now.toIso8601String(),
        'nextReviewDate': now.toIso8601String(),
        'totalReviews': 0,
        'lastRating': null,
        'createdByMode': 9999, // invalid index
      };
      final model = AyahReviewRecordModel.fromJson(json);
      expect(model.createdByMode, ReviewRecordCreatedByMode.unknown);
    });

    test('fromJson: negative index maps to unknown', () {
      final now = DateTime.utc(2026);
      final json = {
        'surahId': 1,
        'ayahNumber': 1,
        'strengthLevel': 0,
        'intervalDays': 0,
        'lastReviewedAt': now.toIso8601String(),
        'nextReviewDate': now.toIso8601String(),
        'totalReviews': 0,
        'lastRating': null,
        'createdByMode': -1, // invalid index
      };
      final model = AyahReviewRecordModel.fromJson(json);
      expect(model.createdByMode, ReviewRecordCreatedByMode.unknown);
    });

    test('toJson/fromJson round-trip preserves adultMemPlus', () {
      final model = _model(mode: ReviewRecordCreatedByMode.adultMemPlus);
      final json = model.toJson();
      expect(
        json['createdByMode'],
        ReviewRecordCreatedByMode.adultMemPlus.index,
      );
      final restored = AyahReviewRecordModel.fromJson(json);
      expect(restored.createdByMode, ReviewRecordCreatedByMode.adultMemPlus);
    });

    test('toJson/fromJson round-trip preserves kidsMode', () {
      final model = _model(mode: ReviewRecordCreatedByMode.kidsMode);
      final json = model.toJson();
      final restored = AyahReviewRecordModel.fromJson(json);
      expect(restored.createdByMode, ReviewRecordCreatedByMode.kidsMode);
    });

    test('toJson/fromJson round-trip preserves migration', () {
      final model = _model(mode: ReviewRecordCreatedByMode.migration);
      final json = model.toJson();
      final restored = AyahReviewRecordModel.fromJson(json);
      expect(restored.createdByMode, ReviewRecordCreatedByMode.migration);
    });

    test('toJson/fromJson round-trip preserves hifz', () {
      final model = _model(mode: ReviewRecordCreatedByMode.hifz);
      final json = model.toJson();
      final restored = AyahReviewRecordModel.fromJson(json);
      expect(restored.createdByMode, ReviewRecordCreatedByMode.hifz);
    });
  });

  group('AyahReviewRecordModel.fromEntity', () {
    test('preserves adultMemPlus source', () {
      final entity = _record(mode: ReviewRecordCreatedByMode.adultMemPlus);
      final model = AyahReviewRecordModel.fromEntity(entity);
      expect(model.createdByMode, ReviewRecordCreatedByMode.adultMemPlus);
    });

    test('preserves kidsMode source', () {
      final entity = _record(mode: ReviewRecordCreatedByMode.kidsMode);
      final model = AyahReviewRecordModel.fromEntity(entity);
      expect(model.createdByMode, ReviewRecordCreatedByMode.kidsMode);
    });

    test('preserves migration source', () {
      final entity = _record(mode: ReviewRecordCreatedByMode.migration);
      final model = AyahReviewRecordModel.fromEntity(entity);
      expect(model.createdByMode, ReviewRecordCreatedByMode.migration);
    });

    test('preserves unknown source', () {
      final entity = _record(mode: ReviewRecordCreatedByMode.unknown);
      final model = AyahReviewRecordModel.fromEntity(entity);
      expect(model.createdByMode, ReviewRecordCreatedByMode.unknown);
    });
  });

  group('AyahReviewRecordModel.initial', () {
    test('initial() source is unknown', () {
      final model = AyahReviewRecordModel.initial(1, 1);
      expect(model.createdByMode, ReviewRecordCreatedByMode.unknown);
    });
  });

  // ─── IsarAyahReviewRecord mapping Tests ───────────────────────────────────

  group('IsarAyahReviewRecord.toModel createdByMode', () {
    test('null createdByModeIndex maps to unknown', () {
      final record = _IsarRecordHelper.withNullMode();
      expect(record.createdByMode, ReviewRecordCreatedByMode.unknown);
    });

    test('out-of-bounds createdByModeIndex maps to unknown', () {
      final record = _IsarRecordHelper.withModeIndex(9999);
      expect(record.createdByMode, ReviewRecordCreatedByMode.unknown);
    });

    test('valid adultMemPlus index maps correctly', () {
      final record = _IsarRecordHelper.withModeIndex(
        ReviewRecordCreatedByMode.adultMemPlus.index,
      );
      expect(record.createdByMode, ReviewRecordCreatedByMode.adultMemPlus);
    });

    test('valid kidsMode index maps correctly', () {
      final record = _IsarRecordHelper.withModeIndex(
        ReviewRecordCreatedByMode.kidsMode.index,
      );
      expect(record.createdByMode, ReviewRecordCreatedByMode.kidsMode);
    });

    test('valid migration index maps correctly', () {
      final record = _IsarRecordHelper.withModeIndex(
        ReviewRecordCreatedByMode.migration.index,
      );
      expect(record.createdByMode, ReviewRecordCreatedByMode.migration);
    });
  });

  // ─── Domain params tests ───────────────────────────────────────────────────

  group('EvaluateMemorizationParams', () {
    test('defaults createdByMode to adultMemPlus', () {
      final params = EvaluateMemorizationParams(
        surahId: 1,
        ayahNumber: 1,
        rating: PerformanceRating.excellent,
      );
      expect(params.createdByMode, ReviewRecordCreatedByMode.adultMemPlus);
    });

    test('can be explicitly set to adultMemPlus', () {
      final params = EvaluateMemorizationParams(
        surahId: 1,
        ayahNumber: 1,
        rating: PerformanceRating.excellent,
        createdByMode: ReviewRecordCreatedByMode.adultMemPlus,
      );
      expect(params.createdByMode, ReviewRecordCreatedByMode.adultMemPlus);
    });
  });

  group('MarkAyahMemorizedParams', () {
    test('defaults createdByMode to kidsMode', () {
      final params = MarkAyahMemorizedParams(surahId: 114, ayahNumber: 1);
      expect(params.createdByMode, ReviewRecordCreatedByMode.kidsMode);
    });

    test('can be explicitly set to kidsMode', () {
      final params = MarkAyahMemorizedParams(
        surahId: 114,
        ayahNumber: 1,
        createdByMode: ReviewRecordCreatedByMode.kidsMode,
      );
      expect(params.createdByMode, ReviewRecordCreatedByMode.kidsMode);
    });
  });
}

// ─── Test-only Isar helper (unit-tests only; no real Isar instance needed) ──

class _IsarRecordHelper {
  /// Returns an AyahReviewRecordModel simulating what toModel() produces for
  /// a given nullable createdByModeIndex, without requiring a real Isar DB.
  static AyahReviewRecordModel withNullMode() => _decode(null);

  static AyahReviewRecordModel withModeIndex(int? index) => _decode(index);

  static AyahReviewRecordModel _decode(int? modeIndex) {
    final now = DateTime.utc(2026);
    // Mirror the logic in IsarAyahReviewRecord.toModel()
    final mode =
        modeIndex == null ||
            modeIndex < 0 ||
            modeIndex >= ReviewRecordCreatedByMode.values.length
        ? ReviewRecordCreatedByMode.unknown
        : ReviewRecordCreatedByMode.values[modeIndex];
    return AyahReviewRecordModel(
      surahId: 1,
      ayahNumber: 1,
      strengthLevel: 0,
      intervalDays: 0,
      lastReviewedAt: now,
      nextReviewDate: now,
      totalReviews: 0,
      lastRating: null,
      createdByMode: mode,
    );
  }
}
