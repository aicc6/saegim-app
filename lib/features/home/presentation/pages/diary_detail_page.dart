import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/features/calendar/data/services/diary_api_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

class DiaryDetailPage extends StatefulWidget {
  final String diaryId;

  const DiaryDetailPage({super.key, required this.diaryId});

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  DiaryEntry? diary;
  bool isLoading = true;
  String? errorMessage;

  // 인라인 편집 모드 관련 변수들
  bool isEditMode = false;
  bool isSaving = false;
  late TextEditingController _titleController;
  late TextEditingController _keywordsController;
  late TextEditingController _aiGeneratedTextController;
  String? _selectedEmotion;

  // 감정 옵션 (서버 호환을 위해 정확한 영어 값 사용)
  final List<Map<String, String>> _emotions = [
    {'value': 'happy', 'emoji': '😊', 'label': '행복'},
    {'value': 'peaceful', 'emoji': '😌', 'label': '평온'},
    {'value': 'unrest', 'emoji': '😰', 'label': '불안'},
    {'value': 'angry', 'emoji': '😠', 'label': '분노'},
    {'value': 'sad', 'emoji': '😢', 'label': '슬픔'},
  ];

  /// 감정을 한글로 변환
  String _getKoreanEmotion(String? emotion) {
    if (emotion == null || emotion.isEmpty) return '설정되지 않음';

    switch (emotion.toLowerCase()) {
      case 'happy':
      case '행복':
        return '행복';
      case 'peaceful':
      case '평온':
        return '평온';
      case 'unrest':
      case 'anxious':
      case '불안':
        return '불안';
      case 'angry':
      case '분노':
      case '화남':
        return '분노';
      case 'sad':
      case '슬픔':
        return '슬픔';
      default:
        return emotion; // 이미 한글이거나 알 수 없는 감정인 경우 그대로 반환
    }
  }

  /// 감정에 해당하는 이모지 반환
  String _getEmotionEmoji(String? emotion) {
    if (emotion == null || emotion.isEmpty) return '😐';

    switch (emotion.toLowerCase()) {
      case 'happy':
      case '행복':
        return '😊';
      case 'peaceful':
      case '평온':
        return '😌';
      case 'unrest':
      case 'anxious':
      case '불안':
        return '😰';
      case 'angry':
      case '분노':
      case '화남':
        return '😠';
      case 'sad':
      case '슬픔':
        return '😢';
      default:
        return '😐';
    }
  }

