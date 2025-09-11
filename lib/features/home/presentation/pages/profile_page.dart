import 'package:flutter/material.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:saegim/features/authentication/presentation/providers/auth_provider.dart';
import 'package:saegim/app/routes/route_paths.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: Color(0xFFB2C5B8)),
            const SizedBox(height: 24),
            const Text('프로필 페이지', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                await authProvider.logout();
                if (context.mounted) {
                  context.go(RoutePaths.authLogin);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}