import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

/// 인증 상태 모델
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? userId;
  final String? userEmail;
  final bool isInitialized;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.userId,
    this.userEmail,
    this.isInitialized = false,
    this.errorMessage,
  });

  /// 상태 복사 메서드
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? userId,
    String? userEmail,
    bool? isInitialized,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'AuthState(isAuthenticated: $isAuthenticated, isLoading: $isLoading, isInitialized: $isInitialized)';
  }
}

/// Riverpod 기반 인증 상태 관리 NotifierProvider
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // 초기 상태 반환
    return const AuthState();
  }

  /// 안전한 초기화 메서드 (앱 시작 후 명시적으로 호출)
  Future<void> initialize() async {
    if (state.isInitialized) return; // 중복 초기화 방지

    await checkAuthStatus();
    state = state.copyWith(isInitialized: true);
  }

  /// 로그인 상태 확인 (내부적으로만 호출)
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // TODO: 실제 인증 상태 확인 로직 구현
      // SharedPreferences나 Secure Storage에서 토큰 확인
      await Future.delayed(const Duration(seconds: 1)); // 임시 로딩 시뮬레이션

      // 임시로 false로 설정 (실제로는 저장된 토큰을 확인)
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 로그인
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // TODO: 실제 로그인 API 호출
      await Future.delayed(const Duration(seconds: 2)); // 임시 로딩 시뮬레이션

      // 임시로 성공으로 처리
      state = state.copyWith(
        isAuthenticated: true,
        userId: 'temp_user_id',
        userEmail: email,
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

  /// 회원가입
  Future<bool> signup(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // TODO: 실제 회원가입 API 호출
      await Future.delayed(const Duration(seconds: 2)); // 임시 로딩 시뮬레이션

      // 임시로 성공으로 처리
      state = state.copyWith(
        isAuthenticated: true,
        userId: 'temp_user_id',
        userEmail: email,
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

  /// 로그아웃
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // TODO: 실제 로그아웃 처리 (토큰 삭제 등)
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(
        isAuthenticated: false,
        userId: null,
        userEmail: null,
        isLoading: false,
      );
    } catch (e) {
      // 에러가 발생해도 로컬 상태는 초기화
      state = state.copyWith(
        isAuthenticated: false,
        userId: null,
        userEmail: null,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 비밀번호 찾기
  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // TODO: 실제 비밀번호 찾기 API 호출
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// 계정 복구
  Future<bool> restoreAccount(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // TODO: 실제 계정 복구 API 호출
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
