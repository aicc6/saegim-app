import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/features/authentication/data/services/change_password_service.dart';
import 'package:saegim/features/authentication/presentation/riverpod/change_password_notifier.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

/// 비밀번호 변경 페이지
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 상태 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(changePasswordNotifierProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordNotifierProvider);

    // 성공 메시지 처리
    ref.listen<ChangePasswordState>(changePasswordNotifierProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        // 성공 시 이전 페이지로 돌아가기
        context.pop();
      }
    });

    return Scaffold(
      appBar: const CommonAppBar(
        title: '비밀번호 변경',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 안내 텍스트
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '보안을 위해 현재 비밀번호를 확인한 후 새로운 비밀번호로 변경할 수 있습니다.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 현재 비밀번호 입력
                const Text(
                  '현재 비밀번호',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    hintText: '현재 사용 중인 비밀번호를 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB2C5B8)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword = !_obscureCurrentPassword;
                            });
                          },
                          icon: Icon(
                            _obscureCurrentPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '현재 비밀번호를 입력해주세요';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // 새 비밀번호 입력
                const Text(
                  '새 비밀번호',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    hintText: '새로운 비밀번호를 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB2C5B8)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(changePasswordNotifierProvider.notifier)
                        .checkPasswordStrength(value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '새 비밀번호를 입력해주세요';
                    }
                    final validation = state.passwordValidation;
                    if (validation != null && !validation.isValid) {
                      return validation.errors.first;
                    }
                    return null;
                  },
                ),

                // 비밀번호 강도 표시
                if (state.passwordValidation != null) ...[
                  const SizedBox(height: 8),
                  _buildPasswordStrengthIndicator(state.passwordValidation!),
                ],

                const SizedBox(height: 24),

                // 비밀번호 확인 입력
                const Text(
                  '새 비밀번호 확인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: '새 비밀번호를 다시 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB2C5B8)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호 확인을 입력해주세요';
                    }
                    if (value != _newPasswordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // 성공 메시지
                if (state.successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.successMessage!,
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 에러 메시지
                if (state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 변경 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _handleChangePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB2C5B8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            '비밀번호 변경',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // 비밀번호 가이드
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFB3E5FC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '안전한 비밀번호 만들기',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordRule('8자 이상 입력', true),
                      _buildPasswordRule('영문자 포함', true),
                      _buildPasswordRule('숫자 포함', true),
                      _buildPasswordRule('특수문자 포함 (권장)', false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(PasswordValidation validation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              validation.isValid ? Icons.check_circle : Icons.error,
              size: 16,
              color: validation.isValid ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              validation.isValid ? '안전한 비밀번호입니다' : '비밀번호 조건을 확인하세요',
              style: TextStyle(
                fontSize: 12,
                color: validation.isValid ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (!validation.isValid && validation.errors.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...validation.errors.map((error) => Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  '• $error',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildPasswordRule(String rule, bool required) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            required ? Icons.circle : Icons.circle_outlined,
            size: 6,
            color: const Color(0xFF0369A1),
          ),
          const SizedBox(width: 8),
          Text(
            rule,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF0369A1),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(changePasswordNotifierProvider.notifier)
        .changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (success) {
      // 성공 시 처리는 listen에서 함
      return;
    }
  }
}