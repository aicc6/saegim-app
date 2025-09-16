# 새김 앱 (SaeGim)

새김은 Flutter로 개발된 모바일 애플리케이션입니다.

## 프로젝트 정보

- **앱 이름**: 새김 (SaeGim)
- **버전**: 0.1.0
- **Flutter SDK**: ^3.9.2
- **플랫폼**: Android, iOS

## 사전 요구사항

- Flutter SDK 3.9.2 이상
- Android Studio (Android 개발용)
- Xcode (iOS 개발용, macOS에서만)
- 에뮬레이터 또는 실제 기기

## 설치 및 설정

### 1. Flutter 환경 설정

```bash
# Flutter 설치 확인
flutter doctor

# 의존성 설치
flutter pub get
```

### 2. 에뮬레이터 설정

#### Android 에뮬레이터

```bash
# 사용 가능한 Android 에뮬레이터 목록 확인
flutter emulators

# Android 에뮬레이터 실행
flutter emulators --launch <emulator_id>

# 또는 Android Studio에서 AVD Manager를 통해 에뮬레이터 생성 후 실행
```

#### iOS 시뮬레이터 (macOS에서만)

```bash
# iOS 시뮬레이터 실행
open -a Simulator

# 또는 Xcode에서 시뮬레이터 실행
```

## 앱 실행

### 개발 모드로 실행

```bash
# 현재 연결된 기기/에뮬레이터에서 실행
flutter run

# 특정 기기에서 실행
flutter run -d <device_id>

# 디버그 모드로 실행
flutter run --debug

# 릴리즈 모드로 실행
flutter run --release
```

### 빌드 및 설치

#### Android APK 빌드

```bash
# 디버그 APK 빌드
flutter build apk --debug

# 릴리즈 APK 빌드
flutter build apk --release

# AAB (Android App Bundle) 빌드
flutter build appbundle --release
```

#### iOS 빌드 (macOS에서만)

```bash
# iOS 앱 빌드
flutter build ios --release
```

### 기기 연결 및 실행

#### Android 기기

```bash
# 연결된 기기 목록 확인
flutter devices

# USB 디버깅이 활성화된 Android 기기 연결 후
flutter run
```

#### iOS 기기 (macOS에서만)

```bash
# iOS 기기 연결 후
flutter run
```

## 개발 명령어

### 핫 리로드

```bash
# 앱 실행 중 'r' 키를 눌러 핫 리로드
# 또는 'R' 키를 눌러 핫 리스타트
```

### 앱 종료

```bash
# 앱 실행 중 'q' 키를 눌러 앱 종료
# 또는 Ctrl+C (Windows/Linux) / Cmd+C (macOS)로 터미널에서 종료

# 특정 기기에서 앱 종료
flutter run --device-id <device_id>
# 실행 후 'q' 키로 종료
```

### 로그 확인

```bash
# Flutter 로그 확인
flutter logs

# 특정 기기의 로그만 확인
flutter logs -d <device_id>
```

### 정리 및 재설치

```bash
# 캐시 정리
flutter clean

# 의존성 재설치
flutter pub get

# 앱 완전 재설치
flutter install
```

## 프로젝트 구조

```
lib/
├── app/                    # 앱 설정 및 라우팅
├── features/              # 기능별 모듈
│   ├── authentication/    # 인증 관련
│   ├── home/             # 홈 화면 관련
│   └── settings/         # 설정 관련
├── shared/               # 공통 위젯 및 유틸리티
└── main.dart             # 앱 진입점
```

## 주요 의존성

- **go_router**: ^14.7.1 - 라우팅 관리
- **provider**: ^6.1.1 - 상태 관리
- **logger**: ^2.0.2+1 - 로깅

## 문제 해결

### 일반적인 문제들

1. **에뮬레이터가 실행되지 않는 경우**

   ```bash
   # Android SDK 경로 확인
   flutter doctor -v

   # 에뮬레이터 재시작
   flutter emulators --launch <emulator_id>
   ```

2. **의존성 문제**

   ```bash
   flutter clean
   flutter pub get
   ```

3. **빌드 오류**
   ```bash
   # Gradle 캐시 정리 (Android)
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

## 추가 정보

- 앱 아이콘 설정은 `assets/icon.png`를 참조합니다.
- 플랫폼별 요구사항은 `docs/platform-requirements.md`를 참조하세요.
- 앱 아이콘 설정 방법은 `docs/app-icon-setup.md`를 참조하세요.
