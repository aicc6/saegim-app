import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/core/theme/theme_extensions.dart';

/// 공통 앱바 위젯 - 브랜드 통일형
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final bool showMenuButton;
  final String? title;

  const CommonAppBar({
    super.key,
    this.showBackButton = false,
    this.showMenuButton = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // backgroundColor 제거 - Theme가 자동으로 적용
      elevation: 0,
      centerTitle: false,
      leading: showBackButton
          ? IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back, color: context.colorScheme.primary),
            )
          : null,
      title: Text(
        title ?? '새김',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: context.colorScheme.primary,
        ),
      ),
      actions: showMenuButton
          ? [
              PopupMenuButton<String>(
                icon: Icon(Icons.menu, color: context.colorScheme.primary),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      context.push(RoutePaths.profile);
                      break;
                    case 'settings':
                      context.push('/settings');
                      break;
                    case 'notifications':
                      context.push('/settings/notifications');
                      break;
                    case 'support':
                      context.push(RoutePaths.support);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('프로필'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('설정'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'notifications',
                    child: ListTile(
                      leading: Icon(Icons.notifications),
                      title: Text('알림'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'support',
                    child: ListTile(
                      leading: Icon(Icons.support),
                      title: Text('고객지원'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
