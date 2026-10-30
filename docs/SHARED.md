# 마음콕(MaeumKok) 팀 공유 문서
모든 마음콕 봇(그로깅 PM, 콕디자인, 콕개발)은 작업 전에 이 문서를 읽고, 결정·변경이 생기면 이 문서를 먼저 고친다. 이 문서가 기준(단일 진실 공급원)이다.

## 1. 제품 개요
- 커플 둘만 쓰는 감정 공유 앱. 사용자=안드로이드, 여자친구=iOS. 스토어 출시 전제.
- 로그인: 구글 로그인(iOS는 심사상 Apple 로그인 추가 검토).
- 커플 연결: 6자리 초대코드(24시간 유효) + QR 공유, 양쪽 확인 후 연결. 한 계정 한 커플. 설정에서 연결 끊기.
- 메인: 상대 아바타가 크게 보임. 하단 시트를 올리면 감정 버튼 약 40개(기분 / 몸 상태 / 하고 싶은 것 / 애정).
- 수신: 감정별 진동 패턴 + 푸시, 상대 아바타가 감정 애니메이션.
- 반응: 감정별 추천 반응 2~3개 원탭(예: 졸려→토닥토닥, 배고파→밥 사줄게). 보낸 쪽 아바타가 반응 애니메이션. 읽음 표시.
- 타임라인: 오늘 주고받은 감정 기록.
- 아바타 꾸미기.

## 2. 기술 스택
- Flutter(안드로이드+iOS), Firebase(Auth, Firestore, FCM, Cloud Functions).
- 애니메이션: **Rive 결정**(콕디자인 10/30). 이유: 아바타 파츠 교체+감정 40종을 상태머신 하나(입력 emotion/play/tap)로 처리, idle/blink 루프 내장, 파일 작고 Flutter `rive` 패키지 지원. Lottie는 감정 FX 오버레이 폴백. 상세: /workspace/maeumkok/avatar_animation.md
- 코드: /workspace/maeumkok — GitHub: https://github.com/dlalstmd/maeumkok (private)
- Firebase 프로젝트: maeumkok (Firestore asia-northeast3 서울). Android 패키지/iOS 번들: com.maeumkok.app

## 3. 담당
- 그로깅: PM, 일정·우선순위, 사용자 보고
- 콕디자인: 디자인 시스템, 화면 시안(Figma), 감정 목록, 아바타·애니메이션
- 콕개발: 앱·백엔드 구현, 빌드, 테스트, 저장소

## 4. 일정 (봇 작업 속도 기준)
- 10/30 밤: 디자인 시스템·감정 목록·주요 시안 / 저장소·Firebase·구글 로그인
- 10/31: 커플 연결·감정 전송·푸시·진동·반응, 안드로이드 테스트 빌드
- 11/1~2: 아바타 꾸미기·감정 애니메이션·타임라인, iOS TestFlight
- 11/3~: 다듬기, 스토어 등록 준비

## 5. 디자인 시스템 (콕디자인이 채움)
- 색상 / 글꼴 / 간격 / 컴포넌트 / Figma 링크:
  - Figma: https://www.figma.com/design/cL2i6N8ewjzTBJBoxjpxL6 (페이지: Design System & Components / Screens / Emotions & Avatar)
  - 색상: primary 코랄 #FF8A73(pressed #F26B55, soft #FFE3DC), secondary 피치 #FFCB98, 배경 크림 #FFFBF5, 텍스트 #241E1C/#7A6E69, danger #D9503B. 카테고리: 기분 #FFE59A, 몸 상태 #A8E6CF, 하고 싶은 것 #A9D4F7, 애정 #FFB3C7. 다크: 배경 #1A1514, 표면 #2A2220, primary #FFA996 (Figma 변수 'Semantic / Dark').
  - 글꼴: Pretendard (Figma는 Noto Sans KR 대체). Display 32B/40, Title1 24B/32, Title2 20B/28, Headline 17M/24, Body 15R/22, Callout 14M/20, Caption 12R/16, Micro 11M/14, 자간 -1%.
  - 간격: 4pt (4~48), 화면 좌우 24. 라운드 sm8/md12/lg16/xl24/full. 그림자 Soft/Card/Sheet.
  - 컴포넌트: Button(Primary/Secondary/Ghost/Danger), EmotionButton(카테고리 4종, 76x84), Card, Toast, Input, AvatarFrame, TabBar, BottomSheet.

