import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 인증 토큰 저장 서비스
class AuthStorageService {
  AuthStorageService._();

  static final AuthStorageService _instance = AuthStorageService._();
  static AuthStorageService get instance => _instance;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // 저장 키 상수
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  /// 인증 토큰 저장
  Future<void> saveAuthToken(String token) async {
    try {
      AppLogger.info(
        'Attempting to save token: ${token.substring(0, 10)}...',
        'AuthStorageService',
      );
      await _storage.write(key: _authTokenKey, value: token);
      AppLogger.info('Auth token saved successfully', 'AuthStorageService');

      // 저장 직후 바로 확인
      final savedToken = await _storage.read(key: _authTokenKey);
      if (savedToken == token) {
        AppLogger.info('Token verification successful', 'AuthStorageService');
      } else {
        AppLogger.error(
          'Token verification failed! Saved: ${savedToken?.substring(0, 10) ?? 'null'}',
          tag: 'AuthStorageService',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Failed to save auth token',
        tag: 'AuthStorageService',
        error: e,
      );
    }
  }

  /// 인증 토큰 가져오기
  Future<String?> getAuthToken() async {
    try {
      AppLogger.info(
        'Attempting to read token from storage...',
        'AuthStorageService',
      );
      final token = await _storage.read(key: _authTokenKey);
      if (token != null && token.isNotEmpty) {
        AppLogger.info(
          'Auth token retrieved successfully: ${token.substring(0, 10)}...',
          'AuthStorageService',
        );
      } else {
        AppLogger.warning(
          'No auth token found in storage',
          'AuthStorageService',
        );
      }
      return token;
    } catch (e) {
      AppLogger.error(
        'Failed to retrieve auth token',
        tag: 'AuthStorageService',
        error: e,
      );
      return null;
    }
  }

  /// 리프레시 토큰 저장
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      AppLogger.info('Refresh token saved successfully', 'AuthStorageService');
    } catch (e) {
      AppLogger.error(
        'Failed to save refresh token',
        tag: 'AuthStorageService',
        error: e,
      );
    }
  }

  /// 리프레시 토큰 가져오기
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      AppLogger.error(
        'Failed to retrieve refresh token',
        tag: 'AuthStorageService',
        error: e,
      );
      return null;
    }
  }

  /// 사용자 ID 저장
  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
      AppLogger.info('User ID saved successfully', 'AuthStorageService');
    } catch (e) {
      AppLogger.error(
        'Failed to save user ID',
        tag: 'AuthStorageService',
        error: e,
      );
    }
  }

  /// 사용자 ID 가져오기
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      AppLogger.error(
        'Failed to retrieve user ID',
        tag: 'AuthStorageService',
        error: e,
      );
      return null;
    }
  }

  /// 사용자 이메일 저장
  Future<void> saveUserEmail(String email) async {
    try {
      await _storage.write(key: _userEmailKey, value: email);
      AppLogger.info('User email saved successfully', 'AuthStorageService');
    } catch (e) {
      AppLogger.error(
        'Failed to save user email',
        tag: 'AuthStorageService',
        error: e,
      );
    }
  }

  /// 사용자 이메일 가져오기
  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _userEmailKey);
    } catch (e) {
      AppLogger.error(
        'Failed to retrieve user email',
        tag: 'AuthStorageService',
        error: e,
      );
      return null;
    }
  }

  /// 모든 인증 데이터 삭제 (로그아웃)
  Future<void> clearAllAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _authTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _userEmailKey),
      ]);
      AppLogger.info(
        'All auth data cleared successfully',
        'AuthStorageService',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to clear auth data',
        tag: 'AuthStorageService',
        error: e,
      );
    }
  }

  /// 인증 데이터 존재 여부 확인
  Future<bool> hasAuthData() async {
    try {
      final token = await getAuthToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      AppLogger.error(
        'Failed to check auth data',
        tag: 'AuthStorageService',
        error: e,
      );
      return false;
    }
  }
}
