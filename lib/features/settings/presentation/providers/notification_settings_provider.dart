import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/features/settings/data/models/notification_settings_model.dart';
import 'package:saegim/features/settings/data/repositories/notification_settings_repository.dart';

// 알림 설정 상태
class NotificationSettingsNotifier extends StateNotifier<AsyncValue<NotificationSettingsModel>> {
  final NotificationSettingsRepository _repository;

  NotificationSettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    
    try {
      final settings = await _repository.getNotificationSettings();
      state = AsyncValue.data(settings);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> updateSettings(NotificationSettingsUpdateRequest request) async {
    try {
      final settings = await _repository.updateNotificationSettings(request);
      state = AsyncValue.data(settings);
    } catch (e) {
      // 오류 발생 시 이전 상태를 유지하고 오류 표시만 함
      // 실제 앱에서는 사용자에게 오류 메시지를 표시하는 로직이 필요
      // TODO: 사용자에게 오류 메시지 표시 로직 추가
    }
  }

  // 개별 설정 업데이트 헬퍼 메서드들
  Future<void> togglePushNotification(bool enabled) async {
    await updateSettings(NotificationSettingsUpdateRequest(pushEnabled: enabled));
  }

  Future<void> toggleDiaryReminder(bool enabled) async {
    await updateSettings(NotificationSettingsUpdateRequest(diaryReminderEnabled: enabled));
  }

  Future<void> updateDiaryReminderTime(String time) async {
    await updateSettings(NotificationSettingsUpdateRequest(diaryReminderTime: time));
  }

  Future<void> toggleReportNotification(bool enabled) async {
    await updateSettings(NotificationSettingsUpdateRequest(reportNotificationEnabled: enabled));
  }

  Future<void> toggleAiProcessingNotification(bool enabled) async {
    await updateSettings(NotificationSettingsUpdateRequest(aiProcessingNotificationEnabled: enabled));
  }

  Future<void> toggleCommentNotification(bool enabled) async {
    await updateSettings(NotificationSettingsUpdateRequest(commentNotificationEnabled: enabled));
  }

  Future<void> toggleLikeNotification(bool enabled) async {
    await updateSettings(NotificationSettingsUpdateRequest(likeNotificationEnabled: enabled));
  }
}

// Provider 정의
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, AsyncValue<NotificationSettingsModel>>((ref) {
  final repository = ref.watch(notificationSettingsRepositoryProvider);
  return NotificationSettingsNotifier(repository);
});