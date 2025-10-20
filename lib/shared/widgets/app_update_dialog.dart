import 'dart:io';

import 'package:flutter/material.dart';
import 'package:saegim/core/models/app_version.dart';
import 'package:url_launcher/url_launcher.dart';

/// 앱 업데이트 다이얼로그
///
/// 새로운 버전이 있을 때 사용자에게 업데이트를 안내하는 다이얼로그
class AppUpdateDialog extends StatelessWidget {
  final CheckAppVersionResponse versionInfo;
  final VoidCallback onSkip;

  const AppUpdateDialog({
    super.key,
    required this.versionInfo,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latestVersion = versionInfo.latestVersion;

    return PopScope(
      canPop: !versionInfo.isMandatory,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('새로운 버전이 있습니다'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (latestVersion != null) ...[
              Text(
                '최신 버전: ${latestVersion.versionName}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (latestVersion.description != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    latestVersion.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
            const SizedBox(height: 16),
            if (versionInfo.isMandatory)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '필수 업데이트입니다. 업데이트 후 사용할 수 있습니다.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          if (!versionInfo.isMandatory)
            TextButton(onPressed: onSkip, child: const Text('나중에')),
          FilledButton(
            onPressed: () => _handleUpdate(context, latestVersion),
            child: const Text('업데이트'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdate(
    BuildContext context,
    AppVersionInfo? latestVersion,
  ) async {
    if (latestVersion?.downloadUrl != null) {
      // 다운로드 URL이 있으면 브라우저로 열기
      final uri = Uri.parse(latestVersion!.downloadUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // 다운로드 URL이 없으면 스토어로 이동
      await _openStore();
    }

    if (context.mounted && !versionInfo.isMandatory) {
      Navigator.of(context).pop();
      onSkip();
    }
  }

  Future<void> _openStore() async {
    if (Platform.isAndroid) {
      // Google Play Store
      final uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.aicc6.saegim',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (Platform.isIOS) {
      // Apple App Store
      final uri = Uri.parse('https://apps.apple.com/app/id YOUR_APP_ID');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
