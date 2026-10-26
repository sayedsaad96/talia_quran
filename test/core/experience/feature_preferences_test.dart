import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/backup/backup_sections.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/experience/feature_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<FeaturePreferences> build({
    Map<String, Object> values = const {},
    String ownerId = 'user-a',
    Set<ExperienceFeature> unavailable = const {},
  }) async {
    SharedPreferences.setMockInitialValues(values);
    final flags = ExperienceFlags(
      (key) => !unavailable.contains(
        ExperienceFeature.values.firstWhere((f) => f.storageKey == key),
      ),
    );
    return FeaturePreferences(
      await SharedPreferences.getInstance(),
      FixedRecordOwnerProvider(ownerId),
      flags,
    );
  }

  test('features are on by default and visible when available', () async {
    final p = await build();
    expect(p.isEnabled(ExperienceFeature.readerRepeat), isTrue);
    expect(p.isVisible(ExperienceFeature.readerRepeat), isTrue);
  });

  test('turning a feature off hides it without touching others', () async {
    final p = await build();
    await p.setEnabled(ExperienceFeature.readerRepeat, false);
    expect(p.isEnabled(ExperienceFeature.readerRepeat), isFalse);
    expect(p.isVisible(ExperienceFeature.readerRepeat), isFalse);
    expect(p.isEnabled(ExperienceFeature.ayahNotes), isTrue);
  });

  test(
    'an unavailable feature is never visible, even when preferred on',
    () async {
      final p = await build(unavailable: {ExperienceFeature.readerRepeat});
      expect(p.isAvailable(ExperienceFeature.readerRepeat), isFalse);
      expect(p.isVisible(ExperienceFeature.readerRepeat), isFalse);
      expect(p.isAvailable(ExperienceFeature.ayahNotes), isTrue);
      expect(p.isVisible(ExperienceFeature.ayahNotes), isTrue);
    },
  );

  test('preferences are isolated per owner', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferences.getInstance();
    final flags = ExperienceFlags((_) => true);
    final a = FeaturePreferences(
      store,
      const FixedRecordOwnerProvider('user-a'),
      flags,
    );
    final b = FeaturePreferences(
      store,
      const FixedRecordOwnerProvider('user-b'),
      flags,
    );
    await a.setEnabled(ExperienceFeature.readerRepeat, false);
    expect(a.isEnabled(ExperienceFeature.readerRepeat), isFalse);
    expect(b.isEnabled(ExperienceFeature.readerRepeat), isTrue);
  });

  test('a wrong-typed stored choice counts as on', () async {
    final p = await build(values: {'feature_pref_readerRepeat|user-a': 'oops'});
    expect(p.isEnabled(ExperienceFeature.readerRepeat), isTrue);
  });

  group('ExperienceFlags.withUserPreferences', () {
    Future<(SharedPreferences, ExperienceFlags Function(String owner))> flags(
      Map<String, Object> values,
    ) async {
      SharedPreferences.setMockInitialValues(values);
      final prefs = await SharedPreferences.getInstance();
      return (
        prefs,
        (owner) => ExperienceFlags.withUserPreferences(
          prefs,
          FixedRecordOwnerProvider(owner),
        ),
      );
    }

    test('the user turning a feature off hides it everywhere', () async {
      final (prefs, make) = await flags({
        ExperienceFeature.ayahNotes.storageKey: true,
      });
      final f = make('user-a');
      expect(f.isEnabled(ExperienceFeature.ayahNotes), isTrue);
      await prefs.setBool('feature_pref_ayahNotes|user-a', false);
      expect(f.isEnabled(ExperienceFeature.ayahNotes), isFalse);
      // The raw rollout flag (Labs) still reads on.
      expect(
        ExperienceFlags.fromPreferences(
          prefs,
        ).isEnabled(ExperienceFeature.ayahNotes),
        isTrue,
      );
    });

    test('owner A off does not affect owner B', () async {
      final (_, make) = await flags({
        ExperienceFeature.groupKhatmah.storageKey: true,
        'feature_pref_groupKhatmah|user-a': false,
      });
      expect(make('user-a').isEnabled(ExperienceFeature.groupKhatmah), isFalse);
      expect(make('user-b').isEnabled(ExperienceFeature.groupKhatmah), isTrue);
    });

    test(
      'the owner is read on each call, so an account switch applies',
      () async {
        SharedPreferences.setMockInitialValues({
          ExperienceFeature.homeWidget.storageKey: true,
          'feature_pref_homeWidget|user-a': false,
        });
        final prefs = await SharedPreferences.getInstance();
        final owner = _MutableOwner('user-a');
        final f = ExperienceFlags.withUserPreferences(prefs, owner);
        expect(f.isEnabled(ExperienceFeature.homeWidget), isFalse);
        owner.id = 'user-b';
        expect(f.isEnabled(ExperienceFeature.homeWidget), isTrue);
      },
    );

    test(
      'a rollout-off feature stays off even when the user wants it',
      () async {
        final (_, make) = await flags({
          ExperienceFeature.handsFreeReview.storageKey: false,
          'feature_pref_handsFreeReview|user-a': true,
        });
        expect(
          make('user-a').isEnabled(ExperienceFeature.handsFreeReview),
          isFalse,
        );
      },
    );

    test('a wrong-typed user choice counts as on', () async {
      final (_, make) = await flags({
        ExperienceFeature.ayahNotes.storageKey: true,
        'feature_pref_ayahNotes|user-a': 'oops',
      });
      expect(make('user-a').isEnabled(ExperienceFeature.ayahNotes), isTrue);
    });

    test(
      'FeaturePreferences over raw rollout flags reports availability',
      () async {
        final (prefs, _) = await flags({
          ExperienceFeature.ayahNotes.storageKey: true,
          'feature_pref_ayahNotes|user-a': false,
        });
        final p = FeaturePreferences(
          prefs,
          const FixedRecordOwnerProvider('user-a'),
          ExperienceFlags.fromPreferences(prefs),
        );
        expect(p.isAvailable(ExperienceFeature.ayahNotes), isTrue);
        expect(p.isVisible(ExperienceFeature.ayahNotes), isFalse);
      },
    );
  });

  test('keys enter the backup tokenized and validated as bools', () {
    expect(
      BackupPreferencePolicy.backupKeyFor(
        'feature_pref_readerRepeat|user-a',
        'user-a',
      ),
      'feature_pref_readerRepeat|$kBackupOwnerToken',
    );
    expect(
      BackupPreferencePolicy.backupKeyFor(
        'feature_pref_readerRepeat|user-b',
        'user-a',
      ),
      isNull,
    );
    expect(
      BackupPreferencePolicy.restoreKeyFor(
        'feature_pref_readerRepeat|$kBackupOwnerToken',
        'user-a',
      ),
      'feature_pref_readerRepeat|user-a',
    );
    expect(
      () => BackupPreferencePolicy.validate(
        'feature_pref_readerRepeat|$kBackupOwnerToken',
        'not-a-bool',
      ),
      throwsA(isA<BackupSectionInvalid>()),
    );
  });
}

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.id);
  String id;

  @override
  String get currentOwnerId => id;

  @override
  bool get isSignedIn => true;
}
