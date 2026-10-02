import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_child_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/parent_dashboard.dart';

void main() {
  group('ParentSettingsModel policy fields', () {
    test('old JSON without the new keys loads defaults', () {
      final m = ParentSettingsModel.fromJson(const {
        'reminderEnabled': true,
        'sessionGoalMinutes': 10,
      });
      expect(m.kidsReduceMotion, isFalse);
      expect(m.maxDailySuggestions, 3);
      expect(m.homeMissionsEnabled, isTrue);
      expect(m.policyVersion, 0);
    });

    test('round-trips all four fields', () {
      const s = ParentSettingsModel(
        kidsReduceMotion: true,
        maxDailySuggestions: 2,
        homeMissionsEnabled: false,
        policyVersion: 7,
      );
      final back = ParentSettingsModel.fromJson(s.toJson());
      expect(back.kidsReduceMotion, isTrue);
      expect(back.maxDailySuggestions, 2);
      expect(back.homeMissionsEnabled, isFalse);
      expect(back.policyVersion, 7);
      final fromEntity = ParentSettingsModel.fromEntity(s);
      expect(fromEntity, s);
    });

    test('maxDailySuggestions is clamped to 1..3 on read', () {
      for (final (raw, expected) in [(0, 1), (5, 3), (-2, 1), (2, 2)]) {
        expect(
          ParentSettingsModel.fromJson({
            'maxDailySuggestions': raw,
          }).maxDailySuggestions,
          expected,
          reason: 'raw $raw',
        );
      }
    });

    test('negative policyVersion reads as 0', () {
      expect(
        ParentSettingsModel.fromJson({'policyVersion': -4}).policyVersion,
        0,
      );
    });
  });

  group('ParentSettings entity', () {
    test('props and copyWith include the new fields', () {
      const base = ParentSettings();
      expect(base.copyWith(kidsReduceMotion: true), isNot(base));
      expect(base.copyWith(maxDailySuggestions: 1), isNot(base));
      expect(base.copyWith(homeMissionsEnabled: false), isNot(base));
      expect(base.copyWith(policyVersion: 1), isNot(base));
      expect(base.copyWith(policyVersion: 1).policyVersion, 1);
    });
  });

  group('KidsChildPolicy.fromSettings', () {
    test('maps all fields', () {
      final p = KidsChildPolicy.fromSettings(
        const ParentSettings(
          kidsReduceMotion: true,
          maxDailySuggestions: 2,
          homeMissionsEnabled: false,
          sessionGoalMinutes: 15,
          policyVersion: 4,
        ),
      );
      expect(
        p,
        const KidsChildPolicy(
          reduceMotion: true,
          maxDailySuggestions: 2,
          homeMissionsEnabled: false,
          sessionGoalMinutes: 15,
          version: 4,
        ),
      );
    });

    test('clamps maxDailySuggestions', () {
      expect(
        KidsChildPolicy.fromSettings(
          const ParentSettings(maxDailySuggestions: 9),
        ).maxDailySuggestions,
        3,
      );
      expect(
        KidsChildPolicy.fromSettings(
          const ParentSettings(maxDailySuggestions: 0),
        ).maxDailySuggestions,
        1,
      );
    });
  });
}
