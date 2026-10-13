import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/kids_support_profile_store.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_learning_support_profile.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';

void main() {
  group('resolveKidsSupportPolicy', () {
    test('no profile ever raises or lowers an age limit', () {
      for (var age = 5; age <= 12; age++) {
        final agePolicy = KidsSessionPolicy.forAge(age);
        for (final reading in KidsReadingAbility.values) {
          final policy = resolveKidsSupportPolicy(
            agePolicy: agePolicy,
            profile: KidsLearningSupportProfile(reading: reading),
          );
          expect(policy.sessionPolicy, agePolicy, reason: '$age $reading');
        }
      }
    });

    test('only reading with help or not yet suggests help early', () {
      bool proactive(KidsReadingAbility r) => resolveKidsSupportPolicy(
        agePolicy: KidsSessionPolicy.forAge(6),
        profile: KidsLearningSupportProfile(reading: r),
      ).proactiveHints;

      expect(proactive(KidsReadingAbility.unknown), isFalse);
      expect(proactive(KidsReadingAbility.independent), isFalse);
      expect(proactive(KidsReadingAbility.withHelp), isTrue);
      expect(proactive(KidsReadingAbility.notYetReading), isTrue);
    });
  });

  group('KidsLearningSupportProfile json', () {
    test('round-trips with a version', () {
      const profile = KidsLearningSupportProfile(
        reading: KidsReadingAbility.notYetReading,
      );

      expect(profile.toJson()['v'], KidsLearningSupportProfile.currentVersion);
      expect(KidsLearningSupportProfile.fromJson(profile.toJson()), profile);
    });

    test('unknown, missing or malformed values read as unknown', () {
      expect(
        KidsLearningSupportProfile.fromJson({'v': 9, 'reading': 'future'}),
        KidsLearningSupportProfile.unknown,
      );
      expect(
        KidsLearningSupportProfile.fromJson(const {}),
        KidsLearningSupportProfile.unknown,
      );
      expect(
        KidsLearningSupportProfile.fromJson('oops'),
        KidsLearningSupportProfile.unknown,
      );
    });
  });

  group('KidsSupportProfileStore', () {
    Future<KidsSupportProfileStore> storeFor(String owner) async =>
        KidsSupportProfileStore(
          await SharedPreferences.getInstance(),
          FixedRecordOwnerProvider(owner),
        );

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('reads unknown until the guardian answers', () async {
      expect((await storeFor('a')).read(), KidsLearningSupportProfile.unknown);
    });

    test('saves and reads back for the same owner only', () async {
      final a = await storeFor('a');
      expect(
        await a.save(
          const KidsLearningSupportProfile(
            reading: KidsReadingAbility.withHelp,
          ),
        ),
        isTrue,
      );

      expect(a.read().reading, KidsReadingAbility.withHelp);
      expect((await storeFor('b')).read(), KidsLearningSupportProfile.unknown);
    });

    test('a save racing an account reset writes nothing', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = await storeFor('a');
      final barrier = AccountDataBarrier.forPreferences(prefs)..invalidate();
      // Leave the shared barrier usable for the next test.
      addTearDown(() => barrier.clear(() async {}));

      final saved = await store.save(
        const KidsLearningSupportProfile(reading: KidsReadingAbility.withHelp),
      );

      expect(saved, isFalse);
      expect(prefs.getString('${KidsSupportProfileStore.keyPrefix}a'), isNull);
    });

    test('a corrupt record reads as unknown', () async {
      SharedPreferences.setMockInitialValues({
        '${KidsSupportProfileStore.keyPrefix}a': '{not json',
      });

      expect((await storeFor('a')).read(), KidsLearningSupportProfile.unknown);
    });

    test('its key is cleared with the account data', () {
      expect(
        AccountDataReset.clearedPreferencePrefixes,
        contains(KidsSupportProfileStore.keyPrefix),
      );
    });
  });
}
