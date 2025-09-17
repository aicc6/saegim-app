import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20),
          // 페이지 제목
          const Center(
            child: Column(
              children: [
                Icon(Icons.settings, size: 60, color: Color(0xFFB2C5B8)),
                SizedBox(height: 16),
                Text(
                  '설정',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3A59),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // 설정 메뉴들
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: '알림 설정',
            subtitle: '푸시 알림, 다이어리 알림 등',
            onTap: () => context.push('/settings/notifications'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.palette_outlined,
            title: '앱 환경설정',
            subtitle: '테마, 언어, 기본 설정',
            onTap: () => context.push('/settings/app-preferences'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: '개인정보 설정',
            subtitle: '계정 정보, 데이터 관리',
            onTap: () => context.push('/settings/privacy'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.key_outlined,
            title: '비밀번호 변경',
            subtitle: '계정 보안 관리',
            onTap: () => context.push('/settings/change-password'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFB2C5B8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFB2C5B8),
            size: 24,
          ),
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
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFFB2C5B8),
        ),
        onTap: onTap,
      ),
    );
  }
}