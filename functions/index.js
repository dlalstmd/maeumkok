// 감정 전송 시 상대에게 FCM 푸시. Blaze 요금제 전환 후 `firebase deploy --only functions`.
// 앱은 users/{uid}.fcmTokens 에 토큰을 저장해야 한다(2단계에서 연결).
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

exports.onEmotionCreated = onDocumentCreated(
  {document: "couples/{coupleId}/emotions/{emotionId}", region: "asia-northeast3"},
  async (event) => {
    const e = event.data && event.data.data();
    if (!e) return;
    const couple = (await db.doc(`couples/${event.params.coupleId}`).get()).data();
    if (!couple) return;
    const partnerUid = couple.members.find((m) => m !== e.senderUid);
    const partner = (await db.doc(`users/${partnerUid}`).get()).data() || {};
    const tokens = partner.fcmTokens || [];
    if (!tokens.length) return;
    await admin.messaging().sendEachForMulticast({
      tokens,
      data: {type: "emotion", emotionId: e.emotionId, emotionDocId: event.params.emotionId},
      notification: {title: "마음콕", body: "새 마음이 도착했어요"},
      android: {priority: "high", notification: {channelId: `emotion_${e.emotionId}`}},
      apns: {payload: {aps: {sound: "default"}}},
    });
  });
