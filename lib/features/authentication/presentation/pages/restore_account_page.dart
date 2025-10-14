import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/core/theme/theme_extensions.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class RestoreAccountPage extends ConsumerStatefulWidget {
  final String email;

  const RestoreAccountPage({super.key, required this.email});

  @override
  ConsumerState<RestoreAccountPage> createState() => _RestoreAccountPageState();
}

class _RestoreAccountPageState extends ConsumerState<RestoreAccountPage> {
  late final TextEditingController _codeController;
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();

    // 페이지 진입 시 자동으로 인증 메일 발송
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendRestoreEmail();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendRestoreEmail() async {
    // 이미 인증된 상태라면 메일 발송하지 않고 즉시 리다이렉트
    final authState = ref.read(authNotifierProvider);

    if (authState.isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미 로그인된 상태입니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(RoutePaths.home);
      }
      return;
    }
    setState(() => _isResending = true);

    try {
      final success = await ref
          .read(authNotifierProvider.notifier)
          .sendVerificationEmail(widget.email);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증 메일을 발송했습니다. 이메일을 확인해주세요.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증 메일 발송에 실패했습니다: $e'),
            backgroundColor: context.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isResending = false);
    }
  }

  Future<void> _restoreAccount() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('6자리 인증 코드를 입력해주세요.'),
          backgroundColor: context.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // verify code, then check status
      final verified = await ref
          .read(authNotifierProvider.notifier)
          .verifyEmail(widget.email, code);

      if (!verified) {
        throw Exception('인증 코드가 올바르지 않습니다.');
      }

      await ref.read(authNotifierProvider.notifier).checkAuthStatus();

      final success = verified;

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계정이 성공적으로 복구되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // 인증 상태 확인 후 적절한 페이지로 이동
        final authState = ref.read(authNotifierProvider);
        context.go(
          authState.isAuthenticated ? RoutePaths.home : RoutePaths.authLogin,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('계정 복구에 실패했습니다: $e'),
            backgroundColor: context.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 인증 상태 변화 감지 및 네비게이션 처리
    ref.listen(authNotifierProvider, (previous, next) {
      final wasAuthenticated = previous?.isAuthenticated ?? false;
      if (!wasAuthenticated && next.isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go(RoutePaths.home);
          }
        });
      }
    });

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true, title: ''),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight -
                  40, // padding
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // 헤더 아이콘과 제목
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: context.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.restore,
                          size: 40,
                          color: context.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '계정 복구',
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '탈퇴된 계정을 복구할 수 있습니다',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.secondaryText,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 이메일 주소 표시
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이메일 주소',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.borderSubtle,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: context.secondaryText,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.primaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 인증 코드 입력
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '인증 코드',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(fontSize: 16, letterSpacing: 2),
                        decoration: InputDecoration(
                          hintText: '이메일로 받은 6자리 인증 코드를 입력하세요',
                          hintStyle: TextStyle(
                            color: context.placeholderText,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: context.secondaryText,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: context.inputBackground,
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: context.borderSubtle,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: context.borderSubtle,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: context.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 계정 복구하기 버튼
                  FilledButton(
                    onPressed: _isLoading ? null : _restoreAccount,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('계정 복구하기'),
                  ),

                  const SizedBox(height: 16),

                  // 인증 코드 다시 받기 버튼
                  OutlinedButton(
                    onPressed: _isResending ? null : _sendRestoreEmail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E3A59),
                      side: const BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E3A59),
                              ),
                            ),
                          )
                        : const Text('인증 코드 다시 발송'),
                  ),

                  const Spacer(),

                  // 로그인 페이지로 돌아가기
                  TextButton(
                    onPressed: () => context.go(RoutePaths.authLogin),
                    child: const Text(
                      '로그인 페이지로 돌아가기',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
