import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Feature flag keys — add new ones here as you ship new features.
/// Set values in Firebase Console → Remote Config without redeploying.
class FeatureFlags {
  // Core
  static const String galleryEnabled      = 'gallery_enabled';
  static const String marketplaceEnabled  = 'marketplace_enabled';
  static const String alertsEnabled       = 'alerts_enabled';
  static const String logbookEnabled      = 'logbook_enabled';

  // Upcoming features — default false until ready
  static const String multiVehicleEnabled = 'multi_vehicle_enabled';
  static const String pdfExportEnabled    = 'pdf_export_enabled';
  static const String aiAssistantEnabled  = 'ai_assistant_enabled';
  static const String mechanicFinderEnabled = 'mechanic_finder_enabled';
  static const String rewardsEnabled      = 'rewards_enabled';

  // Force update
  static const String minAppVersion       = 'min_app_version';
  static const String updateMessage       = 'update_message';

  // Maintenance mode (takes app offline gracefully)
  static const String maintenanceMode     = 'maintenance_mode';
  static const String maintenanceMessage  = 'maintenance_message';
}

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _config;
  bool _initialized = false;

  /// Call once in main() after Firebase.initializeApp().
  Future<void> initialize() async {
    try {
      _config = FirebaseRemoteConfig.instance;

      await _config!.setConfigSettings(RemoteConfigSettings(
        // Fetch interval — 1 hour in production, 0 in debug
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ));

      // ── Default values ───────────────────────────────────────────────────
      // These are used if the fetch fails or the user is offline.
      // Mirrors what you set in Firebase Console.
      await _config!.setDefaults({
        FeatureFlags.galleryEnabled:       true,
        FeatureFlags.marketplaceEnabled:   true,
        FeatureFlags.alertsEnabled:        true,
        FeatureFlags.logbookEnabled:       true,
        FeatureFlags.multiVehicleEnabled:  false,
        FeatureFlags.pdfExportEnabled:     false,
        FeatureFlags.aiAssistantEnabled:   false,
        FeatureFlags.mechanicFinderEnabled:false,
        FeatureFlags.rewardsEnabled:       false,
        FeatureFlags.minAppVersion:        '1.0.0',
        FeatureFlags.updateMessage:
            'A new version of Moto Vitals is available. Please update to continue.',
        FeatureFlags.maintenanceMode:      false,
        FeatureFlags.maintenanceMessage:
            'Moto Vitals is under maintenance. We\'ll be back shortly!',
      });

      // Fetch and activate latest values
      await _config!.fetchAndActivate();
      _initialized = true;
      debugPrint('[RemoteConfig] Initialized and activated.');
    } catch (e) {
      // Non-fatal: app runs with defaults if Remote Config fails
      debugPrint('[RemoteConfig] Init failed, using defaults: $e');
      _initialized = true;
    }
  }

  // ── Feature flag accessors ───────────────────────────────────────────────

  bool get galleryEnabled      => _getBool(FeatureFlags.galleryEnabled);
  bool get marketplaceEnabled  => _getBool(FeatureFlags.marketplaceEnabled);
  bool get alertsEnabled       => _getBool(FeatureFlags.alertsEnabled);
  bool get logbookEnabled      => _getBool(FeatureFlags.logbookEnabled);
  bool get multiVehicleEnabled => _getBool(FeatureFlags.multiVehicleEnabled);
  bool get pdfExportEnabled    => _getBool(FeatureFlags.pdfExportEnabled);
  bool get aiAssistantEnabled  => _getBool(FeatureFlags.aiAssistantEnabled);
  bool get mechanicFinderEnabled => _getBool(FeatureFlags.mechanicFinderEnabled);
  bool get rewardsEnabled      => _getBool(FeatureFlags.rewardsEnabled);
  bool get maintenanceMode     => _getBool(FeatureFlags.maintenanceMode);
  String get maintenanceMessage => _getString(FeatureFlags.maintenanceMessage);
  String get minAppVersion     => _getString(FeatureFlags.minAppVersion);
  String get updateMessage     => _getString(FeatureFlags.updateMessage);

  bool _getBool(String key) {
    if (!_initialized || _config == null) return true;
    return _config!.getBool(key);
  }

  String _getString(String key) {
    if (!_initialized || _config == null) return '';
    return _config!.getString(key);
  }
}
