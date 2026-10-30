# 마음콕 Firestore 데이터 모델 (v1, 2026-10-30)

| 경로 | 필드 | 쓰기 주체 |
|---|---|---|
| `users/{uid}` | uid, displayName, email, photoUrl, coupleId?, fcmTokens[](≤10, 기기별 FCM 토큰), headerText?(≤20자), startDate?('YYYY-MM-DD', 없으면 커플 연결일), dDayFormat(dPlus\|days\|monthsDays\|hidden), countStartAsDayOne(bool, 기본 true), createdAt, updatedAt | 본인(coupleId 제외). 헤더 필드는 **개인 설정, 커플 공유 아님**. coupleId는 커플 확정 배치에서만 |
| `inviteCodes/{6자리}` | ownerUid, status(pending→claimed→confirmed / cancelled), createdAt, expiresAt(+24h), claimedBy, claimedAt, coupleId | A 생성 → B claim → A confirm |
| `couples/{coupleId}` | members[2], inviteCode, createdAt | A의 confirm 트랜잭션 (수정·삭제 불가) |
| `couples/{c}/emotions/{id}` | senderUid, emotionId(assets/emotions.json의 id), createdAt, readAt? | 멤버 생성, 받는 쪽만 readAt |
| `couples/{c}/reactions/{id}` | senderUid, emotionDocId, reactionId(추천 반응 인덱스), createdAt | 멤버 생성 |

## 커플 연결 흐름
1. A: 코드 생성(`pending`, 24h). 커플 있으면 거부.
2. B: 코드 입력 → `claimed`(B 확인). 본인 코드/만료/사용됨/이미 커플이면 거부.
3. A: 수락 → 한 트랜잭션에서 couples 생성 + invite `confirmed` + 양쪽 users.coupleId 설정(A 확인).
모든 조건은 `firestore.rules`에서 서버 검증(Blaze 전환 후 Cloud Functions로 이전 가능).

## 보안 규칙 요약
- 커플 데이터: `couples/{c}.members`에 있는 두 사람만 읽기/쓰기.
- inviteCodes: 문서 단건 get만(목록 조회 불가).
- 삭제는 전부 금지(연결 끊기는 다음 단계에서 설계).

## 푸시
- 앱: 로그인 시 FCM 토큰을 `users/{uid}.fcmTokens`에 arrayUnion, 토큰 갱신 시 교체, 로그아웃 시 제거.
- 서버: `functions/index.js` `onEmotionCreated`(asia-northeast3) → 상대 토큰에 전송, Android `channelId: emotion_<id>`(앱이 만든 감정별 진동 채널), 무효 토큰 정리. Blaze 전환 후 배포.
