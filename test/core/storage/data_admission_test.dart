import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/storage/data_admission.dart';

class FakePlatform implements DataAdmissionPlatform {
  final active = <String, DataAdmissionMode>{};
  int next = 0;
  bool fail = false;
  bool served = false;
  @override
  Future<String?> acquire(DataAdmissionMode mode) async {
    if (fail ||
        (mode == DataAdmissionMode.maintenance &&
            (served || active.isNotEmpty)) ||
        (mode != DataAdmissionMode.maintenance &&
            active.containsValue(DataAdmissionMode.maintenance))) {
      return null;
    }
    final token = '${next++}';
    active[token] = mode;
    if (mode == DataAdmissionMode.foreground) served = true;
    return token;
  }

  @override
  Future<bool> validate(String token) async =>
      !fail && active.containsKey(token);
  @override
  Future<bool> release(String token) async => active.remove(token) != null;
}

void main() {
  test(
    'failed validation releases acquired probe so a retry can maintain',
    () async {
      final platform = _FailFirstValidation();
      final admission = DataAdmission(platform: platform);
      expect(await admission.acquireProbe(), isNull);
      expect(await admission.acquireMaintenance(), isNotNull);
    },
  );
  test(
    'shared holders block maintenance; released permit becomes invalid',
    () async {
      final admission = DataAdmission(platform: FakePlatform());
      final a = (await admission.acquireProbe())!;
      final b = (await admission.acquireWorker())!;
      expect(await admission.acquireMaintenance(), isNull);
      await a.release();
      expect(await a.validate(), isFalse);
      expect(await admission.acquireMaintenance(), isNull);
      await b.release();
      final maintenance = (await admission.acquireMaintenance())!;
      expect(await admission.acquireProbe(), isNull);
      await maintenance.release();
    },
  );
  test(
    'foreground is process lifetime and unsupported or invalid transport fails closed',
    () async {
      final platform = FakePlatform();
      final admission = DataAdmission(platform: platform);
      final foreground = (await admission.acquireForeground())!;
      await expectLater(foreground.release(), throwsStateError);
      expect(await admission.acquireMaintenance(), isNull);
      platform.fail = true;
      expect(await foreground.validate(), isFalse);
      expect(await admission.acquireWorker(), isNull);
    },
  );
}

class _FailFirstValidation extends FakePlatform {
  bool first = true;
  @override
  Future<bool> validate(String token) async {
    if (first) {
      first = false;
      throw StateError('channel');
    }
    return super.validate(token);
  }
}
