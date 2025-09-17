import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';
import 'package:saegim/features/calendar/presentation/riverpod/calendar_notifier.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 테스트용 로그인 위젯 (개발 중에만 사용)
class TestLoginWidget extends ConsumerStatefulWidget {
  const TestLoginWidget({super.key});

  @override
  ConsumerState<TestLoginWidget> createState() => _TestLoginWidgetState();
}

class _TestLoginWidgetState extends ConsumerState<TestLoginWidget> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        AppLogger.warning('Email or password is empty', 'TestLoginWidget');
        return;
      }

      AppLogger.info('Attempting test login with: $email', 'TestLoginWidget');

      final success = await ref
          .read(authNotifierProvider.notifier)
          .login(email, password);

      if (success) {
        AppLogger.info('Test login successful!', 'TestLoginWidget');

        // 로그인 성공 후 캘린더 데이터 새로고침 (토큰 저장 완료 대기)
        if (mounted) {
          // 토큰 저장이 완료될 때까지 잠시 대기
          await Future.delayed(const Duration(milliseconds: 500));
          // CalendarNotifier의 refresh 메서드 호출
          ref.read(calendarNotifierProvider.notifier).refresh();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인 성공! 다이어리 데이터를 새로고침합니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        AppLogger.warning('Test login failed', 'TestLoginWidget');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 실패'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      AppLogger.error('Test login error', tag: 'TestLoginWidget', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 에러: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.isAuthenticated) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '로그인됨: ${authState.userEmail ?? "사용자"}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(authNotifierProvider.notifier).logout();
              },
              child: const Text('로그아웃'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        children: [
          const Text(
            '🔐 테스트 로그인 (개발용)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              hintText: 'test@example.com',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: '비밀번호',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _testLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('테스트 로그인'),
            ),
          ),
        ],
      ),
    );
  }
}
