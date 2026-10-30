import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/emotions.dart';
import 'core/theme.dart';
import 'services/push_service.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await loadEmotions();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(MaeumKokApp(auth: AuthService()));
}

class MaeumKokApp extends StatelessWidget {
  const MaeumKokApp({super.key, required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '마음콕',
      theme: buildTheme(),
      home: StreamBuilder<User?>(
        stream: auth.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snap.data;
          return user == null
              ? LoginScreen(auth: auth)
              : HomeScreen(key: ValueKey(user.uid), auth: auth, user: user);
        },
      ),
    );
  }
}
