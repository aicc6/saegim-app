// home_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saegim/core/theme/theme_extensions.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

import '../riverpod/create_notifier.dart';
import '../riverpod/emotions_notifier.dart';
import 'result_card.dart' as result_card;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  bool showResults = false;
  List<XFile> selectedImages = []; // 선택된 이미지 목록 (최대 3장)

  @override
  void initState() {
    super.initState();
    // 앱 재실행 시 이전 생성 결과 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(createProvider.notifier).clearGeneratedText();
        setState(() {
          showResults = false;
          _promptController.clear();
          selectedImages.clear();
        });
      }
    });
  }

  /// 이미지 선택 (갤러리에서)
  Future<void> _pickImages() async {
    try {
      final remainingSlots = 3 - selectedImages.length;
      if (remainingSlots <= 0) {
        _showErrorSnackBar('최대 3장까지만 선택할 수 있습니다.');
        return;
      }

      final List<XFile> images = await _imagePicker.pickMultipleMedia(
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        final imagesToAdd = images.take(remainingSlots).toList();
        setState(() {
          selectedImages.addAll(imagesToAdd);
        });

        AppLogger.info(
          '${imagesToAdd.length}장의 이미지가 추가되었습니다 (총 ${selectedImages.length}장)',
          'HomePage',
        );

        if (images.length > remainingSlots) {
          _showErrorSnackBar('최대 3장까지만 선택할 수 있어 $remainingSlots장만 추가되었습니다.');
        }
      }
    } catch (e) {
      AppLogger.error('Failed to pick images', tag: 'HomePage', error: e);
      _showErrorSnackBar('이미지 선택 중 오류가 발생했습니다.');
    }
  }

  /// 카메라로 사진 촬영
  Future<void> _takePicture() async {
    try {
      if (selectedImages.length >= 3) {
        _showErrorSnackBar('최대 3장까지만 선택할 수 있습니다.');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          selectedImages.add(image);
        });

        AppLogger.info(
          '카메라로 촬영한 이미지가 추가되었습니다 (총 ${selectedImages.length}장)',
          'HomePage',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to take picture', tag: 'HomePage', error: e);
      _showErrorSnackBar('카메라 사용 중 오류가 발생했습니다.');
    }
  }

  /// 이미지 삭제
  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  /// 이미지 선택 옵션 다이얼로그
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '사진 추가',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '사진을 선택하는 방법을 선택해주세요. (최대 3장)',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // 갤러리에서 선택 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _pickImages();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F764A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.photo_library, size: 20),
                  label: const Text(
                    '갤러리에서 선택',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 카메라로 촬영 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _takePicture();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7280),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: const Text(
                    '카메라로 촬영',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                '취소',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
      _showErrorSnackBar('내용을 입력해주세요.');
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
      SnackBar(
        content: Text(message),
        backgroundColor: context.colorScheme.error,
      ),
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
      appBar: const CommonAppBar(showBackButton: false, showMenuButton: true),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colorScheme.primary.withAlpha(25),
                context.colorScheme.primary.withAlpha(13),
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
    // XFile을 File로 변환
    final imageFiles = selectedImages.map((xFile) => File(xFile.path)).toList();

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
            images: imageFiles.isNotEmpty ? imageFiles : null,
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
            images: imageFiles.isNotEmpty ? imageFiles : null,
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
    // 한글 감정을 영어 enum 값으로 변환
    final emotionMap = {
      '행복': 'happy',
      '평온': 'peaceful',
      '불안': 'unrest',
      '분노': 'angry',
      '화남': 'angry',
      '슬픔': 'sad',
      'happy': 'happy',
      'peaceful': 'peaceful',
      'unrest': 'unrest',
      'angry': 'angry',
      'sad': 'sad',
    };

    final normalizedEmotion = emotionMap[emotion.trim()] ?? emotion;

    final config = emotionConfigs.firstWhere(
      (config) => config.value.toString().split('.').last == normalizedEmotion,
      orElse: () => emotionConfigs.first,
    );

    return result_card.EmotionConfig(
      emoji: config.emoji,
      label: config.label,
      backgroundColor: context.colorScheme.primaryContainer,
      textColor: context.colorScheme.onPrimaryContainer,
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
              // 임시 DiaryEntry 생성하여 DiaryDetailPage로 전달
              final now = DateTime.now();

              // 한글 감정을 영어로 변환
              String? convertedEmotion;
              if (emotion != null && emotion.isNotEmpty) {
                final emotionMap = {
                  '행복': 'happy',
                  '평온': 'peaceful',
                  '불안': 'unrest',
                  '분노': 'angry',
                  '화남': 'angry',
                  '슬픔': 'sad',
                  'happy': 'happy',
                  'peaceful': 'peaceful',
                  'unrest': 'unrest',
                  'angry': 'angry',
                  'sad': 'sad',
                };
                convertedEmotion = emotionMap[emotion.trim()] ?? emotion;
              }

              final userInput = _promptController.text.trim();
              final contentText = userInput.isNotEmpty ? userInput : content;

              // 선택된 이미지들의 경로 추출
              final imagePaths = selectedImages
                  .map((xFile) => xFile.path)
                  .toList();

              final tempDiary = DiaryEntry(
                id: 'temp_${now.millisecondsSinceEpoch}',
                title: null,
                content: contentText, // 원본 사용자 입력
                aiGeneratedText: content, // AI가 생성한 텍스트
                emotion: convertedEmotion,
                aiEmotion: convertedEmotion,
                keywords: keywords ?? [],
                diaryDate: now,
                createdAt: now,
                isPublic: false,
                images: imagePaths, // 변경: imagePaths → images
              );

              // DiaryDetailPage로 이동 (새 다이어리 모드)
              if (mounted) {
                context.go('/diary/new', extra: tempDiary);
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
                selectedImages.clear(); // 이미지도 초기화
                ref.read(createProvider.notifier).clearGeneratedText();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.surface,
              foregroundColor: context.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colorScheme.primary),
              ),
              elevation: 2,
            ),
            child: Row(
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
          Text(
            '어떤 글을 만들어 드릴까요?',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: context.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '키워드나 짧은 글을 입력하면 ai가 글을 생성해 드립니다',
            style: TextStyle(fontSize: 13, color: context.secondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 16),

          // 텍스트 입력 필드 + 이미지 아이콘
          Stack(
            children: [
              TextField(
                controller: _promptController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: '예 : 바람, 초록빛 오후, 천천히 걷는 길',
                  hintStyle: TextStyle(
                    color: context.placeholderText,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: context.inputBackground,
                  contentPadding: const EdgeInsets.fromLTRB(16, 20, 20, 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: context.colorScheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: context.colorScheme.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 65, 119, 68),
                    ),
                  ),
                ),
              ),
              // 이미지 아이콘 (오른쪽 상단)
              Positioned(
                right: 12,
                top: 12,
                child: GestureDetector(
                  onTap: _showImagePickerDialog,
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 24,
                    color: selectedImages.isNotEmpty
                        ? const Color(0xFF3F764A)
                        : Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),

          // 선택된 이미지 미리보기
          if (selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildImagePreviewGrid(),
          ],

          const SizedBox(height: 24),
          _buildOptionsSection(createState, emotionState),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: createState.isGenerating ? null : _generateText,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: context.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: createState.isGenerating
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('생성 중...', style: TextStyle(fontSize: 16)),
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

  // 이미지 미리보기 그리드
  Widget _buildImagePreviewGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: selectedImages.length + (selectedImages.length < 3 ? 1 : 0),
      itemBuilder: (context, index) {
        // 추가 버튼
        if (index == selectedImages.length) {
          return GestureDetector(
            onTap: _showImagePickerDialog,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 28, color: Colors.grey[400]),
                  const SizedBox(height: 4),
                  Text(
                    '추가',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        // 이미지 카드
        final image = selectedImages[index];
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3F764A), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(image.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                    );
                  },
                ),
              ),
            ),
            // 삭제 버튼
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.secondaryText,
                    ),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.secondaryText,
                    ),
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
            color: context.colorScheme.primary,
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
        border: Border.all(color: context.borderSubtle),
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
                  color: isSelected
                      ? context.colorScheme.primary
                      : context.colorScheme.surface,
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
                    color: isSelected
                        ? context.colorScheme.onPrimary
                        : context.primaryText,
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
        border: Border.all(color: context.borderSubtle),
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
                  color: isSelected
                      ? context.colorScheme.primary
                      : context.colorScheme.surface,
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
                    color: isSelected
                        ? context.colorScheme.onPrimary
                        : context.primaryText,
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
                        ? context.colorScheme.primary
                        : context.borderSubtle,
                    width: isSelected ? 3 : 1,
                  ),
                  color: isSelected
                      ? _getColorFromStyle(config.styles.bg)
                      : context.colorScheme.surface,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: context.colorScheme.primary.withAlpha(38),
                            blurRadius: 3,
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
                          : context.primaryText,
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
        return const Color.fromARGB(255, 255, 250, 203);
      case 'sky':
        return const Color.fromARGB(255, 227, 247, 255);
      case 'green':
        return Colors.green[shade] ?? Colors.green;
      case 'orange':
        return const Color.fromARGB(255, 255, 221, 169);
      case 'purple':
        return const Color.fromARGB(162, 247, 206, 255);
      default:
        return Colors.grey[shade] ?? Colors.grey;
    }
  }
}
