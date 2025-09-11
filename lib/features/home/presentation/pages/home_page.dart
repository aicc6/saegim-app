import 'package:flutter/material.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

/// 메인 홈 페이지 (AI 채팅 생성)
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list, size: 80, color: Color(0xFFB2C5B8)),
            SizedBox(height: 24),
            Text(
              '글 쓰기',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
