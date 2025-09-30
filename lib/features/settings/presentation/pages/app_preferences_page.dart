import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/core/providers/theme_provider.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesPage extends ConsumerStatefulWidget {
  const AppPreferencesPage({super.key});

  @override
  ConsumerState<AppPreferencesPage> createState() => _AppPreferencesPageState();
}

class _AppPreferencesPageState extends ConsumerState<AppPreferencesPage> {
  String _currentLanguage = 'ko';
  bool _autoBackup = true;
  bool _offlineMode = false;
  bool _autoSync = true;
  bool _soundEffects = true;
  bool _hapticFeedback = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'ko';
      _autoBackup = prefs.getBool('auto_backup') ?? true;
      _offlineMode = prefs.getBool('offline_mode') ?? false;
      _autoSync = prefs.getBool('auto_sync') ?? true;
      _soundEffects = prefs.getBool('sound_effects') ?? true;
      _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
    });
  }

  Future<void> _saveTheme(ThemeMode theme) async {
    await ref.read(themeProvider.notifier).setTheme(theme);
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    setState(() {
      _currentLanguage = language;
    });
  }

  Future<void> _saveBoolPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

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
                const Icon(
                  Icons.settings_outlined,
                  size: 60,
                  color: Color(0xFFB2C5B8),
                ),
                SizedBox(height: 16),
                Text(
                  '앱 환경설정',
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

          // 테마 설정 섹션
          _buildSectionTitle('테마 설정'),
          const SizedBox(height: 12),
          _buildThemeSettingItem(),

          const SizedBox(height: 24),

          // 언어 설정 섹션
          _buildSectionTitle('언어 설정'),
          const SizedBox(height: 12),
          _buildLanguageSettingItem(),

          const SizedBox(height: 24),

          // 기본 설정 섹션
          _buildSectionTitle('기본 설정'),
          const SizedBox(height: 12),
          _buildSwitchTile(
            icon: Icons.backup_outlined,
            title: '자동 백업',
            subtitle: '데이터를 자동으로 백업합니다',
            value: _autoBackup,
            onChanged: (value) {
              setState(() {
                _autoBackup = value;
              });
              _saveBoolPreference('auto_backup', value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.cloud_sync_outlined,
            title: '자동 동기화',
            subtitle: '변경사항을 자동으로 동기화합니다',
            value: _autoSync,
            onChanged: (value) {
              setState(() {
                _autoSync = value;
              });
              _saveBoolPreference('auto_sync', value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.offline_bolt_outlined,
            title: '오프라인 모드',
            subtitle: '인터넷 연결 없이도 앱을 사용합니다',
            value: _offlineMode,
            onChanged: (value) {
              setState(() {
                _offlineMode = value;
              });
              _saveBoolPreference('offline_mode', value);
            },
          ),

          const SizedBox(height: 24),

          // 사용자 경험 섹션
          _buildSectionTitle('사용자 경험'),
          const SizedBox(height: 12),
          _buildSwitchTile(
            icon: Icons.volume_up_outlined,
            title: '효과음',
            subtitle: '버튼 터치 등의 효과음을 재생합니다',
            value: _soundEffects,
            onChanged: (value) {
              setState(() {
                _soundEffects = value;
              });
              _saveBoolPreference('sound_effects', value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.vibration_outlined,
            title: '햅틱 피드백',
            subtitle: '터치 시 진동 피드백을 제공합니다',
            value: _hapticFeedback,
            onChanged: (value) {
              setState(() {
                _hapticFeedback = value;
              });
              _saveBoolPreference('haptic_feedback', value);
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

  Widget _buildThemeSettingItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: const Icon(
          Icons.palette_outlined,
          color: Color(0xFFB2C5B8),
          size: 28,
        ),
        title: Text(
          '테마',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          _getThemeDisplayName(ref.watch(themeProvider)),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFFB2C5B8),
          size: 16,
        ),
        onTap: () => _showThemeDialog(),
      ),
    );
  }

  Widget _buildLanguageSettingItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: const Icon(
          Icons.language_outlined,
          color: Color(0xFFB2C5B8),
          size: 28,
        ),
        title: Text(
          '언어',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          _getLanguageDisplayName(_currentLanguage),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFFB2C5B8),
          size: 16,
        ),
        onTap: () => _showLanguageDialog(),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
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
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        secondary: Icon(icon, color: const Color(0xFFB2C5B8), size: 28),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFFB2C5B8),
        activeTrackColor: const Color(0xFFB2C5B8).withValues(alpha: 0.5),
      ),
    );
  }

  String _getThemeDisplayName(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.light:
        return '라이트 모드';
      case ThemeMode.dark:
        return '다크 모드';
      case ThemeMode.system:
        return '시스템 설정';
    }
  }

  String _getLanguageDisplayName(String language) {
    switch (language) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      default:
        return '한국어';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '테마 선택',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(ThemeMode.light, '라이트 모드', Icons.light_mode),
            _buildThemeOption(ThemeMode.dark, '다크 모드', Icons.dark_mode),
            _buildThemeOption(ThemeMode.system, '시스템 설정', Icons.settings),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '취소',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(ThemeMode theme, String title, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFFB2C5B8)),
      title: Text(title),
      trailing: ref.watch(themeProvider) == theme
          ? const Icon(Icons.check, color: Color(0xFFB2C5B8))
          : null,
      onTap: () {
        _saveTheme(theme);
        Navigator.of(context).pop();
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '언어 선택',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('ko', '한국어', '🇰🇷'),
            _buildLanguageOption('en', 'English', '🇺🇸'),
            _buildLanguageOption('ja', '日本語', '🇯🇵'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '취소',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String languageCode, String title, String flag) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(title),
      trailing: _currentLanguage == languageCode
          ? const Icon(Icons.check, color: Color(0xFFB2C5B8))
          : null,
      onTap: () {
        _saveLanguage(languageCode);
        Navigator.of(context).pop();
      },
    );
  }
}
