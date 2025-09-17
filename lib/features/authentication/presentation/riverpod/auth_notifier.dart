import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:saegim/core/services/auth_storage_service.dart';

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
      // 저장된 토큰 확인
      final token = await AuthStorageService.instance.getAuthToken();
      final userId = await AuthStorageService.instance.getUserId();
      final userEmail = await AuthStorageService.instance.getUserEmail();

      if (token != null && token.isNotEmpty) {
        // 토큰이 있으면 유효성 검사 (선택적)
        state = state.copyWith(
          isAuthenticated: true,
          userId: userId,
          userEmail: userEmail,
          isLoading: false,
        );
        AppLogger.info('User authenticated with stored token', 'AuthNotifier');
      } else {
        state = state.copyWith(isAuthenticated: false, isLoading: false);
        AppLogger.info('No authentication token found', 'AuthNotifier');
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: e.toString(),
      );
      AppLogger.error(
        'Auth status check failed',
        tag: 'AuthNotifier',
        error: e,
      );
    }
  }

  /// 로그인
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final dio = DioClient.create();
      final response = await dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.info('Login response data: $data', 'AuthNotifier');

        // 응답 구조에 따라 data 필드에서 사용자 정보 추출
        final responseData = data['data'] ?? data;
        final userId = responseData['user_id']?.toString();
        final userEmail = responseData['email']?.toString();

        // 토큰을 여러 위치에서 찾기
        final token =
            data['access_token']?.toString() ??
            data['token']?.toString() ??
            responseData['access_token']?.toString() ??
            responseData['token']?.toString() ??
            data['data']?['access_token']?.toString() ??
            data['data']?['token']?.toString();

        AppLogger.info(
          'Extracted token: ${token?.substring(0, 10) ?? 'null'}...',
          'AuthNotifier',
        );
        AppLogger.info('Extracted userId: $userId', 'AuthNotifier');
        AppLogger.info('Extracted userEmail: $userEmail', 'AuthNotifier');

        // 토큰과 사용자 정보 저장
        if (token != null && token.isNotEmpty) {
          AppLogger.info('Saving auth token...', 'AuthNotifier');
          await AuthStorageService.instance.saveAuthToken(token);
          AppLogger.info('Auth token save completed', 'AuthNotifier');
        } else {
          AppLogger.error('No token found in response!', tag: 'AuthNotifier');
          AppLogger.error(
            'Full response structure: ${response.data}',
            tag: 'AuthNotifier',
          );
          // 백엔드에서 토큰을 반환하지 않는 경우, 임시 토큰 생성 또는 세션 기반 인증 사용
          AppLogger.warning(
            'Using session-based authentication fallback',
            'AuthNotifier',
          );
          // 임시로 더미 토큰 저장 (실제 프로덕션에서는 사용하지 말 것)
          const dummyToken = 'session_authenticated_user';
          await AuthStorageService.instance.saveAuthToken(dummyToken);
          AppLogger.info(
            'Dummy token saved for session-based auth',
            'AuthNotifier',
          );
        }
        if (userId != null) {
          await AuthStorageService.instance.saveUserId(userId);
        }
        if (userEmail != null) {
          await AuthStorageService.instance.saveUserEmail(userEmail);
        }

        state = state.copyWith(
          isAuthenticated: true,
          userId: userId,
          userEmail: userEmail,
          isLoading: false,
        );

        AppLogger.info('Login successful for user: $email, token saved');
        return true;
      } else {
        throw Exception('로그인에 실패했습니다.');
      }
    } catch (e) {
      AppLogger.error('Login failed for user: $email', error: e);

      String errorMessage = '로그인에 실패했습니다.';
      if (e.toString().contains('401') || e.toString().contains('invalid')) {
        errorMessage = '이메일 또는 비밀번호가 올바르지 않습니다.';
      } else if (e.toString().contains('network')) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  /// 회원가입
  Future<bool> signup(String email, String password, String nickname) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final dio = DioClient.create();
      final response = await dio.post(
        '/api/auth/signup',
        data: {'email': email, 'password': password, 'nickname': nickname},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        state = state.copyWith(
          isAuthenticated: true,
          userId: data['user_id']?.toString(),
          userEmail: data['email']?.toString(),
          isLoading: false,
        );

        AppLogger.info('Signup successful for user: $email');
        return true;
      } else {
        throw Exception('회원가입에 실패했습니다.');
      }
    } catch (e) {
      AppLogger.error('Signup failed for user: $email', error: e);

      String errorMessage = '회원가입에 실패했습니다.';
      if (e.toString().contains('email')) {
        errorMessage = '이미 사용 중인 이메일입니다.';
      } else if (e.toString().contains('network')) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    // 저장된 인증 데이터 모두 삭제
    await AuthStorageService.instance.clearAllAuthData();
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
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 이메일 중복 확인
  Future<bool> checkEmailDuplicate(String email) async {
    if (email.isEmpty) return false;

    try {
      final dio = DioClient.create();
      final response = await dio.get('/api/auth/check-email/$email');

      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.info('Email check API response: $data'); // 디버깅용 로그
        // API 응답에 따라 조정 필요 (available: true/false)
        return data['data']['available'] == false; // 사용불가하면 true (중복됨)
      }
      return false;
    } catch (e) {
      AppLogger.error('Email duplicate check failed: $email', error: e);
      return false; // 에러 시에는 중복되지 않은 것으로 처리
    }
  }

  /// 닉네임 중복 확인
  Future<bool> checkNicknameDuplicate(String nickname) async {
    if (nickname.isEmpty) return false;

    try {
      final dio = DioClient.create();
      final response = await dio.get('/api/auth/check-nickname/$nickname');

      if (response.statusCode == 200) {
        final data = response.data;
        // API 응답에 따라 조정 필요 (available: true/false)
        return data['data']['available'] == false; // 사용불가하면 true (중복됨)
      }
      return false;
    } catch (e) {
      AppLogger.error('Nickname duplicate check failed: $nickname', error: e);
      return false; // 에러 시에는 중복되지 않은 것으로 처리
    }
  }
}
