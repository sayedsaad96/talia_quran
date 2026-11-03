import 'package:shared_preferences/shared_preferences.dart';

import '../security/encrypted_account_preferences_store.dart';
import '../storage/data_admission.dart';
import 'cold_restore_startup.dart';
import 'restore_maintenance_session.dart';
import 'restore_recovery_journal.dart';
import 'restore_request_store.dart';

class RestoreHandoffRetry implements Exception {
  const RestoreHandoffRetry();
}

Future<ColdRestoreAdmission> acquireStartupAdmission() => ColdRestoreStartup(
  admission: DataAdmission.instance,
  needsMaintenance: () async {
    final journal = RestoreRecoveryJournal(
      FlutterEncryptedAccountPreferencesStore(),
    );
    if (!await journal.isCleanForAdmission()) return true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.containsKey(RestoreRequestStore.key);
  },
).enter();

Future<DataAdmissionPermit> finishRestoreMaintenance(
  RestoreMaintenanceSession session,
) async {
  await session.closeForNormalStartup();
  await session.permit.release();
  final foreground = await DataAdmission.instance.acquireForeground();
  if (foreground == null) throw const RestoreHandoffRetry();
  return foreground;
}
