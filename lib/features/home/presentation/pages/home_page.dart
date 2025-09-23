// home_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../riverpod/create_notifier.dart';
import '../riverpod/emotions_notifier.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  List<File> selectedImages = [];
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  bool showResults = false;

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 이미지 선택
  Future<void> _selectImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          selectedImages.addAll(
            images
                .take(10 - selectedImages.length)
                .map((xfile) => File(xfile.path)),
          );
        });
      }
    } catch (e) {
      _showErrorSnackBar('이미지 선택 중 오류가 발생했습니다.');
    }
  }

  // 이미지 제거
  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  // 날짜 선택
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        // 과거 날짜가 아닌 경우 시간 초기화
        if (picked.isAtSameMomentAs(DateTime.now()) ||
            picked.isAfter(DateTime.now())) {
          selectedTime = null;
        } else
          selectedTime ??= const TimeOfDay(hour: 11, minute: 0);
      });
    }
  }

  // 시간 선택
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 11, minute: 0),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
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
    setState(() {
      showResults = true;
    });
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
    // isDarkMode 제거 (미사용)

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
      backgroundColor: Colors.transparent, // 배경색 투명하게
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            30,
            60,
            30,
            10,
          ), // left, top, right, bottom
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3F764A).withOpacity(0.1),
                const Color(0xFF3F764A).withOpacity(0.05),
              ],
            ),
          ),
          child: SingleChildScrollView(
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

                // 이미지 추가 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: selectedImages.length < 10
                            ? _selectImages
                            : null,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text('이미지 추가 (${selectedImages.length}/10)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3F764A),
                          side: const BorderSide(color: Color(0xFF3F764A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (selectedImages.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedImages.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all),
                        tooltip: '모든 이미지 제거',
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),

                // 이미지 미리보기
                if (selectedImages.isNotEmpty) _buildImagePreview(),

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
                const SizedBox(height: 24),
                if (createState.generatedText != null)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.article_outlined,
                                color: Color(0xFF3F764A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '생성된 글',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF3F764A),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            createState.generatedText!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 로딩 애니메이션
  Widget _buildLoadingAnimation() {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'AI가 글을 생성하고 있습니다...',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  // 메타 정보 표시
  Widget _buildMetaInfo(CreateState createState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '생성 정보',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              '문체',
              createState.getStyleDisplayName(createState.style),
            ),
            _buildInfoRow(
              '길이',
              createState.getLengthDisplayName(createState.length),
            ),
            if (createState.emotion.isNotEmpty)
              _buildInfoRow('감정', createState.emotion),
            if (createState.generatedKeywords?.isNotEmpty == true)
              _buildInfoRow(
                '키워드',
                createState.generatedKeywords!.take(5).join(', '),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  // 하단 입력 영역
  Widget _buildBottomInputArea() {
    final createState = ref.watch(createProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이미지 미리보기
          if (selectedImages.isNotEmpty) _buildImagePreview(),

          // 입력창
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    hintText: '새로운 글을 생성해보세요...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!createState.isGenerating) {
                      _generateText();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: selectedImages.length < 10 ? _selectImages : null,
                icon: const Icon(Icons.image),
                tooltip: '이미지 추가',
              ),
              IconButton(
                onPressed: createState.isGenerating ? null : _generateText,
                icon: createState.isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                tooltip: '생성',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 이미지 미리보기
  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '선택된 이미지 (${selectedImages.length}/10)',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          selectedImages[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          onPressed: () => _removeImage(index),
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 사용되지 않던 메인 입력 섹션 제거

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
                        ? const Color(0xFF3F764A)
                        : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                  color: isSelected
                      ? const Color(0xFF3F764A).withOpacity(0.1)
                      : Colors.white,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF3F764A).withOpacity(0.15),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    config.emoji,
                    style: TextStyle(fontSize: isSelected ? 28 : 22),
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
  void _copyToClipboard() async {
    final createState = ref.read(createProvider);
    if (createState.generatedText != null) {
      // Clipboard.setData 사용 (flutter/services.dart import 필요)
      // await Clipboard.setData(ClipboardData(text: createState.generatedText!));
      _showSuccessSnackBar('텍스트가 복사되었습니다!');
    }
  }

  // 다이어리 저장
  void _saveToDiary() async {
    final createState = ref.read(createProvider);
    if (createState.generatedText != null) {
      // 실제 다이어리 저장 로직 구현
      // 예: API 호출, 로컬 저장 등

      _showSuccessSnackBar('다이어리가 저장되었습니다!');
    }
  }
}
