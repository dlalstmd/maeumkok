import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/emotions.dart';
import 'core/theme.dart';
import 'services/push_service.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
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
              ? _LoginGate(auth: auth)
              : HomeScreen(key: ValueKey(user.uid), auth: auth, user: user);
        },
      ),
    );
  }
}

/// 첫 실행이면 온보딩 4장 → 로그인
class _LoginGate extends StatefulWidget {
  const _LoginGate({required this.auth});
  final AuthService auth;
  @override
  State<_LoginGate> createState() => _LoginGateState();
}

class _LoginGateState extends State<_LoginGate> {
  bool? _seen;
  @override
  void initState() {
    super.initState();
    onboardingSeen().then(
      (v) {
        if (mounted) setState(() => _seen = v);
      },
      onError: (_) {
        if (mounted) setState(() => _seen = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_seen == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_seen!) {
      return OnboardingScreen(onDone: () => setState(() => _seen = true));
    }
    return LoginScreen(auth: widget.auth);
  }
}
