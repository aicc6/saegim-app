import 'package:flutter/material.dart';
import 'package:saegim/app/app.dart';
import 'package:saegim/shared/utils/app_logger.dart';

void main() {
  // 앱 초기화 로깅
  AppLogger.info('앱 시작', 'Main');
  
  runApp(const SaeGimApp());
  
  // 앱 실행 완료 로깅
  AppLogger.info('SaeGimApp 실행 완료', 'Main');
}
