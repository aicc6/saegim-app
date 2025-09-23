import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/app/app.dart';
import 'package:saegim/core/config/environment.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/firebase_options.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:saegim/core/services/fcm_message_service.dart';

bool _foregroundHandlersRegistered = false;

/// 애플리케이션 부트스트랩을 담당하는 진입 지점.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 백그라운드 메시지는 runApp 이전에 핸들러를 등록해야 합니다.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 환경 변수 초기화 후 앱 실행
  await EnvironmentConfig.load();

  // DioClient 초기화
  await DioClient.instance.initialize();
  AppLogger.info('DioClient 초기화 완료', 'Bootstrap');

  await _initializeFirebaseAndMessaging();

  AppLogger.info(
    '앱 시작 (env: ${EnvironmentConfig.current.name}, api: ${EnvironmentConfig.apiBaseUrl})',
    'Main',
  );

  runApp(const ProviderScope(child: SaeGimApp()));

  // 앱 실행 완료 로깅
  AppLogger.info('SaeGimApp 실행 완료', 'Main');
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  AppLogger.info(
    '백그라운드 메시지를 처리했습니다. (id: ${message.messageId ?? 'unknown'})',
    'FCM',
  );
}

Future<void> _initializeFirebaseAndMessaging() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.info('Firebase 초기화 완료', 'Firebase');
    }
  } on Object catch (error, stackTrace) {
    AppLogger.error(
      'Firebase 초기화에 실패했습니다.',
      tag: 'Firebase',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }

  final messaging = FirebaseMessaging.instance;

  await messaging.setAutoInitEnabled(true);

  // 플랫폼별 알림 권한 요청
  if (kIsWeb) {
    final settings = await messaging.requestPermission();
    AppLogger.info('웹 알림 권한 상태: ${settings.authorizationStatus.name}', 'FCM');
  } else {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      AppLogger.info(
        'iOS/macOS 알림 권한 상태: ${settings.authorizationStatus.name}',
        'FCM',
      );
    }
  }

  final token = await messaging.getToken();
  if (token != null) {
    AppLogger.debug('FCM 등록 토큰: $token', 'FCM');
  } else {
    AppLogger.warning('FCM 등록 토큰을 가져오지 못했습니다.', 'FCM');
  }

  // FCM 메시지 서비스 초기화
  AppLogger.info('FCMMessageService.instance.initialize() 호출 직전', 'Bootstrap');
  await FCMMessageService.instance.initialize();
  AppLogger.info('FCMMessageService.instance.initialize() 호출 직후', 'Bootstrap');

  if (!_foregroundHandlersRegistered) {
    FirebaseMessaging.onMessage.listen((message) {
      AppLogger.info(
        '포그라운드 메시지 수신 (id: ${message.messageId ?? 'unknown'})',
        'FCM',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLogger.info(
        '사용자가 알림을 통해 앱을 열었습니다. (id: ${message.messageId ?? 'unknown'})',
        'FCM',
      );
    });

    _foregroundHandlersRegistered = true;
  }
}
