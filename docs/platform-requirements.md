# 새김 앱 플랫폼 요구사항 및 개발 환경 설정

## 📋 목차

- [플랫폼 최소 버전 요구사항](#플랫폼-최소-버전-요구사항)
- [타겟층 분석](#타겟층-분석)
- [Android 에뮬레이터 전략](#android-에뮬레이터-전략)
- [개발 환경 설정](#개발-환경-설정)
- [테스트 전략](#테스트-전략)

---

## 플랫폼 최소 버전 요구사항

### 🎯 권고 설정

| 플랫폼 | 현재 설정 | 권고 설정 | 커버리지 | 근거 |
|--------|-----------|-----------|----------|------|
| **iOS** | 13.0 | **15.0** | 95%+ | PWA 완전 지원, Safari 성능 개선 |
| **Android** | Flutter 기본값 | **API 30 (Android 11)** | 85%+ | PWA 최적화, 파일 시스템 API 개선 |

### 📱 타겟층 특성

#### 핵심 페르소나

- **김서연 (28세)**: 마케팅 대리, 감성적 여행 기록
- **이준호 (35세)**: IT PM, 체계적 회고 분석
- **정하늘 (26세)**: UX 디자이너, 감정 관리 실천

#### 공통 특성

- **연령대**: 20-40대 (디지털 네이티브)
- **기기 사용 패턴**: 스마트폰 중심, 높은 최신 버전 채택률
- **한국 시장**: Samsung 82%, Apple 18%

---

## Android 에뮬레이터 전략

### 🎯 개발팀 표준 전략

#### Phase 1: Primary Development (통일)

```bash
# 주 개발용 에뮬레이터
API Level: 30 (Android 11)
Target: Google APIs with Play Store
Architecture: x86_64
```

**생성 명령어**:

```bash
avdmanager create -n saegim_dev -k "system-images;android-30;google_apis_playstore;x86_64"
```

#### Phase 2: 로컬 테스트 (병행)

- **API 30**: 최소 지원 버전 검증
- **API 34**: 현재 주류 버전 검증 (Android 14, 33.67% 점유율)

#### Phase 3: CI/CD (고정)

```yaml
# GitHub Actions 설정 예시
android_emulator:
  api-level: 30
  target: google_apis_playstore
  arch: x86_64
```

#### Phase 4: QA 매트릭스 테스트

- **API 30**: 최소 지원 기능 검증
- **API 33**: 중간 버전 호환성
- **API 34**: 최신 안정 성능 검증

### 🛠️ 새김 특화 에뮬레이터 설정

#### 필수 설정 (이미지 업로드 고려)

```bash
Internal Storage: 4GB           # 사진 업로드용
SD Card: 512MB                  # 대용량 파일 테스트
RAM: 3GB                        # Flutter 앱 최적화
VM Heap: 256MB                  # 메모리 최적화
Front Camera: Webcam0           # 카메라 기능
Back Camera: Webcam0            # 카메라 기능
```

#### 성능 최적화 실행 명령어

```bash
# 성능 최적화된 에뮬레이터 실행
emulator @saegim_dev -gpu host -memory 3072 -cores 4

# Flutter 핫 리로드 최적화
flutter run -d emulator-5554 --hot
```

---

## 개발 환경 설정

### iOS 설정 변경

**파일**: `ios/Runner.xcodeproj/project.pbxproj`

다음 세 곳의 설정을 모두 변경:

```xml
IPHONEOS_DEPLOYMENT_TARGET = 15.0;
```

**변경 위치**:

- Line 349 (Profile 설정)
- Line 476 (Debug 설정)
- Line 527 (Release 설정)

### Android 설정 변경

**파일**: `android/app/build.gradle.kts`

```kotlin
defaultConfig {
    applicationId = "com.aicc_project.saegim"
    minSdk = 30  // Android 11 (API 30)
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

### 설정 후 검증

```bash
flutter clean
flutter pub get
flutter build android --debug
flutter build ios --debug
```

---

## 테스트 전략

### 👥 팀 워크플로우

#### 일일 개발

- **모든 개발자**: API 30 에뮬레이터 사용
- **기본 기능 검증**: 카메라, 파일 업로드, UI

#### 주간 테스트

- **매주 금요일**: API 34에서 호환성 검증
- **핵심 기능**: 전체 사용자 플로우 테스트

#### 릴리즈 전 검증

- **매트릭스 테스트**: API 30, 33, 34
- **실기기 테스트**: Samsung Galaxy (주요 타겟)
- **성능 측정**: 로딩 시간, 메모리 사용량

### 🧪 테스트 매트릭스

| 기능 | API 30 (매일) | API 33 (주간) | API 34 (릴리즈) | 실기기 |
|------|---------------|---------------|-----------------|---------|
| 🎨 기본 UI | ✅ | ✅ | ✅ | 📱 |
| 📷 카메라/갤러리 | ✅ | ✅ | ✅ | 📱 |
| 📁 파일 업로드 | ✅ | ✅ | ✅ | 📱 |
| 🔔 알림 기능 | 주간 | ✅ | ✅ | 📱 |
| 🤖 AI 글귀 생성 | ✅ | ✅ | ✅ | 📱 |
| 📊 감정 분석 | 주간 | ✅ | ✅ | 📱 |

---

## 성능 최적화 팁

### 에뮬레이터 최적화

1. **Hardware Acceleration** 활성화
2. **적절한 리소스 할당** (RAM 3GB, 4 cores)
3. **GPU 가속** 활성화 (`-gpu host`)
4. **Quick Boot** 사용 (Cold Boot 대신)
5. **Snapshot 기능** 활용

### 개발 효율성

- 정기적인 에뮬레이터 재시작 (메모리 정리)
- 불필요한 Google 기본 앱 제거
- AVD Manager에서 디스크 공간 정리

### Flutter 특화 최적화

```bash
# 핫 리로드 성능 향상
flutter run --hot

# 빌드 캐시 정리 (문제 발생 시)
flutter clean && flutter pub get

# 디버그 성능 프로파일링
flutter run --profile
```

---

## 트러블슈팅

### 일반적인 문제와 해결책

#### 에뮬레이터 느림 현상

```bash
# 해결 방법
1. AVD RAM을 3GB로 증가
2. -gpu host 옵션 사용
3. HAXM/Hyper-V 설정 확인
```

#### 카메라 기능 오류

```bash
# 해결 방법
1. AVD에서 Front/Back Camera를 Webcam0으로 설정
2. 호스트 시스템 카메라 권한 확인
3. Google Play Store 포함 이미지 사용
```

#### 파일 업로드 문제

```bash
# 해결 방법
1. 충분한 Internal Storage 할당 (4GB)
2. SD Card 추가 설정
3. 파일 권한 설정 확인
```

---

## 추가 리소스

### 관련 문서

- [Flutter 공식 Android 설정 가이드](https://docs.flutter.dev/get-started/install/windows#android-setup)
- [Android 에뮬레이터 최적화 가이드](https://developer.android.com/studio/run/emulator-acceleration)

### 팀 컨벤션

- **코드 스타일**: `flutter_lints: ^5.0.0` 사용
- **브랜치 전략**: feature branch에서 개발 후 PR
- **테스트 커버리지**: 핵심 기능 80% 이상

---

*이 문서는 새김 프로젝트의 개발 환경 표준화를 위한 가이드입니다. 문의사항이 있으면 개발팀에 연락해주세요.*
