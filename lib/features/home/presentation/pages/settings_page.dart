import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _developerModeKey = 'developer_mode_enabled';
  static const int _requiredTaps = 7;

  int _tapCount = 0;
  bool _isDeveloperModeEnabled = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadDeveloperModeState();
    _loadAppVersion();
  }

  Future<void> _loadDeveloperModeState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDeveloperModeEnabled = prefs.getBool(_developerModeKey) ?? false;
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _onVersionTap() async {
    setState(() {
      _tapCount++;
    });

    if (_tapCount >= _requiredTaps && !_isDeveloperModeEnabled) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_developerModeKey, true);

      setState(() {
        _isDeveloperModeEnabled = true;
        _tapCount = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔧 개발자 모드가 활성화되었습니다'),
            backgroundColor: Color(0xFFB2C5B8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (_tapCount >= _requiredTaps && _isDeveloperModeEnabled) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_developerModeKey, false);

      setState(() {
        _isDeveloperModeEnabled = false;
        _tapCount = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('개발자 모드가 비활성화되었습니다'),
            backgroundColor: Colors.grey,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // 3초 후 탭 카운트 초기화
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _tapCount = 0;
        });
      }
    });
  }

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

          const SizedBox(height: 40),

          // 앱 정보 섹션
          const Divider(),
          const SizedBox(height: 20),
          const Text(
            '앱 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 16),

          // 버전 정보 (이스터에그 트리거)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB2C5B8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFFB2C5B8),
                  size: 24,
                ),
              ),
              title: const Text(
                '앱 버전',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3A59),
                ),
              ),
              subtitle: Text(
                _appVersion,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              onTap: _onVersionTap,
            ),
          ),

          // 개발자 도구 (개발자 모드 활성화 시에만)
          if (_isDeveloperModeEnabled) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  '개발자 도구',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3A59),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB2C5B8).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    kDebugMode ? 'DEBUG MODE' : 'EASTER EGG',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3A59),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              context,
              icon: Icons.bug_report_outlined,
              title: 'FCM 디버깅',
              subtitle: 'Firebase 알림 상태 및 토큰 확인',
              onTap: () => context.push('/debug/fcm'),
            ),
          ],
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
            color: Colors.grey.withValues(alpha: 0.1),
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
            color: const Color(0xFFB2C5B8).withValues(alpha: 0.1),
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