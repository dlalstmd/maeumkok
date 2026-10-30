# iOS TestFlight 배포 (마음콕 전용)

워크플로: `.github/workflows/ios-testflight.yml` (Actions에서 수동 실행 또는 `v*` 태그 push).
흐름: flutter build ios --no-codesign → xcodebuild archive(무서명) → 엔타이틀먼트 주입 → exportArchive(-allowProvisioningUpdates, API 키 자동 서명) → altool 업로드. (꾸준 habit-tracker 방식과 동일, match 미사용)

## 필요한 GitHub Secrets (dlalstmd/maeumkok, 값은 커밋 금지)
| 이름 | 내용 |
|---|---|
| ASC_KEY_ID | App Store Connect API 키 ID (68S925NZDX 또는 J7846WGK3Q 중 ASC 키) |
| ASC_ISSUER_ID | App Store Connect > 사용자 및 액세스 > 통합 > Issuer ID |
| ASC_KEY_P8_B64 | 해당 AuthKey_<KEY_ID>.p8 의 base64 (한 줄) |

Team ID 837A3LFV2K는 워크플로·Xcode 프로젝트에 직접 기재(비밀 아님). 인증서·프로필은 API 키로 Xcode 자동 서명이 생성/재사용(새 시크릿 불필요).

등록 명령(박스, 키 내용 출력 없음, 파일 이동 없음):
```
base64 -w0 /home/box/secrets/kkujun/AuthKey_<KEY_ID>.p8 | gh secret set ASC_KEY_P8_B64 -R dlalstmd/maeumkok
gh secret set ASC_KEY_ID -R dlalstmd/maeumkok -b <KEY_ID>
gh secret set ASC_ISSUER_ID -R dlalstmd/maeumkok -b <ISSUER_ID>
```

## Apple Developer / App Store Connect 준비
1. App ID `com.maeumkok.app` 등록, Capabilities: **Push Notifications**, **Sign in with Apple** 켜기.
2. 프로비저닝 프로필은 export 시 자동 생성(수동 생성 불필요). 기존 배포 인증서 재사용, 새로 만들지 않음.
3. App Store Connect에 앱 레코드 생성(번들 com.maeumkok.app).
4. APNs 인증 키(.p8)를 Firebase 콘솔 > 프로젝트 설정 > Cloud Messaging > Apple 앱에 업로드(iOS 푸시).
5. Apple 로그인: Services ID + Sign in with Apple 키 생성 후 Firebase Auth의 Apple 제공자 활성화(대기 중).

entitlements: `ios/Runner/Runner.entitlements` (applesignin Default, aps-environment production).
