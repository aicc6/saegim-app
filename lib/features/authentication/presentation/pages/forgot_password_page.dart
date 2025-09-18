import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/features/authentication/data/models/forgot_password_models.dart';
import 'package:saegim/features/authentication/presentation/riverpod/forgot_password_notifier.dart';


/// 비밀번호 찾기 페이지 (3단계 프로세스)
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forgotPasswordState = ref.watch(forgotPasswordNotifierProvider);
    
    // 에러 메시지 표시
    ref.listen(forgotPasswordNotifierProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (forgotPasswordState.currentStep == ForgotPasswordStep.emailInput) {
              context.pop();
            } else {
              ref.read(forgotPasswordNotifierProvider.notifier).goToPreviousStep();
            }
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFB2C5B8),
          ),
        ),
        title: const Text(
          '새김',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB2C5B8),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildStepContent(forgotPasswordState),
        ),
      ),
    );
  }

  Widget _buildStepContent(ForgotPasswordState state) {
    switch (state.currentStep) {
      case ForgotPasswordStep.emailInput:
        return _buildEmailStep(state);
      case ForgotPasswordStep.emailSent:
        return _buildEmailSentStep(state);
    }
  }

  /// 1단계: 이메일 입력
  Widget _buildEmailStep(ForgotPasswordState state) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // 제목과 설명
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 80,
                  color: Color(0xFFB2C5B8),
                ),
                const SizedBox(height: 24),
                const Text(
                  '비밀번호 찾기',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '가입시 사용하신 이메일 주소를 입력해주세요\n비밀번호 재설정 링크를 발송해드립니다',
                  textAlign: TextAlign.center,
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
            enabled: !state.isLoading,
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
              if (value == null || value.isEmpty) {
                return '이메일을 입력해주세요';
              }
              final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(value)) {
                return '올바른 이메일 형식을 입력해주세요';
              }
              return null;
            },
            onChanged: (value) {
              ref.read(forgotPasswordNotifierProvider.notifier).setEmail(value);
            },
          ),

          const SizedBox(height: 32),

          // 인증코드 발송 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _handleSendEmail,
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '재설정 링크 발송',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // 로그인으로 돌아가기
          Center(
            child: TextButton(
              onPressed: () => context.go(RoutePaths.authLogin),
              child: const Text(
                '로그인으로 돌아가기',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFB2C5B8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2단계: 이메일 발송 완료
  Widget _buildEmailSentStep(ForgotPasswordState state) {
    return Column(
      children: [
        const SizedBox(height: 80),
        
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFB2C5B8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '이메일을 확인해주세요',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${state.email ?? '입력하신 이메일'}로\n비밀번호 재설정 링크를 발송했습니다.\n\n이메일을 확인하시고 링크를 클릭하여\n비밀번호를 재설정해주세요.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 32),
              
              // 이메일 재발송 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: state.isLoading ? null : _handleResendEmail,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFB2C5B8)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB2C5B8)),
                          ),
                        )
                      : const Text(
                          '이메일 재발송',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB2C5B8),
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 로그인 페이지로 이동 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(RoutePaths.authLogin),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2C5B8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '로그인 페이지로 돌아가기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 도움말 텍스트
              const Text(
                '이메일이 도착하지 않았나요?\n스팸 폴더도 확인해보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 이벤트 핸들러들
  Future<void> _handleSendEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    ref.read(forgotPasswordNotifierProvider.notifier).clearMessages();
    
    final success = await ref
        .read(forgotPasswordNotifierProvider.notifier)
        .sendPasswordResetEmail(_emailController.text.trim());

    if (!success && mounted) {
      // 에러는 notifier에서 처리됨
    }
  }

  Future<void> _handleResendEmail() async {
    ref.read(forgotPasswordNotifierProvider.notifier).clearMessages();
    
    final success = await ref
        .read(forgotPasswordNotifierProvider.notifier)
        .resendPasswordResetEmail();

    if (!success && mounted) {
      // 에러는 notifier에서 처리됨
    }
  }
}