import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';

/// Local safety acknowledgement, scoped to the account accepting it.
final class HandsFreeWarningStore {
  const HandsFreeWarningStore(this.prefs, this.owner, this.barrier);
  final SharedPreferences prefs;
  final RecordOwnerProvider owner;
  final AccountDataBarrier barrier;
  static const prefix = 'hands_free_warning_seen|';

  bool get hasAccepted {
    final id = owner.currentOwnerId;
    final lease = barrier.capture();
    lease.checkOwner(id);
    return prefs.getBool('$prefix$id') == true;
  }

  Future<void> accept() async {
    final id = owner.currentOwnerId;
    final lease = barrier.capture();
    await barrier.run((authority) async {
      authority.checkOwner(id);
      if (!await prefs.setBool('$prefix$id', true)) {
        throw StateError('Safety acknowledgement was not saved');
      }
      authority.checkOwner(id);
    }, authority: lease);
  }
}
