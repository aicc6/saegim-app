import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 앱 실행 환경을 정의합니다.
enum AppEnvironment { development, staging, production }

extension AppEnvironmentX on AppEnvironment {
  static AppEnvironment parse(String value) {
    final normalized = value.toLowerCase();
    return AppEnvironment.values.firstWhere(
      (env) => env.name == normalized,
      orElse: () => AppEnvironment.development,
    );
  }

  bool get isProduction => this == AppEnvironment.production;
}

/// Dotenv 기반 환경 설정 로더.
class EnvironmentConfig {
  EnvironmentConfig._();

  static AppEnvironment _current = AppEnvironment.development;

  /// 현재 앱 실행 환경
  static AppEnvironment get current => _current;

  /// API 엔드포인트 기본 URL
  static String get apiBaseUrl =>
      dotenv.maybeGet('API_BASE_URL') ?? 'https://saegim-api.aicc-project.com';

  /// 빌드 시 전달된 ENV 값에 따라 환경 설정을 로드합니다.
  static Future<void> load() async {
    const envFromDefine = String.fromEnvironment(
      'ENV',
      defaultValue: 'development',
    );

    final parsedEnv = AppEnvironmentX.parse(envFromDefine);

    try {
      await dotenv.load(fileName: 'assets/env/.env');
      _current = parsedEnv;
      AppLogger.info(
        'Loaded environment file: assets/env/.env',
        'EnvironmentConfig',
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unable to load environment configuration file: assets/env/.env.',
        tag: 'EnvironmentConfig',
        error: error,
        stackTrace: stackTrace,
      );
      if (kDebugMode) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }
}
