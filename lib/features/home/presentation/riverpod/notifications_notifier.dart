import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saegim/features/home/data/models/notification_model.dart';
import 'package:saegim/features/home/data/services/notification_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

part 'notifications_notifier.g.dart';

/// 알림 상태 모델
class NotificationState {
  final List<NotificationItem> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int total;
  final int unreadCount;
  final bool hasMore;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.total = 0,
    this.unreadCount = 0,
    this.hasMore = false,
  });

  /// 상태 복사 메서드
  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? total,
    int? unreadCount,
    bool? hasMore,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  String toString() {
    return 'NotificationState(notifications: ${notifications.length}, isLoading: $isLoading, unreadCount: $unreadCount)';
  }
}

/// Riverpod 기반 알림 상태 관리
@Riverpod(keepAlive: true)
class NotificationsNotifier extends _$NotificationsNotifier {
  late final NotificationService _notificationService;

  @override
  NotificationState build() {
    _notificationService = NotificationService();
    return const NotificationState();
  }

  /// 알림 목록 초기 로드
  Future<void> loadNotifications({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        notifications: [], // 새로고침 시 기존 목록 클리어
      );
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final response = await _notificationService.getNotificationHistory(
        limit: 20,
        offset: 0,
      );

      state = state.copyWith(
        notifications: response.notifications,
        total: response.total,
        unreadCount: response.unreadCount,
        hasMore: response.hasMore,
        isLoading: false,
      );

      AppLogger.info(
        'Loaded ${response.notifications.length} notifications',
        'NotificationsNotifier'
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );

      AppLogger.error(
        'Failed to load notifications',
        error: e,
        tag: 'NotificationsNotifier'
      );
    }
  }

  /// 더 많은 알림 로드 (페이지네이션)
  Future<void> loadMoreNotifications() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final response = await _notificationService.getNotificationHistory(
        limit: 20,
        offset: state.notifications.length,
      );

      final updatedNotifications = [...state.notifications, ...response.notifications];

      state = state.copyWith(
        notifications: updatedNotifications,
        total: response.total,
        unreadCount: response.unreadCount,
        hasMore: response.hasMore,
        isLoadingMore: false,
      );

      AppLogger.info(
        'Loaded ${response.notifications.length} more notifications, total: ${updatedNotifications.length}',
        'NotificationsNotifier'
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );

      AppLogger.error(
        'Failed to load more notifications',
        error: e,
        tag: 'NotificationsNotifier'
      );
    }
  }

  /// 특정 알림을 읽음 처리
  Future<bool> markAsRead(String notificationId) async {
    try {
      final success = await _notificationService.markNotificationAsRead(notificationId);

      if (success) {
        // 로컬 상태 업데이트
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
          return notification;
        }).toList();

        // 읽지 않은 개수 업데이트
        final newUnreadCount = state.unreadCount > 0 ? state.unreadCount - 1 : 0;

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        );

        AppLogger.info(
          'Marked notification $notificationId as read',
          'NotificationsNotifier'
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );

      AppLogger.error(
        'Failed to mark notification as read: $notificationId',
        error: e,
        tag: 'NotificationsNotifier'
      );
      return false;
    }
  }

  /// 모든 알림을 읽음 처리
  Future<bool> markAllAsRead() async {
    try {
      final success = await _notificationService.markAllNotificationsAsRead();

      if (success) {
        // 로컬 상태 업데이트 - 모든 알림을 읽음으로 변경
        final updatedNotifications = state.notifications.map((notification) {
          if (!notification.isRead) {
            return notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
          return notification;
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        );

        AppLogger.info('Marked all notifications as read', 'NotificationsNotifier');
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );

      AppLogger.error(
        'Failed to mark all notifications as read',
        error: e,
        tag: 'NotificationsNotifier'
      );
      return false;
    }
  }

  /// 특정 알림 삭제
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final success = await _notificationService.deleteNotification(notificationId);

      if (success) {
        // 로컬 상태에서 해당 알림 제거
        final updatedNotifications = state.notifications
            .where((notification) => notification.id != notificationId)
            .toList();

        // 삭제된 알림이 읽지 않은 상태였다면 읽지 않은 개수 감소
        final deletedNotification = state.notifications
            .firstWhere((notification) => notification.id == notificationId);
        final newUnreadCount = deletedNotification.isRead
            ? state.unreadCount
            : (state.unreadCount > 0 ? state.unreadCount - 1 : 0);

        state = state.copyWith(
          notifications: updatedNotifications,
          total: state.total > 0 ? state.total - 1 : 0,
          unreadCount: newUnreadCount,
        );

        AppLogger.info(
          'Deleted notification $notificationId',
          'NotificationsNotifier'
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );

      AppLogger.error(
        'Failed to delete notification: $notificationId',
        error: e,
        tag: 'NotificationsNotifier'
      );
      return false;
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 새로고침
  Future<void> refresh() async {
    await loadNotifications(refresh: true);
  }
}