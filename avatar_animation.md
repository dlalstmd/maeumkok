# 마음콕 아바타 파츠 & 감정 애니메이션 콘셉트

## 1. 파츠 구성 (총 옵션)
| 파츠 | 옵션 수 | 비고 |
|---|---|---|
| 얼굴형 | 4 | 동글, 갸름, 찹쌀떡(넓음), 하트 |
| 피부톤 | 6 | 아이보리~딥브라운 (색만 교체) |
| 눈 | 8 | 동글, 반달, 점눈, 초롱, 졸린, 윙크용 세트 포함 |
| 입 | 6 | 스마일, ㅅ자, 오, 고양이입, 헤벌쭉, 일자 (감정별 오버라이드) |
| 볼터치 | 4 + 없음 | 원형, 타원, 빗금, 하트 / 색 3 |
| 헤어 | 12 (색 8) | 앞머리/뒷머리 분리 레이어 |
| 모자/액세서리 | 10 + 없음 | 비니, 캡, 리본, 머리띠(곰귀/토끼귀), 안경, 꽃핀, 헤드폰… |
| 옷 | 8 (색 6) | 후드, 니트, 셔츠, 멜빵, 파자마… |

## 2. 레이어 구조 (아래→위, Rive/Lottie 공통)
```
Avatar (root, 512x512)
├─ shadow
├─ body/ (clothes_back, torso, clothes_front, arms_L, arms_R)
├─ hair_back
├─ head/
│  ├─ face_shape (skin fill)
│  ├─ blush
│  ├─ eyes/ (eye_L, eye_R, eyelid_L, eyelid_R)  ← blink
│  ├─ brows
│  ├─ mouth (swap by emotion)
│  └─ fx_face (눈물, 땀, 홍조)
├─ hair_front
├─ accessory
└─ fx_overlay (하트, Zzz, 김, 반짝이 파티클)
```
파츠 교체는 Rive 6+ Data Binding / 이미지 asset 교체, 또는 Flutter에서 레이어 스택(Stack of SVG)으로 처리.

## 3. Rive 상태머신 `AvatarSM`
**Inputs**
- `emotion` (Number, 0~39: emotions.json 인덱스) 또는 `anim_key` 매핑 테이블
- `play` (Trigger) — 감정 수신 시 재생
- `intensity` (Number 0~1)
- `is_sender` (Boolean) — 내가 보낸 미리보기는 축소판
- `tap` (Trigger) — 아바타 터치 반응(꺄르르)
- `sleep_mode` (Boolean) — 밤 22시 이후 idle 변형

**Layers**
1. Base: `Idle` (2.4s 숨쉬기: scaleY 1→1.02, 몸 2px 상하) ↔ `Sleep_Idle`
2. Blink: 2.5~5s 랜덤 간격 eyelid 120ms 닫힘/열림, 15% 확률 더블 블링크
3. Emotion: `Any State --(play && emotion==n)--> Emo_n (1.5~2.5s) --> Exit → Idle`
4. FX: 파티클 레이어 (emotion별 on/off)

## 4. 감정별 모션 (animation_key)
| key | 모션 |
|---|---|
| joy_bounce / jump | 두 번 통통 튐, 눈 반달, 볼터치 진해짐 |
| cry / droop / longing | 고개 숙임, 눈물 방울 2개 낙하, 어깨 처짐 |
| fume / pout | 볼 부풀림, 머리 위 김, 좌우 미세 떨림 |
| shiver | 빠른 x축 ±2px 진동, 파랗게 틴트 |
| doze / sleep_wave | 고개 끄덕, Zzz 파티클, 눈 반쯤 감김 |
| tummy / drool / tummy_pat | 배 문지르기, 꼬르륵 말풍선, 침 |
| sick_wobble / head_hold | 이마에 수건, 느린 흔들림 |
| heart_pop / kiss / arms_open | 하트 3개 팝, 팔 벌림, 쪽 입모양 |
| sparkle / flex / cheer | 반짝이, 팔 올림 |
| 기타 (sway, sigh, rush, walk, popcorn, phone, …) | 해당 소품 1개 + 2초 루프 |

## 5. Lottie 대안
- 파츠 조합 수가 많아 Lottie는 **베이스 아바타 1종 + 감정 오버레이(FX) 40개**로 분리: `lottie/fx_{animation_key}.json`
- 아바타 본체는 Flutter `AnimatedBuilder`로 breathe/blink/bounce 트랜스폼, 위에 Lottie FX를 겹침.
- 장점: 디자이너 툴(AE+Bodymovin) 익숙함 / 단점: 파츠 교체·상태 전환은 코드 책임.
- 권장: Rive(`rive` 패키지) 1순위, 런타임 용량 제약 시 Lottie 폴백.
