import 'package:flutter/material.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

/// 회원가입 페이지
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true, showMenuButton: false),
      backgroundColor: Colors.white,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add,
              size: 80,
              color: Color(0xFFB2C5B8),
            ),
            SizedBox(height: 24),
            Text(
              '회원가입 페이지',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '회원가입 기능을 준비 중입니다.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}