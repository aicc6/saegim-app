import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';
import 'package:saegim/shared/utils/app_logger.dart';

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
    AppLogger.info('=== SplashPage initState 호출됨 ===', 'SplashPage');
    // 빌드 완료 후 안전하게 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.info('PostFrameCallback 실행 - mounted: $mounted', 'SplashPage');
      if (mounted) {
        _initialize();
      }
    });
  }

  Future<void> _initialize() async {
    try {
      // 인증 상태 확인 및 화면 이동
      await _proceedToNextScreen();
    } catch (e) {
      AppLogger.error('초기화 중 오류 발생', tag: 'SplashPage', error: e);
      // 오류가 발생해도 계속 진행
      if (mounted) {
        await _proceedToNextScreen();
      }
    }
  }

  Future<void> _proceedToNextScreen() async {
    try {
      AppLogger.info('인증 상태 초기화 시작', 'SplashPage');

      // AuthNotifier 초기화 (저장된 토큰 확인)
      await ref.read(authNotifierProvider.notifier).initialize();

      if (!mounted) return;

      final authState = ref.read(authNotifierProvider);
      AppLogger.info(
        '인증 상태 확인 완료 - isAuthenticated: ${authState.isAuthenticated}, userId: ${authState.userId}',
        'SplashPage',
      );

      // 최소 1초 대기 (스플래시 화면이 너무 빨리 사라지는 것 방지)
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // 인증 상태에 따라 적절한 페이지로 이동
      if (authState.isAuthenticated) {
        AppLogger.info('인증된 사용자 - 홈 화면으로 이동', 'SplashPage');
        context.go(RoutePaths.home);
      } else {
        AppLogger.info('미인증 사용자 - 로그인 화면으로 이동', 'SplashPage');
        context.go(RoutePaths.authLogin);
      }
    } catch (e) {
      AppLogger.error('화면 전환 중 오류 발생', tag: 'SplashPage', error: e);
      // 오류 발생 시 로그인 화면으로 이동
      if (mounted) {
        context.go(RoutePaths.authLogin);
      }
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
