import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';

void main() {
  group('AuthNotifier 테스트', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('초기 상태가 올바른지 확인', () {
      final authState = container.read(authNotifierProvider);

      expect(authState.isAuthenticated, false);
      expect(authState.isLoading, false);
      expect(authState.isInitialized, false);
      expect(authState.userId, null);
      expect(authState.userEmail, null);
      expect(authState.errorMessage, null);
    });

    test('초기화 후 상태가 올바른지 확인', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      await authNotifier.initialize();

      final authState = container.read(authNotifierProvider);
      expect(authState.isInitialized, true);
      expect(authState.isLoading, false);
    });

    test('로그인 성공 시 상태 변경 확인', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      final result = await authNotifier.login('test@example.com', 'password123');

      expect(result, true);

      final authState = container.read(authNotifierProvider);
      expect(authState.isAuthenticated, true);
      expect(authState.isLoading, false);
      expect(authState.userEmail, 'test@example.com');
      expect(authState.userId, 'temp_user_id');
    });

    test('회원가입 성공 시 상태 변경 확인', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      final result = await authNotifier.signup(
        'newuser@example.com',
        'password123',
        '새로운 사용자',
      );

      expect(result, true);

      final authState = container.read(authNotifierProvider);
      expect(authState.isAuthenticated, true);
      expect(authState.isLoading, false);
      expect(authState.userEmail, 'newuser@example.com');
      expect(authState.userId, 'temp_user_id');
    });

    test('로그아웃 시 상태 초기화 확인', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      // 먼저 로그인
      await authNotifier.login('test@example.com', 'password123');

      // 로그아웃
      await authNotifier.logout();

      final authState = container.read(authNotifierProvider);
      expect(authState.isAuthenticated, false);
      expect(authState.isLoading, false);
      expect(authState.userId, null);
      expect(authState.userEmail, null);
    });

    test('비밀번호 찾기 기능 확인', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      final result = await authNotifier.forgotPassword('test@example.com');

      expect(result, true);

      final authState = container.read(authNotifierProvider);
      expect(authState.isLoading, false);
    });

    test('계정 복구 기능 확인', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      final result = await authNotifier.restoreAccount('test@example.com');

      expect(result, true);

      final authState = container.read(authNotifierProvider);
      expect(authState.isLoading, false);
    });

    test('에러 메시지 초기화 확인', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      // 에러 상태 임의로 설정 (실제로는 API 에러 등으로 발생)
      // 이 부분은 실제 에러 케이스가 구현되면 수정 필요

      authNotifier.clearError();

      final authState = container.read(authNotifierProvider);
      expect(authState.errorMessage, null);
    });

    test('상태 변경 중 로딩 상태 확인', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      // 비동기 작업 시작
      final loginFuture = authNotifier.login('test@example.com', 'password123');

      // 로딩 상태 확인 (실제로는 매우 짧은 시간이므로 테스트하기 어려울 수 있음)
      // 실제 구현에서는 Mock 서비스를 사용하여 지연 시간을 조절할 수 있음

      await loginFuture;

      final authState = container.read(authNotifierProvider);
      expect(authState.isLoading, false); // 작업 완료 후 로딩 해제 확인
    });

    group('상태 복사 메서드 테스트', () {
      test('copyWith 메서드가 올바르게 작동하는지 확인', () {
        const originalState = AuthState(
          isAuthenticated: false,
          isLoading: false,
          userId: null,
          userEmail: null,
          isInitialized: false,
          errorMessage: null,
        );

        final newState = originalState.copyWith(
          isAuthenticated: true,
          userEmail: 'test@example.com',
        );

        expect(newState.isAuthenticated, true);
        expect(newState.userEmail, 'test@example.com');
        expect(newState.isLoading, false); // 변경되지 않은 값 유지
        expect(newState.userId, null); // 변경되지 않은 값 유지
      });

      test('copyWith에서 null 값 전달 시 기존 값 유지 확인', () {
        const originalState = AuthState(
          isAuthenticated: true,
          userEmail: 'test@example.com',
        );

        final newState = originalState.copyWith();

        expect(newState.isAuthenticated, true);
        expect(newState.userEmail, 'test@example.com');
      });
    });
  });

  group('AuthState toString 테스트', () {
    test('toString 메서드가 올바른 형식으로 출력되는지 확인', () {
      const authState = AuthState(
        isAuthenticated: true,
        isLoading: false,
        isInitialized: true,
      );

      final result = authState.toString();

      expect(
        result,
        'AuthState(isAuthenticated: true, isLoading: false, isInitialized: true)',
      );
    });
  });
}