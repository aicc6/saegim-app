import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 앱 전체에서 사용할 로깅 유틸리티 클래스
class AppLogger {
  static final Logger _logger = Logger(
    level: kDebugMode ? Level.debug : Level.warning,
    printer: kDebugMode
        ? PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          )
        : SimplePrinter(),
    filter: ProductionFilter(),
  );

  /// 디버그 메시지 출력 (개발 환경에서만)
  static void debug(String message, [String? tag]) {
    _logger.d(_formatMessage(message, tag));
  }

  /// 정보성 메시지 출력
  static void info(String message, [String? tag]) {
    _logger.i(_formatMessage(message, tag));
  }

  /// 경고 메시지 출력
  static void warning(String message, [String? tag]) {
    _logger.w(_formatMessage(message, tag));
  }

  /// 오류 메시지 출력
  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      _formatMessage(message, tag),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 구조화된 로깅을 위한 메서드
  static void logEvent({
    required String event,
    String? tag,
    Map<String, dynamic>? data,
  }) {
    final message = StringBuffer(event);
    if (data != null && data.isNotEmpty) {
      message.write(' | Data: $data');
    }
    info(message.toString(), tag);
  }

  /// 성능 측정을 위한 로깅
  static void logPerformance({
    required String operation,
    required Duration duration,
    String? tag,
  }) {
    info(
      'Performance: $operation took ${duration.inMilliseconds}ms',
      tag ?? 'Performance',
    );
  }

  /// 네트워크 요청 로깅
  static void logNetworkRequest({
    required String method,
    required String url,
    int? statusCode,
    Duration? duration,
    dynamic error,
  }) {
    final message = StringBuffer('$method $url');
    if (statusCode != null) {
      message.write(' → $statusCode');
    }
    if (duration != null) {
      message.write(' (${duration.inMilliseconds}ms)');
    }

    if (error != null) {
      AppLogger.error(message.toString(), tag: 'Network', error: error);
    } else {
      AppLogger.info(message.toString(), 'Network');
    }
  }

  /// 사용자 액션 로깅
  static void logUserAction({
    required String action,
    String? screen,
    Map<String, dynamic>? metadata,
  }) {
    final message = StringBuffer('User Action: $action');
    if (screen != null) {
      message.write(' on $screen');
    }
    
    logEvent(
      event: message.toString(),
      tag: 'UserAction',
      data: metadata,
    );
  }

  /// 메시지 포맷팅
  static String _formatMessage(String message, String? tag) {
    return tag != null ? '[$tag] $message' : message;
  }
}

/// 프로덕션 환경에서 로그 필터링
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kDebugMode) {
      return true;
    }
    // 프로덕션에서는 warning 이상만 로그
    return event.level.index >= Level.warning.index;
  }
}