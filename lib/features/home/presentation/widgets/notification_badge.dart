import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/features/home/presentation/providers/fcm_notification_provider.dart';

/// 읽지 않은 알림 개수를 표시하는 뱃지 위젯
class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? fontSize;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.fontSize,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (unreadCount > 0 || showZero)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: fontSize ?? 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// 특정 감정의 알림 뱃지
class EmotionNotificationBadge extends ConsumerWidget {
  final String emotion;
  final Widget child;
  final Color? badgeColor;

  const EmotionNotificationBadge({
    super.key,
    required this.emotion,
    required this.child,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsByEmotionProvider(emotion));
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (unreadCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: badgeColor ?? _getEmotionColor(emotion),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
      ],
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case 'happy':
        return const Color(0xFFFF9800);
      case 'sad':
        return const Color(0xFF2196F3);
      case 'angry':
        return const Color(0xFFF44336);
      case 'peaceful':
        return const Color(0xFF4CAF50);
      case 'unrest':
        return const Color(0xFFFF5722);
      default:
        return Colors.grey;
    }
  }
}

/// 알림 목록 미리보기 위젯
class NotificationPreview extends ConsumerWidget {
  final int maxItems;
  final VoidCallback? onViewAll;

  const NotificationPreview({
    super.key,
    this.maxItems = 3,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentNotifications = ref.watch(recentNotificationsProvider);
    final displayNotifications = recentNotifications.take(maxItems).toList();

    if (displayNotifications.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              '새로운 알림이 없습니다',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최근 알림',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('전체 보기'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 알림 목록
          ...displayNotifications.map((notification) =>
            NotificationPreviewItem(notification: notification)
          ),

          // 전체 보기 버튼 (하단)
          if (recentNotifications.length > maxItems && onViewAll != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: TextButton(
                  onPressed: onViewAll,
                  child: Text('${recentNotifications.length - maxItems}개 더 보기'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 개별 알림 미리보기 아이템
class NotificationPreviewItem extends ConsumerWidget {
  final FCMNotificationItem notification;

  const NotificationPreviewItem({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        // 알림을 읽음으로 표시
        if (!notification.isRead) {
          ref.read(fcmNotificationProvider.notifier).markAsRead(notification.id);
        }

        // 해당 페이지로 네비게이션
        _navigateToNotification(context, notification);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? null : Colors.blue.withOpacity(0.05),
          border: const Border(
            bottom: BorderSide(color: Colors.grey, width: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 감정 아이콘
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getEmotionColor(notification.emotion).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEmotionIcon(notification.emotion),
                color: _getEmotionColor(notification.emotion),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // 알림 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // 읽지 않음 표시
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToNotification(BuildContext context, FCMNotificationItem notification) {
    // TODO: 실제 네비게이션 로직 구현
    // 예: GoRouter.of(context).go(notification.url ?? '/notifications');
  }

  Color _getEmotionColor(String? emotion) {
    switch (emotion) {
      case 'happy':
        return const Color(0xFFFF9800);
      case 'sad':
        return const Color(0xFF2196F3);
      case 'angry':
        return const Color(0xFFF44336);
      case 'peaceful':
        return const Color(0xFF4CAF50);
      case 'unrest':
        return const Color(0xFFFF5722);
      default:
        return Colors.grey;
    }
  }

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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}