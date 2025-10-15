import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/features/calendar/data/services/diary_api_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

class DiaryEditPage extends StatefulWidget {
  final DiaryEntry diary;

  const DiaryEditPage({super.key, required this.diary});

  @override
  State<DiaryEditPage> createState() => _DiaryEditPageState();
}

class _DiaryEditPageState extends State<DiaryEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _aiGeneratedTextController;
  late TextEditingController _keywordsController;

  String? _selectedEmotion;
  bool _isLoading = false;
  DateTime? _selectedDate;

  // 감정 옵션 (서버 호환을 위해 정확한 영어 값 사용)
  final List<Map<String, String>> _emotions = [
    {'value': 'happy', 'emoji': '😊', 'label': '행복'},
    {'value': 'peaceful', 'emoji': '😌', 'label': '평온'},
    {'value': 'unrest', 'emoji': '😰', 'label': '불안'},
    {'value': 'angry', 'emoji': '😠', 'label': '분노'},
    {'value': 'sad', 'emoji': '😢', 'label': '슬픔'},
  ];

  @override
  void initState() {
    super.initState();
    _isLoading = false; // 명시적으로 로딩 상태 초기화
    _titleController = TextEditingController(text: widget.diary.title ?? '');
    _aiGeneratedTextController = TextEditingController(
      text: widget.diary.aiGeneratedText ?? '',
    );
    _keywordsController = TextEditingController(
      text: widget.diary.keywords.join(', '),
    );
    // 원래 감정이 null이면 첫 번째 감정을 기본값으로 설정
    _selectedEmotion =
        widget.diary.emotion ?? _emotions.first['value'] as String;
    // 선택된 날짜 초기화 (기존 다이어리 날짜 사용)
    _selectedDate = widget.diary.diaryDate;

    AppLogger.info(
      '📱 DiaryEditPage initialized, _isLoading = $_isLoading',
      'DiaryEditPage',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _aiGeneratedTextController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  /// 다이어리 수정 저장
  Future<void> _saveDiary() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    AppLogger.info(
      '🔄 Starting diary save, setting _isLoading = true',
      'DiaryEditPage',
    );
    setState(() {
      _isLoading = true;
    });
    AppLogger.info('✅ _isLoading state set to true', 'DiaryEditPage');

    try {
      // 키워드 파싱 (쉼표로 구분)
      final keywordsList = _keywordsController.text
          .split(',')
          .map((keyword) => keyword.trim())
          .where((keyword) => keyword.isNotEmpty)
          .toList();

      // 🔥 강제 디버깅 로그
      print('🔥 DEBUGGING: _selectedEmotion = $_selectedEmotion');
      print('🔥 DEBUGGING: widget.diary.emotion = ${widget.diary.emotion}');
      print('🔥 DEBUGGING: title = ${_titleController.text}');
      print('🔥 DEBUGGING: keywords = $keywordsList');

      // 다이어리 정보 로깅
      AppLogger.info(
        'Attempting to update diary - ID: ${widget.diary.id}, Title: ${widget.diary.title}',
        'DiaryEditPage',
      );

      // 감정 선택 상태 디버깅
      AppLogger.info(
        'Selected emotion: $_selectedEmotion (original: ${widget.diary.emotion})',
        'DiaryEditPage',
      );

      final success = await DiaryApiService.instance.updateDiary(
        diaryId: widget.diary.id,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        content: widget.diary.content, // 기존 content 유지 (API 스키마에 포함)
        emotion: _selectedEmotion ?? widget.diary.emotion, // null이면 기존 감정 유지
        keywords: keywordsList,
        aiGeneratedText: _aiGeneratedTextController.text.trim().isEmpty
            ? null
            : _aiGeneratedTextController.text.trim(),
        diaryDate: _selectedDate, // 선택된 날짜 전달
      );

      if (success) {
        // 로딩 상태 먼저 해제
        AppLogger.info(
          '✅ Diary update successful, setting _isLoading = false',
          'DiaryEditPage',
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          AppLogger.info(
            '✅ _isLoading state updated to false, current value: $_isLoading',
            'DiaryEditPage',
          );
        } else {
          AppLogger.warning(
            '⚠️ Widget not mounted, cannot update _isLoading state',
            'DiaryEditPage',
          );
        }

        // 성공 메시지 표시
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('다이어리가 성공적으로 저장되었습니다.'),
              backgroundColor: Color(0xFF4A7C59),
            ),
          );
        }

        // 페이지 닫기 (약간의 지연을 두어 상태 업데이트가 완료되도록)
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && context.mounted) {
          context.pop(true); // true를 반환하여 수정 완료를 알림
        }
      } else {
        AppLogger.warning(
          '❌ Diary update failed, setting _isLoading = false',
          'DiaryEditPage',
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          AppLogger.info(
            '✅ _isLoading state updated to false (failed case)',
            'DiaryEditPage',
          );
        }

        if (mounted && context.mounted) {
          _showUpdateNotAvailableDialog(context);
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error updating diary: ${widget.diary.id}',
        tag: 'DiaryEditPage',
        error: e,
      );
      AppLogger.info(
        '💥 Exception occurred, setting _isLoading = false',
        'DiaryEditPage',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppLogger.info(
          '✅ _isLoading state updated to false (exception case)',
          'DiaryEditPage',
        );
      }

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('다이어리 수정 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 수정 기능이 사용 불가능할 때 보여줄 다이얼로그
  void _showUpdateNotAvailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('수정 기능 준비 중'),
          content: const Text(
            '죄송합니다. 다이어리 수정 중 서버 오류가 발생했습니다.\n\n'
            '현재 상황:\n'
            '• 요청 데이터는 올바르게 전송됨\n'
            '• 서버 내부 처리 중 오류 발생\n'
            '• 백엔드 팀에서 문제 해결 중\n'
            '• 곧 정상 서비스 제공 예정\n\n'
            '잠시 후 다시 시도해 주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pop(); // 수정 페이지도 닫기
              },
              child: const Text(
                '확인',
                style: TextStyle(color: Color(0xFF4A7C59)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = _selectedDate ?? widget.diary.diaryDate;
    final formattedDate = displayDate != null
        ? '${displayDate.month}월 ${displayDate.day}일'
        : '날짜 없음';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 앱바
            _buildCustomAppBar(context),

            // 폼 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 날짜 표시 및 선택
                      Text(
                        '$formattedDate 일기 수정',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 날짜 선택 필드
                      _buildDateField(),

                      const SizedBox(height: 24),

                      // 제목 입력
                      _buildTitleField(),

                      const SizedBox(height: 24),

                      // 감정 선택
                      _buildEmotionField(),

                      const SizedBox(height: 24),

                      // 키워드 입력
                      _buildKeywordsField(),

                      const SizedBox(height: 24),

                      // AI 생성글 수정
                      _buildAiGeneratedTextField(),

                      const SizedBox(height: 32),

                      // 저장/취소 버튼
                      _buildActionButtons(context),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 커스텀 앱바
  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '다이어리 수정',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 날짜 선택 필드
  Widget _buildDateField() {
    print('🗓️ _buildDateField 호출됨, _selectedDate: $_selectedDate');
    final formattedDate = _selectedDate != null
        ? '${_selectedDate!.month}월 ${_selectedDate!.day}일'
        : '날짜를 선택하세요';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4A7C59),
          width: 2,
        ), // 더 진한 테두리
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 날짜 선택',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF4A7C59),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              print('🗓️ 날짜 필드 터치됨');
              _selectDate(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF4A7C59)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF8FFFE),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _selectedDate != null
                          ? const Color(0xFF1F2937)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    size: 24,
                    color: Color(0xFF4A7C59),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '날짜를 터치하여 변경하세요',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // 날짜 선택 다이얼로그
  Future<void> _selectDate(BuildContext context) async {
    print('🗓️ 날짜 선택 다이얼로그 호출됨');

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A7C59),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    print('🗓️ 선택된 날짜: $picked');

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        print('🗓️ _selectedDate 업데이트됨: $_selectedDate');
      });
    }
  }

  // 제목 입력 필드
  Widget _buildTitleField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '제목',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: '제목을 입력하세요 (선택사항)',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }

  // 감정 선택 필드
  Widget _buildEmotionField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '감정',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _emotions.map((emotion) {
              final isSelected = _selectedEmotion == emotion['value'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEmotion = emotion['value'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4A7C59)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4A7C59)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        emotion['emoji']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        emotion['label']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 키워드 입력 필드
  Widget _buildKeywordsField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '키워드',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _keywordsController,
            decoration: const InputDecoration(
              hintText: '키워드를 쉼표(,)로 구분하여 입력하세요',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // AI 생성글 수정 필드
  Widget _buildAiGeneratedTextField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI 생성 글',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _aiGeneratedTextController,
            decoration: const InputDecoration(
              hintText: 'AI 생성 글을 수정하세요',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
              height: 1.6,
            ),
            maxLines: 8,
            minLines: 4,
          ),
        ],
      ),
    );
  }

  // 액션 버튼들
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 취소 버튼
        Container(
          width: 120,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextButton(
            onPressed: _isLoading ? null : () => context.pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              '취소',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 저장 버튼
        Container(
          width: 120,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF4A7C59),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextButton(
            onPressed: _isLoading ? null : _saveDiary,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
