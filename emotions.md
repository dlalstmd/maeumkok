# 마음콕 감정 80개 (v4.2: 대분류 4 · 소분류 12, 모노톤 라인 아이콘)

진동: `[대기,진동,대기,진동…]` ms. 프리셋은 `vibration_presets`. 표시 규칙은 `display_rules`(기본 charcoal #2B2B2B, 선택 시 탠저린 #FF6A3D). 이모지는 푸시 알림·호환용.


## 기분 (mood)

### 좋아 (mood.good)

| 아이콘 | id | 라벨 | 이모지 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| `lucide:smile` | `happy` | 행복해 | 😊 | 나도 행복해! / 좋은 일 있었어? / 그 웃음 최고야 | heart [0, 60, 100, 120] | `joy_bounce` |
| `lucide:party-popper` | `excited` | 신난다! | 🥰 | 같이 신나! / 무슨 일인데?! | triple [0, 30, 60, 30, 60, 30] | `jump` |
| `lucide:leaf` | `calm` | 평온해 | 😌 | 좋다~ / 나도 마음이 편해져 | soft [0, 120] | `breathe` |
| `lucide:trophy` | `proud` | 뿌듯해 | 🤩 | 역시 최고야! / 자랑스러워 | triple [0, 30, 60, 30, 60, 30] | `sparkle` |
| `lucide:shield-check` | `relieved` | 휴 다행 | 😮‍💨 | 다행이다 / 걱정했어 | soft [0, 120] | `breathe` |
| `lucide:heart-handshake` | `touched` | 감동ㅠ | 🥲 | 나도 감동 / 울지 마ㅠㅠ | heart [0, 60, 100, 120] | `longing` |
| `lucide:badge-check` | `confident` | 자신감 | 😎 | 멋있다! / 너라면 돼 | triple [0, 30, 60, 30, 60, 30] | `flex` |
| `lucide:circle-question-mark` | `curious` | 궁금해 | 🤔 | 뭐가 궁금해? / 물어봐! | short [0, 40] | `look_around` |

### 가라앉아 (mood.down)

| 아이콘 | id | 라벨 | 이모지 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| `lucide:frown` | `sad` | 슬퍼ㅠ | 😢 | 토닥토닥 / 무슨 일이야? 얘기해줘 / 꼭 안아줄게 | slow [0, 200, 300, 200] | `cry` |
| `lucide:cloud-rain` | `lonely` | 외로워 | 🥺 | 지금 전화할까? / 내가 옆에 있을게 / 보고 싶었어 | slow [0, 200, 300, 200] | `droop` |
| `lucide:meh` | `bored` | 심심해 | 😑 | 놀아줄게! / 영상통화 할래? | short [0, 40] | `sway` |
| `lucide:cloud` | `gloomy` | 꿀꿀해 | 😞 | 무슨 일 있었어? / 내가 웃겨줄게 / 꼭 안아줄게 | slow [0, 200, 300, 200] | `droop` |
| `lucide:thumbs-down` | `disappointed` | 실망이야 | 😔 | 많이 속상했지 / 얘기해줘 | slow [0, 200, 300, 200] | `slump` |
| `lucide:circle-dashed` | `empty` | 허전해 | 🫥 | 내가 채워줄게 / 지금 갈까? | slow [0, 200, 300, 200] | `sway` |

### 예민해 (mood.tense)

| 아이콘 | id | 라벨 | 이모지 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| `lucide:angry` | `angry` | 화났어 | 😠 | 누가 그랬어?! / 내가 혼내줄게 / 진정 진정~ | buzz [0, 80, 50, 80, 50, 80] | `fume` |
| `lucide:cloud-lightning` | `anxious` | 불안해 | 😰 | 괜찮아, 내가 있어 / 천천히 숨 쉬어봐 | slow [0, 200, 300, 200] | `shiver` |
| `lucide:flame` | `stressed` | 스트레스 | 😤 | 고생 많았어 / 맛있는 거 먹자 / 내가 다 들어줄게 | buzz [0, 80, 50, 80, 50, 80] | `sigh` |
| `lucide:zap-off` | `annoyed` | 짜증나 | 😒 | 누가 그랬어? / 맛있는 거 먹자 | buzz [0, 80, 50, 80, 50, 80] | `fume` |
| `lucide:activity` | `nervous` | 떨려 | 😬 | 잘할 수 있어 / 심호흡 한 번! | buzz [0, 80, 50, 80, 50, 80] | `shiver` |
| `lucide:cloud-drizzle` | `upset` | 서운해 | 🥺 | 미안해ㅠ / 얘기해줘, 들을게 | slow [0, 200, 300, 200] | `pout` |
| `lucide:badge-alert` | `surprised` | 깜짝! | 😲 | 무슨 일이야?! / 괜찮아? | triple [0, 30, 60, 30, 60, 30] | `jump` |

## 몸 상태 (body)

### 에너지 (body.energy)

| 아이콘 | id | 라벨 | 이모지 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| `lucide:moon` | `sleepy` | 졸려 | 😴 | 토닥토닥 / 얼른 자~ 잘자 / 꿈에서 만나 | long [0, 400] | `doze` |
| `lucide:battery-low` | `tired` | 피곤해 | 😩 | 오늘 수고했어 / 어깨 주물러줄게 / 일찍 쉬자 | long [0, 400] | `slump` |
| `lucide:dumbbell` | `energetic` | 힘 넘쳐 | 💪 | 멋져! / 그 힘 나한테도 줘 | triple [0, 30, 60, 30, 60, 30] | `flex` |
| `lucide:timer` | `busy` | 바빠ㅠ | 🏃 | 파이팅! / 끝나면 연락해 | short [0, 40] | `rush` |
| `lucide:droplets` | `refreshed` | 개운해 | 😆 | 좋겠다! / 나도 개운해지고 싶다 | soft [0, 120] | `sparkle` |
| `lucide:sofa` | `lazy` | 귀찮아 | 🫠 | 오늘은 쉬어 / 내가 해줄게 | long [0, 400] | `lie_down` |
| `lucide:bike` | `workout` | 운동 끝 | 🚴 | 멋져! / 고생했어 | triple [0, 30, 60, 30, 60, 30] | `flex` |
| `lucide:eye-off` | `sleepless` | 잠이 안 와 | 😵 | 통화할까? / 양 세어줄게 | slow [0, 200, 300, 200] | `look_around` |

### 컨디션 (body.condition)

| 아이콘 | id | 라벨 | 이모지 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| `lucide:thermometer` | `sick` | 아파ㅠ | 🤒 | 약 먹었어? / 죽 사갈게 / 푹 쉬어 | slow [0, 200, 300, 200] | `sick_wobble` |
| `lucide:brain-circuit` | `headache` | 머리 아파 | 🤕 | 약 챙겨 먹어 / 조금 쉬어 | slow [0, 200, 300, 200] | `head_hold` |
| `lucide:sun` | `hot` | 더워 | 🥵 | 시원한 거 사줄게 / 에어컨 켜! | short [0, 40] | `sweat` |
| `lucide:snowflake` | `cold` | 추워 | 🥶 | 따뜻하게 입어 / 안아서 데워줄게 | buzz [0, 80, 50, 80, 50, 80] | `shiver` |
| `lucide:thermometer-snowflake` | `cold_flu` | 감기 기운 | 🤧 | 따뜻하게 해 / 약 사갈게 | slow [0, 200, 300, 200] | `sick_wobble` |
| `lucide:pill` | `stomachache` | 배 아파 | 😖 | 약 먹었어? / 따뜻한 물 마셔 | slow [0, 200, 300, 200] | `tummy` |
| `lucide:bandage` | `sore` | 몸살 ㅠ | 🤕 | 푹 쉬어 / 죽 사갈게 | slow [0, 200, 300, 200] | `sick_wobble` |

### 먹는 것 (body.tummy)

| 아이콘 | id | 라벨 | 이모지 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| `lucide:utensils` | `hungry` | 배고파 | 🍚 | 밥 사줄게! / 뭐 먹고 싶어? / 배달 시켜줄까? | double [0, 40, 80, 40] | `tummy` |
| `lucide:cookie` | `full` | 배불러 | 🤢 | 많이 먹었구나ㅋㅋ / 산책할까? | soft [0, 120] | `tummy_pat` |
| `lucide:cup-soda` | `thirsty` | 목말라 | 🥤 | 물 마셔! / 음료 사줄게 | short [0, 40] | `drool` |
| `lucide:salad` | `diet` | 다이어트 | 🥗 | 화이팅! / 지금도 예뻐 | short [0, 40] | `breathe` |
| `lucide:pizza` | `midnight_snack` | 야식 ㄱ? | 🍕 | 시켜줄까? / 나도 배고파 | double [0, 40, 80, 40] | `drool` |

## 하고 싶은 것 (want)

### 함께 (want.together)

| 아이콘 | id | 라벨 | 이모지 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| `lucide:hand-heart` | `want_hug` | 안아줘 | 🫂 | 꼬옥 안아줄게 / 달려갈게! | heart [0, 60, 100, 120] | `arms_open` |
| `lucide:phone` | `want_call` | 전화해줘 | 📞 | 지금 걸게! / 5분만 기다려 | double [0, 40, 80, 40] | `phone` |
| `lucide:eye` | `want_see` | 보고 싶어 | 👀 | 나도 보고 싶어 / 오늘 만날까? | heart [0, 60, 100, 120] | `look_around` |
| `lucide:gamepad-2` | `want_play` | 놀자! | 🎮 | 게임 한판? / 지금 놀자! | triple [0, 30, 60, 30, 60, 30] | `play` |
| `lucide:calendar-heart` | `want_date` | 데이트 ㄱ? | 💑 | 이번 주말 어때? / 어디 갈까? | heart [0, 60, 100, 120] | `joy_bounce` |
| `lucide:video` | `want_videocall` | 영통 ㄱ? | 📹 | 지금 걸게! / 잠깐만 기다려 | double [0, 40, 80, 40] | `phone` |
| `lucide:message-circle` | `want_talk` | 내 얘기 좀 | 💬 | 다 들어줄게 / 전화할까? | soft [0, 120] | `phone` |
| `lucide:hand` | `want_pat` | 쓰담해줘 | 🫳 | 쓰담쓰담 / 착하다~ | heart [0, 60, 100, 120] | `tummy_pat` |

### 나들이 (want.outing)

| 아이콘 | id | 라벨 | 이모지 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| `lucide:clapperboard` | `want_movie` | 영화 ㄱ? | 🎬 | 주말에 보자! / 뭐 볼까? | short [0, 40] | `popcorn` |
| `lucide:footprints` | `want_walk` | 산책 ㄱ? | 🚶 | 같이 걷자 / 어디로 갈까? | short [0, 40] | `walk` |
| `lucide:plane` | `want_trip` | 여행 가자 | ✈️ | 어디 가고 싶어? / 계획 짜보자 | triple [0, 30, 60, 30, 60, 30] | `dream` |
| `lucide:coffee` | `want_cafe` | 카페 가자 | ☕ | 카페 가자! / 어디 갈까? | short [0, 40] | `walk` |
| `lucide:shopping-bag` | `want_shopping` | 쇼핑 가자 | 🛍️ | 같이 가자 / 뭐 살 거야? | short [0, 40] | `walk` |
| `lucide:music` | `want_concert` | 공연 보자 | 🎵 | 예매해볼까? / 누구 공연? | triple [0, 30, 60, 30, 60, 30] | `sway` |
| `lucide:camera` | `want_photo` | 사진 찍자 | 📸 | 같이 찍자! / 네컷 가자 | short [0, 40] | `sparkle` |

### 휴식·먹거리 (want.treat)

| 아이콘 | id | 라벨 | 이모지 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| `lucide:cake-slice` | `want_dessert` | 달달한 거 | 🍰 | 디저트 사갈게 / 카페 가자! | double [0, 40, 80, 40] | `drool` |
| `lucide:wine` | `want_drink` | 한잔 ㄱ? | 🍻 | 오늘 콜! / 안주 뭐 할까? | double [0, 40, 80, 40] | `cheers` |
| `lucide:bed` | `want_rest` | 쉬고 싶어 | 🛌 | 푹 쉬어 / 방해 안 할게 | long [0, 400] | `lie_down` |
| `lucide:beef` | `want_meat` | 고기 먹자 | 🥩 | 고기 콜! / 내가 쏜다 | double [0, 40, 80, 40] | `drool` |
| `lucide:soup` | `want_noodles` | 라면 먹자 | 🍜 | 끓여줄게 / 계란 넣어? | double [0, 40, 80, 40] | `drool` |
| `lucide:bath` | `want_bath` | 씻고 쉴래 | 🛁 | 푹 쉬어 / 따뜻하게 씻어 | long [0, 400] | `breathe` |

## 애정 (love)

### 애정 표현 (love.affection)

| 아이콘 | id | 라벨 | 이모지 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| `lucide:heart` | `love_you` | 사랑해 | ❤️ | 나도 사랑해 / 더 많이 사랑해 | heart [0, 60, 100, 120] | `heart_pop` |
| `lucide:message-circle-heart` | `kiss` | 뽀뽀 | 😘 | 쪽! / 나도 뽀뽀 | heart [0, 60, 100, 120] | `kiss` |
| `lucide:heart-pulse` | `flutter` | 설레 | 💓 | 나도 설레 / 두근두근 | heart [0, 60, 100, 120] | `heart_pop` |
| `lucide:flower` | `thinking_of_you` | 네 생각 | 🌸 | 나도 네 생각! / 무슨 생각? | soft [0, 120] | `daydream` |
| `lucide:zap` | `jealous` | 질투나 | 😳 | 너밖에 없어 / 귀여워ㅋㅋ | buzz [0, 80, 50, 80, 50, 80] | `pout` |
| `lucide:cat` | `cute` | 귀여워 | 🐱 | 네가 더 귀여워 / 헤헤 | heart [0, 60, 100, 120] | `sparkle` |
| `lucide:handshake` | `hug_tight` | 꼭 안아 | 🤗 | 얼른 와 / 나도 안아줄게 | heart [0, 60, 100, 120] | `arms_open` |
| `lucide:thumbs-up` | `thanks` | 고마워 | 🙏 | 내가 더 고마워 / 언제든지! | soft [0, 120] | `bow` |
| `lucide:heart-crack` | `sorry` | 미안해 | 🙇 | 괜찮아 / 나도 미안해 / 얘기하자 | slow [0, 200, 300, 200] | `bow_deep` |

### 인사 (love.greeting)

| 아이콘 | id | 라벨 | 이모지 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| `lucide:sunrise` | `good_morning` | 굿모닝 | 🌅 | 좋은 아침! / 잘 잤어? | soft [0, 120] | `breathe` |
| `lucide:car` | `take_care` | 조심히 와 | 🚗 | 응 금방 갈게 / 도착하면 연락할게 | soft [0, 120] | `walk` |
| `lucide:house` | `welcome_home` | 수고했어 | 🏠 | 고마워 / 너도 수고했어 | soft [0, 120] | `bow` |
| `lucide:moon-star` | `good_night` | 잘 자 | 🌙 | 너도 잘 자 / 꿈에서 만나 / 사랑해 굿나잇 | long [0, 400] | `sleep_wave` |

### 응원 (love.support)

| 아이콘 | id | 라벨 | 이모지 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| `lucide:sparkles` | `cheer_up` | 힘내! | 🫶 | 고마워 힘낼게 / 덕분에 힘나 | heart [0, 60, 100, 120] | `cheer` |
| `lucide:medal` | `proud_of_you` | 자랑스러워 | 💌 | 헤헤 고마워 / 네 덕분이야 | triple [0, 30, 60, 30, 60, 30] | `sparkle` |
| `lucide:rocket` | `you_can` | 할 수 있어 | 🚀 | 고마워 힘낼게 / 덕분에 힘나 | triple [0, 30, 60, 30, 60, 30] | `cheer` |
| `lucide:shield` | `with_you` | 내가 있어 | 🛡️ | 고마워 / 든든해 | heart [0, 60, 100, 120] | `arms_open` |
| `lucide:gift` | `congrats` | 축하해! | 🎁 | 고마워! / 같이 축하하자 | triple [0, 30, 60, 30, 60, 30] | `jump` |
