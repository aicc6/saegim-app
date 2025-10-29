import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/core/services/auth_storage_service.dart';
import 'package:saegim/core/services/fcm_message_service.dart';
import 'package:saegim/features/authentication/data/services/forgot_password_service.dart';
import 'package:saegim/features/authentication/data/services/google_sign_in_service.dart';
import 'package:saegim/features/home/presentation/riverpod/create_notifier.dart';
import 'package:saegim/shared/utils/app_logger.dart';

part 'auth_notifier.g.dart';

/// 이메일 로그인 결과 클래스
class EmailLoginResult {
  final bool isSuccess;
  final bool isAccountDeleted;
  final String? errorMessage;
  final String? email;

  const EmailLoginResult._({
    required this.isSuccess,
    required this.isAccountDeleted,
    this.errorMessage,
    this.email,
  });

  factory EmailLoginResult.success() {
    return const EmailLoginResult._(isSuccess: true, isAccountDeleted: false);
  }

  factory EmailLoginResult.accountDeleted({String? email, String? message}) {
    return EmailLoginResult._(
      isSuccess: false,
      isAccountDeleted: true,
      email: email,
      errorMessage: message,
    );
  }

  factory EmailLoginResult.failure(String message) {
    return EmailLoginResult._(
      isSuccess: false,
      isAccountDeleted: false,
      errorMessage: message,
    );
  }
}

/// Google 로그인 결과 클래스
class GoogleLoginResult {
  final bool isSuccess;
  final bool isAccountDeleted;
  final String? userEmail;
  final String? errorMessage;

  const GoogleLoginResult._({
    required this.isSuccess,
    required this.isAccountDeleted,
    this.userEmail,
    this.errorMessage,
  });

  factory GoogleLoginResult.success() {
    return const GoogleLoginResult._(isSuccess: true, isAccountDeleted: false);
  }

  factory GoogleLoginResult.accountDeleted(String email) {
    return GoogleLoginResult._(
      isSuccess: false,
      isAccountDeleted: true,
      userEmail: email,
    );
  }

  factory GoogleLoginResult.failure(String message) {
    return GoogleLoginResult._(
      isSuccess: false,
      isAccountDeleted: false,
      errorMessage: message,
    );
  }
}

