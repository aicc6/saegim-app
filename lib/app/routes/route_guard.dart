import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';

/// 라우트 가드 클래스
/// 인증이 필요한 페이지에 대한 접근을 제어합니다.
class RouteGuard {
  /// 인증이 필요한 라우트에 대한 리다이렉트 로직
  static String? authGuard(BuildContext context, GoRouterState state) {
    final currentPath = state.matchedLocation;
    final isAuthRoute = _isAuthRoute(currentPath);

    // 스플래시 화면은 항상 접근 허용 (초기화가 여기서 이루어짐)
    if (currentPath == RoutePaths.splash) {
      return null;
    }

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final authState = container.read(authNotifierProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isInitialized = authState.isInitialized;

      // AuthNotifier가 아직 초기화되지 않은 경우 스플래시로 리다이렉트
      if (!isInitialized) {
        return RoutePaths.splash;
      }

      // 초기화가 완료된 상태

      // 인증되지 않은 상태
      if (!isAuthenticated) {
        // 인증 관련 화면이 아니라면 로그인으로 리다이렉트
        if (!isAuthRoute) {
          return RoutePaths.authLogin;
        }
        return null; // 현재 경로 유지
      }

      // 인증된 상태에서 인증 화면에 접근하면 홈으로 리다이렉트
      if (isAuthenticated && isAuthRoute) {
        return RoutePaths.home;
      }

      return null; // 현재 경로 유지
    } catch (e) {
      // 예외 발생 시 스플래시로 이동하여 초기화 재시도
      return RoutePaths.splash;
    }
  }

  /// 주어진 경로가 인증 관련 라우트인지 확인
  static bool _isAuthRoute(String location) {
    return location.startsWith('/auth/') ||
        location == RoutePaths.splash ||
        location == RoutePaths.onboarding;
  }

  /// 인증된 사용자만 접근 가능한 라우트인지 확인
  static bool requiresAuth(String location) {
    final authRoutes = [
      RoutePaths.splash,
      RoutePaths.onboarding,
      RoutePaths.authLogin,
      RoutePaths.authSignup,
      RoutePaths.authForgotPassword,
      RoutePaths.authResetPassword,
      RoutePaths.authRestoreAccount,
    ];

    return !authRoutes.contains(location) && !location.startsWith('/auth/');
  }
}
