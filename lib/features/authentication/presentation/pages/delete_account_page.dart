import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/features/authentication/data/services/delete_account_service.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  String? _selectedReason;
  String _customReason = '';
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _hasAgreed = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate() || !_hasAgreed) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reason = _selectedReason == '기타' ? _customReason : _selectedReason;

      final success = await DeleteAccountService.deleteAccount(
        password: _passwordController.text,
        reason: reason,
      );

      if (success && mounted) {
        // 계정 탈퇴 성공 시 인증 상태 초기화
        await ref.read(authNotifierProvider.notifier).logout();
        _showDeleteSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFFB2C5B8), size: 24),
            SizedBox(width: 8),
            Text(
              '계정 탈퇴 완료',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          '계정이 성공적으로 탈퇴되었습니다.\n7일 이내에 고객센터로 연락하시면 복구가 가능합니다.',
          style: TextStyle(
            color: Color(0xFF4A5C54),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 스플래시 페이지로 이동하여 재인증 플로우 시작
              context.go('/splash');
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFB2C5B8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('확인', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFF8B7355), size: 24),
            SizedBox(width: 8),
            Text(
              '탈퇴 실패',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF4A5C54),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFB2C5B8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('확인', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF8B7355), size: 24),
            SizedBox(width: 8),
            Text(
              '계정 탈퇴 확인',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          '정말로 계정을 탈퇴하시겠습니까?\n\n탈퇴 후에는 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다.',
          style: TextStyle(
            color: Color(0xFF4A5C54),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              '취소',
              style: TextStyle(
                color: Color(0xFF718096),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('탈퇴하기', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        showBackButton: true,
        showMenuButton: false,
      ),
      backgroundColor: const Color(0xFFFAFBFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '계정 탈퇴',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '계정을 탈퇴하기 전에 아래 내용을 확인해주세요.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
              ),
              const SizedBox(height: 32),

              // 탈퇴 안내사항
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF8),
                  border: Border.all(color: const Color(0xFFB2C5B8), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF6B8E77),
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          '탈퇴 전 확인사항',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A5C54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...DeleteAccountService.deletionWarnings.map(
                      (warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 8, right: 12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFB2C5B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                warning,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4A5C54),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 탈퇴 사유 선택
              const Text(
                '탈퇴 사유',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: DeleteAccountService.deletionReasons.map(
                    (reason) => Container(
                      decoration: BoxDecoration(
                        border: reason != DeleteAccountService.deletionReasons.last
                            ? const Border(bottom: BorderSide(color: Color(0xFFF7FAFC)))
                            : null,
                      ),
                      child: RadioListTile<String>(
                        title: Text(
                          reason,
                          style: const TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 15,
                          ),
                        ),
                        value: reason,
                        groupValue: _selectedReason,
                        activeColor: const Color(0xFFB2C5B8),
                        onChanged: (value) {
                          setState(() {
                            _selectedReason = value;
                          });
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                    ),
                  ).toList(),
                ),
              ),

              // 기타 사유 입력
              if (_selectedReason == '기타') ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: '기타 사유',
                      labelStyle: TextStyle(color: Color(0xFF718096)),
                      hintText: '탈퇴 사유를 입력해주세요',
                      hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFB2C5B8)),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: 3,
                    style: const TextStyle(color: Color(0xFF2D3748)),
                    onChanged: (value) {
                      _customReason = value;
                    },
                    validator: (value) {
                      if (_selectedReason == '기타' && (value?.isEmpty ?? true)) {
                        return '기타 사유를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // 비밀번호 확인
              const Text(
                '본인 확인',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(color: Color(0xFF2D3748)),
                  decoration: InputDecoration(
                    labelText: '현재 비밀번호',
                    labelStyle: const TextStyle(color: Color(0xFF718096)),
                    hintText: '본인 확인을 위해 현재 비밀번호를 입력해주세요',
                    hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                    border: const OutlineInputBorder(borderSide: BorderSide.none),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB2C5B8)),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF718096),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return '비밀번호를 입력해주세요.';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 32),

              // 동의 체크박스
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: CheckboxListTile(
                  title: const Text(
                    '위 내용을 모두 확인했으며, 계정 탈퇴에 동의합니다.',
                    style: TextStyle(
                      color: Color(0xFF2D3748),
                      fontSize: 15,
                    ),
                  ),
                  value: _hasAgreed,
                  activeColor: const Color(0xFFB2C5B8),
                  onChanged: (value) {
                    setState(() {
                      _hasAgreed = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),

              const SizedBox(height: 32),

              // 탈퇴 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || !_hasAgreed || _selectedReason == null
                      ? null
                      : _showConfirmDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B7355),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          '계정 탈퇴하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        ),
      ),
    );
  }
}