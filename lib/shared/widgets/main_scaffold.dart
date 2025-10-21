import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/core/theme/theme_extensions.dart';

/// 메인 앱의 공통 Scaffold (하단 네비게이션 포함)
class MainScaffold extends StatelessWidget {
  const MainScaffold({
    super.key,
    required this.child,
    required this.currentUri,
  });

  final Widget child;
  final Uri currentUri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final currentIndex = _getCurrentIndex();

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: context.colorScheme.primary,
      unselectedItemColor: context.secondaryText,
      elevation: 8,
      onTap: (index) => _onTap(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.edit_outlined),
          activeIcon: Icon(Icons.edit),
          label: '글쓰기',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_outlined),
          activeIcon: Icon(Icons.list),
          label: '글목록',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: '캘린더',
        ),
      ],
    );
  }

  int _getCurrentIndex() {
    if (currentUri.path.startsWith('/diary')) return 1;
    if (currentUri.path.startsWith(RoutePaths.calendar)) return 2;
    return 0; // 글쓰기 (홈)
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.home);
        break;
      case 1:
        context.go(RoutePaths.diaryList);
        break;
      case 2:
        context.go(RoutePaths.calendar);
        break;
    }
  }
}
