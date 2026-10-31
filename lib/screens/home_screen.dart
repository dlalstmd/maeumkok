import '../avatar/part_adjust.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../background/background.dart';
import '../core/header_prefs.dart';
import 'background_picker_screen.dart';

import 'dart:async';

import '../services/auth_service.dart';
import '../services/couple_service.dart';
import '../services/emotion_prefs_service.dart';
import '../services/emotion_service.dart';
import '../services/notify_service.dart';
import '../services/push_service.dart';
import 'connect_screen.dart';
import 'couple_home_screen.dart';
import 'avatar_edit_screen.dart';
import 'header_edit_screen.dart';
import 'settings_screen.dart';
import 'timeline_screen.dart';

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
  final _prefs = EmotionPrefsService();
  bool _touchHaptics = true;
  BgCatalog? _bgCat;
  Timer? _todTimer;
  // 설정 → 배경 진입용 최신 값
  BgChoice _myBg = BgChoice.fallback;
  bool _bgShared = false;
  String? _coupleId, _partnerName;
  Map<String, String> _myAvatar = const {};
  final _notify = NotifyService();
  final _push = PushService();

  @override
  void initState() {
    super.initState();
    _push.register(widget.user.uid);
    BgCatalog.load().then((c) {
      if (mounted) setState(() => _bgCat = c);
    });
    // 시간대 세트: 1분마다 기기 시각으로 다시 계산
    _todTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _todTimer?.cancel();
    super.dispose();
  }

  void _openBackground() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BackgroundPickerScreen(
          uid: widget.user.uid,
          coupleId: _coupleId,
          initial: _bgShared ? _sharedBg ?? _myBg : _myBg,
          shared: _bgShared,
          myAvatar: _myAvatar,
          partnerName: _partnerName,
        ),
      ),
    );
  }

  BgChoice? _sharedBg;

  Future<void> _signOut() async {
    try {
      await _push.unregister(widget.user.uid);
    } catch (_) {}
    await widget.auth.signOut();
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          email: widget.user.email,
          onSignOut: _signOut,
          touchHaptics: _touchHaptics,
          extraTiles: [
            ListTile(
              key: const Key('openBackground'),
              leading: const Icon(LucideIcons.image),
              title: const Text('배경'),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: _openBackground,
            ),
          ],
          onTouchHaptics: (v) async {
            _touchHaptics = v;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.user.uid)
                .update({'prefs.touchHaptics': v});
          },
          onDeleteAccount: () async {
            try {
              await _push.unregister(widget.user.uid);
            } catch (_) {}
            await widget.auth.deleteAccount();
          },
        ),
      ),
    );
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
                  onPressed: _openSettings,
                  icon: const Icon(LucideIcons.settings),
                  tooltip: '설정',
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
                final partnerAvatar =
                    ((ps.data?.data()?['avatar'] as Map?) ?? const {})
                        .cast<String, String>();
                final partnerAdjusts = parseAdjusts(
                  ps.data?.data()?['avatarAdjust'],
                );
                final myAdjusts = parseAdjusts(me?['avatarAdjust']);
                final myAvatar = ((me?['avatar'] as Map?) ?? const {})
                    .cast<String, String>();
                final prefs = HeaderPrefs.fromUser(
                  me,
                  coupleCreatedAt: created,
                );
                final sub = prefs.subtitle(DateTime.now());
                _myBg = BgChoice.fromJson(me?['background']);
                _bgShared = couple?['backgroundShared'] == true;
                _sharedBg = couple?['background'] == null
                    ? null
                    : BgChoice.fromJson(couple!['background']);
                _coupleId = coupleId;
                _partnerName = partnerName;
                _myAvatar = myAvatar;
                final choice = effectiveChoice(
                  mine: me?['background'],
                  couple: couple,
                );
                final resolved = _bgCat == null
                    ? null
                    : resolveBg(_bgCat!, choice, DateTime.now());
                final light = resolved?.lightInk ?? false;
                final ink = inkColor(light);
                final inkSub = inkColor(light, sub: true);
                return Scaffold(
                  backgroundColor: resolved == null ? null : Colors.transparent,
                  body: Stack(
                    children: [
                      if (resolved != null)
                        Positioned.fill(
                          child: MainBackground(
                            resolved: resolved,
                            motion: choice.motion,
                          ),
                        ),
                      SafeArea(
                        child: IconTheme(
                          data: IconThemeData(color: ink),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  16,
                                  12,
                                  0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (sub != null)
                                            Row(
                                              children: [
                                                Icon(
                                                  LucideIcons.calendarHeart,
                                                  size: 13,
                                                  color: inkSub,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  sub,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: inkSub,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            prefs.title(partnerName),
                                            style: TextStyle(
                                              fontSize: 24,
                                              color: ink,
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
                                      tooltip: '내 아바타 꾸미기',
                                      icon: const Icon(LucideIcons.smile),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AvatarEditScreen(
                                            uid: widget.user.uid,
                                            initial: myAvatar,
                                            initialAdjusts: myAdjusts,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: '타임라인',
                                      icon: const Icon(LucideIcons.clock),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TimelineScreen(
                                            uid: widget.user.uid,
                                            coupleId: coupleId,
                                            emotions: _emotions,
                                            partnerName: partnerName,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _openSettings,
                                      icon: const Icon(LucideIcons.settings),
                                      tooltip: '설정',
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
                                  partnerAvatar: partnerAvatar,
                                  partnerAdjusts: partnerAdjusts,
                                  prefs: _prefs,
                                  myAvatar: myAvatar,
                                  touchHaptics: _touchHaptics =
                                      ((me?['prefs'] as Map?)?['touchHaptics']
                                          as bool?) ??
                                      true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
