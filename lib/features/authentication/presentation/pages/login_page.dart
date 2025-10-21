import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/core/theme/theme_extensions.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';

/// 로그인 페이지
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      // backgroundColor 제거 - Theme의 scaffoldBackgroundColor 자동 적용
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // 로고와 제목
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: context.colorScheme.primary,
                        ),
                        child: Center(
                          child: Text(
                            '새김',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '다시 만나서 반가워요!',
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '마음을 새기는 여정을 계속해보세요',
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: context.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // 이메일 입력
                Text(
                  '이메일',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: '이메일을 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                      return '올바른 이메일 형식을 입력해주세요';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // 비밀번호 입력
                Text(
                  '비밀번호',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '비밀번호를 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.colorScheme.primary,
                      ),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: context.secondaryText,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final password = value ?? '';
                    if (password.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (password.length < 9) {
                      return '비밀번호는 9자 이상이어야 합니다';
                    }
                    final pattern = RegExp(
                      r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{9,}$',
                    );
                    if (!pattern.hasMatch(password)) {
                      return '영문, 숫자, 특수문자를 모두 포함해야 합니다';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    // style 제거 - Theme의 elevatedButtonTheme 자동 적용
                    child: authState.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // 구글 로그인 버튼 (브랜드 가이드라인: 흰 배경, 검은 텍스트)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: authState.isLoading ? null : _handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    icon: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://developers.google.com/identity/images/g-logo.png',
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    label: const Text(
                      'Google로 로그인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 또는 구분선
                Row(
                  children: [
                    Expanded(child: Divider(color: context.borderSubtle)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '또는',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.secondaryText,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: context.borderSubtle)),
                  ],
                ),

                const SizedBox(height: 24),

                // 비밀번호 찾기
                Center(
                  child: TextButton(
                    onPressed: () =>
                        context.push(RoutePaths.authForgotPassword),
                    child: Text(
                      '비밀번호를 잊으셨나요?',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 회원가입 링크
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '아직 계정이 없으신가요? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.secondaryText,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(RoutePaths.authSignup),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref
        .read(authNotifierProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;

    if (result.isSuccess) {
      final authState = ref.read(authNotifierProvider);

      // 계정 복구 알림 표시
      if (authState.isRecovered) {
        _showRecoveryDialog(authState.recoveryMessage);
      } else {
        // 로그인 후 글쓰기 페이지(홈페이지)로 이동
        context.go(RoutePaths.home);
      }
    } else if (result.isAccountDeleted) {
      final email = result.email ?? _emailController.text.trim();
      _showAccountRestoreDialog(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ??
                '해당 계정은 탈퇴된 상태입니다. 계정 복구를 진행해주세요.',
          ),
          backgroundColor: context.colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? '로그인에 실패했습니다. 다시 시도해주세요.',
          ),
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }

  void _showRecoveryDialog(String? message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.restore, color: context.colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              '계정이 복구되었습니다',
              style: TextStyle(
                color: context.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message ?? '30일 이내에 로그인하여 계정이 자동으로 복구되었습니다.\n새김과 함께 다시 시작해보세요!',
          style: TextStyle(
            color: context.secondaryText,
            height: 1.5,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(RoutePaths.home);
            },
            // style 제거 - Theme의 textButtonTheme 또는 커스텀 스타일 사용
            style: TextButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: context.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              '시작하기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    final result = await ref
        .read(authNotifierProvider.notifier)
        .loginWithGoogle();

    if (!mounted) return;

    if (result.isSuccess) {
      // 로그인 후 홈페이지로 이동
      context.go(RoutePaths.home);
    } else if (result.isAccountDeleted) {
      // 계정이 탈퇴된 상태인 경우 복구 동의 다이얼로그 표시
      _showAccountRestoreDialog(result.userEmail ?? '');
    } else {
      // 일반적인 로그인 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? '구글 로그인에 실패했습니다.'),
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }

  /// 계정 복구 동의 다이얼로그 표시
  void _showAccountRestoreDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('계정 복구'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이 계정($email)은 탈퇴된 상태입니다.'),
            const SizedBox(height: 12),
            const Text('30일 이내에 로그인하면 계정을 다시 복구할 수 있습니다.'),
            const SizedBox(height: 12),
            const Text(
              '• "복구하기"를 선택하면 인증 메일이 발송됩니다\n'
              '• 이메일에서 6자리 복구 코드를 입력하면 계정이 복구됩니다\n'
              '• 복구 완료 후 다시 로그인하실 수 있습니다',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 이메일 인증 기반 복구 플로우로 이동
              context.go('${RoutePaths.authRestoreAccount}?email=$email');
            },
            child: const Text('복구하기'),
          ),
        ],
      ),
    );
  }
}
