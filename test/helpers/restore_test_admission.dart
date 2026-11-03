import 'package:talia_quran/core/storage/data_admission.dart';

late DataAdmissionPermit testRestorePermit;

Future<void> initializeRestoreAdmissionForTests() async {
  testRestorePermit = (await DataAdmission(
    platform: _TestAdmission(),
  ).acquireMaintenance())!;
}

/// The native boundary has a separate real JVM/process contention harness.
class _TestAdmission implements DataAdmissionPlatform {
  @override
  Future<String?> acquire(DataAdmissionMode mode) async => 'host-restore-test';
  @override
  Future<bool> validate(String token) async => token == 'host-restore-test';
  @override
  Future<bool> release(String token) async => true;
}