/// 인증 상태 모델
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? userId;
  final String? userEmail;
  final bool isInitialized;
  final String? errorMessage;
  final bool isRecovered;
  final String? recoveryMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.userId,
    this.userEmail,
    this.isInitialized = false,
    this.errorMessage,
    this.isRecovered = false,
    this.recoveryMessage,
  });

  /// 상태 복사 메서드
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? userId,
    String? userEmail,
    bool? isInitialized,
    String? errorMessage,
    bool? isRecovered,
    String? recoveryMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage ?? this.errorMessage,
      isRecovered: isRecovered ?? this.isRecovered,
      recoveryMessage: recoveryMessage ?? this.recoveryMessage,
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
    AppLogger.info(
      'initialize() 호출됨 - isInitialized: ${state.isInitialized}',
      'AuthNotifier',
    );

    if (state.isInitialized) {
      AppLogger.info('이미 초기화됨 - 중복 초기화 방지', 'AuthNotifier');
      return; // 중복 초기화 방지
    }

    AppLogger.info('인증 상태 확인 시작', 'AuthNotifier');
    await checkAuthStatus();

    state = state.copyWith(isInitialized: true);
    AppLogger.info(
      '초기화 완료 - isAuthenticated: ${state.isAuthenticated}, userId: ${state.userId}',
      'AuthNotifier',
    );
  }

  /// 로그인 상태 확인 (내부적으로만 호출)
  Future<void> checkAuthStatus() async {
    AppLogger.info('=== checkAuthStatus 시작 ===', 'AuthNotifier');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 저장된 토큰 확인
      AppLogger.info('저장된 토큰 조회 시작...', 'AuthNotifier');
      final token = await AuthStorageService.instance.getAuthToken();

      if (token != null && token.isNotEmpty) {
        AppLogger.info(
          '토큰 발견: ${token.substring(0, 20)}... (길이: ${token.length})',
          'AuthNotifier',
        );

        // 서버에서 토큰 유효성 검증
        AppLogger.info('서버에 토큰 검증 요청 중...', 'AuthNotifier');
        final isValid = await _validateTokenWithServer(token);
        AppLogger.info('토큰 검증 결과: $isValid', 'AuthNotifier');

        if (isValid) {
          final userId = await AuthStorageService.instance.getUserId();
          final userEmail = await AuthStorageService.instance.getUserEmail();

          AppLogger.info(
            '사용자 정보 조회 완료 - userId: $userId, email: $userEmail',
            'AuthNotifier',
          );

          state = state.copyWith(
            isAuthenticated: true,
            userId: userId,
            userEmail: userEmail,
            isLoading: false,
          );
          AppLogger.info('✅ 인증 성공 - 로그인 상태 복원됨', 'AuthNotifier');
        } else {
          // 토큰이 유효하지 않으면 인증 데이터 정리
          AppLogger.warning('❌ 토큰 검증 실패 - 인증 데이터 정리', 'AuthNotifier');
          await AuthStorageService.instance.clearAllAuthData();
          state = state.copyWith(isAuthenticated: false, isLoading: false);
        }
      } else {
        AppLogger.info('❌ 저장된 토큰 없음', 'AuthNotifier');
        state = state.copyWith(isAuthenticated: false, isLoading: false);
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

  /// 로그인 (이메일 계정)
  Future<EmailLoginResult> login(String email, String password) async {
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

        // 계정 복구 상태 확인
        final isRecovered = responseData['is_recovered'] == true;
        final recoveryMessage = responseData['recovery_message']?.toString();

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

          // ✅ 저장 검증: 바로 다시 읽어서 확인
          final verifyToken = await AuthStorageService.instance.getAuthToken();
          if (verifyToken == accessToken) {
            AppLogger.info('✅ 토큰 저장 검증 성공', 'AuthNotifier');
          } else {
            AppLogger.error(
              '❌ 토큰 저장 검증 실패! 저장: ${accessToken.substring(0, 10)}, 조회: ${verifyToken?.substring(0, 10) ?? 'null'}',
              tag: 'AuthNotifier',
            );
          }

          // refresh_token도 별도 저장
          if (refreshToken != null && refreshToken.isNotEmpty) {
            await AuthStorageService.instance.saveRefreshToken(refreshToken);
            AppLogger.info('Refresh token save completed', 'AuthNotifier');
          }

          // 사용자 정보도 저장
          if (userId != null) {
            await AuthStorageService.instance.saveUserId(userId);
            AppLogger.info('User ID saved: $userId', 'AuthNotifier');
          }
          if (userEmail != null) {
            await AuthStorageService.instance.saveUserEmail(userEmail);
            AppLogger.info('User email saved: $userEmail', 'AuthNotifier');
          }

          // 로그인 타입 저장 (이메일 로그인)
          await AuthStorageService.instance.saveLoginType('email');
          AppLogger.info('Login type saved: email', 'AuthNotifier');

          state = state.copyWith(
            isAuthenticated: true,
            userId: userId,
            userEmail: userEmail,
            isLoading: false,
            isRecovered: isRecovered,
            recoveryMessage: recoveryMessage,
          );

          // FCM 토큰 서버 등록
          try {
            final fcmRegistered = await FCMMessageService.instance
                .registerTokenOnLogin(userId: userId);
            AppLogger.info('FCM 토큰 등록 결과: $fcmRegistered', 'AuthNotifier');
          } catch (e) {
            AppLogger.error('FCM 토큰 등록 실패', error: e, tag: 'AuthNotifier');
            // FCM 등록 실패는 로그인 성공에 영향주지 않음
          }

          // 사용자의 생성된 글 데이터 복원
          try {
            await ref.read(createProvider.notifier).loadUserData();
            AppLogger.info('사용자 생성된 글 데이터 복원 완료', 'AuthNotifier');
          } catch (e) {
            AppLogger.error(
              '사용자 생성된 글 데이터 복원 실패',
              error: e,
              tag: 'AuthNotifier',
            );
          }

          AppLogger.info('Login successful for user: $email, token saved');

          // 계정 복구 상태 로깅
          if (isRecovered) {
            AppLogger.info('Account recovered for user: $email');
            if (recoveryMessage != null) {
              AppLogger.info('Recovery message: $recoveryMessage');
            }
          }

          return EmailLoginResult.success();
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

          return EmailLoginResult.failure('백엔드 서버에서 인증 토큰을 반환하지 않았습니다.');
        }
      } else {
        throw Exception('로그인에 실패했습니다.');
      }
    } on DioException catch (e, stackTrace) {
      AppLogger.error(
        'Login failed for user: $email',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthNotifier',
      );

      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      String? detailMessage;
      if (responseData is Map<String, dynamic>) {
        detailMessage =
            responseData['message']?.toString() ??
            responseData['detail']?.toString() ??
            responseData['error']?.toString();
      } else if (responseData is String) {
        detailMessage = responseData;
      }

      bool isAccountDeleted = false;
      String errorMessage = detailMessage ?? '로그인에 실패했습니다.';

      if (statusCode == 401) {
        errorMessage = '이메일 또는 비밀번호가 올바르지 않습니다.';
      } else if (statusCode == 403 ||
          statusCode == 410 ||
          (detailMessage != null &&
              (detailMessage.contains('탈퇴') ||
                  detailMessage.toLowerCase().contains('deleted')))) {
        isAccountDeleted = true;
        errorMessage = detailMessage ?? '해당 계정은 탈퇴된 상태입니다. 복구를 진행해주세요.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '서버 연결 시간이 초과되었습니다. 네트워크 상태를 확인해주세요.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      }

      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: isAccountDeleted ? null : errorMessage,
      );

      if (isAccountDeleted) {
        return EmailLoginResult.accountDeleted(
          email: email,
          message: errorMessage,
        );
      }

      return EmailLoginResult.failure(errorMessage);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Login failed for user: $email',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthNotifier',
      );

      const errorMessage = '로그인에 실패했습니다.';
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: errorMessage,
      );

      return EmailLoginResult.failure(errorMessage);
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
        AppLogger.info('Signup successful for user: $email');

        state = state.copyWith(isLoading: false);
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
      // 현재 로그인한 사용자 정보 조회 (토큰 검증 겸용)
      final response = await DioClient.instance.dio.get(
        '/api/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        AppLogger.info('Token validation successful', 'AuthNotifier');

        // 프로필 정보 업데이트 (서버 최신 상태 반영)
        final responseData = response.data is Map<String, dynamic>
            ? response.data['data'] ?? response.data
            : null;

        final fetchedUserId = responseData is Map<String, dynamic>
            ? responseData['id']?.toString() ??
                  responseData['user_id']?.toString()
            : null;
        final fetchedEmail = responseData is Map<String, dynamic>
            ? responseData['email']?.toString()
            : null;

        if (fetchedUserId != null && fetchedUserId.isNotEmpty) {
          await AuthStorageService.instance.saveUserId(fetchedUserId);
          AppLogger.info(
            'User ID refreshed from server: $fetchedUserId',
            'AuthNotifier',
          );
        }

        if (fetchedEmail != null && fetchedEmail.isNotEmpty) {
          await AuthStorageService.instance.saveUserEmail(fetchedEmail);
          AppLogger.info(
            'User email refreshed from server: $fetchedEmail',
            'AuthNotifier',
          );
        }

        return true;
      }

      if (response.statusCode == 401) {
        AppLogger.warning(
          'Token validation failed with 401 Unauthorized',
          'AuthNotifier',
        );
        return false;
      }

      AppLogger.warning(
        'Token validation returned unexpected status: ${response.statusCode}',
        'AuthNotifier',
      );
      return true; // 예외적인 상태지만 토큰을 즉시 무효화하지는 않음
    } on DioException catch (dioError) {
      final statusCode = dioError.response?.statusCode;
      if (statusCode == 401) {
        AppLogger.warning(
          'Token validation received Dio 401 response',
          'AuthNotifier',
        );
        return false;
      }

      AppLogger.warning(
        'Token validation request failed (${dioError.type}) - status: $statusCode, keeping session',
        'AuthNotifier',
      );
      return true; // 네트워크 오류 등은 세션 유지
    } catch (e, stackTrace) {
      AppLogger.error(
        'Unexpected error while validating token',
        tag: 'AuthNotifier',
        error: e,
        stackTrace: stackTrace,
      );
      return true; // 알 수 없는 오류는 세션 유지
    }
  }

  /// 로그아웃 (일반 로그인 + 소셜 로그인 통합)
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. 서버에 로그아웃 요청 (토큰 무효화)
      try {
        final token = await AuthStorageService.instance.getAuthToken();
        if (token != null && token.isNotEmpty) {
          await DioClient.instance.dio.post(
            '/api/auth/logout',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          AppLogger.info('서버 로그아웃 완료', 'AuthNotifier');
        }
      } catch (e) {
        AppLogger.warning('서버 로그아웃 실패 (무시됨): $e', 'AuthNotifier');
      }

      // 2. FCM 토큰 서버에서 해제
      try {
        await FCMMessageService.instance.deactivateTokenOnLogout();
        AppLogger.info('FCM 토큰 해제 완료', 'AuthNotifier');
      } catch (e) {
        AppLogger.error('FCM 토큰 해제 실패', error: e, tag: 'AuthNotifier');
      }

      // 3. Google 로그아웃 (소셜 로그인인 경우)
      try {
        await GoogleSignInService.instance.signOut();
        AppLogger.info('Google 로그아웃 완료', 'AuthNotifier');
      } catch (e) {
        AppLogger.error('Google 로그아웃 실패', error: e, tag: 'AuthNotifier');
      }

      // 4. 저장된 인증 데이터 모두 삭제
      await AuthStorageService.instance.clearAllAuthData();
      AppLogger.info('로컬 인증 데이터 삭제 완료', 'AuthNotifier');

      // 5. 상태 초기화
      state = state.copyWith(
        isAuthenticated: false,
        userId: null,
        userEmail: null,
        isLoading: false,
      );

      // 6. 생성된 글 상태도 초기화 (SharedPreferences 데이터 포함)
      try {
        ref.read(createProvider.notifier).resetToDefaults();
        AppLogger.info('생성된 글 상태 초기화 완료', 'AuthNotifier');
      } catch (e) {
        AppLogger.error('생성된 글 상태 초기화 실패', error: e, tag: 'AuthNotifier');
      }

      AppLogger.info('전체 로그아웃 프로세스 완료', 'AuthNotifier');
    } catch (e) {
      // 에러가 발생해도 로컬 상태는 초기화
      AppLogger.error('로그아웃 중 오류 발생', error: e, tag: 'AuthNotifier');

      // 강제로 로컬 데이터 정리
      await AuthStorageService.instance.clearAllAuthData();

      state = state.copyWith(
        isAuthenticated: false,
        userId: null,
        userEmail: null,
        isLoading: false,
        errorMessage: '로그아웃 중 오류가 발생했지만 로컬 데이터는 정리되었습니다.',
      );
    }
  }

  /// 비밀번호 찾기 (일반 계정만 가능)
  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      AppLogger.info('비밀번호 찾기 요청: $email', 'AuthNotifier');

      // ForgotPasswordService 사용
      final result = await ForgotPasswordService.sendPasswordResetEmail(email);

      state = state.copyWith(isLoading: false);

      if (result.success) {
        AppLogger.info('비밀번호 재설정 이메일 발송 성공: $email', 'AuthNotifier');
        return true;
      } else {
        AppLogger.warning(
          '비밀번호 재설정 이메일 발송 실패: ${result.message}',
          'AuthNotifier',
        );
        state = state.copyWith(errorMessage: result.message);
        return false;
      }
    } catch (e) {
      AppLogger.error('비밀번호 찾기 중 오류 발생', error: e, tag: 'AuthNotifier');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '비밀번호 찾기 중 오류가 발생했습니다: ${e.toString()}',
      );
      return false;
    }
  }

  /// 계정 복구 (일반 계정용)
  Future<bool> restoreAccount(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      AppLogger.info('계정 복구 요청: $email', 'AuthNotifier');

      // 일반 계정 복구는 이메일 인증을 통해 처리
      final result = await ForgotPasswordService.sendPasswordResetEmail(email);

      state = state.copyWith(isLoading: false);

      if (result.success) {
        AppLogger.info('계정 복구 이메일 발송 성공: $email', 'AuthNotifier');
        return true;
      } else {
        AppLogger.warning('계정 복구 이메일 발송 실패: ${result.message}', 'AuthNotifier');
        state = state.copyWith(errorMessage: result.message);
        return false;
      }
    } catch (e) {
      AppLogger.error('계정 복구 중 오류 발생', error: e, tag: 'AuthNotifier');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '계정 복구 중 오류가 발생했습니다: ${e.toString()}',
      );
      return false;
    }
  }

  /// Google 로그인
  Future<GoogleLoginResult> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await GoogleSignInService.instance.signInWithGoogle();

      if (result.success) {
        state = state.copyWith(
          isAuthenticated: true,
          userId: result.userId,
          userEmail: result.userEmail,
          isLoading: false,
        );

        AppLogger.info('Google login successful for user: ${result.userEmail}');
        return GoogleLoginResult.success();
      } else {
        // 계정이 탈퇴된 상태인지 확인
        if (result.isAccountDeleted) {
          AppLogger.info(
            'Account is deleted, user needs to restore: ${result.userEmail}',
          );
          return GoogleLoginResult.accountDeleted(result.userEmail ?? '');
        }

        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: result.message,
        );

        AppLogger.warning('Google login failed: ${result.message}');
        return GoogleLoginResult.failure(result.message);
      }
    } catch (e) {
      AppLogger.error('Google login error', error: e, tag: 'AuthNotifier');

      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: '구글 로그인 중 오류가 발생했습니다.',
      );

      return GoogleLoginResult.failure('구글 로그인 중 오류가 발생했습니다.');
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 복구 성공 후 로그인 상태 설정
  void setRestoredLoginState(String userId, String userEmail) {
    state = state.copyWith(
      isAuthenticated: true,
      userId: userId,
      userEmail: userEmail,
      isLoading: false,
      errorMessage: null,
    );
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

  /// 이메일 인증 코드 발송 (일반 회원가입용)
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

  /// 이메일 인증 코드 검증 (일반 회원가입용)
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

  /// 탈퇴 계정 복구용 인증 코드 발송
  Future<bool> sendRestoreEmail(String email) async {
    if (email.isEmpty) return false;

    try {
      final dio = DioClient.instance.dio;
      AppLogger.info('Sending restore email to: $email');

      final response = await dio.post(
        '/api/auth/restore/send-restore-email',
        data: {'email': email},
      );

      AppLogger.info(
        'Restore email response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        AppLogger.info('Restore email sent successfully to: $email');
        return true;
      }

      AppLogger.warning(
        'Unexpected restore status code: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      AppLogger.error('Failed to send restore email: $email', error: e);
      return false;
    }
  }

  /// 탈퇴 계정 복구 코드 검증
  Future<bool> verifyRestoreCode(String email, String code) async {
    if (email.isEmpty || code.isEmpty) return false;

    try {
      final dio = DioClient.instance.dio;
      final response = await dio.post(
        '/api/auth/restore',
        data: {'email': email, 'verification_code': code},
      );

      if (response.statusCode == 200) {
        AppLogger.info('Restore verification successful: $email');
        return true;
      }

      AppLogger.warning(
        'Restore verification failed with status: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      AppLogger.error('Restore verification failed: $email', error: e);
      return false;
    }
  }
}
