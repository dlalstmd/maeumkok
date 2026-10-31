// 감정 전송 시 상대에게 FCM 푸시. Blaze 요금제 전환 후 `firebase deploy --only functions`.
// 앱(lib/services/push_service.dart)이 users/{uid}.fcmTokens 에 토큰을 저장한다.
// Android: channelId emotion_<id> → 앱이 만든 감정별 진동 채널로 표시.
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
initializeApp();
const db = getFirestore();

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
    const res = await getMessaging().sendEachForMulticast({
      tokens,
      data: {type: "emotion", emotionId: e.emotionId, emotionDocId: event.params.emotionId},
      notification: {title: "마음콕", body: "새 마음이 도착했어요"},
      android: {priority: "high", notification: {channelId: `emotion_${e.emotionId}`}},
      apns: {payload: {aps: {sound: "default", "content-available": 1}}},
    });
    // 만료/무효 토큰 정리
    const dead = [];
    res.responses.forEach((r, i) => {
      const code = r.error && r.error.code;
      if (code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token") dead.push(tokens[i]);
    });
    if (dead.length) {
      await db.doc(`users/${partnerUid}`).update({
        fcmTokens: FieldValue.arrayRemove(...dead),
      });
    }
  });

// 반응 생성 시 감정을 보낸 사람(상대)에게 푸시.
const emotionsJson = require("./emotions.json");
function reactionText(emotionId, reactionId) {
  const e = (emotionsJson.emotions || []).find((x) => x.id === emotionId);
  const label = e && e.reactions && e.reactions[Number(reactionId)];
  return label || "반응이 도착했어요";
}
exports.onReactionCreated = onDocumentCreated(
  {document: "couples/{coupleId}/reactions/{reactionId}", region: "asia-northeast3"},
  async (event) => {
    const r = event.data && event.data.data();
    if (!r) return;
    const couple = (await db.doc(`couples/${event.params.coupleId}`).get()).data();
    if (!couple) return;
    const partnerUid = couple.members.find((m) => m !== r.senderUid);
    const emo = (await db.doc(`couples/${event.params.coupleId}/emotions/${r.emotionDocId}`).get()).data() || {};
    const partner = (await db.doc(`users/${partnerUid}`).get()).data() || {};
    const tokens = partner.fcmTokens || [];
    if (!tokens.length) return;
    await getMessaging().sendEachForMulticast({
      tokens,
      data: {type: "reaction", emotionDocId: r.emotionDocId, reactionId: r.reactionId},
      notification: {title: "마음콕", body: reactionText(emo.emotionId, r.reactionId)},
      android: {priority: "high"},
      apns: {payload: {aps: {sound: "default"}}},
    });
  });

// 계정 삭제(스토어 필수): 본인 users 문서, 소속 커플의 감정·리액션·커플 문서, 초대코드, Auth 계정 삭제.
// 상대방은 coupleId 해제되어 다시 연결 가능한 상태가 된다.
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {getAuth} = require("firebase-admin/auth");
exports.deleteAccount = onCall({region: "asia-northeast3"}, async (req) => {
  const uid = req.auth && req.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
  const userRef = db.doc(`users/${uid}`);
  const me = (await userRef.get()).data() || {};
  if (me.coupleId) {
    const coupleRef = db.doc(`couples/${me.coupleId}`);
    const couple = (await coupleRef.get()).data();
    await db.recursiveDelete(coupleRef);
    if (couple) {
      for (const m of couple.members || []) {
        if (m !== uid) {
          await db.doc(`users/${m}`).set({coupleId: FieldValue.delete()}, {merge: true});
        }
      }
    }
  }
  const codes = await db.collection("inviteCodes").where("ownerUid", "==", uid).get();
  for (const d of codes.docs) await d.ref.delete();
  await db.recursiveDelete(userRef);
  await getAuth().deleteUser(uid).catch((e) => {
    if (e.code !== "auth/user-not-found") throw e;
  });
  return {ok: true};
});
