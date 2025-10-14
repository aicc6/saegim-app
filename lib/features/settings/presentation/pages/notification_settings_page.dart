import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/core/theme/theme_extensions.dart';
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

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    NotificationSettingsModel settings,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 페이지 제목
        Center(
          child: Column(
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 60,
                color: context.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '알림 설정',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 기본 알림 설정
        _buildSectionTitle(context, '기본 알림'),
        _buildSwitchTile(
          context,
          title: '푸시 알림',
          subtitle: '새김 앱의 모든 알림을 받습니다',
          value: settings.pushEnabled,
          onChanged: (value) => ref
              .read(notificationSettingsProvider.notifier)
              .togglePushNotification(value),
        ),

        const SizedBox(height: 24),

        // 다이어리 알림
        _buildSectionTitle(context, '다이어리 알림'),
        _buildSwitchTile(
          context,
          title: '다이어리 작성 알림',
          subtitle: '매일 다이어리 작성을 알려드립니다',
          value: settings.diaryReminderEnabled,
          onChanged: (value) => ref
              .read(notificationSettingsProvider.notifier)
              .toggleDiaryReminder(value),
        ),

        if (settings.diaryReminderEnabled)
          _buildTimeTile(
            context,
            title: '알림 시간',
            subtitle: settings.diaryReminderTime ?? '20:00',
            onTap: () => _showTimePicker(
              context,
              ref,
              settings.diaryReminderTime ?? '20:00',
            ),
          ),

        const SizedBox(height: 24),

        // 활동 알림
        _buildSectionTitle(context, '활동 알림'),
        _buildSwitchTile(
          context,
          title: '주간 리포트 알림',
          subtitle: '감정 분석 리포트가 생성되면 알려드립니다',
          value: settings.reportNotificationEnabled,
          onChanged: (value) => ref
              .read(notificationSettingsProvider.notifier)
              .toggleReportNotification(value),
        ),
        _buildSwitchTile(
          context,
          title: 'AI 처리 완료 알림',
          subtitle: 'AI 감정 분석이 완료되면 알려드립니다',
          value: settings.aiProcessingNotificationEnabled,
          onChanged: (value) => ref
              .read(notificationSettingsProvider.notifier)
              .toggleAiProcessingNotification(value),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: context.secondaryText),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: context.colorScheme.primary,
        activeTrackColor: context.colorScheme.primary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildTimeTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16),
      decoration: BoxDecoration(
        color: context.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.colorScheme.primary,
          ),
        ),
        trailing: Icon(Icons.access_time, color: context.colorScheme.primary),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    WidgetRef ref,
    String currentTime,
  ) async {
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
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: context.colorScheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      ref
          .read(notificationSettingsProvider.notifier)
          .updateDiaryReminderTime(timeString);
    }
  }
}
