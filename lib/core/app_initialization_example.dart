import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/core/providers/app_providers.dart';
import 'package:saegim/core/services/fcm_message_service.dart';
import 'package:saegim/features/home/presentation/providers/fcm_notification_provider.dart';
import 'package:saegim/features/home/presentation/widgets/notification_badge.dart';

/// 앱 초기화 및 Riverpod + FCM 연동 예제
/// 실제 main.dart에서 이 패턴을 참고하여 구현하세요
class AppInitializationExample extends StatefulWidget {
  const AppInitializationExample({super.key});

  @override
  State<AppInitializationExample> createState() => _AppInitializationExampleState();
}

class _AppInitializationExampleState extends State<AppInitializationExample> {
  late final ProviderContainer _container;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. ProviderContainer 초기화
    _container = AppProviders.initializeProviders();

    // 2. FCMMessageService에 Navigator Key 설정
    FCMMessageService.setNavigatorKey(_navigatorKey);

    // 3. FCM 서비스 초기화 (백그라운드에서 실행)
    _initializeFCMInBackground();
  }

  void _initializeFCMInBackground() {
    // 앱 시작 시 FCM 초기화를 백그라운드에서 실행
    Future.microtask(() async {
      try {
        await FCMMessageService.instance.initialize();

        // 서버 알림과 동기화
        final fcmNotifier = _container.read(fcmNotificationProvider.notifier);
        await fcmNotifier.syncWithServerNotifications();

        debugPrint('FCM 초기화 및 동기화 완료');
      } catch (e) {
        debugPrint('FCM 초기화 실패: $e');
      }
    });
  }

  @override
  void dispose() {
    AppProviders.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      parent: _container,
      child: MaterialApp.router(
        title: '새김 - FCM 연동 예제',
        routerConfig: _createRouter(),
      ),
    );
  }

  GoRouter _createRouter() {
    return GoRouter(
      navigatorKey: _navigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/diary/new',
          builder: (context, state) => const NewDiaryScreen(),
        ),
        GoRoute(
          path: '/diary/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DiaryDetailScreen(diaryId: id);
          },
        ),
      ],
    );
  }
}

/// 홈 스크린 - FCM 상태를 보여주는 예제
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새김 홈'),
        actions: [
          // 알림 아이콘 with 뱃지
          NotificationBadge(
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => context.go('/notifications'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FCM 상태 카드
            const _FCMStatusCard(),
            const SizedBox(height: 16),

            // 알림 미리보기
            NotificationPreview(
              onViewAll: () => context.go('/notifications'),
            ),
            const SizedBox(height: 16),

            // 감정별 알림 뱃지 예제
            const _EmotionNotificationExample(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/diary/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// FCM 상태를 보여주는 카드
class _FCMStatusCard extends ConsumerWidget {
  const _FCMStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fcmState = ref.watch(fcmNotificationProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'FCM 상태',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (fcmState.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('총 알림: ${fcmState.notifications.length}개'),
                Text('읽지 않음: ${fcmState.unreadCount}개'),
              ],
            ),

            if (fcmState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                '오류: ${fcmState.error}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    ref.read(fcmNotificationProvider.notifier).syncWithServerNotifications();
                  },
                  child: const Text('동기화'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: fcmState.unreadCount > 0 ? () {
                    ref.read(fcmNotificationProvider.notifier).markAllAsRead();
                  } : null,
                  child: const Text('모두 읽음'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 감정별 알림 뱃지 예제
class _EmotionNotificationExample extends StatelessWidget {
  const _EmotionNotificationExample();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '감정별 알림',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEmotionButton('happy', '😊', '기쁨'),
                _buildEmotionButton('sad', '😢', '슬픔'),
                _buildEmotionButton('angry', '😡', '분노'),
                _buildEmotionButton('peaceful', '😌', '평온'),
                _buildEmotionButton('unrest', '😰', '불안'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionButton(String emotion, String emoji, String label) {
    return Column(
      children: [
        EmotionNotificationBadge(
          emotion: emotion,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

/// 알림 목록 스크린
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fcmState = ref.watch(fcmNotificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          if (fcmState.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(fcmNotificationProvider.notifier).markAllAsRead();
              },
              child: const Text('모두 읽음'),
            ),
        ],
      ),
      body: fcmState.isLoading
        ? const Center(child: CircularProgressIndicator())
        : fcmState.notifications.isEmpty
          ? const Center(
              child: Text('알림이 없습니다'),
            )
          : ListView.builder(
              itemCount: fcmState.notifications.length,
              itemBuilder: (context, index) {
                final notification = fcmState.notifications[index];
                return NotificationPreviewItem(notification: notification);
              },
            ),
    );
  }
}

/// 새 다이어리 작성 스크린 (예제)
class NewDiaryScreen extends StatelessWidget {
  const NewDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 다이어리'),
      ),
      body: const Center(
        child: Text('새 다이어리 작성 화면'),
      ),
    );
  }
}

/// 다이어리 상세 스크린 (예제)
class DiaryDetailScreen extends StatelessWidget {
  final String diaryId;

  const DiaryDetailScreen({
    super.key,
    required this.diaryId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('다이어리 상세'),
      ),
      body: Center(
        child: Text('다이어리 ID: $diaryId'),
      ),
    );
  }
}