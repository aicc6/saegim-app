import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/core/services/auth_storage_service.dart';
import 'package:saegim/core/services/fcm_message_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// Google 로그인 서비스
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal() {
    _dio = DioClient.instance.dio;
    final clientId = dotenv.env['GOOGLE_ANDROID_CLIENT_ID'];
    AppLogger.info('Google Client ID: ${clientId?.substring(0, 10)}...', _tag);
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );
  }

  static GoogleSignInService get instance => _instance;
  static const String _tag = 'GoogleSignInService';

  late final GoogleSignIn _googleSignIn;
  late final Dio _dio;

  /// Google 로그인 수행
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      AppLogger.info('Google 로그인 시작', _tag);

      // 기존 로그인 상태 확인 및 로그아웃
      final currentUser = _googleSignIn.currentUser;
      if (currentUser != null) {
        await _googleSignIn.signOut();
        AppLogger.info('기존 Google 계정에서 로그아웃', _tag);
      }

      // Google 로그인 시도
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        AppLogger.info('사용자가 Google 로그인을 취소했습니다', _tag);
        return GoogleSignInResult(
          success: false,
          message: '로그인이 취소되었습니다.',
        );
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        AppLogger.error('Google 토큰을 가져올 수 없습니다', tag: _tag);
        return GoogleSignInResult(
          success: false,
          message: '구글 인증 토큰을 가져올 수 없습니다.',
        );
      }

      AppLogger.info('Google 로그인 성공: ${googleUser.email}', _tag);

      // 서버에 Google 토큰으로 로그인 요청
      final serverResponse = await _authenticateWithServer(
        googleAuth.idToken!,
        googleUser,
      );

      if (serverResponse.success) {
        AppLogger.info('서버 인증 성공', _tag);
        return serverResponse;
      } else {
        // 서버 인증 실패 시 Google에서 로그아웃
        await _googleSignIn.signOut();
        return serverResponse;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Google 로그인 중 오류 발생: $e',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );

      // 에러 발생 시 Google에서 로그아웃
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        AppLogger.error('Google 로그아웃 실패', error: signOutError, tag: _tag);
      }

      return GoogleSignInResult(
        success: false,
        message: '구글 로그인 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  /// 서버에 Google 토큰으로 인증 요청
  Future<GoogleSignInResult> _authenticateWithServer(
    String idToken,
    GoogleSignInAccount googleUser,
  ) async {
    try {
      AppLogger.info('서버에 Google 토큰으로 인증 요청', _tag);

      final response = await _dio.post(
        '/api/auth/google-login',
        data: {
          'id_token': idToken,
          'email': googleUser.email,
          'display_name': googleUser.displayName,
          'photo_url': googleUser.photoUrl,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.info('서버 인증 성공: $data', _tag);

        // 백엔드 API 응답 구조: 바디에는 user 정보, 헤더(Set-Cookie)에는 토큰
        final responseData = data['data'] ?? data;
        final userId = responseData['user_id']?.toString();
        final userEmail = responseData['email']?.toString();

        // Set-Cookie 헤더에서 access_token 추출
        String? serverAccessToken;
        String? refreshToken;

        final setCookieHeaders = response.headers['set-cookie'];
        AppLogger.info('Set-Cookie headers: $setCookieHeaders', _tag);

        if (setCookieHeaders != null) {
          for (final cookieHeader in setCookieHeaders) {
            AppLogger.info('Processing cookie: $cookieHeader', _tag);

            // access_token 쿠키 찾기
            if (cookieHeader.startsWith('access_token=')) {
              final tokenPart = cookieHeader.split(';')[0]; // 쿠키 옵션 제거
              serverAccessToken = tokenPart.split('=')[1]; // 토큰 값만 추출
              AppLogger.info(
                'Found access_token in cookie: ${serverAccessToken.substring(0, 10)}...',
                _tag,
              );
            }

            // refresh_token 쿠키 찾기
            if (cookieHeader.startsWith('refresh_token=')) {
              final tokenPart = cookieHeader.split(';')[0]; // 쿠키 옵션 제거
              refreshToken = tokenPart.split('=')[1]; // 토큰 값만 추출
              AppLogger.info(
                'Found refresh_token in cookie: ${refreshToken.substring(0, 10)}...',
                _tag,
              );
            }
          }
        } else {
          AppLogger.warning('No Set-Cookie headers found', _tag);
        }

        // 토큰과 사용자 정보 저장
        if (serverAccessToken != null && serverAccessToken.isNotEmpty) {
          AppLogger.info('토큰과 사용자 정보 저장 중...', _tag);
          await AuthStorageService.instance.saveAuthToken(serverAccessToken);
          AppLogger.info('Auth token 저장 완료', _tag);

          // refresh_token도 별도 저장
          if (refreshToken != null && refreshToken.isNotEmpty) {
            await AuthStorageService.instance.saveRefreshToken(refreshToken);
            AppLogger.info('Refresh token 저장 완료', _tag);
          }

          // 사용자 정보도 저장
          if (userId != null) {
            await AuthStorageService.instance.saveUserId(userId);
          }
          if (userEmail != null) {
            await AuthStorageService.instance.saveUserEmail(userEmail);
          }

          // FCM 토큰 서버 등록
          try {
            final fcmRegistered = await FCMMessageService.instance.registerTokenOnLogin(
              userId: userId,
            );
            AppLogger.info('FCM 토큰 등록 결과: $fcmRegistered', _tag);
          } catch (e) {
            AppLogger.error('FCM 토큰 등록 실패', error: e, tag: _tag);
            // FCM 등록 실패는 로그인 성공에 영향주지 않음
          }

          AppLogger.info('Google 로그인 완료: ${googleUser.email}', _tag);

          return GoogleSignInResult(
            success: true,
            message: '구글 로그인이 완료되었습니다.',
            userId: userId,
            userEmail: userEmail,
          );
        } else {
          AppLogger.error(
            'No access_token found in Set-Cookie headers!',
            tag: _tag,
          );

          return GoogleSignInResult(
            success: false,
            message: '백엔드 서버에서 인증 토큰을 반환하지 않았습니다.',
          );
        }
      } else {
        AppLogger.error('서버 인증 실패: ${response.statusCode}', tag: _tag);
        return GoogleSignInResult(
          success: false,
          message: '서버 인증에 실패했습니다.',
        );
      }
    } on DioException catch (e) {
      AppLogger.error('서버 인증 중 네트워크 오류: ${e.message}', tag: _tag);

      String errorMessage = '서버 인증 중 오류가 발생했습니다.';
      if (e.response?.statusCode == 401) {
        errorMessage = '구글 인증이 유효하지 않습니다.';
      } else if (e.response?.statusCode == 400) {
        errorMessage = '잘못된 요청입니다.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '서버 연결 시간이 초과되었습니다.';
      }

      return GoogleSignInResult(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      AppLogger.error('서버 인증 중 알 수 없는 오류: $e', tag: _tag);
      return GoogleSignInResult(
        success: false,
        message: '알 수 없는 오류가 발생했습니다.',
      );
    }
  }

  /// Google 로그아웃
  Future<void> signOut() async {
    try {
      AppLogger.info('Google에서 로그아웃 중...', _tag);
      await _googleSignIn.signOut();
      AppLogger.info('Google 로그아웃 완료', _tag);
    } catch (e) {
      AppLogger.error('Google 로그아웃 중 오류: $e', tag: _tag);
    }
  }

  /// Google 계정 연결 해제
  Future<void> disconnect() async {
    try {
      AppLogger.info('Google 계정 연결 해제 중...', _tag);
      await _googleSignIn.disconnect();
      AppLogger.info('Google 계정 연결 해제 완료', _tag);
    } catch (e) {
      AppLogger.error('Google 계정 연결 해제 실패', error: e, tag: _tag);
    }
  }

  /// 현재 Google 로그인 상태 확인
  Future<bool> isSignedIn() async {
    try {
      return _googleSignIn.currentUser != null;
    } catch (e) {
      AppLogger.error('Google 로그인 상태 확인 실패', error: e, tag: _tag);
      return false;
    }
  }

  /// 현재 Google 사용자 정보 가져오기
  Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return _googleSignIn.currentUser;
    } catch (e) {
      AppLogger.error('Google 사용자 정보 가져오기 실패', error: e, tag: _tag);
      return null;
    }
  }
}

/// Google 로그인 결과 클래스
class GoogleSignInResult {
  final bool success;
  final String message;
  final String? userId;
  final String? userEmail;

  const GoogleSignInResult({
    required this.success,
    required this.message,
    this.userId,
    this.userEmail,
  });

  @override
  String toString() {
    return 'GoogleSignInResult(success: $success, message: $message, userId: $userId, userEmail: $userEmail)';
  }
}