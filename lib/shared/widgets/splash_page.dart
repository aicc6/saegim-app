import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';
import 'package:saegim/app/routes/route_paths.dart';

/// 스플래시 화면
/// 앱 시작시 인증 상태를 확인하고 적절한 화면으로 이동
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // 빌드 완료 후 안전하게 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initialize();
      }
    });
  }

  Future<void> _initialize() async {
    await ref.read(authNotifierProvider.notifier).initialize();

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    // 인증 상태에 따라 적절한 페이지로 이동
    if (authState.isAuthenticated) {
      context.go(RoutePaths.home);
    } else {
      context.go(RoutePaths.authLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // sage-20과 유사한 색상
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '새김',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB2C5B8), // sage-100과 유사한 색상
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 로딩 인디케이터
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB2C5B8)),
            ),
            const SizedBox(height: 24),
            // 로딩 텍스트
            const Text(
              '마음을 새기는 특별한 여정',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '잠시만 기다려주세요...',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
