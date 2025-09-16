import 'package:flutter/material.dart';
import 'package:saegim/app/app.dart';
import 'package:saegim/core/config/environment.dart';
import 'package:saegim/shared/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 초기화 후 앱 실행
  await EnvironmentConfig.load();

  AppLogger.info(
    '앱 시작 (env: ${EnvironmentConfig.current.name}, api: ${EnvironmentConfig.apiBaseUrl})',
    'Main',
  );

  runApp(const SaeGimApp());

  AppLogger.info('SaeGimApp 실행 완료', 'Main');
}
