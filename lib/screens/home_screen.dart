import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/header_prefs.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/couple_service.dart';
import '../services/emotion_service.dart';
import '../services/notify_service.dart';
import '../services/push_service.dart';
import 'connect_screen.dart';
import 'couple_home_screen.dart';
import 'header_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.auth, required this.user});
  final AuthService auth;
  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _couples = CoupleService();
  final _emotions = EmotionService();
  final _notify = NotifyService();
  final _push = PushService();

  @override
  void initState() {
    super.initState();
    _push.register(widget.user.uid);
  }

  Future<void> _signOut() async {
    try {
      await _push.unregister(widget.user.uid);
    } catch (_) {}
    await widget.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _couples.watchUser(widget.user.uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final me = snap.data!.data();
        final coupleId = me?['coupleId'] as String?;
        if (coupleId == null) {
          return Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  onPressed: _signOut,
                  icon: const Icon(LucideIcons.logOut),
                  tooltip: '로그아웃',
                ),
              ],
            ),
            body: ConnectScreen(uid: widget.user.uid, couples: _couples),
          );
        }
        return StreamBuilder(
          stream: _couples.watchCouple(coupleId),
          builder: (context, cs) {
            final couple = cs.data?.data();
            final members =
                (couple?['members'] as List?)?.cast<String>() ?? const [];
            final partnerUid = members
                .where((m) => m != widget.user.uid)
                .firstOrNull;
            final created = (couple?['createdAt'] as Timestamp?)?.toDate();
            return StreamBuilder(
              stream: partnerUid == null
                  ? null
                  : _couples.watchUser(partnerUid),
              builder: (context, ps) {
                final partnerName = ps.data?.data()?['displayName'] as String?;
                final prefs = HeaderPrefs.fromUser(
                  me,
                  coupleCreatedAt: created,
                );
                final sub = prefs.subtitle(DateTime.now());
                return Scaffold(
                  body: SafeArea(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (sub != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.calendarHeart,
                                            size: 13,
                                            color: MkColors.textSub,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            sub,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: MkColors.textSub,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      prefs.title(partnerName),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: '상단 문구 편집',
                                icon: const Icon(LucideIcons.pencil),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HeaderEditScreen(
                                      uid: widget.user.uid,
                                      initial: prefs,
                                      partnerName: partnerName,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _signOut,
                                icon: const Icon(LucideIcons.logOut),
                                tooltip: '로그아웃',
                              ),
                            ],
                          ),
                        ),
                        Positioned.fill(
                          top: 90,
                          child: CoupleHomeScreen(
                            uid: widget.user.uid,
                            coupleId: coupleId,
                            emotions: _emotions,
                            notify: _notify,
                            partnerName: partnerName,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
