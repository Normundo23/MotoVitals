import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'providers/vehicle_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/onboarding_screen.dart';
import 'services/remote_config_service.dart';
import 'services/app_version_service.dart';

bool firebaseConfigured = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('.env file not found or failed to load: $e');
  }

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    firebaseConfigured = true;
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  // Initialize Remote Config and version service (non-fatal if offline)
  if (firebaseConfigured) {
    try {
      await RemoteConfigService().initialize();
    } catch (e) {
      debugPrint('RemoteConfig init failed: $e');
    }
    try {
      await AppVersionService().initialize();
    } catch (e) {
      debugPrint('AppVersionService init failed: $e');
    }
  }

  bool hasSeenOnboarding = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  } catch (e) {
    debugPrint('Prefs init failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
      ],
      child: MotoVitalsApp(
        firebaseConfigured: firebaseConfigured,
        hasSeenOnboarding: hasSeenOnboarding,
      ),
    ),
  );
}

class MotoVitalsApp extends StatelessWidget {
  final bool firebaseConfigured;
  final bool hasSeenOnboarding;
  const MotoVitalsApp({
    super.key,
    required this.firebaseConfigured,
    required this.hasSeenOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moto Vitals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12121A),
        textTheme: GoogleFonts.outfitTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: OnboardingGate(
        firebaseConfigured: firebaseConfigured,
        initialHasSeenOnboarding: hasSeenOnboarding,
      ),
    );
  }
}

class OnboardingGate extends StatefulWidget {
  final bool firebaseConfigured;
  final bool initialHasSeenOnboarding;

  const OnboardingGate({
    super.key,
    required this.firebaseConfigured,
    required this.initialHasSeenOnboarding,
  });

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late bool _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _hasSeenOnboarding = widget.initialHasSeenOnboarding;
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    setState(() {
      _hasSeenOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSeenOnboarding) {
      return OnboardingScreen(onCompleted: _completeOnboarding);
    }
    return _AppGate(firebaseConfigured: widget.firebaseConfigured);
  }
}

/// Gates the app behind maintenance mode and force-update checks
/// before handing off to AuthWrapper.
class _AppGate extends StatelessWidget {
  final bool firebaseConfigured;
  const _AppGate({required this.firebaseConfigured});

  @override
  Widget build(BuildContext context) {
    if (!firebaseConfigured) {
      return AuthWrapper(firebaseConfigured: false);
    }

    final rc = RemoteConfigService();
    final vs = AppVersionService();

    // ── Maintenance mode ───────────────────────────────────────────────────
    if (rc.maintenanceMode) {
      return _FullscreenMessage(
        icon: Icons.build_rounded,
        iconColor: Colors.orangeAccent,
        title: 'Under Maintenance',
        body: rc.maintenanceMessage,
      );
    }

    // ── Force update ───────────────────────────────────────────────────────
    if (vs.updateRequired) {
      return _FullscreenMessage(
        icon: Icons.system_update_rounded,
        iconColor: Colors.deepPurpleAccent,
        title: 'Update Required',
        body: vs.updateMessage,
        actionLabel: 'Update Now',
        onAction: () async {
          const url =
              'https://play.google.com/store/apps/details?id=com.motovitals.app';
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      );
    }

    return AuthWrapper(firebaseConfigured: firebaseConfigured);
  }
}

/// Reusable fullscreen message for maintenance / force update.
class _FullscreenMessage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _FullscreenMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(36.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(icon, size: 56, color: iconColor),
                ),
                const SizedBox(height: 28),
                Text(title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                Text(body,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white60,
                        height: 1.6)),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(actionLabel!,
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
