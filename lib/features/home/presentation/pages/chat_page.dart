import 'package:flutter/material.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class ChatPage extends StatelessWidget {
  final String? sessionId;

  const ChatPage({super.key, this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 80, color: Color(0xFFB2C5B8)),
            SizedBox(height: 24),
            Text(
              'AI 채팅 페이지',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
