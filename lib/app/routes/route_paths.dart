/// 앱의 라우트 경로를 정의하는 상수 클래스
class RoutePaths {
  // 앱 시작/인증 플로우
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  // 인증 관련
  static const String authLogin = '/auth/login';
  static const String authSignup = '/auth/signup';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authRestoreAccount = '/auth/restore-account';
  static const String authDeleteAccount = '/auth/delete-account';

  // 메인 앱 (인증 필요)
  static const String home = '/';
  static const String chat = '/chat';
  static const String calendar = '/calendar';
  static const String handwritingDiary = '/handwriting-diary';

  // 다이어리
  static const String diaryList = '/diary';
  static const String diaryDetail = '/diary/:id';

  // 사용자 관리
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String settingsChangePassword = '/settings/change-password';
  static const String settingsAppPreferences = '/settings/app-preferences';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsPrivacyPolicy = '/settings/privacy/policy';

  // 기타
  static const String notifications = '/notifications';
  static const String support = '/support';

  // 유틸리티 메서드
  static String diaryDetailPath(String id) => '/diary/$id';
}
