// viewpage.dart
import 'package:flutter/material.dart';

import '../../../calendar/data/models/diary_model.dart';

class ViewPostPage extends StatelessWidget {
  final DiaryEntry tempEntry;
  final String fromPath;

  const ViewPostPage({
    super.key,
    required this.tempEntry,
    required this.fromPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일기 작성')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 입력
            TextField(
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '제목을 입력하세요',
              ),
            ),
            const SizedBox(height: 16),

            // 내용 표시
            Text(
              tempEntry.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 16),
            // 키워드 표시
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tempEntry.keywords.map((keyword) {
                return Chip(label: Text(keyword));
              }).toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: 일기 저장 로직 구현
          Navigator.pop(context);
        },
        label: const Text('저장'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
