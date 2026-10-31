# 마음콕 감정 40개 (v3: 대분류 4 · 소분류 12)

진동: `[대기,진동,대기,진동…]` ms (vibration 패키지). 폴백: HapticFeedback.


## 기분 (mood)

### 좋아 (mood.good)

| 이모지 | 아이콘 | id | 라벨 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| 😊 | `lucide:smile` | `happy` | 행복해 | 나도 행복해! / 좋은 일 있었어? / 그 웃음 최고야 | heart [0, 60, 100, 120] | `joy_bounce` |
| 🥰 | `lucide:party-popper` | `excited` | 신나! | 같이 신나! / 무슨 일인데?! | triple [0, 30, 60, 30, 60, 30] | `jump` |
| 😌 | `lucide:leaf` | `calm` | 평온해 | 좋다~ / 나도 마음이 편해져 | soft [0, 120] | `breathe` |
| 🤩 | `lucide:trophy` | `proud` | 뿌듯해 | 역시 최고야! / 자랑스러워 | triple [0, 30, 60, 30, 60, 30] | `sparkle` |

### 가라앉아 (mood.down)

| 이모지 | 아이콘 | id | 라벨 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| 😢 | `lucide:frown` | `sad` | 슬퍼 | 토닥토닥 / 무슨 일이야? 얘기해줘 / 꼭 안아줄게 | slow [0, 200, 300, 200] | `cry` |
| 🥺 | `lucide:cloud-rain` | `lonely` | 외로워 | 지금 전화할까? / 내가 옆에 있을게 / 보고 싶었어 | slow [0, 200, 300, 200] | `droop` |
| 😑 | `lucide:meh` | `bored` | 심심해 | 놀아줄게! / 영상통화 할래? | short [0, 40] | `sway` |

### 예민해 (mood.tense)

| 이모지 | 아이콘 | id | 라벨 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| 😠 | `lucide:angry` | `angry` | 화나 | 누가 그랬어?! / 내가 혼내줄게 / 진정 진정~ | buzz [0, 80, 50, 80, 50, 80] | `fume` |
| 😰 | `lucide:cloud-lightning` | `anxious` | 불안해 | 괜찮아, 내가 있어 / 천천히 숨 쉬어봐 | slow [0, 200, 300, 200] | `shiver` |
| 😤 | `lucide:flame` | `stressed` | 스트레스 | 고생 많았어 / 맛있는 거 먹자 / 내가 다 들어줄게 | buzz [0, 80, 50, 80, 50, 80] | `sigh` |

## 몸 상태 (body)

### 에너지 (body.energy)

| 이모지 | 아이콘 | id | 라벨 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| 😴 | `lucide:moon` | `sleepy` | 졸려 | 토닥토닥 / 얼른 자~ 잘자 / 꿈에서 만나 | long [0, 400] | `doze` |
| 😩 | `lucide:battery-low` | `tired` | 피곤해 | 오늘 수고했어 / 어깨 주물러줄게 / 일찍 쉬자 | long [0, 400] | `slump` |
| 💪 | `lucide:dumbbell` | `energetic` | 힘이 넘쳐 | 멋져! / 그 힘 나한테도 줘 | triple [0, 30, 60, 30, 60, 30] | `flex` |
| 🏃 | `lucide:timer` | `busy` | 바빠 | 파이팅! / 끝나면 연락해 | short [0, 40] | `rush` |

### 컨디션 (body.condition)

| 이모지 | 아이콘 | id | 라벨 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| 🤒 | `lucide:thermometer` | `sick` | 아파 | 약 먹었어? / 죽 사갈게 / 푹 쉬어 | slow [0, 200, 300, 200] | `sick_wobble` |
| 🤕 | `lucide:brain-circuit` | `headache` | 머리 아파 | 약 챙겨 먹어 / 조금 쉬어 | slow [0, 200, 300, 200] | `head_hold` |
| 🥵 | `lucide:sun` | `hot` | 더워 | 시원한 거 사줄게 / 에어컨 켜! | short [0, 40] | `sweat` |
| 🥶 | `lucide:snowflake` | `cold` | 추워 | 따뜻하게 입어 / 안아서 데워줄게 | buzz [0, 80, 50, 80, 50, 80] | `shiver` |

### 배 (body.tummy)

| 이모지 | 아이콘 | id | 라벨 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| 🍚 | `lucide:utensils` | `hungry` | 배고파 | 밥 사줄게! / 뭐 먹고 싶어? / 배달 시켜줄까? | double [0, 40, 80, 40] | `tummy` |
| 🤢 | `lucide:cookie` | `full` | 배불러 | 많이 먹었구나ㅋㅋ / 산책할까? | soft [0, 120] | `tummy_pat` |

