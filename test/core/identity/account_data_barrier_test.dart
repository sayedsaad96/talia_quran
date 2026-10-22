import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a same-owner lease from a different barrier cannot authorize work',
    () async {
      SharedPreferences.setMockInitialValues({});
      final firstPrefs = await SharedPreferences.getInstance();
      final first = AccountDataBarrier.forPreferences(firstPrefs)
        ..owner = const FixedRecordOwnerProvider('owner-a');
      final foreignLease = first.capture();
      SharedPreferences.setMockInitialValues({});
      final secondPrefs = await SharedPreferences.getInstance();
      expect(identical(firstPrefs, secondPrefs), isFalse);
      final second = AccountDataBarrier.forPreferences(secondPrefs)
        ..owner = const FixedRecordOwnerProvider('owner-a');
      var executed = false;
      expect(
        () => second.run((_) async {
          executed = true;
        }, authority: foreignLease),
        throwsA(isA<AccountDataUnavailableException>()),
      );
      expect(executed, isFalse);
      final local = second.capture();
      await second.run((lease) async {
        lease.checkOwner('owner-a');
        executed = true;
      }, authority: local);
      expect(executed, isTrue);
    },
  );
}
