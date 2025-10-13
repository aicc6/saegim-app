# STT(Speech-to-Text) 기능 구현 가이드

## 📋 개요

새김 앱에 음성 인식을 통한 다이어리 작성 기능이 추가되었습니다. 사용자는 마이크 버튼을 눌러 음성으로 글을 입력할 수 있습니다.

## 🎯 주요 기능

### 1. 음성 인식 기능

- **실시간 음성 인식**: 사용자의 음성을 실시간으로 텍스트로 변환
- **한국어 지원**: 기본 언어로 한국어 설정 (`ko_KR`)
- **커서 위치 삽입**: 인식된 텍스트가 현재 커서 위치에 자동 삽입
- **토글 방식**: 마이크 버튼을 눌러 시작/중지

### 2. 권한 관리

- **자동 권한 요청**: 첫 사용 시 자동으로 마이크 권한 요청
- **권한 상태 확인**: 권한이 없으면 사용자에게 안내 메시지 표시
- **설정 안내**: 권한이 영구적으로 거부된 경우 설정으로 안내

## 🏗️ 구조

### 파일 구조

```
lib/
├── core/
│   └── services/
│       └── stt_service.dart          # STT 서비스 싱글톤
├── features/
│   └── create/
│       └── createid.dart              # 글 작성 페이지 (STT 통합)
└── shared/
    └── utils/
        └── app_logger.dart            # 로깅 유틸리티
```

### 플랫폼 설정

```
android/
└── app/
    └── src/
        └── main/
            └── AndroidManifest.xml    # Android 권한 설정

ios/
└── Runner/
    └── Info.plist                     # iOS 권한 설명
```

## 🔧 구현 세부사항

### 1. STT Service (`lib/core/services/stt_service.dart`)

#### 주요 메서드

- `initialize()`: STT 서비스 초기화 및 권한 확인
- `startListening()`: 음성 인식 시작
- `stopListening()`: 음성 인식 중지
- `cancelListening()`: 음성 인식 취소
- `dispose()`: 리소스 정리

#### 특징

- **싱글톤 패턴**: 앱 전체에서 하나의 인스턴스만 사용
- **에러 핸들링**: 모든 STT 관련 에러를 로깅하고 적절히 처리
- **상태 관리**: `isInitialized`, `isListening` 상태 추적

### 2. UI 통합 (`lib/features/create/createid.dart`)

#### 추가된 상태 변수

```dart
final SttService _sttService = SttService();
bool _isListening = false;
```

#### 주요 메서드

- `_initializeStt()`: 페이지 로드 시 STT 서비스 초기화
- `_toggleStt()`: 음성 인식 시작/중지 토글
- 텍스트 삽입: 커서 위치에 인식된 텍스트 추가

#### UI 컴포넌트

```dart
// 마이크 버튼과 상태 표시
Row(
  children: [
    Text(_isListening ? '음성 인식 중...' : '음성으로 입력하기'),
    IconButton(
      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
      onPressed: _toggleStt,
      color: _isListening ? Colors.red : Colors.green,
    ),
  ],
)
```

### 3. 권한 설정

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<!-- STT(음성 인식)를 위한 마이크 권한 -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>음성으로 다이어리를 작성하기 위해 마이크에 접근합니다.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>음성을 텍스트로 변환하여 다이어리를 작성하기 위해 음성 인식 기능이 필요합니다.</string>
```

## 📦 의존성

### pubspec.yaml

```yaml
dependencies:
  speech_to_text: ^7.0.0      # STT 기능
  permission_handler: ^11.3.1  # 권한 관리
```

## 🎨 사용자 경험

### 정상 플로우

1. 사용자가 글 작성 페이지에서 수정 모드 진입
2. 마이크 버튼 클릭
3. 마이크 권한 요청 (처음 사용 시)
4. 음성 인식 시작 (버튼 색상이 빨간색으로 변경)
5. 사용자가 음성으로 내용 입력
6. 인식된 텍스트가 실시간으로 TextField에 추가
7. 다시 마이크 버튼을 눌러 인식 중지

### 에러 처리

- **권한 거부**: "음성 인식을 시작할 수 없습니다. 마이크 권한을 확인해주세요." 메시지 표시
- **초기화 실패**: 로그에 에러 기록 후 사용자에게 안내
- **인식 실패**: STT 서비스 내부에서 에러 로깅

## 🔍 디버깅

### 로그 확인

모든 STT 관련 동작은 `AppLogger`를 통해 로깅됩니다:

```dart
AppLogger.info('STT Service initialized successfully', 'SttService');
AppLogger.error('Failed to start listening: $e', 'SttService');
```

### 주요 로그 메시지

- `STT Service initialized successfully`: 초기화 성공
- `Microphone permission denied`: 권한 거부
- `Started listening`: 음성 인식 시작
- `Stopped listening`: 음성 인식 중지
- `Recognized: {text} (Final: {boolean})`: 인식된 텍스트

## 🧪 테스트 방법

### 수동 테스트

1. 앱 실행
2. 글 작성 페이지로 이동 (`/post/{id}`)
3. 수정 버튼 클릭
4. 글 본문 영역 하단의 마이크 버튼 클릭
5. 권한 허용 (처음 사용 시)
6. 음성 입력 테스트
7. 인식 결과 확인

### 권한 테스트

1. 앱 설정에서 마이크 권한 거부
2. 마이크 버튼 클릭
3. 에러 메시지 확인
4. 권한 재요청 또는 설정으로 안내 확인

## 🚀 향후 개선 사항

### 단기 개선

- [ ] 음성 인식 중 애니메이션 효과 추가
- [ ] 인식된 텍스트 미리보기 기능
- [ ] 음성 인식 타임아웃 설정
- [ ] 백그라운드 소음 필터링

### 장기 개선

- [ ] 다국어 지원 (영어, 일본어 등)
- [ ] 사용자 음성 프로필 학습
- [ ] 오프라인 음성 인식
- [ ] 음성 명령어 지원

## 📝 참고사항

### 제약사항

- **네트워크 필요**: 음성 인식은 온라인 상태에서만 작동 (기본 설정)
- **배터리 소모**: 장시간 음성 인식 사용 시 배터리 소모 증가
- **정확도**: 주변 소음이 많으면 인식 정확도 저하

### 권장사항

- 조용한 환경에서 사용
- 명확한 발음으로 말하기
- 짧은 문장 단위로 입력
- 정기적으로 인식을 중지하고 결과 확인

## 🔗 관련 문서

- [speech_to_text 패키지 문서](https://pub.dev/packages/speech_to_text)
- [permission_handler 패키지 문서](https://pub.dev/packages/permission_handler)
- [Flutter 권한 처리 가이드](https://docs.flutter.dev/development/data-and-backend/permissions)

---

**작성일**: 2025년 10월 13일
**버전**: 1.0.0
**작성자**: GitHub Copilot