## 하고 싶은 것 (want)

### 함께 (want.together)

| 이모지 | 아이콘 | id | 라벨 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| 🫂 | `lucide:hand-heart` | `want_hug` | 안아줘 | 꼬옥 안아줄게 / 달려갈게! | heart [0, 60, 100, 120] | `arms_open` |
| 📞 | `lucide:phone` | `want_call` | 전화하고 싶어 | 지금 걸게! / 5분만 기다려 | double [0, 40, 80, 40] | `phone` |
| 👀 | `lucide:eye` | `want_see` | 보고 싶어 | 나도 보고 싶어 / 오늘 만날까? | heart [0, 60, 100, 120] | `look_around` |
| 🎮 | `lucide:gamepad-2` | `want_play` | 같이 놀고 싶어 | 게임 한판? / 지금 놀자! | triple [0, 30, 60, 30, 60, 30] | `play` |

### 나들이 (want.outing)

| 이모지 | 아이콘 | id | 라벨 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| 🎬 | `lucide:clapperboard` | `want_movie` | 영화 보고 싶어 | 주말에 보자! / 뭐 볼까? | short [0, 40] | `popcorn` |
| 🚶 | `lucide:footprints` | `want_walk` | 산책하고 싶어 | 같이 걷자 / 어디로 갈까? | short [0, 40] | `walk` |
| ✈️ | `lucide:plane` | `want_trip` | 여행 가고 싶어 | 어디 가고 싶어? / 계획 짜보자 | triple [0, 30, 60, 30, 60, 30] | `dream` |

### 휴식·간식 (want.treat)

| 이모지 | 아이콘 | id | 라벨 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| 🍰 | `lucide:cake-slice` | `want_dessert` | 달달한 거 먹고 싶어 | 디저트 사갈게 / 카페 가자! | double [0, 40, 80, 40] | `drool` |
| 🍻 | `lucide:wine` | `want_drink` | 한잔하고 싶어 | 오늘 콜! / 안주 뭐 할까? | double [0, 40, 80, 40] | `cheers` |
| 🛌 | `lucide:bed` | `want_rest` | 쉬고 싶어 | 푹 쉬어 / 방해 안 할게 | long [0, 400] | `lie_down` |

## 애정 (love)

### 애정 표현 (love.affection)

| 이모지 | 아이콘 | id | 라벨 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| ❤️ | `lucide:heart` | `love_you` | 사랑해 | 나도 사랑해 / 더 많이 사랑해 | heart [0, 60, 100, 120] | `heart_pop` |
| 😘 | `lucide:message-circle-heart` | `kiss` | 뽀뽀 | 쪽! / 나도 뽀뽀 | heart [0, 60, 100, 120] | `kiss` |
| 🥹 | `lucide:hourglass` | `miss_you` | 보고싶어 | 나도 너무 보고싶어 / 곧 만나자 | slow [0, 200, 300, 200] | `longing` |
| 🌸 | `lucide:flower` | `thinking_of_you` | 네 생각 중 | 나도 네 생각! / 무슨 생각? | soft [0, 120] | `daydream` |
| 😳 | `lucide:zap` | `jealous` | 질투나 | 너밖에 없어 / 귀여워ㅋㅋ | buzz [0, 80, 50, 80, 50, 80] | `pout` |

### 마음 전하기 (love.words)

| 이모지 | 아이콘 | id | 라벨 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| 🙏 | `lucide:thumbs-up` | `thanks` | 고마워 | 내가 더 고마워 / 언제든지! | soft [0, 120] | `bow` |
| 🙇 | `lucide:heart-crack` | `sorry` | 미안해 | 괜찮아 / 나도 미안해 / 얘기하자 | slow [0, 200, 300, 200] | `bow_deep` |
| 🌙 | `lucide:moon-star` | `good_night` | 잘 자 | 너도 잘 자 / 꿈에서 만나 / 사랑해 굿나잇 | long [0, 400] | `sleep_wave` |

### 응원 (love.support)

| 이모지 | 아이콘 | id | 라벨 | 추천 반응 | 진동(ms) | 애니메이션 |
|---|---|---|---|---|---|---|
| 🫶 | `lucide:sparkles` | `cheer_up` | 힘내 | 고마워 힘낼게 / 덕분에 힘나 | heart [0, 60, 100, 120] | `cheer` |
| 💌 | `lucide:medal` | `proud_of_you` | 자랑스러워 | 헤헤 고마워 / 네 덕분이야 | triple [0, 30, 60, 30, 60, 30] | `sparkle` |
