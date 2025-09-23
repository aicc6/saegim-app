import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/features/home/data/models/notification_model.dart';
import 'package:saegim/features/home/data/services/notification_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// FCM 메시지로부터 생성된 알림 아이템 모델
class FCMNotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? emotion;
  final String? diaryId;
  final String? url;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> originalData;

  const FCMNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.emotion,
    this.diaryId,
    this.url,
    required this.timestamp,
    this.isRead = false,
    required this.originalData,
  });

  /// RemoteMessage로부터 FCMNotificationItem 생성
  factory FCMNotificationItem.fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    return FCMNotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? '새김 알림',
      body: notification?.body ?? '',
      type: data['type'] ?? 'notification',
      emotion: data['emotion'],
      diaryId: data['diaryId'],
      url: data['url'],
      timestamp: data['timestamp'] != null
        ? DateTime.tryParse(data['timestamp']) ?? DateTime.now()
        : DateTime.now(),
      originalData: data,
    );
  }

  /// NotificationItem으로 변환
  NotificationItem toNotificationItem() {
    return NotificationItem(
      id: id,
      title: title,
      message: body,
      isRead: isRead,
      type: type,
      createdAt: timestamp,
      readAt: isRead ? timestamp : null,
      metadata: originalData,
    );
  }

  /// 읽음 상태 변경
  FCMNotificationItem copyWithRead(bool read) {
    return FCMNotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      emotion: emotion,
      diaryId: diaryId,
      url: url,
      timestamp: timestamp,
      isRead: read,
      originalData: originalData,
    );
  }
}

/// FCM 알림 상태 관리
class FCMNotificationState {
  final List<FCMNotificationItem> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const FCMNotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  FCMNotificationState copyWith({
    List<FCMNotificationItem>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return FCMNotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// 읽지 않은 알림 개수 계산
  int get actualUnreadCount => notifications.where((n) => !n.isRead).length;
}

/// FCM 알림 상태 관리 Notifier
class FCMNotificationNotifier extends StateNotifier<FCMNotificationState> {
  final NotificationService _notificationService;

  FCMNotificationNotifier(this._notificationService) : super(const FCMNotificationState());

  /// 새로운 FCM 메시지 추가
  void addFCMMessage(RemoteMessage message) {
    try {
      final fcmNotification = FCMNotificationItem.fromRemoteMessage(message);

      // 중복 메시지 확인
      final existingIndex = state.notifications.indexWhere((n) => n.id == fcmNotification.id);

      List<FCMNotificationItem> updatedNotifications;
      if (existingIndex != -1) {
        // 기존 메시지 업데이트
        updatedNotifications = List.from(state.notifications);
        updatedNotifications[existingIndex] = fcmNotification;
        AppLogger.info('FCM 메시지 업데이트: ${fcmNotification.id}', 'FCMNotificationProvider');
      } else {
        // 새 메시지 추가 (최신 순으로 정렬)
        updatedNotifications = [fcmNotification, ...state.notifications];
        AppLogger.info('새 FCM 메시지 추가: ${fcmNotification.id}', 'FCMNotificationProvider');
      }

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: updatedNotifications.where((n) => !n.isRead).length,
        error: null,
      );

      // 앱 내 알림 표시 로직 (필요시)
      _showInAppNotification(fcmNotification);

    } catch (e) {
      AppLogger.error('FCM 메시지 처리 실패', error: e, tag: 'FCMNotificationProvider');
      state = state.copyWith(error: 'FCM 메시지 처리 중 오류가 발생했습니다.');
    }
  }

  /// 특정 알림을 읽음으로 표시
  Future<void> markAsRead(String notificationId) async {
    try {
      // 로컬 상태 즉시 업데이트
      final updatedNotifications = state.notifications.map((notification) {
        return notification.id == notificationId
          ? notification.copyWithRead(true)
          : notification;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: updatedNotifications.where((n) => !n.isRead).length,
      );

      // 서버에 읽음 상태 동기화 (백그라운드)
      _syncReadStatusToServer(notificationId);

    } catch (e) {
      AppLogger.error('알림 읽음 처리 실패: $notificationId', error: e, tag: 'FCMNotificationProvider');
    }
  }

  /// 모든 알림을 읽음으로 표시
  Future<void> markAllAsRead() async {
    try {
      final updatedNotifications = state.notifications
          .map((notification) => notification.copyWithRead(true))
          .toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );

      // 서버에 전체 읽음 상태 동기화
      _syncAllReadStatusToServer();

    } catch (e) {
      AppLogger.error('전체 알림 읽음 처리 실패', error: e, tag: 'FCMNotificationProvider');
    }
  }

  /// 특정 알림 삭제
  void removeNotification(String notificationId) {
    final updatedNotifications = state.notifications
        .where((notification) => notification.id != notificationId)
        .toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: updatedNotifications.where((n) => !n.isRead).length,
    );

    AppLogger.info('FCM 알림 삭제: $notificationId', 'FCMNotificationProvider');
  }

  /// 모든 알림 삭제
  void clearAllNotifications() {
    state = const FCMNotificationState();
    AppLogger.info('모든 FCM 알림 삭제', 'FCMNotificationProvider');
  }

  /// 감정별 알림 필터링
  List<FCMNotificationItem> getNotificationsByEmotion(String emotion) {
    return state.notifications
        .where((notification) => notification.emotion == emotion)
        .toList();
  }

