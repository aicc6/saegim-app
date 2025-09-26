import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true, showMenuButton: false),
      backgroundColor: const Color(0xFFFAFBFA),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '개인정보 설정',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '개인정보 보호 및 계정 관리 설정',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 32),

            // 개인정보 보호 섹션
            _buildSectionTitle('개인정보 보호'),
            const SizedBox(height: 16),
            _buildSettingItem(
              context,
              icon: Icons.privacy_tip_outlined,
              title: '개인정보 처리방침',
              subtitle: '개인정보 수집 및 이용에 대한 안내',
              onTap: () {
                // 개인정보 처리방침 페이지로 이동
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.security_outlined,
              title: '데이터 보안',
              subtitle: '내 데이터 보안 설정 관리',
              onTap: () {
                // 데이터 보안 설정 페이지로 이동
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.download_outlined,
              title: '내 데이터 다운로드',
              subtitle: '작성한 일기와 사진을 다운로드',
              onTap: () {
                // 데이터 다운로드 기능
              },
            ),

            const SizedBox(height: 32),

            // 계정 관리 섹션
            _buildSectionTitle('계정 관리'),
            const SizedBox(height: 16),
            _buildSettingItem(
              context,
              icon: Icons.delete_outline,
              title: '계정 탈퇴',
              subtitle: '계정을 탈퇴합니다 (30일 이내 복구 가능)',
              onTap: () {
                context.push('/auth/delete-account');
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? const Color(0xFF8B7355) : const Color(0xFFB2C5B8),
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDestructive ? const Color(0xFF8B7355) : const Color(0xFF2D3748),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF718096),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF718096),
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}