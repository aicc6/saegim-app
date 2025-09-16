import 'package:dio/dio.dart';
import 'package:saegim/core/config/environment.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 공통 Dio 인스턴스를 생성하고 구성합니다.
class DioClient {
  DioClient._();

  static Dio create() {
    final baseOptions = BaseOptions(
      baseUrl: EnvironmentConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
    );

    final dio = Dio(baseOptions);

    dio.interceptors.add(
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

    return dio;
  }

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
}
