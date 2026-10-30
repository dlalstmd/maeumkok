import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/couple_service.dart';
import '../services/emotion_service.dart';
import '../services/notify_service.dart';
import 'connect_screen.dart';
import 'couple_home_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key, required this.auth, required this.user});
  final AuthService auth;
  final User user;
  final _couples = CoupleService();
  final _emotions = EmotionService();
  final _notify = NotifyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마음콕'),
        actions: [
          IconButton(
            onPressed: auth.signOut,
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _couples.watchUser(user.uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final coupleId = snap.data!.data()?['coupleId'] as String?;
          if (coupleId == null) {
            return ConnectScreen(uid: user.uid, couples: _couples);
          }
          return CoupleHomeScreen(
            uid: user.uid,
            coupleId: coupleId,
            emotions: _emotions,
            notify: _notify,
          );
        },
      ),
    );
  }
}
