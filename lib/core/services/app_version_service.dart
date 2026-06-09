import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  const AppVersionInfo({required this.version, required this.buildNumber});

  const AppVersionInfo.unavailable() : version = '—', buildNumber = '—';

  final String version;
  final String buildNumber;
}

abstract class AppVersionInfoProvider {
  Future<AppVersionInfo> getVersionInfo();
}

class PackageInfoAppVersionInfoProvider implements AppVersionInfoProvider {
  const PackageInfoAppVersionInfoProvider();

  @override
  Future<AppVersionInfo> getVersionInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppVersionInfo(
        version: info.version.trim().isEmpty ? '—' : info.version,
        buildNumber: info.buildNumber.trim().isEmpty ? '—' : info.buildNumber,
      );
    } catch (_) {
      return const AppVersionInfo.unavailable();
    }
  }
}
