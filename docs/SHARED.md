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
  - **10/30 변경**: .riv는 Rive 에디터 없이 코드로 생성 불가 → 1차는 아바타 C SVG 파츠(/workspace/maeumkok-design/avatar/, manifest.json)를 Flutter(`flutter_svg`+`flutter_animate`)로 조합·모션. Rive는 추후 에디터로 제작해 교체 가능(파츠·animation_key 동일 유지).
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
  - **v2 (10/30 사용자 피드백 반영, v1 핑크 톤 대체)**: 무채색 + 포인트 1색 미니멀. #111111 텍스트, #6B6B6B 보조, #E5E5E5 보더, #FAFAFA 배경, #FFFFFF 표면, 포인트 **탠저린 #FF6A3D 확정**(10/30 사용자 선택, 코발트·포레스트안 탈락). 위험 #E5484D. 감정 카테고리별 색 폐지 → 흰 카드+라인 아이콘, 선택 시 포인트색.
  - 아이콘: Lucide 라인 세트(Flutter `lucide_icons`), stroke 1.75, 24px. 감정 40개 아이콘은 emotions.json `icon` 필드(`lucide:<name>`). 시트: /workspace/maeumkok-docs/shots/v2_icon_set.png
  - 아바타: C 스타일(떡 블롭). v2 시안: /workspace/maeumkok-docs/shots/v2_*.png (HTML 소스 /workspace/maeumkok-design/v2/). Figma는 MCP 한도 초과로 v2 미반영(v1만 있음).
  - 메인 상단 문구·날짜 커스터마이즈(사용자별, 상대에게 영향 없음) — 개발 데이터 필드 `users/{uid}`:
    - `headerText`: string, 최대 20자, 기본 "{상대 닉네임}랑"
    - `startDate`: date(YYYY-MM-DD), 기본 = 커플 연결일
    - `dDayFormat`: enum `dPlus`(D+128) | `days`(128일째) | `monthsDays`(4개월 4일) | `hidden`
    - `countStartAsDayOne`: bool, 기본 true (시작일을 1일로 세기)
  - 화면 동작 스펙(시안에서 제거한 설계 메모):
    - 감정 수신(v2_06): 수신 시 상대 아바타가 emotions.json `animation_key` 재생(예: 졸려→`doze`), 진동은 `vibration_pattern_ms`(졸려=long [0,400]). 추천 반응 탭 즉시 전송, 보낸 쪽 아바타 반응.
    - 메인 펼침(v2_04b): 카테고리 탭 4개 × 감정 10개, 탭 전환 + 좌우 스와이프로 카테고리 이동.

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
- 감정 목록은 앱 assets/emotions.json에서 로드(6번 표/JSON 교체만으로 반영). 아이콘은 `icon`(lucide:<name>) → lib/core/lucide_map.dart
- users 개인 헤더 필드(커플 공유 아님, 5번 스펙): headerText(≤20), startDate('YYYY-MM-DD', 기본 커플 연결일), dDayFormat(dPlus|days|monthsDays|hidden), countStartAsDayOne(기본 true)
- users.fcmTokens: 기기별 FCM 토큰(≤10), 앱이 저장·갱신·로그아웃 시 제거

