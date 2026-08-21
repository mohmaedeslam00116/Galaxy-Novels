import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  const AppVersionInfo({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  String get displayLabel {
    final resolvedVersion = version.trim();
    final resolvedBuild = buildNumber.trim();
    return resolvedBuild.isEmpty
        ? resolvedVersion
        : '$resolvedVersion ($resolvedBuild)';
  }
}

typedef AppVersionLoader = Future<AppVersionInfo> Function();

Future<AppVersionInfo> loadPackageVersionInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return AppVersionInfo(
    version: packageInfo.version,
    buildNumber: packageInfo.buildNumber,
  );
}
