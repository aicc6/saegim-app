import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/core/services/auth_storage_service.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;

  ThemeNotifier(this._ref) : super(ThemeMode.system) {
    _loadTheme();
    _listenToAuthState();
  }

  static const String _themeKey = 'theme_mode';
  static const String _userThemeKey = 'user_theme_mode';

  void _listenToAuthState() {
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      // 초기화가 완료된 후에만 테마 변경 로직 실행
      if (next.isInitialized &&
          previous?.isAuthenticated != next.isAuthenticated) {
        if (next.isAuthenticated) {
          _loadUserTheme();
        } else {
          _resetToSystemTheme();
        }
      }
    });
  }

  Future<void> _loadTheme() async {
    final authState = _ref.read(authNotifierProvider);

    // AuthNotifier가 초기화되지 않았거나 로그인되지 않은 경우 게스트 테마 로드
    if (authState.isInitialized && authState.isAuthenticated) {
      await _loadUserTheme();
    } else {
      await _loadGuestTheme();
    }
  }

  Future<void> _loadUserTheme() async {
    try {
      final userId = await AuthStorageService.instance.getUserId();
      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        final userThemeKey = '${_userThemeKey}_$userId';
        final themeIndex = prefs.getInt(userThemeKey) ?? 0;
        state = ThemeMode.values[themeIndex];
        AppLogger.info(
          '사용자별 테마 로드: ${ThemeMode.values[themeIndex]}',
          'ThemeNotifier',
        );
      }
    } catch (e) {
      state = ThemeMode.system;
      AppLogger.error('사용자 테마 로드 실패', error: e, tag: 'ThemeNotifier');
    }
  }

  Future<void> _loadGuestTheme() async {
    try {
      // 게스트 상태에서는 항상 시스템 테마로 시작
      state = ThemeMode.system;
      AppLogger.info(
        '게스트 테마 로드 (시스템 테마): ${ThemeMode.system}',
        'ThemeNotifier',
      );
    } catch (e) {
      state = ThemeMode.system;
      AppLogger.error('게스트 테마 로드 실패', error: e, tag: 'ThemeNotifier');
    }
  }

  Future<void> _resetToSystemTheme() async {
    try {
      state = ThemeMode.system;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, ThemeMode.system.index);
      AppLogger.info('로그아웃 후 시스템 테마로 초기화', 'ThemeNotifier');
    } catch (e) {
      AppLogger.error('테마 초기화 실패', error: e, tag: 'ThemeNotifier');
    }
  }

  Future<void> setTheme(ThemeMode theme) async {
    try {
      final authState = _ref.read(authNotifierProvider);

      if (authState.isInitialized && authState.isAuthenticated) {
        // 로그인된 사용자만 테마 설정을 저장
        final userId = await AuthStorageService.instance.getUserId();
        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          final userThemeKey = '${_userThemeKey}_$userId';
          await prefs.setInt(userThemeKey, theme.index);
          AppLogger.info(
            '사용자별 테마 저장: $theme (userId: $userId)',
            'ThemeNotifier',
          );
        }
        state = theme;
      } else {
        // 게스트 상태에서는 테마 변경을 허용하지 않음 (시스템 테마 유지)
        AppLogger.info('게스트 상태에서는 테마 변경이 제한됩니다.', 'ThemeNotifier');
      }
    } catch (e) {
      AppLogger.error('테마 저장 실패', error: e, tag: 'ThemeNotifier');
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(ref),
);
