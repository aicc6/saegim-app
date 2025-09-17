import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:saegim/core/config/environment.dart';
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
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
    );

    _dio = Dio(baseOptions);

    // 보안 쿠키 저장소 설정 (암호화된 영구 저장소)
    final secureCookieJar = SecureCookieJar();
    await secureCookieJar.init();
    _dio.interceptors.add(CookieManager(secureCookieJar));

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

  /// 리소스 정리 (앱 종료 시 호출)
  void dispose() {
    AppLogger.info('DioClient disposed', 'DioClient');
  }
}
