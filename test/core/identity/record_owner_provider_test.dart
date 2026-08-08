import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';

void main() {
  group('RecordOwnerProvider', () {
    test('SupabaseRecordOwnerProvider falls back to local when uninitialized',
        () {
      // Supabase is not initialized in a plain unit test, so the provider must
      // degrade to the reserved local owner instead of throwing.
      const provider = SupabaseRecordOwnerProvider();
      expect(provider.currentOwnerId, ReviewRecordIdentity.localOwnerId);
      expect(provider.isSignedIn, isFalse);
    });

    test('FixedRecordOwnerProvider reports a real owner as signed in', () {
      const provider = FixedRecordOwnerProvider('user-a');
      expect(provider.currentOwnerId, 'user-a');
      expect(provider.isSignedIn, isTrue);
    });

    test('FixedRecordOwnerProvider with the local owner is not signed in', () {
      const provider =
          FixedRecordOwnerProvider(ReviewRecordIdentity.localOwnerId);
      expect(provider.isSignedIn, isFalse);
    });
  });
}
