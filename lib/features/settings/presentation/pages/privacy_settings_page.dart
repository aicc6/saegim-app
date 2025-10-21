import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/core/theme/theme_extensions.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true, showMenuButton: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 페이지 제목
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 60,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '개인정보 설정',
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

          // 개인정보 보호 섹션
          _buildSectionTitle(context, '개인정보 보호'),
          const SizedBox(height: 12),
          _buildSettingItem(
            context,
            icon: Icons.privacy_tip_outlined,
            title: '개인정보 처리방침',
            subtitle: '개인정보 수집 및 이용에 대한 안내',
            onTap: () => context.push(RoutePaths.settingsPrivacyPolicy),
          ),
          _buildSettingItem(
            context,
            icon: Icons.security_outlined,
            title: '데이터 보안',
            subtitle: '내 데이터 보안 설정 관리',
            onTap: () => _showSecurityGuide(context),
          ),
          _buildSettingItem(
            context,
            icon: Icons.download_outlined,
            title: '내 데이터 다운로드',
            subtitle: '작성한 일기와 사진을 다운로드',
            onTap: () => _showDataExportGuide(context),
          ),

          const SizedBox(height: 32),
        ],
      ),
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

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: context.colorScheme.primary, size: 28),
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
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: context.colorScheme.primary,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showSecurityGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '데이터 보안 안내',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _BottomSheetBullet(
                  text: '다이어리와 이미지 데이터는 암호화 저장소에 보관되며, 서비스 운영진도 원문을 직접 열람할 수 없습니다.',
                ),
                _BottomSheetBullet(
                  text: '로그인 기록과 의심스러운 접속은 실시간으로 감시되며, 비정상 활동 감지 시 즉시 계정 보호 조치를 시행합니다.',
                ),
                _BottomSheetBullet(
                  text: '계정 복구나 탈퇴 요청 시 본인 인증 절차를 필수로 진행하며, 요청 완료 후 30일이 지나면 데이터는 완전히 삭제됩니다.',
                ),
                const SizedBox(height: 16),
                Text(
                  '추가 도움이 필요하시면 고객 지원 > 1:1 문의를 통해 연락해 주세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.secondaryText,
                      ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDataExportGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '데이터 다운로드 안내',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _BottomSheetBullet(
                  text: '작성한 일기와 첨부 이미지는 추출 요청 후 48시간 이내에 암호화된 파일 형태로 제공됩니다.',
                ),
                _BottomSheetBullet(
                  text: '앱에서 직접 다운로드하는 기능을 준비 중이며, 그동안은 고객 지원 채널을 통해 신청하시면 안내해 드립니다.',
                ),
                _BottomSheetBullet(
                  text: '계정 탈퇴 전에 데이터를 백업하려면 최소 3일 전에 신청해 주세요.',
                ),
                const SizedBox(height: 16),
                Text(
                  '문의: support@saegim.app 또는 앱 내 고객 지원 > 1:1 문의',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.secondaryText,
                      ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomSheetBullet extends StatelessWidget {
  const _BottomSheetBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: context.secondaryText)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: context.secondaryText,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
