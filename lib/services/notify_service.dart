import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import '../core/emotions.dart';

/// 감정별 진동 + 로컬 알림. Android는 감정마다 진동 패턴이 다른 알림 채널을 쓴다
/// (FCM 서버 푸시도 channelId `emotion_<id>`로 보내면 같은 패턴 적용).
class NotifyService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static String channelId(String emotionId) => 'emotion_$emotionId';

  Future<void> init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
      for (final e in kEmotions) {
        await android.createNotificationChannel(
          AndroidNotificationChannel(
            channelId(e.id),
            '감정: ${e.label}',
            importance: Importance.high,
            enableVibration: true,
            vibrationPattern: Int64List.fromList(e.vibrationPattern),
          ),
        );
      }
    }
    _ready = true;
  }

  Future<void> vibrateFor(Emotion e) async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(pattern: e.vibrationPattern);
    }
  }

  Future<void> showEmotion(Emotion e, {String from = '상대'}) async {
    await init();
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '$from: ${e.emoji} ${e.label}',
      body: '탭해서 반응을 보내 보세요',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId(e.id),
          '감정: ${e.label}',
          importance: Importance.high,
          priority: Priority.high,
          vibrationPattern: Int64List.fromList(e.vibrationPattern),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
