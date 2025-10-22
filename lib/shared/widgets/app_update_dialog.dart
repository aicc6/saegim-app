import 'dart:io';

import 'package:flutter/material.dart';
import 'package:saegim/core/models/app_version.dart';
import 'package:saegim/shared/utils/app_logger.dart';
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
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Icon(
                Icons.system_update_outlined,
                color: theme.colorScheme.primary,
                size: 56,
              ),
              const SizedBox(height: 20),

              // 타이틀
              Text(
                '업데이트',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 버전 정보
              if (latestVersion != null) ...[
                Text(
                  'v${latestVersion.versionName}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // 설명 (있는 경우)
                if (latestVersion.description != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      latestVersion.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // 필수 업데이트 뱃지
              if (versionInfo.isMandatory)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.priority_high,
                        color: theme.colorScheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '필수',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // 버튼들
              Row(
                children: [
                  if (!versionInfo.isMandatory)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onSkip();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('나중에'),
                      ),
                    ),
                  if (!versionInfo.isMandatory) const SizedBox(width: 12),
                  Expanded(
                    flex: versionInfo.isMandatory ? 1 : 1,
                    child: FilledButton(
                      onPressed: () => _handleUpdate(context, latestVersion),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('업데이트'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdate(
    BuildContext context,
    AppVersionInfo? latestVersion,
  ) async {
    try {
      AppLogger.info(
        '업데이트 버튼 클릭 - downloadUrl: ${latestVersion?.downloadUrl}',
        'AppUpdateDialog',
      );

      if (latestVersion?.downloadUrl != null &&
          latestVersion!.downloadUrl!.isNotEmpty) {
        // 다운로드 URL이 있으면 브라우저로 열기
        final downloadUrl = latestVersion.downloadUrl!;
        AppLogger.info('다운로드 URL 열기 시도: $downloadUrl', 'AppUpdateDialog');

        final uri = Uri.parse(downloadUrl);
        final canLaunch = await canLaunchUrl(uri);

        AppLogger.info('URL 실행 가능 여부: $canLaunch', 'AppUpdateDialog');

        if (canLaunch) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          AppLogger.info('URL 실행 결과: $launched', 'AppUpdateDialog');

          if (!launched) {
            throw Exception('URL 실행 실패');
          }
        } else {
          throw Exception('URL을 실행할 수 없습니다');
        }
      } else {
        // 다운로드 URL이 없으면 스토어로 이동
        AppLogger.info('다운로드 URL 없음 - 스토어로 이동', 'AppUpdateDialog');
        await _openStore();
      }

      if (context.mounted && !versionInfo.isMandatory) {
        Navigator.of(context).pop();
        onSkip();
      }
    } catch (e) {
      AppLogger.error('업데이트 처리 중 오류: $e', tag: 'AppUpdateDialog', error: e);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('다운로드를 시작할 수 없습니다: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openStore() async {
    try {
      if (Platform.isAndroid) {
        // Google Play Store
        final uri = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.aicc6.saegim',
        );
        AppLogger.info('Play Store 열기 시도: $uri', 'AppUpdateDialog');

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Play Store를 열 수 없습니다');
        }
      } else if (Platform.isIOS) {
        // Apple App Store
        final uri = Uri.parse('https://apps.apple.com/app/id YOUR_APP_ID');
        AppLogger.info('App Store 열기 시도: $uri', 'AppUpdateDialog');

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('App Store를 열 수 없습니다');
        }
      }
    } catch (e) {
      AppLogger.error('스토어 열기 실패: $e', tag: 'AppUpdateDialog', error: e);
      rethrow;
    }
  }
}