## 6. 감정 목록 (콕디자인이 채움, 콕개발은 이 표를 그대로 코드에 반영)
| id | 이름 | 이모지 | 카테고리 | 추천 반응 | 진동 패턴 | 애니메이션 |
|---|---|---|---|---|---|---|
| happy | 행복해 | 😊 | mood(기분) | 나도 행복해! / 좋은 일 있었어? / 그 웃음 최고야 | heart [0, 60, 100, 120] | joy_bounce |
| excited | 신나! | 🥰 | mood(기분) | 같이 신나! / 무슨 일인데?! | triple [0, 30, 60, 30, 60, 30] | jump |
| sad | 슬퍼 | 😢 | mood(기분) | 토닥토닥 / 무슨 일이야? 얘기해줘 / 꼭 안아줄게 | slow [0, 200, 300, 200] | cry |
| angry | 화나 | 😠 | mood(기분) | 누가 그랬어?! / 내가 혼내줄게 / 진정 진정~ | buzz [0, 80, 50, 80, 50, 80] | fume |
| anxious | 불안해 | 😰 | mood(기분) | 괜찮아, 내가 있어 / 천천히 숨 쉬어봐 | slow [0, 200, 300, 200] | shiver |
| calm | 평온해 | 😌 | mood(기분) | 좋다~ / 나도 마음이 편해져 | soft [0, 120] | breathe |
| lonely | 외로워 | 🥺 | mood(기분) | 지금 전화할까? / 내가 옆에 있을게 / 보고 싶었어 | slow [0, 200, 300, 200] | droop |
| bored | 심심해 | 😑 | mood(기분) | 놀아줄게! / 영상통화 할래? | short [0, 40] | sway |
| stressed | 스트레스 | 😤 | mood(기분) | 고생 많았어 / 맛있는 거 먹자 / 내가 다 들어줄게 | buzz [0, 80, 50, 80, 50, 80] | sigh |
| proud | 뿌듯해 | 🤩 | mood(기분) | 역시 최고야! / 자랑스러워 | triple [0, 30, 60, 30, 60, 30] | sparkle |
| sleepy | 졸려 | 😴 | body(몸 상태) | 토닥토닥 / 얼른 자~ 잘자 / 꿈에서 만나 | long [0, 400] | doze |
| hungry | 배고파 | 🍚 | body(몸 상태) | 밥 사줄게! / 뭐 먹고 싶어? / 배달 시켜줄까? | double [0, 40, 80, 40] | tummy |
| sick | 아파 | 🤒 | body(몸 상태) | 약 먹었어? / 죽 사갈게 / 푹 쉬어 | slow [0, 200, 300, 200] | sick_wobble |
| tired | 피곤해 | 😩 | body(몸 상태) | 오늘 수고했어 / 어깨 주물러줄게 / 일찍 쉬자 | long [0, 400] | slump |
| hot | 더워 | 🥵 | body(몸 상태) | 시원한 거 사줄게 / 에어컨 켜! | short [0, 40] | sweat |
| cold | 추워 | 🥶 | body(몸 상태) | 따뜻하게 입어 / 안아서 데워줄게 | buzz [0, 80, 50, 80, 50, 80] | shiver |
| headache | 머리 아파 | 🤕 | body(몸 상태) | 약 챙겨 먹어 / 조금 쉬어 | slow [0, 200, 300, 200] | head_hold |
| energetic | 힘이 넘쳐 | 💪 | body(몸 상태) | 멋져! / 그 힘 나한테도 줘 | triple [0, 30, 60, 30, 60, 30] | flex |
| full | 배불러 | 🤢 | body(몸 상태) | 많이 먹었구나ㅋㅋ / 산책할까? | soft [0, 120] | tummy_pat |
| busy | 바빠 | 🏃 | body(몸 상태) | 파이팅! / 끝나면 연락해 | short [0, 40] | rush |
| want_hug | 안아줘 | 🫂 | want(하고 싶은 것) | 꼬옥 안아줄게 / 달려갈게! | heart [0, 60, 100, 120] | arms_open |
| want_call | 전화하고 싶어 | 📞 | want(하고 싶은 것) | 지금 걸게! / 5분만 기다려 | double [0, 40, 80, 40] | phone |
| want_see | 보고 싶어 | 👀 | want(하고 싶은 것) | 나도 보고 싶어 / 오늘 만날까? | heart [0, 60, 100, 120] | look_around |
| want_dessert | 달달한 거 먹고 싶어 | 🍰 | want(하고 싶은 것) | 디저트 사갈게 / 카페 가자! | double [0, 40, 80, 40] | drool |
| want_movie | 영화 보고 싶어 | 🎬 | want(하고 싶은 것) | 주말에 보자! / 뭐 볼까? | short [0, 40] | popcorn |
| want_walk | 산책하고 싶어 | 🚶 | want(하고 싶은 것) | 같이 걷자 / 어디로 갈까? | short [0, 40] | walk |
| want_trip | 여행 가고 싶어 | ✈️ | want(하고 싶은 것) | 어디 가고 싶어? / 계획 짜보자 | triple [0, 30, 60, 30, 60, 30] | dream |
| want_drink | 한잔하고 싶어 | 🍻 | want(하고 싶은 것) | 오늘 콜! / 안주 뭐 할까? | double [0, 40, 80, 40] | cheers |
| want_play | 같이 놀고 싶어 | 🎮 | want(하고 싶은 것) | 게임 한판? / 지금 놀자! | triple [0, 30, 60, 30, 60, 30] | play |
| want_rest | 쉬고 싶어 | 🛌 | want(하고 싶은 것) | 푹 쉬어 / 방해 안 할게 | long [0, 400] | lie_down |
| love_you | 사랑해 | ❤️ | love(애정) | 나도 사랑해 / 더 많이 사랑해 | heart [0, 60, 100, 120] | heart_pop |
| kiss | 뽀뽀 | 😘 | love(애정) | 쪽! / 나도 뽀뽀 | heart [0, 60, 100, 120] | kiss |
| miss_you | 보고싶어 | 🥹 | love(애정) | 나도 너무 보고싶어 / 곧 만나자 | slow [0, 200, 300, 200] | longing |
| thanks | 고마워 | 🙏 | love(애정) | 내가 더 고마워 / 언제든지! | soft [0, 120] | bow |
| sorry | 미안해 | 🙇 | love(애정) | 괜찮아 / 나도 미안해 / 얘기하자 | slow [0, 200, 300, 200] | bow_deep |
| thinking_of_you | 네 생각 중 | 🌸 | love(애정) | 나도 네 생각! / 무슨 생각? | soft [0, 120] | daydream |
| cheer_up | 힘내 | 🫶 | love(애정) | 고마워 힘낼게 / 덕분에 힘나 | heart [0, 60, 100, 120] | cheer |
| proud_of_you | 자랑스러워 | 💌 | love(애정) | 헤헤 고마워 / 네 덕분이야 | triple [0, 30, 60, 30, 60, 30] | sparkle |
| jealous | 질투나 | 😳 | love(애정) | 너밖에 없어 / 귀여워ㅋㅋ | buzz [0, 80, 50, 80, 50, 80] | pout |
| good_night | 잘 자 | 🌙 | love(애정) | 너도 잘 자 / 꿈에서 만나 / 사랑해 굿나잇 | long [0, 400] | sleep_wave |
- 원본: /workspace/maeumkok/emotions.json (사본 /workspace/maeumkok-design/). 진동 패턴 = [대기,진동,...] ms, vibration 패키지; 미지원 시 HapticFeedback 폴백

