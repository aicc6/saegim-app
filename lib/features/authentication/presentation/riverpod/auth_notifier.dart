import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/core/services/auth_storage_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

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

      if (token != null && token.isNotEmpty) {
        // 서버에서 토큰 유효성 검증
        final isValid = await _validateTokenWithServer(token);

        if (isValid) {
          final userId = await AuthStorageService.instance.getUserId();
          final userEmail = await AuthStorageService.instance.getUserEmail();

          state = state.copyWith(
            isAuthenticated: true,
            userId: userId,
            userEmail: userEmail,
            isLoading: false,
          );
          AppLogger.info('User authenticated with valid token', 'AuthNotifier');
        } else {
          // 토큰이 유효하지 않으면 인증 데이터 정리
          await AuthStorageService.instance.clearAllAuthData();
          state = state.copyWith(isAuthenticated: false, isLoading: false);
          AppLogger.warning(
            'Token validation failed, cleared auth data',
            'AuthNotifier',
          );
        }
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
      final dio = DioClient.instance.dio;
      final response = await dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.info('Login response data: $data', 'AuthNotifier');

        // 백엔드 API 응답 구조: 바디에는 user 정보, 헤더(Set-Cookie)에는 토큰
        final responseData = data['data'] ?? data;
        final userId = responseData['user_id']?.toString();
        final userEmail = responseData['email']?.toString();

        // Set-Cookie 헤더에서 access_token 추출
        String? accessToken;
        String? refreshToken;

        final setCookieHeaders = response.headers['set-cookie'];
        AppLogger.info('Set-Cookie headers: $setCookieHeaders', 'AuthNotifier');

        if (setCookieHeaders != null) {
          for (final cookieHeader in setCookieHeaders) {
            AppLogger.info('Processing cookie: $cookieHeader', 'AuthNotifier');

            // access_token 쿠키 찾기
            if (cookieHeader.startsWith('access_token=')) {
              final tokenPart = cookieHeader.split(';')[0]; // 쿠키 옵션 제거
              accessToken = tokenPart.split('=')[1]; // 토큰 값만 추출
              AppLogger.info(
                'Found access_token in cookie: ${accessToken.substring(0, 10)}...',
                'AuthNotifier',
              );
            }

            // refresh_token 쿠키 찾기
            if (cookieHeader.startsWith('refresh_token=')) {
              final tokenPart = cookieHeader.split(';')[0]; // 쿠키 옵션 제거
              refreshToken = tokenPart.split('=')[1]; // 토큰 값만 추출
              AppLogger.info(
                'Found refresh_token in cookie: ${refreshToken.substring(0, 10)}...',
                'AuthNotifier',
              );
            }
          }
        } else {
          AppLogger.warning('No Set-Cookie headers found', 'AuthNotifier');
        }

        // 전체 응답 구조 로깅 (디버깅용)
        AppLogger.info('Full login response: ${response.data}', 'AuthNotifier');
        AppLogger.info(
          'Response status: ${response.statusCode}',
          'AuthNotifier',
        );
        AppLogger.info('Response headers: ${response.headers}', 'AuthNotifier');

        AppLogger.info(
          'Extracted accessToken: ${accessToken?.substring(0, 10) ?? 'null'}...',
          'AuthNotifier',
        );
        AppLogger.info(
          'Extracted refreshToken: ${refreshToken?.substring(0, 10) ?? 'null'}...',
          'AuthNotifier',
        );
        AppLogger.info('Extracted userId: $userId', 'AuthNotifier');
        AppLogger.info('Extracted userEmail: $userEmail', 'AuthNotifier');

        // 토큰과 사용자 정보 저장
        if (accessToken != null && accessToken.isNotEmpty) {
          AppLogger.info('Saving auth token...', 'AuthNotifier');
          await AuthStorageService.instance.saveAuthToken(accessToken);
          AppLogger.info('Auth token save completed', 'AuthNotifier');

          // refresh_token도 별도 저장
          if (refreshToken != null && refreshToken.isNotEmpty) {
            await AuthStorageService.instance.saveRefreshToken(refreshToken);
            AppLogger.info('Refresh token save completed', 'AuthNotifier');
          }

          // 사용자 정보도 저장
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
          AppLogger.error(
            'No access_token found in Set-Cookie headers!',
            tag: 'AuthNotifier',
          );
          AppLogger.error(
            'Login failed: Backend did not return access_token in cookies',
            tag: 'AuthNotifier',
          );

          state = state.copyWith(
            isAuthenticated: false,
            isLoading: false,
            errorMessage: '백엔드 서버에서 인증 토큰을 반환하지 않았습니다.',
          );

          return false;
        }
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
      final dio = DioClient.instance.dio;
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

      // DioException에서 상세 에러 정보 추출
      if (e is DioException && e.response != null) {
        AppLogger.error(
          'Signup error response: ${e.response?.statusCode} - ${e.response?.data}',
        );

        if (e.response?.statusCode == 422) {
          final responseData = e.response?.data;
          if (responseData is Map && responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          } else if (responseData is Map &&
              responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          } else {
            errorMessage = '입력 정보를 다시 확인해주세요.';
          }
        }
      } else if (e.toString().contains('email')) {
        errorMessage = '이미 사용 중인 이메일입니다.';
      } else if (e.toString().contains('network')) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  /// 서버에서 토큰 유효성 검증
  Future<bool> _validateTokenWithServer(String token) async {
    try {
      // 간단한 사용자 정보 조회로 토큰 유효성 확인
      final response = await DioClient.instance.dio.get(
        '/api/user/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        AppLogger.info('Token validation successful', 'AuthNotifier');
        return true;
      } else {
        AppLogger.warning(
          'Token validation failed with status: ${response.statusCode}',
          'AuthNotifier',
        );
        return false;
      }
    } catch (e) {
      AppLogger.warning('Token validation failed: $e', 'AuthNotifier');
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
      final dio = DioClient.instance.dio;
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
      final dio = DioClient.instance.dio;
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

  /// 이메일 인증 코드 발송
  Future<bool> sendVerificationEmail(String email) async {
    if (email.isEmpty) return false;

    try {
      final dio = DioClient.instance.dio;
      AppLogger.info('Sending verification email to: $email');

      final response = await dio.post(
        '/api/auth/send-verification-email',
        data: {'email': email},
      );

      AppLogger.info(
        'Verification email response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('Verification email sent successfully to: $email');
        return true;
      }
      AppLogger.warning('Unexpected status code: ${response.statusCode}');
      return false;
    } catch (e) {
      AppLogger.error('Failed to send verification email: $email', error: e);
      return false;
    }
  }

  /// 이메일 인증 코드 검증
  Future<bool> verifyEmail(String email, String verificationCode) async {
    if (email.isEmpty || verificationCode.isEmpty) return false;

    try {
      final dio = DioClient.instance.dio;
      final response = await dio.post(
        '/api/auth/verify-email',
        data: {'email': email, 'verification_code': verificationCode},
      );

      if (response.statusCode == 200) {
        AppLogger.info('Email verification successful: $email');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Email verification failed: $email', error: e);
      return false;
    }
  }
}
