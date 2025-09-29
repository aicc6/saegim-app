import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
          const Center(
            child: Column(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 60,
                  color: Color(0xFFB2C5B8),
                ),
                SizedBox(height: 16),
                Text(
                  '개인정보 설정',
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

          // 개인정보 보호 섹션
          _buildSectionTitle('개인정보 보호'),
          const SizedBox(height: 12),
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
        ],
      ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(
          icon,
          color: const Color(0xFFB2C5B8),
          size: 28,
        ),
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
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFFB2C5B8),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}