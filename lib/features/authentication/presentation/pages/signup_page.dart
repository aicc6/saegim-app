import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/core/theme/theme_extensions.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

/// 회원가입 페이지
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _obscurePassword = true;

  // 실시간 검증 상태
  String _emailValidationStatus =
      ''; // '', 'checking', 'available', 'unavailable'
  String _nicknameValidationStatus =
      ''; // '', 'checking', 'available', 'unavailable'
  String _emailValidationMessage = '';
  String _nicknameValidationMessage = '';

  // 이메일 인증 상태
  bool _isEmailVerified = false;
  bool _isVerificationSent = false;
  bool _isVerificationSending = false;
  bool _isVerificationChecking = false;
  String _verificationMessage = '';
  final _verificationCodeController = TextEditingController();

  Timer? _emailDebounceTimer;
  Timer? _nicknameDebounceTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    _verificationCodeController.dispose();
    _emailDebounceTimer?.cancel();
    _nicknameDebounceTimer?.cancel();
    super.dispose();
  }

  // 이메일 실시간 검증
  void _checkEmail(String email) {
    _emailDebounceTimer?.cancel();

    if (email.isEmpty) {
      setState(() {
        _emailValidationStatus = '';
        _emailValidationMessage = '';
      });
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() {
        _emailValidationStatus = 'invalid';
        _emailValidationMessage = '올바른 이메일 형식을 입력해주세요';
      });
      return;
    }

    setState(() {
      _emailValidationStatus = 'checking';
      _emailValidationMessage = '확인 중...';
    });

    _emailDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final isDuplicate = await authNotifier.checkEmailDuplicate(email);

      if (mounted) {
        setState(() {
          if (isDuplicate) {
            _emailValidationStatus = 'unavailable';
            _emailValidationMessage = '이미 사용 중인 이메일입니다';
          } else {
            _emailValidationStatus = 'available';
            _emailValidationMessage = '사용 가능한 이메일입니다';
          }
        });
      }
    });
  }

  // 닉네임 실시간 검증
  void _checkNickname(String nickname) {
    _nicknameDebounceTimer?.cancel();

    if (nickname.isEmpty) {
      setState(() {
        _nicknameValidationStatus = '';
        _nicknameValidationMessage = '';
      });
      return;
    }

    if (nickname.length < 2) {
      setState(() {
        _nicknameValidationStatus = 'invalid';
        _nicknameValidationMessage = '닉네임은 2자 이상 입력해주세요';
      });
      return;
    }

    // 한글과 영문만 허용하는 정규식 검사
    if (!RegExp(r'^[가-힣a-zA-Z]+$').hasMatch(nickname)) {
      setState(() {
        _nicknameValidationStatus = 'invalid';
        _nicknameValidationMessage = '닉네임은 한글과 영문만 사용 가능합니다';
      });
      return;
    }

    setState(() {
      _nicknameValidationStatus = 'checking';
      _nicknameValidationMessage = '확인 중...';
    });

    _nicknameDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final isDuplicate = await authNotifier.checkNicknameDuplicate(nickname);

      if (mounted) {
        setState(() {
          if (isDuplicate) {
            _nicknameValidationStatus = 'unavailable';
            _nicknameValidationMessage = '이미 사용 중인 닉네임입니다';
          } else {
            _nicknameValidationStatus = 'available';
            _nicknameValidationMessage = '사용 가능한 닉네임입니다';
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true, showMenuButton: false),
      // backgroundColor 제거 - Theme 자동 적용
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 제목과 설명
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
                      child: Icon(
                        Icons.person_add,
                        size: 40,
                        color: context.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '새로운 시작을 환영해요!',
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '마음을 새기는 여정을 시작해보세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

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
                onChanged: _checkEmail,
                decoration: InputDecoration(
                  hintText: '이메일을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          _emailValidationStatus == 'unavailable' ||
                              _emailValidationStatus == 'invalid'
                          ? context.colorScheme.error
                          : context.borderSubtle,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _emailValidationStatus == 'available'
                          ? Colors.green
                          : _emailValidationStatus == 'unavailable' ||
                                _emailValidationStatus == 'invalid'
                          ? context.colorScheme.error
                          : context.colorScheme.primary,
                    ),
                  ),
                  suffixIcon: _emailValidationStatus == 'checking'
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _emailValidationStatus == 'available'
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : _emailValidationStatus == 'unavailable' ||
                            _emailValidationStatus == 'invalid'
                      ? Icon(Icons.error, color: context.colorScheme.error)
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  if (_emailValidationStatus == 'unavailable' ||
                      _emailValidationStatus == 'invalid') {
                    return _emailValidationMessage;
                  }
                  return null;
                },
              ),
              if (_emailValidationMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _emailValidationMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: _emailValidationStatus == 'available'
                          ? Colors.green
                          : context.colorScheme.error,
                    ),
                  ),
                ),

              // 인증 코드 발송 버튼
              if (_emailValidationStatus == 'available' && !_isEmailVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isVerificationSending
                          ? null
                          : _sendVerificationEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isVerificationSending
                            ? context.colorScheme.surfaceContainerHighest
                            : context.colorScheme.primary,
                        foregroundColor: context.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: _isVerificationSending ? 0 : 2,
                      ),
                      child: _isVerificationSending
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              _isVerificationSent ? '인증 코드 재발송' : '인증 코드 발송',
                            ),
                    ),
                  ),
                ),

              // 인증 코드 입력 필드
              if (_isVerificationSent && !_isEmailVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '인증 코드',
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _verificationCodeController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '인증 코드 6자리',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: context.borderSubtle,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: context.colorScheme.primary,
                                  ),
                                ),
                              ),
                              maxLength: 6,
                              buildCounter:
                                  (
                                    context, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) => null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isVerificationChecking
                                ? null
                                : _verifyEmailCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isVerificationChecking
                                  ? context.colorScheme.surfaceContainerHighest
                                  : context.colorScheme.primary,
                              foregroundColor: context.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: _isVerificationChecking ? 0 : 2,
                            ),
                            child: _isVerificationChecking
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('인증'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // 인증 메시지
              if (_verificationMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _verificationMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isEmailVerified ? Colors.green : Colors.red,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // 닉네임 입력
              Text(
                '닉네임',
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nicknameController,
                onChanged: _checkNickname,
                decoration: InputDecoration(
                  hintText: '닉네임을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          _nicknameValidationStatus == 'unavailable' ||
                              _nicknameValidationStatus == 'invalid'
                          ? context.colorScheme.error
                          : context.borderSubtle,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _nicknameValidationStatus == 'available'
                          ? Colors.green
                          : _nicknameValidationStatus == 'unavailable' ||
                                _nicknameValidationStatus == 'invalid'
                          ? context.colorScheme.error
                          : context.colorScheme.primary,
                    ),
                  ),
                  suffixIcon: _nicknameValidationStatus == 'checking'
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _nicknameValidationStatus == 'available'
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : _nicknameValidationStatus == 'unavailable' ||
                            _nicknameValidationStatus == 'invalid'
                      ? Icon(Icons.error, color: context.colorScheme.error)
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요';
                  }
                  if (value.length < 2) {
                    return '닉네임은 2자 이상 입력해주세요';
                  }
                  if (!RegExp(r'^[가-힣a-zA-Z]+$').hasMatch(value)) {
                    return '닉네임은 한글과 영문만 사용 가능합니다';
                  }
                  if (_nicknameValidationStatus == 'unavailable' ||
                      _nicknameValidationStatus == 'invalid') {
                    return _nicknameValidationMessage;
                  }
                  return null;
                },
              ),
              if (_nicknameValidationMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _nicknameValidationMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: _nicknameValidationStatus == 'available'
                          ? Colors.green
                          : context.colorScheme.error,
                    ),
                  ),
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
                    borderSide: BorderSide(color: context.colorScheme.primary),
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
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요';
                  }
                  if (value.length < 9) {
                    return '비밀번호는 9자 이상이어야 합니다';
                  }
                  if (!RegExp(
                    r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{9,}$',
                  ).hasMatch(value)) {
                    return '영문, 숫자, 특수문자를 모두 포함해야 합니다';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // 회원가입 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSignup()
                        ? context.colorScheme.primary
                        : context.colorScheme.surfaceContainerHighest,
                    foregroundColor: _canSignup()
                        ? context.colorScheme.onPrimary
                        : context.colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _canSignup() ? 3 : 0,
                  ),
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
                          '회원가입',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // 로그인 링크
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '이미 계정이 있으신가요? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.secondaryText,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(RoutePaths.authLogin),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '로그인',
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
            ],
          ),
        ),
      ),
    );
  }

  // 인증 코드 발송
  Future<void> _sendVerificationEmail() async {
    if (_emailValidationStatus != 'available') return;

    setState(() {
      _isVerificationSending = true;
      _verificationMessage = '';
    });

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final success = await authNotifier.sendVerificationEmail(
      _emailController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isVerificationSending = false;
        if (success) {
          _isVerificationSent = true;
          _verificationMessage = '인증 코드가 발송되었습니다';
        } else {
          _verificationMessage = '인증 코드 발송에 실패했습니다';
        }
      });
    }
  }

  // 인증 코드 검증
  Future<void> _verifyEmailCode() async {
    if (_verificationCodeController.text.isEmpty) return;

    setState(() {
      _isVerificationChecking = true;
      _verificationMessage = '';
    });

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final success = await authNotifier.verifyEmail(
      _emailController.text.trim(),
      _verificationCodeController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isVerificationChecking = false;
        if (success) {
          _isEmailVerified = true;
          _verificationMessage = '이메일 인증이 완료되었습니다';
        } else {
          _verificationMessage = '인증 코드가 올바르지 않습니다';
        }
      });
    }
  }

  bool _canSignup() {
    return !ref.watch(authNotifierProvider).isLoading &&
        _emailValidationStatus == 'available' &&
        _isEmailVerified &&
        _nicknameValidationStatus == 'available' &&
        _emailController.text.isNotEmpty &&
        _nicknameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .signup(
          _emailController.text.trim(),
          _passwordController.text,
          _nicknameController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      // 회원가입 후 홈페이지로 이동
      context.go(RoutePaths.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('회원가입에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }
}
