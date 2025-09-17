import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/features/settings/data/models/notification_settings_model.dart';
import 'package:saegim/features/settings/presentation/providers/notification_settings_provider.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('설정을 불러올 수 없습니다\n$error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(notificationSettingsProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (settings) => _buildSettingsContent(context, ref, settings),
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, WidgetRef ref, NotificationSettingsModel settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 페이지 제목
        const Center(
          child: Column(
            children: [
              Icon(Icons.notifications_outlined, size: 60, color: Color(0xFFB2C5B8)),
              SizedBox(height: 16),
              Text(
                '알림 설정',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3A59),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 기본 알림 설정
        _buildSectionTitle('기본 알림'),
        _buildSwitchTile(
          title: '푸시 알림',
          subtitle: '새김 앱의 모든 알림을 받습니다',
          value: settings.pushEnabled,
          onChanged: (value) => ref.read(notificationSettingsProvider.notifier).togglePushNotification(value),
        ),
        
        const SizedBox(height: 24),

        // 다이어리 알림
        _buildSectionTitle('다이어리 알림'),
        _buildSwitchTile(
          title: '다이어리 작성 알림',
          subtitle: '매일 다이어리 작성을 알려드립니다',
          value: settings.diaryReminderEnabled,
          onChanged: (value) => ref.read(notificationSettingsProvider.notifier).toggleDiaryReminder(value),
        ),
        
        if (settings.diaryReminderEnabled)
          _buildTimeTile(
            title: '알림 시간',
            subtitle: settings.diaryReminderTime ?? '20:00',
            onTap: () => _showTimePicker(context, ref, settings.diaryReminderTime ?? '20:00'),
          ),

        const SizedBox(height: 24),

        // 활동 알림
        _buildSectionTitle('활동 알림'),
        _buildSwitchTile(
          title: '주간 리포트 알림',
          subtitle: '감정 분석 리포트가 생성되면 알려드립니다',
          value: settings.reportNotificationEnabled,
          onChanged: (value) => ref.read(notificationSettingsProvider.notifier).toggleReportNotification(value),
        ),
        _buildSwitchTile(
          title: 'AI 처리 완료 알림',
          subtitle: 'AI 감정 분석이 완료되면 알려드립니다',
          value: settings.aiProcessingNotificationEnabled,
          onChanged: (value) => ref.read(notificationSettingsProvider.notifier).toggleAiProcessingNotification(value),
        ),

        const SizedBox(height: 24),

        // 소셜 알림
        _buildSectionTitle('소셜 알림'),
        _buildSwitchTile(
          title: '댓글 알림',
          subtitle: '내 다이어리에 댓글이 달리면 알려드립니다',
          value: settings.commentNotificationEnabled,
          onChanged: (value) => ref.read(notificationSettingsProvider.notifier).toggleCommentNotification(value),
        ),
        _buildSwitchTile(
          title: '좋아요 알림',
          subtitle: '내 다이어리에 좋아요가 눌리면 알려드립니다',
          value: settings.likeNotificationEnabled,
          onChanged: (value) => ref.read(notificationSettingsProvider.notifier).toggleLikeNotification(value),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E3A59),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E3A59),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFB2C5B8),
        activeTrackColor: const Color(0xFFB2C5B8).withOpacity(0.5),
      ),
    );
  }

  Widget _buildTimeTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E3A59),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFB2C5B8),
          ),
        ),
        trailing: const Icon(
          Icons.access_time,
          color: Color(0xFFB2C5B8),
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context, WidgetRef ref, String currentTime) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFB2C5B8),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      ref.read(notificationSettingsProvider.notifier).updateDiaryReminderTime(timeString);
    }
  }
}