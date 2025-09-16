# Riverpod 상태 관리 설정 가이드

이 문서는 saegim-app 프로젝트에서 Riverpod 상태 관리를 설정하고 사용하는 방법을 설명합니다.

## 📚 개요

Riverpod은 Flutter 애플리케이션을 위한 반응형 캐싱 및 데이터 바인딩 프레임워크입니다. 기존 Provider와 완전히 공존하며, 점진적 마이그레이션을 지원합니다.

### 주요 장점

- **컴파일 타임 안전성**: 런타임 에러 대신 컴파일 타임에 오류 감지
- **코드 생성**: @riverpod 어노테이션을 통한 보일러플레이트 코드 자동 생성
- **테스트 용이성**: Provider 오버라이드를 통한 쉬운 테스트
- **성능 최적화**: 자동 dispose 및 lazy 초기화

## 🛠️ 설정 방법

### 1. 의존성 추가

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.7
```

### 2. 앱 최상단에 ProviderScope 래핑

```dart
// main.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SaeGimApp(),
    ),
  );
}
```

### 3. 코드 생성 실행

```bash
# 일회성 코드 생성
dart run build_runner build

# 파일 변경 감시 모드
dart run build_runner watch
```

## 📝 사용 방법

### 1. Notifier 클래스 작성

```dart
// auth_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

// 상태 모델 정의
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  // ... 기타 필드들
}

// Riverpod Notifier 정의
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(); // 초기 상태
  }

  // 상태 변경 메서드들
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    // ... 로그인 로직
    return true;
  }
}
```

### 2. 위젯에서 상태 사용

```dart
// ConsumerWidget 또는 ConsumerStatefulWidget 사용
class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상태 구독
    final authState = ref.watch(authNotifierProvider);

    // Notifier 인스턴스 접근
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          Text('인증됨: ${authState.isAuthenticated}'),
          ElevatedButton(
            onPressed: () => authNotifier.login('email', 'password'),
            child: Text('로그인'),
          ),
        ],
      ),
    );
  }
}
```

## 🔄 Provider와 Riverpod 공존

기존 Provider 코드를 유지하면서 새로운 기능에만 Riverpod을 적용할 수 있습니다:

```dart
// app.dart - Riverpod 기반 구성
class SaeGimApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Riverpod은 main.dart에서 ProviderScope로 래핑됨
      routerConfig: AppRouter.createRouter(),
    );
  }
}
```

## 🧪 테스트

### Provider 오버라이드를 통한 테스트

```dart
testWidgets('로그인 테스트', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => MockAuthNotifier()),
      ],
      child: MyApp(),
    ),
  );

  // 테스트 코드...
});
```

## 📁 프로젝트 구조

```
lib/
├── features/
│   └── authentication/
│       └── presentation/
│           ├── providers/         # 기존 Provider 코드
│           │   └── auth_provider.dart
│           ├── riverpod/          # 새로운 Riverpod 코드
│           │   ├── auth_notifier.dart
│           │   ├── auth_notifier.g.dart  # 생성된 파일
│           │   └── README_RIVERPOD.md
│           └── pages/
│               ├── login_page.dart       # Provider 사용
│               └── riverpod_example_page.dart  # Riverpod 사용
```

## 🚀 마이그레이션 가이드

### 점진적 마이그레이션 전략

1. **단계 1**: 새로운 기능에만 Riverpod 적용
2. **단계 2**: 복잡한 상태 로직부터 Riverpod으로 전환
3. **단계 3**: 전체 앱을 Riverpod으로 통일

### Provider vs Riverpod 비교

| 특징 | Provider | Riverpod |
|------|----------|----------|
| 컴파일 타임 안전성 | ❌ | ✅ |
| 코드 생성 | ❌ | ✅ |
| 테스트 용이성 | ⚠️ | ✅ |
| 학습 곡선 | 낮음 | 중간 |
| 기존 코드 호환성 | ✅ | ⚠️ |

## 💡 모범 사례

### 1. 상태 모델 설계

```dart
// ✅ 좋은 예: Immutable 상태 모델
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
```

### 2. 에러 처리

```dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // API 호출
      final result = await authService.login(email, password);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}
```

### 3. 위젯에서 상태 사용

```dart
// ✅ 좋은 예: 상태와 액션 분리
class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          if (authState.isLoading)
            const CircularProgressIndicator(),
          ElevatedButton(
            onPressed: authState.isLoading
                ? null
                : () => authNotifier.login(email, password),
            child: const Text('로그인'),
          ),
        ],
      ),
    );
  }
}
```

## 🔧 문제 해결

### 일반적인 문제들

1. **코드 생성 파일이 없음**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **상태가 업데이트되지 않음**
   - `state =` 구문으로 상태 변경 확인
   - `copyWith()` 메서드 사용 확인

3. **빌드 에러**
   ```bash
   flutter clean
   flutter pub get
   dart run build_runner build
   ```

## 📚 추가 자료

- [Riverpod 공식 문서](https://riverpod.dev/)
- [Flutter Riverpod 패키지](https://pub.dev/packages/flutter_riverpod)
- [Riverpod Generator](https://pub.dev/packages/riverpod_generator)

---

**참고**: 이 설정은 기존 Provider 패턴과 완전히 공존하며, 점진적으로 마이그레이션할 수 있습니다.
