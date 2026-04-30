import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'providers/vehicle_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/main_layout.dart'; // used by auth_wrapper

/// True only when Firebase.initializeApp() succeeded without error.
bool firebaseConfigured = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseConfigured = true;
  } catch (e) {
    // Firebase not available on this platform; running in offline/mock mode.
    debugPrint('Firebase initialization skipped or failed: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
      ],
      child: const MotoVitalsApp(),
    ),
  );
}

class MotoVitalsApp extends StatelessWidget {
  const MotoVitalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moto Vitals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12121A),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: AuthWrapper(firebaseConfigured: firebaseConfigured),
    );
  }
}
