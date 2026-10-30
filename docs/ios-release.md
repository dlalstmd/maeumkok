# iOS TestFlight 배포 (마음콕 전용)

워크플로: `.github/workflows/ios-testflight.yml` (Actions에서 수동 실행 또는 `v*` 태그 push).
흐름: flutter build ios --no-codesign → fastlane `beta` (수동 서명 archive → TestFlight 업로드).

## 필요한 GitHub Secrets (값은 저장소에 커밋 금지)
| 이름 | 내용 |
|---|---|
| APPLE_TEAM_ID | Apple Developer Team ID (10자) |
| ASC_KEY_ID | App Store Connect API 키 ID |
| ASC_ISSUER_ID | App Store Connect API Issuer ID |
| ASC_KEY_P8_BASE64 | AuthKey_XXXX.p8 의 base64 |
| IOS_DIST_CERT_P12_BASE64 | Apple Distribution 인증서(.p12) base64 |
| IOS_DIST_CERT_PASSWORD | 위 .p12 비밀번호 |
| IOS_PROVISION_PROFILE_BASE64 | com.maeumkok.app App Store 프로비저닝 프로필 base64 |
| KEYCHAIN_PASSWORD | CI 임시 키체인 비밀번호(아무 임의 문자열) |

## Apple Developer / App Store Connect 준비
1. App ID `com.maeumkok.app` 등록, Capabilities: **Push Notifications**, **Sign in with Apple** 켜기.
2. 위 App ID로 App Store 프로비저닝 프로필 생성(Push·Apple 로그인 포함 상태에서 생성).
3. App Store Connect에 앱 레코드 생성(번들 com.maeumkok.app).
4. APNs 인증 키(.p8)를 Firebase 콘솔 > 프로젝트 설정 > Cloud Messaging > Apple 앱에 업로드(iOS 푸시).
5. Apple 로그인: Services ID + Sign in with Apple 키 생성 후 Firebase Auth의 Apple 제공자 활성화(대기 중).

entitlements: `ios/Runner/Runner.entitlements` (applesignin Default, aps-environment production).