  /// 감정 선택 드롭다운 위젯
  Widget _buildEmotionDropdown() {
    return DropdownButton<String>(
      value: _selectedEmotion,
      isExpanded: true,
      underline: Container(),
      items: _emotions.map((emotion) {
        return DropdownMenuItem<String>(
          value: emotion['value'],
          child: Row(
            children: [
              Text(emotion['emoji']!, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                emotion['label']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedEmotion = newValue;
        });
      },
    );
  }

  /// 키워드 추가 다이얼로그
  void _showAddKeywordDialog() {
    final keywordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('키워드 추가'),
          content: TextField(
            controller: keywordController,
            decoration: const InputDecoration(
              hintText: '새 키워드를 입력하세요',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final newKeyword = keywordController.text.trim();
                if (newKeyword.isNotEmpty) {
                  final currentKeywords = _keywordsController.text;
                  final updatedKeywords = currentKeywords.isEmpty
                      ? newKeyword
                      : '$currentKeywords, $newKeyword';
                  _keywordsController.text = updatedKeywords;
                }
                Navigator.of(context).pop();
              },
              child: const Text(
                '추가',
                style: TextStyle(color: Color(0xFF4A7C59)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _keywordsController = TextEditingController();
    _aiGeneratedTextController = TextEditingController();
    _loadDiary();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _keywordsController.dispose();
    _aiGeneratedTextController.dispose();
    super.dispose();
  }

  /// 다이어리 데이터 로드
  Future<void> _loadDiary() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final loadedDiary = await DiaryApiService.instance.getDiaryById(
        widget.diaryId,
      );

      if (mounted) {
        setState(() {
          diary = loadedDiary;
          isLoading = false;
          if (loadedDiary == null) {
            errorMessage = '다이어리를 불러올 수 없습니다.';
          } else {
            // 편집 모드를 위한 컨트롤러 초기화
            _initializeEditControllers();
          }
        });
      }
    } catch (e) {
      AppLogger.error(
        'Failed to load diary: ${widget.diaryId}',
        tag: 'DiaryDetailPage',
        error: e,
      );
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = '다이어리를 불러오는 중 오류가 발생했습니다.';
        });
      }
    }
  }

  /// 편집 컨트롤러 초기화
  void _initializeEditControllers() {
    if (diary == null) return;

    _titleController.text = diary!.title ?? '';
    _keywordsController.text = diary!.keywords.join(', ');
    _aiGeneratedTextController.text = diary!.aiGeneratedText ?? '';
    _selectedEmotion = diary!.emotion ?? _emotions.first['value'] as String;
  }

  /// 편집 모드 시작
  void _startEditMode() {
    setState(() {
      isEditMode = true;
    });
  }

  /// 편집 모드 취소
  void _cancelEditMode() {
    setState(() {
      isEditMode = false;
    });
    // 원래 값으로 되돌리기
    _initializeEditControllers();
  }

  /// 변경사항 저장
  Future<void> _saveChanges() async {
    if (diary == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      // 키워드 파싱 (쉼표로 구분)
      final keywordsList = _keywordsController.text
          .split(',')
          .map((keyword) => keyword.trim())
          .where((keyword) => keyword.isNotEmpty)
          .toList();

      final success = await DiaryApiService.instance.updateDiary(
        diaryId: diary!.id,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        emotion: _selectedEmotion,
        keywords: keywordsList,
        aiGeneratedText: _aiGeneratedTextController.text.trim().isEmpty
            ? null
            : _aiGeneratedTextController.text.trim(),
      );

      if (mounted && context.mounted) {
        setState(() {
          isSaving = false;
          if (success) {
            isEditMode = false; // 성공 시 즉시 편집 모드 종료
          }
        });

        if (success) {
          // 데이터 다시 로드 후 성공 메시지 표시
          await _loadDiary();

          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('다이어리가 성공적으로 수정되었습니다.'),
                backgroundColor: Color(0xFF4A7C59),
              ),
            );
          }
        } else {
          if (mounted && context.mounted) {
            _showUpdateNotAvailableDialog();
          }
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error updating diary: ${diary!.id}',
        tag: 'DiaryDetailPage',
        error: e,
      );
      if (mounted) {
        setState(() {
          isSaving = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('다이어리 수정 중 오류가 발생했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 업데이트 불가 알림 다이얼로그
  void _showUpdateNotAvailableDialog() {
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
              onPressed: () => Navigator.of(context).pop(),
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

  /// 다이어리 삭제
  Future<void> _deleteDiary() async {
    if (diary == null) return;

    try {
      final success = await DiaryApiService.instance.deleteDiary(diary!.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('다이어리가 성공적으로 삭제되었습니다.'),
              backgroundColor: Color(0xFF4A7C59),
            ),
          );
          // 삭제 후 이전 페이지로 돌아가기
          _handleBackNavigation(context);
        } else {
          _showDeleteNotAvailableDialog(context);
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error deleting diary: ${diary!.id}',
        tag: 'DiaryDetailPage',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('다이어리 삭제 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 삭제 기능이 사용 불가능할 때 보여줄 다이얼로그
  void _showDeleteNotAvailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('삭제 기능 준비 중'),
          content: const Text(
            '죄송합니다. 다이어리 삭제 기능이 아직 준비 중입니다.\n\n'
            '현재 상황:\n'
            '• 백엔드 서버에서 삭제 API 개발 중\n'
            '• 읽기 전용 모드로 운영 중\n'
            '• 곧 삭제 기능을 제공할 예정입니다\n\n'
            '양해 부탁드립니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 앱바
            _buildCustomAppBar(context),

            // 스크롤 가능한 콘텐츠
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4A7C59),
                      ),
                    )
                  : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadDiary,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A7C59),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    )
                  : diary == null
                  ? const Center(
                      child: Text(
                        '다이어리를 찾을 수 없습니다.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 제목과 날짜
                          _buildTitleSection(),

                          const SizedBox(height: 24),

                          // 감정 분석 섹션
                          _buildEmotionAnalysisSection(),

                          const SizedBox(height: 20),

                          // 키워드 섹션
                          _buildKeywordSection(),

                          const SizedBox(height: 24),

                          // AI 생성 글 섹션
                          _buildAiContentSection(),

                          const SizedBox(height: 32),

                          // 수정/삭제 버튼
                          _buildActionButtons(context),

                          const SizedBox(height: 20),
                        ],
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
            onTap: () => _handleBackNavigation(context),
            child: const Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '뒤로가기',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 뒤로가기 네비게이션 처리
  void _handleBackNavigation(BuildContext context) {
    final uri = GoRouter.of(context).routeInformationProvider.value.uri;
    final from = uri.queryParameters['from'];

    if (from == 'calendar') {
      // 캘린더에서 왔다면 캘린더로 돌아가기
      context.go('/calendar');
    } else {
      // 그 외의 경우는 기본 pop 동작 (다이어리 목록으로)
      context.pop();
    }
  }

  // 제목과 날짜 섹션
  Widget _buildTitleSection() {
    if (diary == null) return const SizedBox.shrink();

    final diaryDate = diary!.diaryDate;
    final formattedDate = '${diaryDate.month}월 ${diaryDate.day}일';

    return Container(
      padding: isEditMode ? const EdgeInsets.all(16) : EdgeInsets.zero,
      decoration: isEditMode
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4A7C59), width: 2),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditMode) ...[
            // 편집 모드: 제목 입력 필드
            const Text(
              '제목',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ] else ...[
            // 보기 모드: 제목 표시
            Text(
              _titleController.text.isNotEmpty
                  ? _titleController.text
                  : (diary!.title ?? '$formattedDate 일기'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // 감정 분석 섹션
  Widget _buildEmotionAnalysisSection() {
    if (diary == null) return const SizedBox.shrink();

    final userEmotion = _getKoreanEmotion(
      isEditMode ? _selectedEmotion : diary!.emotion,
    );
    final aiEmotion = _getKoreanEmotion(diary!.aiEmotion);
    final currentEmoji = _getEmotionEmoji(
      isEditMode ? _selectedEmotion : diary!.emotion,
    );

    return Row(
      children: [
        // 사용자 감정
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEditMode
                    ? const Color(0xFF4A7C59)
                    : const Color(0xFFE9ECEF),
                width: isEditMode ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '사용자 감정 : ',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    if (isEditMode) ...[
                      // 편집 모드: 감정 선택 드롭다운
                      Expanded(child: _buildEmotionDropdown()),
                    ] else ...[
                      // 보기 모드: 현재 감정 표시
                      Text(currentEmoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 4),
                      Text(
                        userEmotion,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'AI 분석 감정 : ',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    Text(
                      _getEmotionEmoji(diary!.aiEmotion),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      aiEmotion,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '(AI 분석)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 키워드 섹션
  Widget _buildKeywordSection() {
    if (diary == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditMode ? const Color(0xFF4A7C59) : const Color(0xFFE9ECEF),
          width: isEditMode ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '키워드 :',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              if (isEditMode) ...[
                const Spacer(),
                Container(
                  width: 80,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      // 새 키워드 입력 다이얼로그 표시
                      _showAddKeywordDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7C59),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('추가'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (isEditMode) ...[
            // 편집 모드: 텍스트 필드
            TextField(
              controller: _keywordsController,
              decoration: const InputDecoration(
                hintText: '새 키워드 입력',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ] else ...[
            // 보기 모드: 키워드 칩들
            if (diary!.keywords.isEmpty) ...[
              const Text(
                '키워드가 없습니다.',
                style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: diary!.keywords
                    .map((keyword) => _buildKeywordChip('#$keyword'))
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // 키워드 칩
  Widget _buildKeywordChip(String keyword) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        keyword,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF4A7C59),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // AI 생성 글 섹션
  Widget _buildAiContentSection() {
    if (diary == null) return const SizedBox.shrink();

    final aiContent = diary!.aiGeneratedText;
    final originalContent = diary!.content;
    final displayContent = isEditMode
        ? _aiGeneratedTextController.text.isNotEmpty
              ? _aiGeneratedTextController.text
              : (aiContent ?? originalContent)
        : (aiContent ?? originalContent);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditMode ? const Color(0xFF4A7C59) : const Color(0xFFE9ECEF),
          width: isEditMode ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'AI 생성 글',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isEditMode) ...[
                const Spacer(),
                Container(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            // 사진 업로드 기능 (나중에 구현)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('사진 업로드 기능은 준비 중입니다.'),
                                backgroundColor: Color(0xFF4A7C59),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('사진 올리기'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (isEditMode) ...[
            // 편집 모드: 텍스트 필드
            TextField(
              controller: _aiGeneratedTextController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'AI 생성 글을 수정하세요...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF1F2937),
              ),
            ),
          ] else ...[
            // 보기 모드: 텍스트 표시
            Text(
              displayContent,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                '•',
                style: TextStyle(fontSize: 24, color: Color(0xFFB2C5B8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 수정/삭제 버튼
  Widget _buildActionButtons(BuildContext context) {
    if (isEditMode) {
      // 편집 모드: 저장/취소 버튼
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 저장 버튼
          Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4A7C59),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextButton(
              onPressed: isSaving ? null : _saveChanges,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // 취소 버튼
          Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextButton(
              onPressed: isSaving ? null : _cancelEditMode,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '취소',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // 보기 모드: 수정/삭제 버튼
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 수정 버튼
          Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFB2C5B8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextButton(
              onPressed: _startEditMode,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '수정',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 삭제 버튼
          Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextButton(
              onPressed: () {
                _showDeleteConfirmDialog(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '삭제',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('일기 삭제'),
          content: const Text('정말로 이 일기를 삭제하시겠습니까?\n삭제된 일기는 복구할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDiary();
              },
              child: const Text(
                '삭제',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        );
      },
    );
  }
}
