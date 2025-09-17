import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/features/home/data/models/notification_model.dart';
import 'package:saegim/features/home/presentation/riverpod/notifications_notifier.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 알림 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsNotifierProvider.notifier).loadNotifications();
    });

    // 스크롤 이벤트 감지 (무한 스크롤)
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 하단 200px 남았을 때 더 많은 데이터 로드
      ref.read(notificationsNotifierProvider.notifier).loadMoreNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFB2C5B8),
          ),
        ),
        title: const Text(
          '알림',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB2C5B8),
          ),
        ),
        actions: [
          if (notificationState.unreadCount > 0)
            TextButton(
              onPressed: () async {
                final success = await ref
                    .read(notificationsNotifierProvider.notifier)
                    .markAllAsRead();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모든 알림을 읽음 처리했습니다.')),
                  );
                }
              },
              child: const Text(
                '모두 읽음',
                style: TextStyle(color: Color(0xFFB2C5B8)),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationsNotifierProvider.notifier).refresh();
        },
        child: _buildBody(context, notificationState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state) {
    // 에러 상태
    if (state.errorMessage != null && state.notifications.isEmpty) {
      return _buildErrorWidget(context, state.errorMessage!);
    }

    // 로딩 상태 (첫 로드)
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 빈 상태
    if (state.notifications.isEmpty) {
      return _buildEmptyWidget(context);
    }

    // 알림 목록
    return Column(
      children: [
        // 읽지 않은 알림 개수 표시
        if (state.unreadCount > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFB2C5B8).withValues(alpha: 0.1),
            child: Text(
              '읽지 않은 알림 ${state.unreadCount}개',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              // 로딩 인디케이터 표시
              if (index == state.notifications.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final notification = state.notifications[index];
              return _buildNotificationItem(context, notification);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationItem notification) {
    return Card(
      elevation: notification.isRead ? 1 : 3,
      color: notification.isRead ? Colors.grey[50] : Colors.white,
      child: InkWell(
        onTap: () async {
          if (!notification.isRead) {
            await ref
                .read(notificationsNotifierProvider.notifier)
                .markAsRead(notification.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 읽지 않은 알림 표시
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB2C5B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (!notification.isRead) const SizedBox(width: 8),

                  // 알림 타입 아이콘
                  Icon(
                    _getNotificationIcon(notification.type),
                    size: 20,
                    color: Color(0xFFB2C5B8),
                  ),
                  const SizedBox(width: 8),

                  // 제목
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),

                  // 삭제 버튼
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _showDeleteDialog(context, notification),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 메시지
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),

              // 시간
              Text(
                _formatDate(notification.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            '알림이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 알림이 도착하면 여기에 표시됩니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 24),
          Text(
            '오류가 발생했습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationsNotifierProvider.notifier).loadNotifications();
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, NotificationItem notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('알림 삭제'),
          content: const Text('이 알림을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await ref
                    .read(notificationsNotifierProvider.notifier)
                    .deleteNotification(notification.id);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('알림이 삭제되었습니다.')),
                  );
                }
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'diary':
        return Icons.book;
      case 'system':
        return Icons.settings;
      case 'reminder':
        return Icons.alarm;
      case 'achievement':
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}