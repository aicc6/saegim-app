import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_paths.dart';
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
      backgroundColor: Colors.white,
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
                          color: const Color(0xFFB2C5B8),
                        ),
                        child: const Center(
                          child: Text(
                            '새김',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '다시 만나서 반가워요!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '마음을 새기는 여정을 계속해보세요',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // 이메일 입력
                const Text(
                  '이메일',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
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
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB2C5B8)),
                    ),
                  ),
                  validator: (value) {
                    // TODO: 이메일 유효성 검사 추가
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // 비밀번호 입력
                const Text(
                  '비밀번호',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
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
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB2C5B8)),
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
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  validator: (value) {
                    // TODO: 비밀번호 유효성 검사 추가
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB2C5B8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                    ),
                    child: authState.isLoading
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
                            '로그인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // 구글 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: authState.isLoading ? null : _handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    icon: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage('https://developers.google.com/identity/images/g-logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    label: const Text(
                      'Google로 로그인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 또는 구분선
                Row(
                  children: const [
                    Expanded(child: Divider(color: Color(0xFFD1D5DB))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '또는',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFD1D5DB))),
                  ],
                ),

                const SizedBox(height: 24),

                // 비밀번호 찾기
                Center(
                  child: TextButton(
                    onPressed: () =>
                        context.push(RoutePaths.authForgotPassword),
                    child: const Text(
                      '비밀번호를 잊으셨나요?',
                      style: TextStyle(fontSize: 14, color: Color(0xFFB2C5B8)),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 회원가입 링크
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '아직 계정이 없으신가요? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(RoutePaths.authSignup),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB2C5B8),
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

    final success = await ref
        .read(authNotifierProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;

    if (success) {
      final authState = ref.read(authNotifierProvider);

      // 계정 복구 알림 표시
      if (authState.isRecovered) {
        _showRecoveryDialog(authState.recoveryMessage);
      } else {
        // 로그인 후 글쓰기 페이지(홈페이지)로 이동
        context.go(RoutePaths.home);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
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
        title: const Row(
          children: [
            Icon(Icons.restore, color: Color(0xFFB2C5B8), size: 24),
            SizedBox(width: 8),
            Text(
              '계정이 복구되었습니다',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message ?? '30일 이내에 로그인하여 계정이 자동으로 복구되었습니다.\n새김과 함께 다시 시작해보세요!',
          style: const TextStyle(
            color: Color(0xFF4A5C54),
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
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFB2C5B8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    final success = await ref
        .read(authNotifierProvider.notifier)
        .loginWithGoogle();

    if (!mounted) return;

    if (success) {
      // 로그인 후 홈페이지로 이동
      context.go(RoutePaths.home);
    } else {
      final authState = ref.read(authNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage ?? '구글 로그인에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
