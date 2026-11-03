import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/storage/app_isar.dart';
import 'package:talia_quran/core/storage/data_admission.dart';

class _Native implements DataAdmissionPlatform {
  bool valid = true;
  @override
  Future<String?> acquire(DataAdmissionMode mode) async => mode.name;
  @override
  Future<bool> validate(String token) async => valid;
  @override
  Future<bool> release(String token) async {
    valid = false;
    return true;
  }
}

void main() {
  test('a probe cannot open progress storage', () async {
    final probe = (await DataAdmission(platform: _Native()).acquireProbe())!;
    await expectLater(
      openAppIsar(directory: 'must-not-open', admission: probe),
      throwsStateError,
    );
  });
  test('a revoked worker cannot reuse or open progress storage', () async {
    final worker = (await DataAdmission(platform: _Native()).acquireWorker())!;
    await worker.release();
    await expectLater(
      openAppIsar(directory: 'must-not-open', admission: worker),
      throwsStateError,
    );
  });
}