  /// 타입별 알림 필터링
  List<FCMNotificationItem> getNotificationsByType(String type) {
    return state.notifications
        .where((notification) => notification.type == type)
        .toList();
  }

  /// 서버 알림 히스토리와 동기화
  Future<void> syncWithServerNotifications() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final historyResponse = await _notificationService.getNotificationHistory(
        limit: 50,
        offset: 0,
      );

      // 서버 알림을 FCM 알림 형태로 변환
      final serverNotifications = historyResponse.notifications
          .map((notification) => _convertServerNotificationToFCM(notification))
          .toList();

      // 로컬 FCM 알림과 병합 (중복 제거)
      final mergedNotifications = _mergeNotifications(serverNotifications, state.notifications);

      state = state.copyWith(
        notifications: mergedNotifications,
        unreadCount: mergedNotifications.where((n) => !n.isRead).length,
        isLoading: false,
      );

      AppLogger.info('서버 알림과 동기화 완료: ${mergedNotifications.length}개', 'FCMNotificationProvider');

    } catch (e) {
      AppLogger.error('서버 알림 동기화 실패', error: e, tag: 'FCMNotificationProvider');
      state = state.copyWith(
        isLoading: false,
        error: '서버 알림 동기화 중 오류가 발생했습니다.',
      );
    }
  }

  /// 앱 내 알림 표시 (옵셔널)
  void _showInAppNotification(FCMNotificationItem notification) {
    // TODO: 앱 내 알림 UI 표시 로직
    // 예: SnackBar, Toast, 커스텀 알림 위젯 등
    AppLogger.info(
      '앱 내 알림 표시: ${notification.title} - ${notification.body}',
      'FCMNotificationProvider'
    );
  }

  /// 서버에 읽음 상태 동기화 (백그라운드)
  void _syncReadStatusToServer(String notificationId) {
    // 백그라운드에서 실행하여 UI 블로킹 방지
    Future.microtask(() async {
      try {
        await _notificationService.markNotificationAsRead(notificationId);
        AppLogger.info('서버 읽음 상태 동기화 완료: $notificationId', 'FCMNotificationProvider');
      } catch (e) {
        AppLogger.error('서버 읽음 상태 동기화 실패: $notificationId', error: e, tag: 'FCMNotificationProvider');
      }
    });
  }

  /// 서버에 전체 읽음 상태 동기화
  void _syncAllReadStatusToServer() {
    Future.microtask(() async {
      try {
        await _notificationService.markAllNotificationsAsRead();
        AppLogger.info('서버 전체 읽음 상태 동기화 완료', 'FCMNotificationProvider');
      } catch (e) {
        AppLogger.error('서버 전체 읽음 상태 동기화 실패', error: e, tag: 'FCMNotificationProvider');
      }
    });
  }

  /// 서버 알림을 FCM 알림으로 변환
  FCMNotificationItem _convertServerNotificationToFCM(NotificationItem serverNotification) {
    return FCMNotificationItem(
      id: serverNotification.id,
      title: serverNotification.title,
      body: serverNotification.message,
      type: serverNotification.type,
      emotion: serverNotification.metadata?['emotion'],
      diaryId: serverNotification.metadata?['diaryId'],
      url: serverNotification.metadata?['url'],
      timestamp: serverNotification.createdAt,
      isRead: serverNotification.isRead,
      originalData: serverNotification.metadata ?? {},
    );
  }

  /// 서버 알림과 로컬 FCM 알림 병합
  List<FCMNotificationItem> _mergeNotifications(
    List<FCMNotificationItem> serverNotifications,
    List<FCMNotificationItem> localNotifications,
  ) {
    final Map<String, FCMNotificationItem> mergedMap = {};

    // 서버 알림 추가
    for (final notification in serverNotifications) {
      mergedMap[notification.id] = notification;
    }

    // 로컬 알림 추가 (서버에 없는 것만)
    for (final notification in localNotifications) {
      if (!mergedMap.containsKey(notification.id)) {
        mergedMap[notification.id] = notification;
      }
    }

    // 시간 순으로 정렬 (최신 순)
    final mergedList = mergedMap.values.toList();
    mergedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return mergedList;
  }
}

/// FCM 알림 Provider
final fcmNotificationProvider = StateNotifierProvider<FCMNotificationNotifier, FCMNotificationState>((ref) {
  final notificationService = NotificationService();
  return FCMNotificationNotifier(notificationService);
});

/// 읽지 않은 알림 개수 Provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  final state = ref.watch(fcmNotificationProvider);
  return state.unreadCount;
});

/// 특정 타입의 알림 목록 Provider
final notificationsByTypeProvider = Provider.family<List<FCMNotificationItem>, String>((ref, type) {
  final notifier = ref.watch(fcmNotificationProvider.notifier);
  return notifier.getNotificationsByType(type);
});

/// 특정 감정의 알림 목록 Provider
final notificationsByEmotionProvider = Provider.family<List<FCMNotificationItem>, String>((ref, emotion) {
  final notifier = ref.watch(fcmNotificationProvider.notifier);
  return notifier.getNotificationsByEmotion(emotion);
});

/// 최근 알림 (최대 5개) Provider
final recentNotificationsProvider = Provider<List<FCMNotificationItem>>((ref) {
  final state = ref.watch(fcmNotificationProvider);
  return state.notifications.take(5).toList();
});