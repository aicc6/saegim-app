import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/app/routes/route_paths.dart';

/// 메인 앱의 공통 Scaffold (하단 네비게이션 포함)
class MainScaffold extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentLocation,
  });

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
      selectedItemColor: const Color(0xFFB2C5B8),
      unselectedItemColor: const Color(0xFF6B7280),
      backgroundColor: Colors.white,
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
    if (currentLocation.startsWith('/diary')) return 1;
    if (currentLocation.startsWith(RoutePaths.calendar)) return 2;
    return 0; // 글쓰기 (홈)
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.home); // 글쓰기
        break;
      case 1:
        context.go('/diary'); // 글목록
        break;
      case 2:
        context.go(RoutePaths.calendar); // 캘린더
        break;
    }
  }
}