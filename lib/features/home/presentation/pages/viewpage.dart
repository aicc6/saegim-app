// viewpage.dart
import 'package:flutter/material.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/features/calendar/data/services/diary_api_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

class ViewPostPage extends StatefulWidget {
  final DiaryEntry tempEntry;
  final String fromPath;

  const ViewPostPage({
    super.key,
    required this.tempEntry,
    required this.fromPath,
  });

  @override
  State<ViewPostPage> createState() => _ViewPostPageState();
}

class _ViewPostPageState extends State<ViewPostPage> {
  late TextEditingController _titleController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.tempEntry.title ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      AppLogger.info('Saving diary to backend', 'ViewPostPage');

      // 백엔드 API 스펙에 맞춘 데이터 구조
      final diaryData = <String, dynamic>{
        'content': widget.tempEntry.content, // 필수
      };

      // 선택적 필드 추가 (비어있지 않을 때만)
      if (widget.tempEntry.aiGeneratedText != null &&
          widget.tempEntry.aiGeneratedText!.isNotEmpty) {
        diaryData['ai_generated_text'] = widget.tempEntry.aiGeneratedText;
      }

      if (widget.tempEntry.emotion != null &&
          widget.tempEntry.emotion!.isNotEmpty) {
        diaryData['user_emotion'] = widget.tempEntry.emotion;
      }

      if (widget.tempEntry.aiEmotion != null &&
          widget.tempEntry.aiEmotion!.isNotEmpty) {
        diaryData['ai_emotion'] = widget.tempEntry.aiEmotion;
        // ai_emotion이 있으면 confidence도 추가
        diaryData['ai_emotion_confidence'] = 0.8;
      }

      if (widget.tempEntry.keywords.isNotEmpty) {
        diaryData['keywords'] = widget.tempEntry.keywords;
      }

      // diary_date를 YYYY-MM-DD 형식으로 변환
      final date = widget.tempEntry.diaryDate;
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      diaryData['diary_date'] = dateString;

      AppLogger.info('Request data: $diaryData', 'ViewPostPage');

      // DiaryApiService를 통해 저장
      final dio = DiaryApiService.instance.dio;
      final response = await dio.post('/api/diary', data: diaryData);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('Diary saved successfully', 'ViewPostPage');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('다이어리가 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to save diary: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Failed to save diary', tag: 'ViewPostPage', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일기 작성')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 감정 표시
            if (widget.tempEntry.aiEmotion != null ||
                widget.tempEntry.emotion != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text(
                      widget.tempEntry.emotionEmoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.tempEntry.aiEmotion ?? widget.tempEntry.emotion}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // 제목 입력
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '제목을 입력하세요',
              ),
            ),
            const SizedBox(height: 16),

            // 내용 표시
            Text(
              widget.tempEntry.aiGeneratedText ?? widget.tempEntry.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 16),
            // 키워드 표시
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.tempEntry.keywords.map((keyword) {
                return Chip(label: Text(keyword));
              }).toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _handleSave,
        label: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('저장'),
        icon: _isSaving ? null : const Icon(Icons.save),
        backgroundColor: _isSaving ? Colors.grey : null,
      ),
    );
  }
}
