# Firebase Cloud Messaging (FCM) 연동 가이드

이 문서는 `saegim` Flutter 애플리케이션에 Firebase Cloud Messaging(FCM)을 설정하고 사용하는 방법을 안내합니다. Firebase를 통한 푸시 알림 발송을 시작하기 위해 아래 단계를 순차적으로 진행하세요.

## 1. Firebase 프로젝트 준비

1. [Firebase Console](https://console.firebase.google.com/)에서 새 프로젝트를 생성하거나 기존 프로젝트를 사용합니다.
2. 프로젝트 설정에서
   - **Android 앱**을 추가하고 `com.aicc_project.saegim` 번들을 등록합니다.
   - **iOS 앱**을 추가하고 동일한 번들을 등록합니다.
3. 각 플랫폼별 구성 파일을 다운로드합니다.
   - Android: `google-services.json`
   - iOS: `GoogleService-Info.plist`
4. FlutterFire CLI를 사용할 경우 다음 명령으로 자동 생성할 수 있습니다.

   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure --project=<firebase-project-id>
   ```

   > CLI가 생성한 `firebase_options.dart`는 현재 코드에 필수는 아니지만, 여러 Firebase 앱을 관리하거나 웹을 지원하려면 사용하는 것을 권장합니다.

## 2. 프로젝트에 구성 파일 추가

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

> 민감 정보이므로 버전 관리에서 제외되어야 합니다. CI/CD나 배포 파이프라인에서 별도로 주입하세요.

## 3. Flutter 의존성

`pubspec.yaml`에는 다음 패키지가 추가되어 있습니다.

```yaml
dependencies:
  firebase_core: ^4.1.0
  firebase_messaging: ^16.0.1
```

`flutter pub get`을 실행하여 의존성을 설치합니다. 또한 FlutterFire CLI가 생성한 `lib/firebase_options.dart`를 사용해 플랫폼별 초기화 옵션을 버전 관리할 수 있습니다.

## 4. Android 설정

1. `android/settings.gradle.kts`에 Google Services 플러그인이 등록되었습니다.
2. `android/app/build.gradle.kts`에서 `com.google.gms.google-services` 플러그인이 적용되었습니다. 빌드 시 자동으로 `google-services.json`을 읽어들입니다.
3. `android/app/src/main/AndroidManifest.xml`에 Android 13 이상을 위한 `POST_NOTIFICATIONS` 권한이 선언되어 있습니다. 실제 런타임 권한 요청은 `firebase_messaging`의 `requestPermission()` 호출에서 이루어집니다.
4. 필요 시 커스텀 Notification Channel이 필요하다면 Android 네이티브 코드(또는 `flutter_local_notifications`)에서 채널을 생성하세요. 디폴트 채널(`fcm_fallback_notification_channel`)이 기본값으로 사용됩니다.

## 5. iOS 설정

1. `ios/Runner/AppDelegate.swift`
   - `FirebaseApp.configure()`가 호출되어 Firebase가 초기화됩니다.
   - `UNUserNotificationCenter` delegate 등록 및 `registerForRemoteNotifications()` 호출로 APNs 토큰을 수신합니다.
   - APNs 토큰은 `FirebaseMessaging`에 전달되어 FCM 토큰과 매핑됩니다.
2. `ios/Runner/Info.plist`
   - `UIBackgroundModes`에 `remote-notification`이 추가되어 백그라운드 푸시 처리를 허용합니다.
3. Xcode에서 `Runner` 타겟 Capabilities에 **Push Notifications**와 **Background Modes > Remote notifications**를 활성화하고, `Runner.entitlements`에 `aps-environment` 키가 포함되도록 설정하세요.

## 6. Dart 초기화 로직

`lib/bootstrap.dart`에서 다음과 같은 초기화가 수행됩니다.

- `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`으로 플랫폼별 Firebase 구성을 명시적으로 적용합니다.
- `FirebaseMessaging.onBackgroundMessage(...)`가 등록되어 앱이 종료된 상태에서도 메시지를 처리합니다.
- 플랫폼별로 알림 권한을 요청하고, 발급된 FCM 토큰을 로깅합니다.
- 포그라운드/백그라운드 메시지를 수신할 때마다 `AppLogger`를 통해 로그가 남습니다.

필요 시 `FirebaseMessaging.onMessage`/`onMessageOpenedApp` 리스너에서 UI 라우팅이나 상태 갱신 로직을 추가하세요.

## 7. 토큰 관리 및 서버 연동

- `FirebaseMessaging.instance.getToken()`으로 현재 디바이스의 등록 토큰을 획득합니다.
- 토큰은 사용자의 계정 정보와 함께 백엔드 서버로 안전하게 전송하고 저장하세요.
- 로그에는 토큰이 출력되지만, 프로덕션에서는 민감한 정보이므로 서버 전송 이후 로그를 제거하는 것을 권장합니다.

## 8. 테스트 방법

1. 디버그로 앱을 실행하고 초기화 로그를 확인합니다.
2. Firebase Console > Cloud Messaging에서 테스트 메시지를 전송합니다.
   - Android: 앱이 실행 중일 때 콘솔 로그에서 `포그라운드 메시지 수신` 로그를 확인합니다.
   - iOS: 권한 팝업을 허용해야 알림이 도착합니다.
3. 앱을 완전히 종료한 뒤 메시지를 전송하여 `백그라운드 메시지를 처리했습니다` 로그가 출력되는지 확인합니다. (Android는 `adb logcat`, iOS는 Xcode 콘솔 참조)

## 9. 문제 해결 체크리스트

- 토큰이 발급되지 않는다면 네트워크 상태 및 Firebase 프로젝트 권한을 확인하세요.
- iOS에서 알림이 오지 않으면 APNs 인증 키/인증서가 Firebase Console에 등록되어 있는지 확인합니다.
- Android 13 이상에서 알림이 표시되지 않으면 설정 앱에서 알림 권한이 허용되었는지 확인합니다.
- FCM과 다른 Firebase 서비스를 추가하려면 `Firebase.initializeApp()` 이후에 각 서비스 초기화 코드를 추가하면 됩니다.

위 단계를 완료하면 `saegim` 앱에서 Firebase Cloud Messaging을 활용한 푸시 알림 기능을 사용할 수 있습니다.
