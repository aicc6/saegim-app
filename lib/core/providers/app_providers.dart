import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/features/home/presentation/providers/fcm_notification_provider.dart';
import 'package:saegim/core/services/fcm_message_service.dart';

/// 앱 전체 Provider 초기화 관리
class AppProviders {
  static ProviderContainer? _container;

  /// ProviderContainer 초기화 및 설정
  static ProviderContainer initializeProviders() {
    _container = ProviderContainer();

    // FCMMessageService에 ProviderContainer 설정
    FCMMessageService.setProviderContainer(_container!);

    return _container!;
  }

  /// ProviderContainer 가져오기
  static ProviderContainer? get container => _container;

  /// Provider 정리
  static void dispose() {
    _container?.dispose();
    _container = null;
  }
}

/// FCM 관련 Provider들을 한 번에 초기화하는 Provider
final fcmInitializationProvider = FutureProvider<void>((ref) async {
  // FCM 서비스 초기화
  await FCMMessageService.instance.initialize();

  // 서버 알림과 동기화
  final fcmNotifier = ref.read(fcmNotificationProvider.notifier);
  await fcmNotifier.syncWithServerNotifications();
});

/// 앱 초기화 상태 Provider
final appInitializationProvider = FutureProvider<bool>((ref) async {
  try {
    // FCM 초기화 완료 대기
    await ref.watch(fcmInitializationProvider.future);

    // 다른 초기화 작업들...
    // await 다른초기화Provider.future;

    return true;
  } catch (e) {
    // 초기화 실패 시에도 앱은 계속 실행되도록 함
    return false;
  }
});