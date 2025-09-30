// home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../calendar/data/models/diary_model.dart';
import '../riverpod/create_notifier.dart';
import '../riverpod/emotions_notifier.dart';
import 'result_card.dart' as result_card;
import 'viewpage.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  bool showResults = false;

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 감정 토글
  void _toggleEmotion(EmotionOption emotion) {
    ref.read(emotionProvider.notifier).toggleEmotion(emotion);
  }

  // 글 생성
  void _generateText() async {
    final createNotifier = ref.read(createProvider.notifier);
    final emotionState = ref.read(emotionProvider);

    if (_promptController.text.trim().isEmpty) {
      _showErrorSnackBar('프롬프트를 입력해주세요.');
      return;
    }

    if (!mounted) return;
    createNotifier.setPrompt(_promptController.text);
    await createNotifier.generateText(
      emotion: emotionState.selectedEmotion.value,
    );

    if (!mounted) return;

    // 생성 성공 확인 및 상태 업데이트
    final currentState = ref.read(createProvider);
    if (currentState.generatedText != null &&
        currentState.generatedText!.isNotEmpty) {
      setState(() {
        showResults = true;
      });
    }
  }

  // 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // 성공 스낵바 표시
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createProvider);
    final emotionState = ref.watch(emotionProvider);

    // 에러 처리 (dispose 이후 콜백 실행 방지)
    if (createState.error != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showErrorSnackBar(createState.error!);
        if (!mounted) return;
        ref.read(createProvider.notifier).clearError();
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(30, 60, 30, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3F764A).withOpacity(0.1),
                const Color(0xFF3F764A).withOpacity(0.05),
              ],
            ),
          ),
          child:
              (createState.generatedText != null &&
                      createState.generatedText!.isNotEmpty) ||
                  showResults
              ? _buildResultView(createState)
              : _buildInputView(createState, emotionState),
        ),
      ),
    );
  }

  // CreateState를 GeneratedMessage로 변환
  result_card.GeneratedMessage _convertToGeneratedMessage(
    CreateState createState,
  ) {
    // 히스토리가 비어있으면 현재 텍스트로 단일 버전 생성
    if (createState.generationHistory.isEmpty) {
      return result_card.GeneratedMessage(
        id:
            createState.sessionId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        versions: [
          result_card.MessageVersion(
            text: createState.generatedText ?? '',
            emotion: createState.emotion.isNotEmpty ? createState.emotion : '',
            length: createState.length.value,
            style: createState.style.value,
            keywords: createState.generatedKeywords,
          ),
        ],
        currentVersionIndex: 0,
      );
    }

    // 히스토리에서 모든 버전 생성
    final versions = createState.generationHistory
        .map(
          (text) => result_card.MessageVersion(
            text: text,
            emotion: createState.emotion.isNotEmpty ? createState.emotion : '',
            length: createState.length.value,
            style: createState.style.value,
            keywords: createState.generatedKeywords,
          ),
        )
        .toList();

    return result_card.GeneratedMessage(
      id:
          createState.sessionId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      versions: versions,
      currentVersionIndex: createState.currentHistoryIndex,
    );
  }

  // 감정 설정 가져오기
  result_card.EmotionConfig _getEmotionConfig(String emotion) {
    final config = emotionConfigs.firstWhere(
      (config) => config.value.toString().split('.').last == emotion,
      orElse: () => emotionConfigs.first,
    );
    return result_card.EmotionConfig(
      emoji: config.emoji,
      label: config.label,
      backgroundColor: const Color(0xFFE8F5E8),
      textColor: const Color(0xFF22543D),
    );
  }

  // 결과 화면
  Widget _buildResultView(CreateState createState) {
    final generatedMessage = _convertToGeneratedMessage(createState);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // MessageCard 사용
          result_card.MessageCard(
            message: generatedMessage,
            isRegenerating: createState.isGenerating,
            getEmotionConfig: _getEmotionConfig,
            getStyleDisplayName: (style) => createState.getStyleDisplayName(
              style == 'poem' ? WritingStyle.poem : WritingStyle.shortStory,
            ),
            getLengthDisplayName: (length) => createState.getLengthDisplayName(
              length == 'short'
                  ? LengthOption.short
                  : length == 'medium'
                  ? LengthOption.medium
                  : LengthOption.long,
            ),
            onCopy: (content) {
              // 클립보드 복사 로직
              _copyToClipboard(content);
            },
            onMoveToDiary: (content, emotion, keywords) async {
              final now = DateTime.now();
              final diary = DiaryEntry(
                id: now.millisecondsSinceEpoch.toString(),
                title: '', // 제목은 편집 페이지에서 입력
                content: content,
                aiGeneratedText: content,
                emotion: emotion,
                aiEmotion: emotion, // AI가 분석한 감정을 사용
                keywords: keywords ?? [],
                diaryDate: now,
                createdAt: now,
                isPublic: false,
              );

              // 다이어리 편집 페이지로 이동
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ViewPostPage(tempEntry: diary, fromPath: '/create'),
                  ),
                );
              }
            },
            onRegenerate: (message) {
              // 재생성 로직 (5번 제한 확인)
              final createState = ref.read(createProvider);
              if (createState.generationHistory.length < 5) {
                ref.read(createProvider.notifier).regenerateText();
              }
            },
            onPreviousVersion: (messageId) {
              // 이전 버전 로직
              ref.read(createProvider.notifier).goToPreviousHistory();
            },
            onNextVersion: (messageId) {
              // 다음 버전 로직
              ref.read(createProvider.notifier).goToNextHistory();
            },
          ),
          const SizedBox(height: 24),
          // 새로 글 생성하기 버튼
          ElevatedButton(
            onPressed: () {
              setState(() {
                _promptController.clear();
                showResults = false;
                ref.read(createProvider.notifier).clearGeneratedText();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3F764A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF3F764A)),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('새로운 글 생성하기', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 입력 화면
  Widget _buildInputView(CreateState createState, EmotionState emotionState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '어떤 글을 만들어 드릴까요?',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3F764A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            '키워드나 짧은 글을 입력하면 ai가 글을 생성해 드립니다',
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: '예 : 바람, 초록빛 오후, 천천히 걷는 길',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Color(0xFF3F764A)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildOptionsSection(createState, emotionState),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: createState.isGenerating ? null : _generateText,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F764A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: createState.isGenerating
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('생성 중...', style: TextStyle(fontSize: 16)),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome),
                      SizedBox(width: 8),
                      Text('글 생성하기', style: TextStyle(fontSize: 16)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // 옵션 선택 섹션
  Widget _buildOptionsSection(
    CreateState createState,
    EmotionState emotionState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 문체와 길이 선택
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '문체 선택',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  _buildStyleSelector(createState),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '길이 선택',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  _buildLengthSelector(createState),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 감정 선택
        Text(
          '감정을 선택해주세요 (선택 사항)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        _buildEmotionSelector(emotionState),

        const SizedBox(height: 5),
        Text(
          '선택된 감정: ${emotionState.selectedEmotion != EmotionOption.none ? emotionState.getEmotionLabel(emotionState.selectedEmotion) : "감정 선택 안함"}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF3F764A),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 문체 선택기
  Widget _buildStyleSelector(CreateState createState) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: WritingStyle.values.map((style) {
          final isSelected = createState.style == style;
          return Expanded(
            child: InkWell(
              onTap: () => ref.read(createProvider.notifier).setStyle(style),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3F764A) : Colors.white,
                  borderRadius: style == WritingStyle.poem
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        )
                      : const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                ),
                child: Text(
                  style.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 길이 선택기
  Widget _buildLengthSelector(CreateState createState) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: LengthOption.values.map((length) {
          final isSelected = createState.length == length;
          return Expanded(
            child: InkWell(
              onTap: () => ref.read(createProvider.notifier).setLength(length),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3F764A) : Colors.white,
                  borderRadius: length == LengthOption.short
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        )
                      : length == LengthOption.long
                      ? const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        )
                      : null,
                ),
                child: Text(
                  length.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 감정 선택기
  Widget _buildEmotionSelector(EmotionState emotionState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: emotionConfigs.map((config) {
          final isSelected = emotionState.selectedEmotion == config.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => _toggleEmotion(config.value),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? _getColorFromStyle(config.styles.ring)
                        : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                  color: isSelected
                      ? _getColorFromStyle(config.styles.bg)
                      : Colors.white,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _getColorFromStyle(
                              config.styles.ring,
                            ).withOpacity(0.15),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    config.emoji,
                    style: TextStyle(
                      fontSize: isSelected ? 28 : 22,
                      color: isSelected
                          ? _getColorFromStyle(config.styles.text)
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 클립보드 복사
  void _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _showSuccessSnackBar('텍스트가 복사되었습니다!');
    } catch (e) {
      _showErrorSnackBar('복사 중 오류가 발생했습니다.');
    }
  }

  Color _getColorFromStyle(String style) {
    final parts = style.split('-');
    if (parts.length != 3) return Colors.grey;

    final color = parts[1];
    final shade = int.tryParse(parts[2]) ?? 500;

    switch (color) {
      case 'yellow':
        return Colors.yellow[shade] ?? Colors.yellow;
      case 'blue':
        return Colors.blue[shade] ?? Colors.blue;
      case 'red':
        return Colors.red[shade] ?? Colors.red;
      case 'green':
        return Colors.green[shade] ?? Colors.green;
      case 'orange':
        return Colors.orange[shade] ?? Colors.orange;
      default:
        return Colors.grey[shade] ?? Colors.grey;
    }
  }
}
