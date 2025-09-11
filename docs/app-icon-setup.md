# 새김 앱 아이콘 설정 가이드

## 📱 앱 아이콘 개요

새김(SaeGim) Flutter 앱에서 사용하는 앱 아이콘 설정 방법과 리소스 구조에 대한 문서입니다.

## 🎨 아이콘 디자인

### 사용된 로고
- **원본 파일**: `../saegim-frontend/public/images/logoop.png`
- **디자인 특징**: 
  - 🐦 주황색 새 아이콘 (브랜드 아이덴티티)
  - 🌱 녹색 새싹 (성장과 기록의 의미)
  - 📝 "새김" 한글 타이포그래피
  - 🎨 친근하고 감성적인 디자인

### 색상 구성
- **주 색상**: 주황색 (`#FF7F50` 계열) - 새 아이콘
- **보조 색상**: 틸 그린 (`#4A9B8E` 계열) - 텍스트 및 새싹
- **배경**: 밝은 베이지 (`#f5f5f5`)

## 🛠️ 기술적 설정

### 사용된 패키지
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

### pubspec.yaml 설정
```yaml
flutter:
  assets:
    - assets/icon.png

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon.png"
  adaptive_icon_background: "#f5f5f5"
  adaptive_icon_foreground: "assets/icon.png"
  remove_alpha_ios: true  # iOS App Store 제출용
```

## 📁 생성된 파일 구조

### Android 아이콘 리소스
```
android/app/src/main/res/
├── mipmap-mdpi/
│   ├── ic_launcher.png (48x48)
│   └── launcher_icon.png (48x48)
├── mipmap-hdpi/
│   ├── ic_launcher.png (72x72)
│   └── launcher_icon.png (72x72)
├── mipmap-xhdpi/
│   ├── ic_launcher.png (96x96)
│   └── launcher_icon.png (96x96)
├── mipmap-xxhdpi/
│   ├── ic_launcher.png (144x144)
│   └── launcher_icon.png (144x144)
├── mipmap-xxxhdpi/
│   ├── ic_launcher.png (192x192)
│   └── launcher_icon.png (192x192)
├── mipmap-anydpi-v26/
│   └── launcher_icon.xml (Adaptive Icon)
└── drawable-*/
    └── ic_launcher_foreground.png (다양한 밀도)
```

### iOS 아이콘 리소스
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Contents.json
├── Icon-App-20x20@1x.png (20x20)
├── Icon-App-20x20@2x.png (40x40)
├── Icon-App-20x20@3x.png (60x60)
├── Icon-App-29x29@1x.png (29x29)
├── Icon-App-29x29@2x.png (58x58)
├── Icon-App-29x29@3x.png (87x87)
├── Icon-App-40x40@1x.png (40x40)
├── Icon-App-40x40@2x.png (80x80)
├── Icon-App-40x40@3x.png (120x120)
├── Icon-App-60x60@2x.png (120x120)
├── Icon-App-60x60@3x.png (180x180)
├── Icon-App-76x76@1x.png (76x76)
├── Icon-App-76x76@2x.png (152x152)
├── Icon-App-83.5x83.5@2x.png (167x167)
└── Icon-App-1024x1024@1x.png (1024x1024)
```

## ⚡ 아이콘 생성 및 업데이트

### 초기 설정
```bash
# 1. 의존성 설치
flutter pub get

# 2. 아이콘 생성
flutter pub run flutter_launcher_icons:main
```

### 아이콘 변경 시
```bash
# 1. assets/icon.png 파일 교체
# 2. 아이콘 재생성
flutter pub run flutter_launcher_icons:main

# 3. 클린 빌드 (권장)
flutter clean
flutter pub get
```

## 📋 검증 및 테스트

### 빌드 검증
```bash
# Android 빌드 테스트
flutter build apk --debug

# iOS 빌드 테스트 (macOS에서만)
flutter build ios --debug
```

### 아이콘 확인 방법
1. **에뮬레이터에서 확인**: `flutter run`으로 앱 실행 후 홈 화면에서 아이콘 확인
2. **Android**: 다양한 밀도(mdpi, hdpi, xhdpi 등)에서 아이콘 품질 확인
3. **iOS**: 다양한 크기(Settings, Spotlight, App Icon)에서 아이콘 확인

## 🚨 주의사항

### iOS App Store 제출
- **알파 채널 제거**: `remove_alpha_ios: true` 설정으로 투명도 제거
- **고해상도 요구**: 1024x1024px 아이콘 필수
- **정사각형 형태**: iOS는 자동으로 모서리를 둥글게 처리

### Android Adaptive Icons
- **배경 + 전경** 구조로 다양한 OEM 런처 지원
- **배경색**: `#f5f5f5`로 설정하여 로고와 조화
- **전경**: 원본 로고 이미지 사용

### 성능 고려사항
- **파일 크기**: 각 밀도별로 최적화된 크기 자동 생성
- **벡터 미지원**: Android Vector Drawable 대신 래스터 이미지 사용
- **호환성**: API 26+ (Android 8.0+)에서 Adaptive Icon 지원

## 🔧 문제 해결

### 일반적인 문제
```bash
# 아이콘이 생성되지 않는 경우
flutter clean
rm -rf build/
flutter pub get
flutter pub run flutter_launcher_icons:main

# 앱에서 아이콘이 표시되지 않는 경우
flutter clean
flutter run
```

### 품질 문제
- **흐릿한 아이콘**: 원본 이미지의 해상도를 1024x1024px 이상으로 사용
- **왜곡된 아이콘**: 정사각형 비율(1:1) 확인
- **색상 문제**: PNG 형식에서 색상 프로필 확인

## 📚 관련 문서

- [Flutter 앱 아이콘 공식 가이드](https://docs.flutter.dev/deployment/android#adding-a-launcher-icon)
- [Android Adaptive Icons](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
- [iOS Human Interface Guidelines - App Icon](https://developer.apple.com/design/human-interface-guidelines/ios/icons-and-images/app-icon/)

---

*이 문서는 새김 프로젝트의 앱 아이콘 설정을 위한 완전한 가이드입니다. 문의사항이 있으면 개발팀에 연락해주세요.*