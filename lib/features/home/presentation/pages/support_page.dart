import 'package:flutter/material.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support, size: 80, color: Color(0xFFB2C5B8)),
            SizedBox(height: 24),
            Text('고객지원 페이지', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}