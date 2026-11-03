import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/backup/cold_restore_startup.dart';
import 'package:talia_quran/core/storage/data_admission.dart';

void main() {
  test(
    'pending recovery enters exclusive graph without foreground activation',
    () async {
      final native = _Admission();
      final result = await ColdRestoreStartup(
        admission: DataAdmission(platform: native),
        needsMaintenance: () async => true,
      ).enter();
      expect(result, isA<MaintenanceRestoreAdmission>());
      expect(native.events, [
        'acquire:probe',
        'release:probe',
        'acquire:maintenance',
      ]);
    },
  );

  test('clean startup promotes while the shared probe is still held', () async {
    final native = _Admission();
    final result = await ColdRestoreStartup(
      admission: DataAdmission(platform: native),
      needsMaintenance: () async => false,
    ).enter();
    expect(result, isA<NormalRestoreAdmission>());
    expect(native.events, [
      'acquire:probe',
      'acquire:foreground',
      'release:probe',
    ]);
  });

  test(
    'worker contention blocks recovery without constructing foreground',
    () async {
      final native = _Admission(deny: DataAdmissionMode.maintenance);
      final result = await ColdRestoreStartup(
        admission: DataAdmission(platform: native),
        needsMaintenance: () async => true,
      ).enter();
      expect(result, isA<BlockedRestoreAdmission>());
      expect(native.events, isNot(contains('acquire:foreground')));
    },
  );

  test('unreadable private markers fail closed and release probe', () async {
    final native = _Admission();
    final result = await ColdRestoreStartup(
      admission: DataAdmission(platform: native),
      needsMaintenance: () async => throw StateError('keystore'),
    ).enter();
    expect(result, isA<BlockedRestoreAdmission>());
    expect(native.events, ['acquire:probe', 'release:probe']);
  });
}

class _Admission implements DataAdmissionPlatform {
  _Admission({this.deny});
  final DataAdmissionMode? deny;
  final events = <String>[];
  final holders = <String>{};
  @override
  Future<String?> acquire(DataAdmissionMode mode) async {
    events.add('acquire:${mode.name}');
    if (mode == deny) return null;
    holders.add(mode.name);
    return mode.name;
  }

  @override
  Future<bool> validate(String token) async => holders.contains(token);
  @override
  Future<bool> release(String token) async {
    events.add('release:$token');
    return holders.remove(token);
  }
}
