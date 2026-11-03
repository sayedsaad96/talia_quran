import '../storage/data_admission.dart';

sealed class ColdRestoreAdmission {
  const ColdRestoreAdmission();
}

final class NormalRestoreAdmission extends ColdRestoreAdmission {
  const NormalRestoreAdmission(this.permit);
  final DataAdmissionPermit permit;
}

final class MaintenanceRestoreAdmission extends ColdRestoreAdmission {
  const MaintenanceRestoreAdmission(this.permit);
  final DataAdmissionPermit permit;
}

final class BlockedRestoreAdmission extends ColdRestoreAdmission {
  const BlockedRestoreAdmission();
}

/// Decides the startup graph before any progress service can be constructed.
class ColdRestoreStartup {
  const ColdRestoreStartup({
    required this.admission,
    required this.needsMaintenance,
  });
  final DataAdmission admission;
  final Future<bool> Function() needsMaintenance;

  Future<ColdRestoreAdmission> enter() async {
    final probe = await admission.acquireProbe();
    if (probe == null) return const BlockedRestoreAdmission();
    bool maintenance;
    try {
      maintenance = await needsMaintenance();
      if (!await probe.validate()) return const BlockedRestoreAdmission();
      if (!maintenance) {
        final foreground = await admission.acquireForeground();
        return foreground == null
            ? const BlockedRestoreAdmission()
            : NormalRestoreAdmission(foreground);
      }
    } catch (_) {
      return const BlockedRestoreAdmission();
    } finally {
      await probe.release();
    }
    final exclusive = await admission.acquireMaintenance();
    return exclusive == null
        ? const BlockedRestoreAdmission()
        : MaintenanceRestoreAdmission(exclusive);
  }
}
