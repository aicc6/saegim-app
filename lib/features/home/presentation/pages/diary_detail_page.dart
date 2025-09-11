import 'package:flutter/material.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class DiaryDetailPage extends StatelessWidget {
  final String diaryId;
  
  const DiaryDetailPage({super.key, required this.diaryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book, size: 80, color: Color(0xFFB2C5B8)),
            const SizedBox(height: 24),
            Text('다이어리 상세: $diaryId', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}