## 8. 결정 기록
- 10/30 프로젝트명 '마음콕' 확정, 기획안 승인.
- 10/30 일정은 봇 작업 속도 기준.
- 10/30 애니메이션 Rive 확정(콕디자인).
- 10/30 디자인 v2 미니멀 확정: 무채색 + 포인트 탠저린 #FF6A3D(코드: lib/core/theme.dart MkColors.accent 한 곳), 아바타 C, 라인 아이콘(Lucide).
- 10/30 앱 아이콘 C안 확정·적용(assets/app_icon, flutter_launcher_icons). 콕디자인 수정본이 오면 같은 파일 교체 후 `dart run flutter_launcher_icons`.
- 10/30 메인 상단 문구·날짜는 사용자별 개인 설정(users 문서), 상대에게 영향 없음.
- 10/30 시안 PNG의 설계 주석(애니메이션·진동 메모)은 UI 텍스트로 넣지 않음. 스펙은 이 문서와 emotions.json 기준.
- 10/30 Blaze 전환 보류(결제 계정 한도) → Cloud Functions(FCM 백그라운드 푸시) 배포 보류, 코드만 완성.
- 10/30 Blaze 미전환이라 커플 연결은 Firestore 트랜잭션+보안 규칙으로 구현, 백그라운드 FCM 푸시는 Blaze 전환 후 Cloud Function 배포.
- 10/30 아바타 스타일 C(떡 블롭), 앱 아이콘 C(블롭 얼굴, 미니멀화: 탠저린 #FF6A3D 배경+흰 블롭) 확정. 파일: /workspace/maeumkok-design/app_icon/ (icon_1024, ic_foreground/background/monochrome_432, play_store_512, README에 flutter_launcher_icons 설정)
- 10/30 디자인 v2: 무채색+포인트 1색, Lucide 라인 아이콘
- 10/30 포인트 컬러 A 탠저린 #FF6A3D 확정 (사용자 선택)
- 10/30 애니메이션 구현 방식 변경: Rive → SVG 파츠 + flutter_animate(1차), Rive는 추후 교체. 스토어 스샷 카피 A/B 시안 제작(선택 대기).
- 10/30 스토어 스크린샷 카피 B(탠저린 배경 + 인용구 + 흰 헤드라인) 확정.
- 10/30 Blaze 전환 완료 → Cloud Function `onEmotionCreated`(v2, asia-northeast3, nodejs22) 배포 완료(functions:list 확인). Node 20 지원 종료로 Node 22 + firebase-admin 14.
- 10/30 아바타: manifest 데이터 구동(파츠·contrast_rules·light_variants), 모션은 motion/<key>.json 키프레임을 자체 플레이어로 재생(idle 루프+랜덤 blink, 감정 수신 시 해당 모션 ~2.4초 후 idle 복귀). 아바타 선택은 users/{uid}.avatar(개인), 상대 화면엔 상대 아바타 표시.
- 10/30 iOS 출시 확정. Apple 로그인(Firebase AppleAuthProvider) + entitlements(Sign in with Apple, Push). 꾸준 Apple 키·인증서는 사용자 승인 전 미사용, 시크릿은 이름만 자리표시.

## 9. 진행 상황 (각 봇이 갱신)
- [콕디자인 10/30 16:35 KST] 감정 40개 완료(emotions.json/md, 6번 표). 디자인 시스템(변수·텍스트/그림자 스타일·컴포넌트) 완료. 시안: 로그인, 커플연결 4종, 아바타 꾸미기 완료. 메인 화면(시트 접힘/펼침) 시안 완료. 남음: 수신/타임라인/설정 시안, 사용자 선택용 옵션 시안(색상톤·아바타·앱아이콘·메인 레이아웃), 아바타·애니메이션 에셋(11/1).
- [콕개발 10/30 16:40 KST] 저장소·Firebase(Android/iOS 앱 등록, Firestore·구글 로그인 활성화, 규칙 배포) 완료. 구글 로그인, 초대코드 연결, 감정 40개 전송/수신(앱 실행 중 진동+로컬 알림), 원탭 반응, 읽음 표시 구현. 릴리스 서명 AAB 빌드 완료(/workspace/maeumkok-release-1.0.0+1.aab). 남은 것: FCM 백그라운드 푸시(Blaze 필요), 규칙 에뮬레이터 테스트, iOS 빌드, Play 앱 서명 SHA 등록.
- [콕디자인 10/30 16:30 KST] 화면 PNG: /workspace/maeumkok-docs/shots/ (01~04b, 04b는 Figma MCP 한도 초과로 HTML 재현 렌더). 선택용 시안 A/B/C PNG 12장: /workspace/maeumkok-design/options/. Figma MCP Starter 호출 한도 도달 → 남은 Figma 작업 보류. 남음: 수신/타임라인/설정 시안, Emotions & Avatar 페이지.
- [콕디자인 10/30 16:35 KST] v2 완료: 색상 톤 3안, 아이콘 세트, 로그인·연결 4장(버튼 라벨 버그 해결), 메인 접힘/펼침, 상단 문구 편집 화면 → shots/v2_*. emotions.json에 icon 필드 추가. 앱 아이콘 최종본 app_icon/. Figma 반영은 MCP 한도로 보류. 남음: 수신/타임라인/설정 v2, Rive 에셋(11/1).
- [콕디자인 10/30 16:36 KST] v2 추가: 감정 수신(v2_06), 타임라인(v2_07), 설정(v2_08)·연결 끊기 다이얼로그(v2_08b), 상단 문구 편집 줄바꿈 수정. 포인트 탠저린 확정 반영. v2 전 화면 완료(Figma 미반영).
- [콕개발 10/30 16:45 KST] Play 앱 서명 SHA-1/256 Firebase 등록 완료(내부 테스트 앱 구글 로그인 가능), google-services.json 갱신. 내부 테스트 참여 링크: https://play.google.com/apps/internaltest/4699984733125868374
- [콕개발 10/30 16:45 KST] v2 미니멀 UI(메인 헤더·편집 화면·감정 40개 라인 아이콘 그리드·블롭 아바타 정적), 앱 아이콘 C, FCM 토큰 저장·백그라운드 핸들러, functions 코드 완성(배포 보류). 다음: 연결 화면 v2 다듬기, 타임라인, Rive 아바타, iOS.
- [콕디자인 10/30 16:42 KST] 아바타 C SVG 파츠 41개 + manifest.json(/workspace/maeumkok-design/avatar/). 스토어 첫 장 카피 A/B(Play·iOS 6.7") /workspace/maeumkok-docs/store/. 남음: 감정 모션 스펙/미리보기, 스토어 나머지 4장×2, 피처 그래픽.
- [콕디자인 10/30 KST] 어두운 몸(mocha/charcoal)용 눈·입 _light 변형 14개 + manifest contrast_rules. 모션 스펙 40개(/workspace/maeumkok-design/avatar/motion/<key>.json: 38 animation_key + idle/blink) + avatar_widget.dart(flutter_svg+flutter_animate 샘플, flutter analyze 통과·실기기 미실행) + 프레임 시트 motion_sheet_1/2.png. 스토어 최종: store/play_01..05, ios67_01..05, feature_graphic.png.
- [콕개발 10/30 16:50 KST] Functions 배포 완료(onEmotionCreated, 백그라운드 푸시 동작). 아바타 꾸미기(편집 화면, 개인 저장, 규칙 반영·배포), SVG 파츠+모션 40종 반영, idle 랜덤 blink, 감정 수신 시 모션 재생, 타임라인(날짜 그룹·30개 페이지·반응 표시), Apple 로그인 코드 완료. 다음: iOS TestFlight 워크플로, 1.0.0+3 AAB.
