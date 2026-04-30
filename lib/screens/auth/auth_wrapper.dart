import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_layout.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  final bool firebaseConfigured;

  const AuthWrapper({super.key, required this.firebaseConfigured});

  @override
  Widget build(BuildContext context) {
    // When Firebase is not configured (e.g. web without flutterfire configure),
    // show the app in "preview mode" — bypasses auth and shows dashboard directly.
    if (!firebaseConfigured) {
      return MainLayout(firebaseConfigured: firebaseConfigured);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF12121A),
            body: Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
          );
        }
        if (snapshot.hasData) {
          return MainLayout(firebaseConfigured: firebaseConfigured);
        }
        return const LoginScreen();
      },
    );
  }
}
