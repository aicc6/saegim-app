import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:saegim/features/home/data/services/notification_service.dart';
import 'package:saegim/features/home/presentation/providers/fcm_notification_provider.dart';

/// FCM 메시지 처리 서비스
class FCMMessageService {
  static final FCMMessageService _instance = FCMMessageService._internal();
  factory FCMMessageService() => _instance;
  FCMMessageService._internal();

  static FCMMessageService get instance => _instance;

  // 초기화 여부
  bool _isInitialized = false;

  // 알림 서비스 인스턴스
  final NotificationService _notificationService = NotificationService();

  // 전역 Navigator Key
  static GlobalKey<NavigatorState>? _navigatorKey;

  // Riverpod Container 참조
  static ProviderContainer? _container;

  /// Navigator Key 설정 (앱 초기화 시 호출)
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Riverpod Container 설정 (앱 초기화 시 호출)
  static void setProviderContainer(ProviderContainer container) {
    _container = container;
  }

  /// FCM 메시지 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // FCM 메시지 핸들러 등록
      _setupMessageHandlers();

      _isInitialized = true;
      AppLogger.info('FCM 메시지 서비스 초기화 완료', 'FCMMessageService');
    } catch (e) {
      AppLogger.error(
        'FCM 메시지 서비스 초기화 실패',
        error: e,
        tag: 'FCMMessageService',
      );
    }
  }

  /// FCM 메시지 핸들러 설정
  void _setupMessageHandlers() {
    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드에서 알림을 탭하여 앱을 연 경우
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);

    // 앱이 종료된 상태에서 알림을 탭하여 앱을 연 경우 처리
    _handleInitialMessage();

    AppLogger.info('FCM 메시지 핸들러 등록 완료', 'FCMMessageService');
  }

  /// 포그라운드 메시지 처리
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info(
      '포그라운드 메시지 수신: ${message.messageId}',
      'FCMMessageService',
    );

    // 새김 앱 특화: 감정별 알림 처리
    final emotionType = message.data['emotion'];
    final notificationType = message.data['type'] ?? 'general';

    AppLogger.info(
      '알림 유형: $notificationType, 감정: $emotionType',
      'FCMMessageService',
    );

    // 포그라운드에서도 알림 표시 (사용자 설정에 따라)
    await _showLocalNotification(message);

    // 앱 내 알림 상태 업데이트 (Riverpod 활용)
    _updateInAppNotifications(message);
  }

  /// 백그라운드에서 알림 탭으로 앱 열기
  Future<void> _handleNotificationOpenedApp(RemoteMessage message) async {
    AppLogger.info(
      '알림 탭으로 앱 열기: ${message.messageId}',
      'FCMMessageService',
    );

    // 딥링크 처리
    await _handleDeepLink(message);

    // 알림 읽음 처리
    await _markNotificationAsRead(message);
  }

  /// 앱 종료 상태에서 알림으로 시작
  Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      AppLogger.info(
        '종료 상태에서 알림으로 앱 시작: ${initialMessage.messageId}',
        'FCMMessageService',
      );

      // 딥링크 처리 (약간의 지연 후)
      Future.delayed(const Duration(seconds: 1), () {
        _handleDeepLink(initialMessage);
      });
    }
  }

  /// 포그라운드 알림 처리 (Flutter 기본 기능 활용)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // 포그라운드에서는 앱 내 UI로 알림 표시
    // flutter_local_notifications 대신 앱 내 알림 UI 활용
    AppLogger.info(
      '포그라운드 알림 처리: ${notification.title} - ${notification.body}',
      'FCMMessageService',
    );

    // 앱 내 알림 상태 업데이트로 대체
    _updateInAppNotifications(message);
  }


  /// 딥링크 처리
  Future<void> _handleDeepLink(RemoteMessage message) async {
    final url = message.data['url'];
    final type = message.data['type'];
    final diaryId = message.data['diaryId'];

    AppLogger.info(
      '딥링크 처리: type=$type, url=$url, diaryId=$diaryId',
      'FCMMessageService',
    );

    final targetData = <String, String?>{
      'type': type,
      'url': url,
      'diaryId': diaryId,
      'emotion': message.data['emotion'],
    };

    _navigateToTarget(targetData);
  }

  /// 대상 화면으로 네비게이션
  void _navigateToTarget(Map<String, String?> data) {
    final type = data['type'];
    final diaryId = data['diaryId'];

    AppLogger.info(
      '네비게이션 대상: type=$type, diaryId=$diaryId',
      'FCMMessageService',
    );

    // Navigator를 사용한 네비게이션 구현
    if (_navigatorKey?.currentContext != null) {
      final context = _navigatorKey!.currentContext!;

      switch (type) {
        case 'diary_reminder':
          context.go('/diary/new');
          break;
        case 'ai_content_ready':
          if (diaryId != null) {
            context.go('/diary/$diaryId');
          } else {
            context.go('/diary');
          }
          break;
        case 'weekly_report':
          context.go('/reports');
          break;
        case 'notification':
        default:
          context.go('/notifications');
          break;
      }
    } else {
      AppLogger.warning(
        'Navigator context not available for navigation',
        'FCMMessageService',
      );
    }
  }

  /// 알림 읽음 처리
  Future<void> _markNotificationAsRead(RemoteMessage message) async {
    final messageId = message.messageId;
    if (messageId == null) return;

    try {
      // NotificationService를 통한 서버 읽음 처리
      final success = await _notificationService.markNotificationAsRead(messageId);

      if (success) {
        AppLogger.info(
          '알림 읽음 처리 완료: $messageId',
          'FCMMessageService',
        );
      } else {
        AppLogger.warning(
          '알림 읽음 처리 실패: $messageId',
          'FCMMessageService',
        );
      }
    } catch (e) {
      AppLogger.error(
        '알림 읽음 처리 실패: $messageId',
        error: e,
        tag: 'FCMMessageService',
      );
    }
  }

  /// 앱 내 알림 상태 업데이트
  void _updateInAppNotifications(RemoteMessage message) {
    AppLogger.info(
      '앱 내 알림 상태 업데이트: ${message.messageId}',
      'FCMMessageService',
    );

    // Riverpod Provider를 통한 상태 업데이트
    if (_container != null) {
      try {
        final notifier = _container!.read(fcmNotificationProvider.notifier);
        notifier.addFCMMessage(message);

        AppLogger.info(
          'Riverpod 상태 업데이트 완료: ${message.messageId}',
          'FCMMessageService',
        );
      } catch (e) {
        AppLogger.error(
          'Riverpod 상태 업데이트 실패: ${message.messageId}',
          error: e,
          tag: 'FCMMessageService',
        );
      }
    } else {
      AppLogger.warning(
        'ProviderContainer가 설정되지 않음. Riverpod 상태 업데이트 건너뛰기',
        'FCMMessageService',
      );
    }

    // 추가 처리: 앱이 포그라운드에 있을 때 시각적 피드백
    if (_navigatorKey?.currentContext != null) {
      _showInAppNotificationFeedback(message);
    }
  }

  /// 앱 내 알림 시각적 피드백 표시
  void _showInAppNotificationFeedback(RemoteMessage message) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final notification = message.notification;
    if (notification == null) return;

    // 감정에 따른 색상 선택
    final emotion = message.data['emotion'];
    Color notificationColor = _getEmotionColor(emotion);

    // 스낵바로 간단한 알림 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getEmotionIcon(emotion),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title ?? '새김 알림',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (notification.body != null)
                    Text(
                      notification.body!,
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: notificationColor,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '보기',
          textColor: Colors.white,
          onPressed: () {
            final targetData = <String, String?>{
              'type': message.data['type'],
              'url': message.data['url'],
              'diaryId': message.data['diaryId'],
              'emotion': message.data['emotion'],
            };
            _navigateToTarget(targetData);
          },
        ),
      ),
    );
  }

  /// 감정별 색상 반환
  Color _getEmotionColor(String? emotion) {
    switch (emotion) {
      case 'happy':
        return const Color(0xFFFF9800); // 주황색
      case 'sad':
        return const Color(0xFF2196F3); // 파란색
      case 'angry':
        return const Color(0xFFF44336); // 빨간색
      case 'peaceful':
        return const Color(0xFF4CAF50); // 초록색
      case 'unrest':
        return const Color(0xFFFF5722); // 주황빨간색
      default:
        return const Color(0xFF9E9E9E); // 회색
    }
  }

  /// 감정별 아이콘 반환
  IconData _getEmotionIcon(String? emotion) {
    switch (emotion) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
        return Icons.sentiment_dissatisfied;
      case 'peaceful':
        return Icons.sentiment_satisfied;
      case 'unrest':
        return Icons.sentiment_neutral;
      default:
        return Icons.notifications;
    }
  }

  /// FCM 토큰 가져오기 (앱 시작 시 호출)
  Future<String?> getToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        AppLogger.info(
          'FCM 토큰 생성: ${token.substring(0, 50)}...',
          'FCMMessageService',
        );
        return token;
      }
    } catch (e) {
      AppLogger.error(
        'FCM 토큰 생성 실패',
        error: e,
        tag: 'FCMMessageService',
      );
    }

    return null;
  }

  /// 로그인 시 FCM 토큰 서버 등록
  /// 웹 프론트엔드와 동일한 패턴으로 구현
  Future<bool> registerTokenOnLogin({String? userId}) async {
    try {
      final token = await getToken();
      if (token == null) {
        AppLogger.warning('FCM 토큰이 없어 서버 등록을 건너뜁니다.', 'FCMMessageService');
        return false;
      }

      // NotificationService를 통한 실제 서버 등록
      final success = await _notificationService.registerFCMToken(
        token: token,
        userId: userId,
      );

      if (success) {
        AppLogger.info(
          'FCM 토큰 서버 등록 성공: ${token.substring(0, 50)}...',
          'FCMMessageService',
        );
      } else {
        AppLogger.warning(
          'FCM 토큰 서버 등록 실패: ${token.substring(0, 50)}...',
          'FCMMessageService',
        );
      }

      return success;
    } catch (e) {
      AppLogger.error(
        'FCM 토큰 서버 등록 실패',
        error: e,
        tag: 'FCMMessageService',
      );
      return false;
    }
  }

  /// 로그아웃 시 FCM 토큰 비활성화
  Future<bool> deactivateTokenOnLogout() async {
    try {
      final token = await getToken();
      if (token == null) {
        AppLogger.warning('FCM 토큰이 없어 서버 해제를 건너뜁니다.', 'FCMMessageService');
        return true; // 토큰이 없으면 성공으로 간주
      }

      // NotificationService를 통한 실제 서버 해제
      final success = await _notificationService.unregisterFCMToken(token);

      if (success) {
        AppLogger.info(
          'FCM 토큰 서버 해제 성공: ${token.substring(0, 50)}...',
          'FCMMessageService',
        );
      } else {
        AppLogger.warning(
          'FCM 토큰 서버 해제 실패: ${token.substring(0, 50)}...',
          'FCMMessageService',
        );
      }

      return success;
    } catch (e) {
      AppLogger.error(
        'FCM 토큰 비활성화 실패',
        error: e,
        tag: 'FCMMessageService',
      );
      return false;
    }
  }

  /// FCM 토큰 등록 상태 확인
  Future<Map<String, dynamic>?> checkTokenStatus() async {
    try {
      final token = await getToken();
      if (token == null) {
        AppLogger.warning('FCM 토큰이 없어 상태 확인을 건너뜁니다.', 'FCMMessageService');
        return null;
      }

      // NotificationService를 통한 토큰 상태 확인
      final status = await _notificationService.checkFCMTokenStatus(token);

      if (status != null) {
        AppLogger.info(
          'FCM 토큰 상태 확인 성공: ${token.substring(0, 50)}...',
          'FCMMessageService',
        );
      } else {
        AppLogger.info(
          'FCM 토큰이 서버에 등록되지 않음: ${token.substring(0, 50)}...',
          'FCMMessageService',
        );
      }

      return status;
    } catch (e) {
      AppLogger.error(
        'FCM 토큰 상태 확인 실패',
        error: e,
        tag: 'FCMMessageService',
      );
      return null;
    }
  }

  /// 서비스 정리
  void dispose() {
    _isInitialized = false;
    AppLogger.info('FCM 메시지 서비스 정리 완료', 'FCMMessageService');
  }
}