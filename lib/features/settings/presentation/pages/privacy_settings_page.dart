import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/core/theme/theme_extensions.dart';
import 'package:saegim/features/settings/data/models/security_settings_model.dart';
import 'package:saegim/features/settings/presentation/providers/security_settings_provider.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class PrivacySettingsPage extends ConsumerStatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  ConsumerState<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends ConsumerState<PrivacySettingsPage> {
  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securitySettingsProvider);

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true, showMenuButton: false),
      body: securityState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, error.toString()),
        data: (settings) => _buildContent(context, settings),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text('보안 설정을 불러오지 못했습니다',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.secondaryText,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(securitySettingsProvider.notifier).refresh(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, SecuritySettingsModel settings) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
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
                '데이터 보안',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '중요한 기록을 안전하게 보호하는 방법을 선택하세요',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.secondaryText,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionTitle(context, '보호 옵션'),
        _buildSecurityCard(
          context,
          icon: Icons.book_outlined,
          title: '다이어리 PIN 잠금',
          description: '다이어리 목록과 상세 내용을 열 때 PIN 또는 생체 인증을 요구합니다.',
          enabled: settings.diaryLockEnabled,
          onToggle: (value) => _handleToggle(
            context,
            settings,
            value,
            onEnable: () => ref
                .read(securitySettingsProvider.notifier)
                .updateLocks(diaryLockEnabled: true),
            onDisable: () => ref
                .read(securitySettingsProvider.notifier)
                .updateLocks(diaryLockEnabled: false),
          ),
        ),
        _buildSecurityCard(
          context,
          icon: Icons.calendar_month_outlined,
          title: '캘린더 PIN 잠금',
          description: '감정 캘린더에 접근할 때 인증을 거쳐 주변에서 엿보는 것을 방지합니다.',
          enabled: settings.calendarLockEnabled,
          onToggle: (value) => _handleToggle(
            context,
            settings,
            value,
            onEnable: () => ref
                .read(securitySettingsProvider.notifier)
                .updateLocks(calendarLockEnabled: true),
            onDisable: () => ref
                .read(securitySettingsProvider.notifier)
                .updateLocks(calendarLockEnabled: false),
          ),
        ),
        _buildSecurityCard(
          context,
          icon: Icons.lock_outline,
          title: '앱 전체 잠금',
          description: '앱을 다시 열 때 자동으로 잠금 화면이 표시되도록 합니다.',
          enabled: settings.appLockEnabled,
          onToggle: (value) => _handleToggle(
            context,
            settings,
            value,
            onEnable: () => ref
                .read(securitySettingsProvider.notifier)
                .updateLocks(appLockEnabled: true),
            onDisable: () => ref
                .read(securitySettingsProvider.notifier)
                .updateLocks(appLockEnabled: false, useBiometrics: false),
          ),
          extraContent: settings.appLockEnabled
              ? _buildBiometricTile(context, settings)
              : null,
        ),
        const SizedBox(height: 32),
        _buildSectionTitle(context, '정책 및 안내'),
        _buildSettingItem(
          context,
          icon: Icons.policy_outlined,
          title: '개인정보 처리방침',
          subtitle: '데이터 수집·이용 및 보관 정책을 확인합니다',
          onTap: () => context.push(RoutePaths.settingsPrivacyPolicy),
        ),
        _buildSettingItem(
          context,
          icon: Icons.security_outlined,
          title: '데이터 보안 안내',
          subtitle: '암호화 저장, 복구 절차 등 보안 정책을 소개합니다',
          onTap: () => _showSecurityGuide(context),
        ),
        _buildSettingItem(
          context,
          icon: Icons.download_outlined,
          title: '내 데이터 다운로드',
          subtitle: '일기와 이미지를 백업하는 방법을 안내합니다',
          onTap: () => _showDataExportGuide(context),
        ),
        const SizedBox(height: 24),
        if (settings.hasPin)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _handleChangePin(context, settings),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('PIN 변경'),
            ),
          ),
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

  Widget _buildSecurityCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
    required Future<void> Function(bool value) onToggle,
    Widget? extraContent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: context.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              color: context.secondaryText,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  activeColor: context.colorScheme.primary,
                  onChanged: (value) async => onToggle(value),
                ),
              ],
            ),
            if (extraContent != null) ...[
              const SizedBox(height: 16),
              extraContent,
            ],
          ],
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Icon(icon, color: context.colorScheme.primary, size: 26),
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
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: context.secondaryText),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBiometricTile(
      BuildContext context, SecuritySettingsModel settings) {
    return Row(
      children: [
        Icon(Icons.fingerprint, color: context.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '생체 인증 함께 사용',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '지원 기기에서는 지문이나 얼굴 인식을 활용해 잠금을 해제합니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.secondaryText,
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: settings.useBiometrics,
          onChanged: (value) => ref
              .read(securitySettingsProvider.notifier)
              .updateLocks(useBiometrics: value),
        ),
      ],
    );
  }

  Future<void> _handleToggle(
    BuildContext context,
    SecuritySettingsModel settings,
    bool value, {
    required Future<void> Function() onEnable,
    required Future<void> Function() onDisable,
  }) async {
    if (value) {
      final ensured = await _ensurePinExists(context, settings);
      if (!ensured) {
        return;
      }
      await onEnable();
    } else {
      final verified = await _verifyPin(context);
      if (!verified) {
        return;
      }
      await onDisable();
    }
  }

  Future<bool> _ensurePinExists(
      BuildContext context, SecuritySettingsModel settings) async {
    if (settings.hasPin) return true;

    final newPin = await _createPinFlow(context);
    if (newPin == null) {
      return false;
    }

    await ref.read(securitySettingsProvider.notifier).setPin(newPin);
    if (!mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN이 설정되었습니다.')),
    );
    return true;
  }

  Future<String?> _createPinFlow(BuildContext context) async {
    final first = await _showPinInputDialog(
      context,
      title: 'PIN 설정',
      message: '6자리 숫자 PIN을 입력해주세요.',
    );
    if (first == null) {
      return null;
    }

    final confirm = await _showPinInputDialog(
      context,
      title: 'PIN 확인',
      message: '다시 한 번 동일한 PIN을 입력해주세요.',
    );

    if (confirm == null) {
      return null;
    }

    if (first != confirm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN이 일치하지 않습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return null;
    }

    return first;
  }

  Future<bool> _verifyPin(BuildContext context) async {
    final input = await _showPinInputDialog(
      context,
      title: 'PIN 확인',
      message: '잠금을 해제하려면 PIN을 입력해주세요.',
    );

    if (input == null) {
      return false;
    }

    final verified = await ref.read(securitySettingsProvider.notifier).verifyPin(input);
    if (!verified && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN이 올바르지 않습니다.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    return verified;
  }

  Future<void> _handleChangePin(
      BuildContext context, SecuritySettingsModel settings) async {
    final verified = await _verifyPin(context);
    if (!verified) return;

    final newPin = await _createPinFlow(context);
    if (newPin == null) return;

    await ref.read(securitySettingsProvider.notifier).setPin(newPin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN이 변경되었습니다.')),
    );
  }

  Future<String?> _showPinInputDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    hintText: '6자리 숫자',
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'PIN을 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '6자리 PIN을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(controller.text);
                }
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    return result;
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
        return const _BottomSheetContent(
          title: '데이터 보안 안내',
          bullets: [
            '다이어리와 이미지 데이터는 암호화 저장소에 보관되며, 서비스 운영진도 원문을 직접 열람할 수 없습니다.',
            '로그인 기록과 의심스러운 접속은 실시간으로 감시되며, 비정상 활동 감지 시 즉시 계정 보호 조치를 시행합니다.',
            '계정 복구나 탈퇴 요청 시 본인 인증 절차를 필수로 진행하며, 요청 완료 후 30일이 지나면 데이터는 완전히 삭제됩니다.',
          ],
          footer: '추가 도움이 필요하시면 고객 지원 > 1:1 문의를 통해 연락해 주세요.',
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
        return const _BottomSheetContent(
          title: '내 데이터 다운로드',
          bullets: [
            '작성한 일기와 첨부 이미지는 추출 요청 후 48시간 이내에 암호화된 파일 형태로 제공됩니다.',
            '앱에서 직접 다운로드하는 기능을 준비 중이며, 현재는 고객 지원 채널을 통해 신청하시면 안내해 드립니다.',
            '계정 탈퇴 전에 데이터를 백업하려면 최소 3일 전에 신청해 주세요.',
          ],
          footer: '문의: support@saegim.app 또는 앱 내 고객 지원 > 1:1 문의',
        );
      },
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  const _BottomSheetContent({
    required this.title,
    required this.bullets,
    required this.footer,
  });

  final String title;
  final List<String> bullets;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...bullets.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: context.secondaryText)),
                    Expanded(
                      child: Text(
                        point,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: context.secondaryText,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              footer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.secondaryText,
                  ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
