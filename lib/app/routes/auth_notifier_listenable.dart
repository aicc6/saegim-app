import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';

/// Riverpod 상태를 GoRouter의 refreshListenable로 사용하기 위한 어댑터
class AuthNotifierListenable extends ChangeNotifier {
  AuthNotifierListenable(this._ref) {
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      // 인증 상태가 변경되면 GoRouter에 알림
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.isInitialized != next.isInitialized) {
        notifyListeners();
      }
    });
  }

  final Ref _ref;

  AuthState get authState => _ref.read(authNotifierProvider);
}

/// Provider for AuthNotifierListenable
final authNotifierListenableProvider = Provider<AuthNotifierListenable>((ref) {
  return AuthNotifierListenable(ref);
});
