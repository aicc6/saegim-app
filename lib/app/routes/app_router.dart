import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_guard.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/debug/fcm_debug_page.dart';
import 'package:saegim/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:saegim/features/authentication/presentation/pages/login_page.dart';
import 'package:saegim/features/authentication/presentation/pages/reset_password_page.dart';
import 'package:saegim/features/authentication/presentation/pages/restore_account_page.dart';
import 'package:saegim/features/authentication/presentation/pages/signup_page.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/features/home/presentation/pages/calendar_page.dart';
import 'package:saegim/features/home/presentation/pages/diary_detail_page.dart';
import 'package:saegim/features/home/presentation/pages/diary_list_page.dart';
import 'package:saegim/features/home/presentation/pages/handwriting_diary_page.dart';
import 'package:saegim/features/home/presentation/pages/home_page.dart';
import 'package:saegim/features/home/presentation/pages/notifications_page.dart';
import 'package:saegim/features/home/presentation/pages/settings_page.dart';
import 'package:saegim/features/home/presentation/pages/support_page.dart';
import 'package:saegim/features/home/presentation/navigation/diary_route_arguments.dart';
import 'package:saegim/features/profile/presentation/pages/profile_page.dart';
import 'package:saegim/features/settings/presentation/pages/app_preferences_page.dart';
import 'package:saegim/features/settings/presentation/pages/change_password_page.dart';
import 'package:saegim/features/settings/presentation/pages/emoji_theme_settings_page.dart';
import 'package:saegim/features/settings/presentation/pages/notification_settings_page.dart';
import 'package:saegim/features/settings/presentation/pages/privacy_settings_page.dart';
import 'package:saegim/shared/widgets/error_page.dart';
import 'package:saegim/shared/widgets/main_scaffold.dart';
import 'package:saegim/shared/widgets/onboarding_page.dart';
import 'package:saegim/shared/widgets/splash_page.dart';

/// 앱의 라우터 설정 클래스
class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: RoutePaths.splash,
      redirect: RouteGuard.authGuard,
      errorBuilder: (context, state) =>
          ErrorPage(error: state.error.toString()),
      routes: [
        // 스플래시 화면
        GoRoute(
          path: RoutePaths.splash,
          builder: (context, state) => const SplashPage(),
        ),

        // 온보딩
        GoRoute(
          path: RoutePaths.onboarding,
          builder: (context, state) => const OnboardingPage(),
        ),

        // 인증 관련 라우트 (하단 네비게이션 없음)
        GoRoute(
          path: '/auth',
          redirect: (context, state) => null,
          routes: [
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginPage(),
            ),
            GoRoute(
              path: '/signup',
              builder: (context, state) => const SignupPage(),
            ),
            GoRoute(
              path: '/forgot-password',
              builder: (context, state) => const ForgotPasswordPage(),
            ),
            GoRoute(
              path: '/reset-password',
              builder: (context, state) => const ResetPasswordPage(),
            ),
            GoRoute(
              path: '/restore-account',
              builder: (context, state) {
                final email = state.uri.queryParameters['email'] ?? '';
                return RestoreAccountPage(email: email);
              },
            ),
          ],
        ),

        // 메인 앱 - 하단 네비게이션이 있는 섹션
        ShellRoute(
          builder: (context, state, child) {
            return MainScaffold(
              currentUri: state.uri,
              child: child,
            );
          },
          routes: [
            // 글쓰기 (홈)
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => const HomePage(),
            ),

            // 글목록 (다이어리)
            GoRoute(
              path: '/diary',
              builder: (context, state) => const DiaryListPage(),
              routes: [
                GoRoute(
                  path: '/list',
                  builder: (context, state) => const DiaryListPage(),
                ),
                GoRoute(
                  path: '/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;

                    DiaryEntry? tempEntry;
                    bool startInEditMode = false;
                    String? initialCategoryId;

                    final extra = state.extra;
                    if (extra is DiaryDetailRouteArguments) {
                      tempEntry = extra.tempEntry;
                      startInEditMode =
                          extra.startInEditMode ?? (tempEntry != null);
                      initialCategoryId = extra.initialCategoryId;
                    } else if (extra is DiaryEntry) {
                      tempEntry = extra;
                      startInEditMode = tempEntry != null;
                    }

                    return DiaryDetailPage(
                      diaryId: id,
                      tempEntry: tempEntry,
                      startInEditMode: startInEditMode,
                      initialCategoryId: initialCategoryId,
                    );
                  },
                ),
              ],
            ),

            // 캘린더
            GoRoute(
              path: RoutePaths.calendar,
              builder: (context, state) => const CalendarPage(),
            ),

            // 손글씨 다이어리
            GoRoute(
              path: RoutePaths.handwritingDiary,
              builder: (context, state) => const HandwritingDiaryPage(),
            ),
          ],
        ),

        // 프로필
        GoRoute(
          path: RoutePaths.profile,
          builder: (context, state) => const ProfilePage(),
        ),

        // 설정
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
          routes: [
            GoRoute(
              path: '/change-password',
              builder: (context, state) => const ChangePasswordPage(),
            ),
            GoRoute(
              path: '/app-preferences',
              builder: (context, state) => const AppPreferencesPage(),
            ),
            GoRoute(
              path: '/emoji-theme',
              builder: (context, state) => const EmojiThemeSettingsPage(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationSettingsPage(),
            ),
            GoRoute(
              path: '/privacy',
              builder: (context, state) => const PrivacySettingsPage(),
            ),
          ],
        ),

        // 알림
        GoRoute(
          path: RoutePaths.notifications,
          builder: (context, state) => const NotificationsPage(),
        ),

        // 고객지원
        GoRoute(
          path: RoutePaths.support,
          builder: (context, state) => const SupportPage(),
        ),

        // FCM 디버깅 (개발용)
        GoRoute(
          path: '/debug/fcm',
          builder: (context, state) => const FcmDebugPage(),
        ),
      ],
    );
  }
}
