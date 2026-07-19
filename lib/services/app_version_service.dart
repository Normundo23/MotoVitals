import 'package:package_info_plus/package_info_plus.dart';
import 'remote_config_service.dart';


class AppVersionService {
  /// Compares semantic versions like "1.2.3".
  /// Returns negative if a < b, 0 if equal, positive if a > b.
  static int compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.tryParse).toList();
    final bParts = b.split('.').map(int.tryParse).toList();
    for (int i = 0; i < 3; i++) {
      final av = (i < aParts.length ? aParts[i] : 0) ?? 0;
      final bv = (i < bParts.length ? bParts[i] : 0) ?? 0;
      if (av != bv) return av - bv;
    }
    return 0;
  }

  static final AppVersionService _instance = AppVersionService._internal();
  factory AppVersionService() => _instance;
  AppVersionService._internal();

  PackageInfo? _packageInfo;

  Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  String get currentVersion => _packageInfo?.version ?? '1.0.0';
  String get buildNumber => _packageInfo?.buildNumber ?? '1';

  /// Returns true if the installed version is below the Remote Config minimum.
  /// Use this to show a force-update dialog.
  bool get updateRequired {
    final minVersion = RemoteConfigService().minAppVersion;
    if (minVersion.isEmpty) return false;
    return compareVersions(currentVersion, minVersion) < 0;
  }

  String get updateMessage => RemoteConfigService().updateMessage;
}
