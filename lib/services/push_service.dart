import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// 백그라운드/종료 상태 메시지 핸들러(top-level 필수).
/// Android는 서버가 감정별 channelId(`emotion_<id>`)로 보내 OS가 해당 진동으로 표시한다.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('bg message: ${message.data}');
}

// 기존 FCM 등록 토큰 방식 유지: Admin SDK sendEachForMulticast와 호환.
// (FID 기반 register()/onRegistered 전환은 서버 지원 확인 후)
// ignore_for_file: deprecated_member_use

/// FCM 토큰을 users/{uid}.fcmTokens 에 저장·갱신.
class PushService {
  PushService({FirebaseMessaging? messaging, FirebaseFirestore? db})
    : _fm = messaging ?? FirebaseMessaging.instance,
      _db = db ?? FirebaseFirestore.instance;
  final FirebaseMessaging _fm;
  final FirebaseFirestore _db;
  StreamSubscription<String>? _refreshSub;
  String? _token;

  Future<void> register(String uid) async {
    await _fm.requestPermission(alert: true, badge: true, sound: true);
    await _fm.setForegroundNotificationPresentationOptions(
      alert: false,
      sound: false,
    );
    try {
      final t = await _fm.getToken();
      if (t != null) await _save(uid, t);
    } catch (e) {
      debugPrint(
        'FCM token error: $e',
      ); // iOS: APNs 토큰 준비 전일 수 있음 → onTokenRefresh에서 재시도
    }
    await _refreshSub?.cancel();
    _refreshSub = _fm.onTokenRefresh.listen((t) => _save(uid, t));
  }

  Future<void> _save(String uid, String token) async {
    final ref = _db.collection('users').doc(uid);
    final old = _token;
    _token = token;
    await ref.update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
    if (old != null && old != token) {
      await ref.update({
        'fcmTokens': FieldValue.arrayRemove([old]),
      });
    }
  }

  /// 로그아웃 시 이 기기 토큰 제거
  Future<void> unregister(String uid) async {
    await _refreshSub?.cancel();
    final t = _token ?? await _fm.getToken();
    if (t != null) {
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([t]),
      });
    }
    await _fm.deleteToken();
    _token = null;
  }
}
