import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:saegim/core/config/environment.dart';
import 'package:saegim/core/services/auth_storage_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

import 'secure_cookie_jar.dart';

/// Singleton Dio 클라이언트
///
/// 권장 방안에 따라 Singleton 패턴을 사용하여 일관된 설정을 관리하고
/// CookieManager를 통해 중앙화된 쿠키 기반 인증 처리를 제공합니다.
class DioClient {
  DioClient._internal();

  static final DioClient _instance = DioClient._internal();
  static DioClient get instance => _instance;

  late final Dio _dio;
  bool _isInitialized = false;

  /// Dio 인스턴스 getter
  Dio get dio => _dio;

  /// 초기화 확인
  bool get isInitialized => _isInitialized;

  /// 초기화 메서드 (앱 시작 시 호출 필요)
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _initializeDio();
    _isInitialized = true;
  }

  /// 하위 호환성을 위한 정적 메서드 (deprecated)
  @Deprecated('Use DioClient.instance.dio instead')
  static Dio create() {
    return _instance.dio;
  }

  /// Dio 인스턴스 초기화
  Future<void> _initializeDio() async {
    final baseOptions = BaseOptions(
      baseUrl: EnvironmentConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60), // 장문 생성 시간을 고려하여 60초로 증가
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
    );

    _dio = Dio(baseOptions);

    // 보안 쿠키 저장소 설정 (암호화된 영구 저장소)
    final secureCookieJar = SecureCookieJar();
    await secureCookieJar.init();
    _dio.interceptors.add(CookieManager(secureCookieJar));

    // JWT 토큰 인증 인터셉터 추가
    _dio.interceptors.add(_createAuthInterceptor());

    // 로깅 인터셉터 추가
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra['requestStartTime'] = DateTime.now();
          AppLogger.logNetworkRequest(
            method: options.method,
            url: _resolveUrl(options),
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          final startTime = response.requestOptions.extra['requestStartTime'];
          final duration = startTime is DateTime
              ? DateTime.now().difference(startTime)
              : null;

          AppLogger.logNetworkRequest(
            method: response.requestOptions.method,
            url: _resolveUrl(response.requestOptions),
            statusCode: response.statusCode,
            duration: duration,
          );
          handler.next(response);
        },
        onError: (dioError, handler) {
          final request = dioError.requestOptions;
          final startTime = request.extra['requestStartTime'];
          final duration = startTime is DateTime
              ? DateTime.now().difference(startTime)
              : null;

          AppLogger.logNetworkRequest(
            method: request.method,
            url: _resolveUrl(request),
            statusCode: dioError.response?.statusCode,
            duration: duration,
            error: dioError.error,
          );
          handler.next(dioError);
        },
      ),
    );
  }

  /// URL 해결 헬퍼 메서드
  static String _resolveUrl(RequestOptions options) {
    if (options.uri.hasAuthority) {
      return options.uri.toString();
    }

    final base = options.baseUrl.endsWith('/')
        ? options.baseUrl.substring(0, options.baseUrl.length - 1)
        : options.baseUrl;
    final path = options.path.startsWith('/')
        ? options.path
        : '/${options.path}';
    return '$base$path';
  }

  /// 이미지 업로드용 요청 (긴 타임아웃)
  Future<Response> uploadImage(String path, FormData data) {
    return _dio.post(
      path,
      data: data,
      options: Options(
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
  }

  /// 파일 다운로드용 요청 (긴 타임아웃)
  Future<Response> download(String url, String savePath) {
    return _dio.download(
      url,
      savePath,
      options: Options(
        receiveTimeout: const Duration(minutes: 10),
        responseType: ResponseType.stream,
      ),
    );
  }

  /// JWT 토큰 인증 인터셉터 생성
  InterceptorsWrapper _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 토큰이 필요한 API 호출에 Authorization 헤더 추가
        final token = await AuthStorageService.instance.getAuthToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          AppLogger.info(
            'Added Authorization header to ${options.method} ${options.path}',
            'DioClient',
          );
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 401 Unauthorized 에러 처리
        if (error.response?.statusCode == 401) {
          AppLogger.warning(
            'Received 401 Unauthorized for ${error.requestOptions.method} ${error.requestOptions.path}',
            'DioClient',
          );

          // 토큰 갱신 시도 (리프레시 토큰이 있는 경우)
          final refreshToken = await AuthStorageService.instance
              .getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final newToken = await _refreshToken(refreshToken);
              if (newToken != null) {
                // 새 토큰으로 원래 요청 재시도
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';

                AppLogger.info(
                  'Retrying request with refreshed token',
                  'DioClient',
                );

                final response = await _dio.fetch(options);
                return handler.resolve(response);
              }
            } catch (refreshError) {
              AppLogger.error(
                'Token refresh failed',
                tag: 'DioClient',
                error: refreshError,
              );
            }
          }

          // 토큰 갱신 실패 또는 리프레시 토큰 없음 - 인증 데이터 정리
          await AuthStorageService.instance.clearAllAuthData();
          AppLogger.warning(
            'Cleared authentication data due to 401 error - user needs to re-login',
            'DioClient',
          );
        }
        handler.next(error);
      },
    );
  }

  /// 토큰 갱신
  Future<String?> _refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      if (response.statusCode == 200) {
        final newToken = response.data['access_token'] as String?;
        if (newToken != null) {
          await AuthStorageService.instance.saveAuthToken(newToken);
          AppLogger.info('Token refreshed successfully', 'DioClient');
          return newToken;
        }
      }
    } catch (e) {
      AppLogger.error(
        'Token refresh request failed',
        tag: 'DioClient',
        error: e,
      );
    }
    return null;
  }

  /// 리소스 정리 (앱 종료 시 호출)
  void dispose() {
    AppLogger.info('DioClient disposed', 'DioClient');
  }
}
