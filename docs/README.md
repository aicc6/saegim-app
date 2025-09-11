# 새김 앱 개발 문서

새김(SaeGim) Flutter 앱의 개발 환경 설정과 플랫폼 요구사항에 대한 종합 가이드입니다.

## 📚 문서 목록

### 🔧 개발 환경

- **[플랫폼 요구사항 및 개발 환경 설정](./platform-requirements.md)**
  - iOS/Android 최소 버전 설정
  - 에뮬레이터 전략 및 설정
  - 개발팀 워크플로우
  - 성능 최적화 가이드

## 🚀 빠른 시작

### 1. 플랫폼 최소 버전 설정

```bash
# iOS: 15.0, Android: API 30 (Android 11)
```

### 2. 권장 에뮬레이터 설정

```bash
# 주 개발용 에뮬레이터 생성
avdmanager create -n saegim_dev -k "system-images;android-30;google_apis_playstore;x86_64"

# 성능 최적화 실행
emulator @saegim_dev -gpu host -memory 3072 -cores 4
```

### 3. 프로젝트 설정 검증

```bash
flutter clean
flutter pub get
flutter build android --debug
flutter build ios --debug
```

## 🎯 타겟층 요약

- **연령대**: 20-40대 디지털 네이티브
- **핵심 페르소나**: 김서연(28세), 이준호(35세), 정하늘(26세)
- **시장 특성**: Samsung 82%, Apple 18% (한국)
- **예상 커버리지**: iOS 15+ (95%), Android API 30+ (85%)

## 📱 개발 환경 매트릭스

| 용도 | iOS | Android | 에뮬레이터 |
|------|-----|---------|------------|
| **일일 개발** | iOS 15+ | API 30 | 통일 |
| **주간 테스트** | iOS 15+ | API 30, 34 | 병행 |
| **CI/CD** | iOS 15+ | API 30 | 고정 |
| **QA 검증** | iOS 15+ | API 30, 33, 34 | 매트릭스 |

## 🛠️ 주요 설정 변경사항

### iOS 업데이트

```
IPHONEOS_DEPLOYMENT_TARGET = 15.0;  // 기존: 13.0
```

### Android 업데이트

```kotlin
minSdk = 30  // 기존: flutter.minSdkVersion
```

---

더 자세한 내용은 각 문서를 참고해주세요. 개발 과정에서 문의사항이 있으면 언제든 개발팀에 연락해주세요.
