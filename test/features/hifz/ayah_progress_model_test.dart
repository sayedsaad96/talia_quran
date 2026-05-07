import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/hifz/data/models/ayah_progress_model.dart';
import 'package:talia_quran/features/hifz/domain/entities/hifz_entities.dart';

void main() {
  group('AyahProgressModel', () {
    group('initial factory', () {
      test('creates with notStarted status', () {
        final model = AyahProgressModel.initial(1, 1);
        expect(model.status, equals(AyahStatus.notStarted));
      });

      test('creates with zero repetitions', () {
        final model = AyahProgressModel.initial(2, 5);
        expect(model.repetitions, equals(0));
      });

      test('sets correct surahId and ayahNumber', () {
        final model = AyahProgressModel.initial(36, 12);
        expect(model.surahId, equals(36));
        expect(model.ayahNumber, equals(12));
      });
    });

    group('advanceWithSpacedRepetition', () {
      test('increments repetitions by 1', () {
        final model = AyahProgressModel.initial(1, 1);
        final advanced = model.advanceWithSpacedRepetition();
        expect(advanced.repetitions, equals(1));
      });

      test(
        'uses configured spaced repetition intervals without skipping first interval',
        () {
          var current = AyahProgressModel.initial(1, 1);

          current = current.advanceWithSpacedRepetition();
          final firstDelayMinutes = current.nextReviewDate
              .difference(DateTime.now())
              .inMinutes;
          expect(
            (firstDelayMinutes - const Duration(days: 1).inMinutes).abs(),
            lessThan(2),
          );

          current = current.advanceWithSpacedRepetition();
          final secondDelayMinutes = current.nextReviewDate
              .difference(DateTime.now())
              .inMinutes;
          expect(
            (secondDelayMinutes - const Duration(days: 3).inMinutes).abs(),
            lessThan(2),
          );
        },
      );

      test('sets status to review before 5 repetitions', () {
        final model = AyahProgressModel.initial(1, 1);
        var current = model;
        for (int i = 0; i < 4; i++) {
          current = current.advanceWithSpacedRepetition();
          expect(current.status, equals(AyahStatus.review));
        }
      });

      test('sets status to memorized at 5+ repetitions', () {
        final model = AyahProgressModel.initial(1, 1);
        var current = model;
        for (int i = 0; i < 5; i++) {
          current = current.advanceWithSpacedRepetition();
        }
        expect(current.status, equals(AyahStatus.memorized));
      });

      test('increases next review date with each advancement', () {
        final model = AyahProgressModel.initial(1, 1);
        final first = model.advanceWithSpacedRepetition();
        final second = first.advanceWithSpacedRepetition();
        // Second advancement should schedule further out than first
        expect(second.nextReviewDate.isAfter(first.nextReviewDate), isTrue);
      });

      test('preserves surahId and ayahNumber', () {
        final model = AyahProgressModel.initial(55, 13);
        final advanced = model.advanceWithSpacedRepetition();
        expect(advanced.surahId, equals(55));
        expect(advanced.ayahNumber, equals(13));
      });
    });

    group('softPenalty', () {
      test('decreases repetitions by 1', () {
        final model = AyahProgressModel.initial(
          1,
          1,
        ).advanceWithSpacedRepetition().advanceWithSpacedRepetition();
        expect(model.repetitions, equals(2));
        final penalized = model.softPenalty();
        expect(penalized.repetitions, equals(1));
      });

      test('does not go below zero repetitions', () {
        final model = AyahProgressModel.initial(1, 1);
        expect(model.repetitions, equals(0));
        final penalized = model.softPenalty();
        expect(penalized.repetitions, equals(0));
      });

      test('sets status to learning when repetitions reach 0', () {
        final model = AyahProgressModel.initial(
          1,
          1,
        ).advanceWithSpacedRepetition(); // rep = 1
        final penalized = model.softPenalty(); // rep = 0
        expect(penalized.status, equals(AyahStatus.learning));
      });

      test('keeps status as review when repetitions > 0', () {
        final model = AyahProgressModel.initial(1, 1)
            .advanceWithSpacedRepetition()
            .advanceWithSpacedRepetition(); // rep = 2
        final penalized = model.softPenalty(); // rep = 1
        expect(penalized.status, equals(AyahStatus.review));
      });

      test('reschedules review to tomorrow', () {
        final model = AyahProgressModel.initial(
          1,
          1,
        ).advanceWithSpacedRepetition();
        final penalized = model.softPenalty();
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        // Allow 1 second tolerance for test execution time
        expect(
          penalized.nextReviewDate.difference(tomorrow).inSeconds.abs(),
          lessThan(2),
        );
      });

      test('preserves surahId and ayahNumber', () {
        final model = AyahProgressModel.initial(
          36,
          7,
        ).advanceWithSpacedRepetition();
        final penalized = model.softPenalty();
        expect(penalized.surahId, equals(36));
        expect(penalized.ayahNumber, equals(7));
      });
    });

    group('JSON serialization', () {
      test('roundtrips correctly through toJson/fromJson', () {
        final original = AyahProgressModel.initial(
          2,
          255,
        ).advanceWithSpacedRepetition();
        final json = original.toJson();
        final restored = AyahProgressModel.fromJson(json);

        expect(restored.surahId, equals(original.surahId));
        expect(restored.ayahNumber, equals(original.ayahNumber));
        expect(restored.status, equals(original.status));
        expect(restored.repetitions, equals(original.repetitions));
      });
    });
  });
}