## 7. 데이터 모델 (콕개발이 채움, 상세: 저장소 docs/data-model.md)
- users/{uid}: displayName, email, photoUrl, coupleId, fcmTokens
- inviteCodes/{6자리}: ownerUid, status(pending→claimed→confirmed/cancelled), expiresAt(24h), claimedBy, coupleId
- couples/{id}: members[2], inviteCode, createdAt
- couples/{id}/emotions/{id}: senderUid, emotionId, createdAt, readAt(읽음)
- couples/{id}/reactions/{id}: senderUid, emotionDocId, reactionId(추천 반응 인덱스)
- 감정 목록은 앱 assets/emotions.json에서 로드(6번 표/JSON 교체만으로 반영)

## 8. 결정 기록
- 10/30 프로젝트명 '마음콕' 확정, 기획안 승인.
- 10/30 일정은 봇 작업 속도 기준.
- 10/30 애니메이션 Rive 확정(콕디자인).
- 10/30 Blaze 미전환이라 커플 연결은 Firestore 트랜잭션+보안 규칙으로 구현, 백그라운드 FCM 푸시는 Blaze 전환 후 Cloud Function 배포.

## 9. 진행 상황 (각 봇이 갱신)
- [콕디자인 10/30 16:35 KST] 감정 40개 완료(emotions.json/md, 6번 표). 디자인 시스템(변수·텍스트/그림자 스타일·컴포넌트) 완료. 시안: 로그인, 커플연결 4종, 아바타 꾸미기 완료. 메인 화면(시트 접힘/펼침) 시안 완료. 남음: 수신/타임라인/설정 시안, 사용자 선택용 옵션 시안(색상톤·아바타·앱아이콘·메인 레이아웃), 아바타·애니메이션 에셋(11/1).
- [콕개발 10/30 16:40 KST] 저장소·Firebase(Android/iOS 앱 등록, Firestore·구글 로그인 활성화, 규칙 배포) 완료. 구글 로그인, 초대코드 연결, 감정 40개 전송/수신(앱 실행 중 진동+로컬 알림), 원탭 반응, 읽음 표시 구현. 릴리스 서명 AAB 빌드 완료(/workspace/maeumkok-release-1.0.0+1.aab). 남은 것: FCM 백그라운드 푸시(Blaze 필요), 규칙 에뮬레이터 테스트, iOS 빌드, Play 앱 서명 SHA 등록.
