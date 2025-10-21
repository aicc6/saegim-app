import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/core/theme/theme_extensions.dart';
import 'package:saegim/features/calendar/data/models/diary_image_model.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/features/calendar/data/services/diary_api_service.dart';
import 'package:saegim/features/home/data/models/diary_category_model.dart';
import 'package:saegim/features/home/data/services/diary_category_service.dart';
import 'package:saegim/features/home/presentation/riverpod/handwriting_diary_notifier.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:saegim/shared/widgets/emotion_emoji_widget.dart';

class DiaryDetailPage extends ConsumerStatefulWidget {
  final String diaryId;
  final DiaryEntry? tempEntry; // 새 다이어리용 임시 데이터
  final bool startInEditMode; // 편집 모드로 시작할지 여부
  final String? initialCategoryId;

  const DiaryDetailPage({
    super.key,
    required this.diaryId,
    this.tempEntry,
    this.startInEditMode = false,
    this.initialCategoryId,
  });

  @override
  ConsumerState<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends ConsumerState<DiaryDetailPage> {
  // 현재 보고 있는 일기
  DiaryEntry? diary;
  bool isLoading = true;
  String? errorMessage;

  // 같은 날짜의 모든 일기들
  List<DiaryEntry> dailyDiaries = [];
  int currentDiaryIndex = 0;
  PageController? _pageController;
  bool isLoadingDailyDiaries = false;

  // 인라인 편집 모드 관련 변수들
  bool isEditMode = false;
  bool isSaving = false;
  late TextEditingController _titleController;
  late TextEditingController _keywordsController;
  late TextEditingController _aiGeneratedTextController;
  String? _selectedEmotion;
  DateTime? _selectedDate;

  // 이미지 관련 변수들
  List<DiaryImage> diaryImages = [];
  bool isLoadingImages = false;

  // 새로 추가된 이미지들 (편집 모드에서만 사용)
  List<XFile> newImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  // 카테고리 관련 상태
  List<DiaryCategory> _categories = [];
  bool _isLoadingCategories = false;
  String? _selectedCategoryId;

  // AI 글 / 사용자 입력 글 토글 관련
  bool _showPromptContent = false; // false: AI 글, true: 사용자 입력 글
  String? _cachedPromptContent; // 캐시된 사용자 입력 글
  bool _isLoadingPromptContent = false; // 로딩 상태

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
    if (emotion == null || emotion.isEmpty) return '미선택';

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

  /// 감정을 한글->영문 코드로 변환
  String _toEnglishEmotion(String? emotion) {
    if (emotion == null) return '';
    switch (emotion.trim()) {
      case '행복':
        return 'happy';
      case '평온':
        return 'peaceful';
      case '불안':
        return 'unrest';
      case '분노':
        return 'angry';
      case '슬픔':
        return 'sad';
      default:
        return emotion.trim().toLowerCase();
    }
  }

  /// 감정 선택 드롭다운 위젯
  Widget _buildEmotionDropdown() {
    // 현재 선택된 값이 없으면 다이어리의 저장된 감정(한글일 수 있음)을 영문 코드로 변환해 사용
    final String resolvedSelected =
        _selectedEmotion ?? _toEnglishEmotion(diary?.emotion);

    String? normalizedSelected = resolvedSelected.toLowerCase().trim();

    // 선택된 감정이 유효한지 확인, 기본값 설정하지 않음
    final validEmotion =
        (_emotions.any(
          (emotion) =>
              (emotion['value'] ?? '').toLowerCase().trim() ==
              normalizedSelected,
        ))
        ? _emotions.firstWhere(
            (emotion) =>
                (emotion['value'] ?? '').toLowerCase().trim() ==
                normalizedSelected,
          )['value']
        : null;

    return DropdownButton<String>(
      value: validEmotion,
      isExpanded: true,
      underline: Container(),
      items: _emotions.map((emotion) {
        return DropdownMenuItem<String>(
          value: emotion['value'],
          child: Row(
            children: [
              EmotionEmojiWidget(
                emotion: emotion['value']!,
                size: 20,
                imageScale: 1.3,
              ),
              const SizedBox(width: 8),
              Text(
                emotion['label']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.primaryText,
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

  Future<void> _initializeCategoryState({
    DiaryEntry? entry,
    String? initialCategoryId,
    bool forceFetch = false,
  }) async {
    if (mounted) {
      setState(() {
        _isLoadingCategories = true;
      });
    }

    try {
      final categoryService = DiaryCategoryService.instance;
      final categories = await categoryService.getCategories();
      final diaryEntry = entry ?? diary;

      String? resolvedCategoryId = initialCategoryId;

      if ((forceFetch ||
              resolvedCategoryId == null ||
              resolvedCategoryId.isEmpty) &&
          diaryEntry != null &&
          diaryEntry.id.isNotEmpty &&
          !diaryEntry.id.startsWith('temp_')) {
        resolvedCategoryId = await categoryService.getCategoryIdForDiary(
          diaryEntry.id,
        );
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _selectedCategoryId =
              (resolvedCategoryId != null && resolvedCategoryId.isEmpty)
              ? null
              : resolvedCategoryId;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Failed to initialize diary categories',
        tag: 'DiaryDetailPage',
        error: e,
      );
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  String _resolveCategoryLabel() {
    if (_isLoadingCategories) {
      return '로딩 중...';
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      return '기본 다이어리';
    }

    for (final category in _categories) {
      if (category.id == _selectedCategoryId) {
        return category.name;
      }
    }

    return '삭제된 다이어리';
  }

  Future<void> _showCreateCategoryDialog() async {
    final controller = TextEditingController();
    String? errorText;
    bool isSaving = false;

    final createdCategory = await showDialog<DiaryCategory>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('새 다이어리 만들기'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '다이어리 이름',
                      errorText: errorText,
                    ),
                    enabled: !isSaving,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) {
                            setState(() {
                              errorText = '다이어리 이름을 입력해주세요.';
                            });
                            return;
                          }

                          setState(() {
                            isSaving = true;
                            errorText = null;
                          });

                          try {
                            final category = await DiaryCategoryService.instance
                                .createCategory(name);
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop(category);
                          } catch (_) {
                            setState(() {
                              isSaving = false;
                              errorText = '다이어리를 만들지 못했습니다. 다시 시도해주세요.';
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('생성'),
                ),
              ],
            );
          },
        );
      },
    );

    if (createdCategory != null && mounted) {
      setState(() {
        _categories.removeWhere(
          (category) => category.id == createdCategory.id,
        );
        _categories.insert(0, createdCategory);
        _selectedCategoryId = createdCategory.id;
      });
    }
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
                  _addKeyword(newKeyword);
                }
                Navigator.of(context).pop();
              },
              child: Text(
                '추가',
                style: TextStyle(color: context.colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 키워드 추가
  void _addKeyword(String keyword) {
    final currentKeywords = _keywordsController.text
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();

    if (!currentKeywords.contains(keyword)) {
      currentKeywords.add(keyword);
      _keywordsController.text = currentKeywords.join(', ');
      setState(() {});
    }
  }

  /// 키워드 삭제
  void _removeKeyword(String keyword) {
    final currentKeywords = _keywordsController.text
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();

    currentKeywords.remove(keyword);
    _keywordsController.text = currentKeywords.join(', ');
    setState(() {});
  }

  /// AI 글 / 사용자 입력 글 토글
  Future<void> _toggleContentType() async {
    if (diary == null) return;

    // 편집 모드에서는 토글 불가
    if (isEditMode) return;

    // 현재 상태가 AI 글이고, 사용자 입력 글로 전환하려는 경우
    if (!_showPromptContent) {
      // 캐시된 content가 없으면 API 호출
      if (_cachedPromptContent == null) {
        setState(() {
          _isLoadingPromptContent = true;
        });

        try {
          final content = await DiaryApiService.instance.getDiaryContent(
            diary!.id,
          );

          if (mounted) {
            setState(() {
              _cachedPromptContent = content ?? diary!.content;
              _showPromptContent = true;
              _isLoadingPromptContent = false;
            });
          }
        } catch (e) {
          AppLogger.error(
            'Failed to load prompt content',
            tag: 'DiaryDetailPage',
            error: e,
          );

          if (mounted) {
            setState(() {
              // 실패 시 기본 content 사용
              _cachedPromptContent = diary!.content;
              _showPromptContent = true;
              _isLoadingPromptContent = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('사용자 입력 글을 불러오는 중 오류가 발생했습니다.'),
                backgroundColor: context.colorScheme.error,
              ),
            );
          }
        }
      } else {
        // 이미 캐시된 content가 있으면 바로 전환
        setState(() {
          _showPromptContent = true;
        });
      }
    } else {
      // 사용자 입력 글에서 AI 글로 전환
      setState(() {
        _showPromptContent = false;
      });
    }
  }

  /// 이미지 선택 기능
  Future<void> _pickImages() async {
    // 이미지 선택 옵션 다이얼로그 표시
    _showImagePickerDialog();
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
          title: Text(
            '사진 추가',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '사진을 선택하는 방법을 선택해주세요.',
                style: TextStyle(fontSize: 14, color: context.secondaryText),
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
                    _pickImagesFromGallery();
                  },
                  style: ElevatedButton.styleFrom(
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
                    _pickImageFromCamera();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.secondaryText,
                    foregroundColor: context.colorScheme.onPrimary,
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
            // 취소 버튼
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                '취소',
                style: TextStyle(
                  color: context.secondaryText,
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

  /// 갤러리에서 이미지 선택
  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> selectedImages = await _imagePicker.pickMultipleMedia(
        imageQuality: 80,
      );

      if (selectedImages.isNotEmpty) {
        setState(() {
          newImages.addAll(selectedImages);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedImages.length}장의 사진이 추가되었습니다.\n저장 버튼을 눌러 업로드하세요.',
            ),
            backgroundColor: context.colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      AppLogger.error(
        'Failed to pick images from gallery',
        tag: 'DiaryDetailPage',
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('사진 선택 중 오류가 발생했습니다.'),
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }

  /// 카메라로 이미지 촬영
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? selectedImage = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (selectedImage != null) {
        setState(() {
          newImages.add(selectedImage);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('1장의 사진이 추가되었습니다.\n저장 버튼을 눌러 업로드하세요.'),
            backgroundColor: context.colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      AppLogger.error(
        'Failed to pick image from camera',
        tag: 'DiaryDetailPage',
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('카메라 사용 중 오류가 발생했습니다.'),
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }

  /// 새로 추가된 이미지 삭제
  void _removeNewImage(int index) {
    setState(() {
      newImages.removeAt(index);
    });
  }

  /// 기존 이미지 삭제
  Future<void> _removeExistingImage(int index) async {
    if (index >= diaryImages.length) return;

    final imageToDelete = diaryImages[index];
    final imageId = imageToDelete.id;

    if (imageId == null) {
      AppLogger.error('❌ Image ID is null', tag: 'DiaryDetailPage');
      return;
    }

    try {
      AppLogger.info(
        '🗑️ Attempting to delete image: $imageId',
        'DiaryDetailPage',
      );

      final success = await DiaryApiService.instance.deleteDiaryImage(
        widget.diaryId,
        imageId,
      );

      if (mounted) {
        if (success) {
          // 삭제 성공 - UI에서 제거
          setState(() {
            diaryImages.removeAt(index);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('이미지가 성공적으로 삭제되었습니다.'),
              backgroundColor: context.colorScheme.primary,
            ),
          );

          AppLogger.info(
            '✅ Successfully deleted image: $imageId',
            'DiaryDetailPage',
          );
        } else {
          // 삭제 실패
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('이미지 삭제에 실패했습니다.\n네트워크 상태를 확인해주세요.'),
              backgroundColor: context.colorScheme.error,
            ),
          );

          AppLogger.warning(
            '❌ Failed to delete image: $imageId',
            'DiaryDetailPage',
          );
        }
      }
    } catch (e) {
      AppLogger.error(
        '❌ Error deleting image: $imageId - $e',
        tag: 'DiaryDetailPage',
        error: e,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('이미지 삭제 중 오류가 발생했습니다.'),
            backgroundColor: context.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _keywordsController = TextEditingController();
    _aiGeneratedTextController = TextEditingController();

    // 편집 모드로 시작하는 경우 설정
    if (widget.startInEditMode) {
      isEditMode = true;
    }

    _loadDiary();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _keywordsController.dispose();
    _aiGeneratedTextController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  /// 다이어리 데이터 로드
  Future<void> _loadDiary() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // 새 다이어리 모드인 경우 (diaryId가 "new"이거나 tempEntry가 있는 경우)
      if (widget.diaryId == 'new' || widget.tempEntry != null) {
        setState(() {
          diary = widget.tempEntry;
          isLoading = false;
          // startInEditMode가 true인 경우에만 편집 모드로 시작
          isEditMode = widget.startInEditMode;
        });

        await _initializeCategoryState(
          entry: widget.tempEntry,
          initialCategoryId: widget.initialCategoryId,
        );

        // tempEntry 이미지 처리는 _loadDiaryImages에서 처리됨
        _loadDiaryImages();

        _initializeEditControllers();
        return;
      }

      // 기존 다이어리 조회
      final loadedDiary = await DiaryApiService.instance.getDiaryById(
        widget.diaryId,
      );

      if (!mounted) {
        return;
      }

      if (loadedDiary == null) {
        setState(() {
          diary = null;
          isLoading = false;
          errorMessage = '다이어리를 불러올 수 없습니다.';
        });
        return;
      }

      setState(() {
        diary = loadedDiary;
        isLoading = false;
        errorMessage = null;
      });

      _initializeEditControllers();
      _loadDiaryImages();
      _loadDailyDiaries();
      await _initializeCategoryState(entry: loadedDiary, forceFetch: true);
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

  /// 같은 날짜의 모든 일기들 로드
  Future<void> _loadDailyDiaries() async {
    if (diary == null) return;

    setState(() {
      isLoadingDailyDiaries = true;
    });

    try {
      final diaryDate = diary!.diaryDate;
      if (diaryDate == null) return;

      // 월간 다이어리 목록을 가져와서 같은 날짜로 필터링
      final monthlyDiaries = await DiaryApiService.instance.getMonthlyDiaries(
        year: diaryDate.year,
        month: diaryDate.month,
      );

      if (mounted && monthlyDiaries != null) {
        // 같은 날짜의 일기들만 필터링
        final sameDateDiaries = monthlyDiaries.where((d) {
          final entryDate = d.diaryDate;
          return entryDate != null &&
              entryDate.year == diaryDate.year &&
              entryDate.month == diaryDate.month &&
              entryDate.day == diaryDate.day;
        }).toList();

        setState(() {
          dailyDiaries = sameDateDiaries.isNotEmpty
              ? sameDateDiaries
              : [diary!];

          // 현재 일기의 인덱스 찾기
          currentDiaryIndex = dailyDiaries.indexWhere((d) => d.id == diary!.id);
          if (currentDiaryIndex == -1) {
            // 현재 일기가 목록에 없으면 첫 번째로 설정
            currentDiaryIndex = 0;
          }

          // PageController 초기화
          if (dailyDiaries.length > 1) {
            _pageController = PageController(initialPage: currentDiaryIndex);
          }

          isLoadingDailyDiaries = false;
        });

        AppLogger.info(
          'Found ${dailyDiaries.length} diaries for date: ${diaryDate.toString().substring(0, 10)}',
          'DiaryDetailPage',
        );
      } else {
        // 응답이 없으면 현재 일기만 목록에 추가
        setState(() {
          dailyDiaries = [diary!];
          currentDiaryIndex = 0;
          isLoadingDailyDiaries = false;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Failed to load daily diaries for date: ${diary!.diaryDate}',
        tag: 'DiaryDetailPage',
        error: e,
      );
      if (mounted) {
        setState(() {
          // 에러 시 현재 일기만 목록에 추가
          dailyDiaries = [diary!];
          currentDiaryIndex = 0;
          isLoadingDailyDiaries = false;
        });
      }
    }
  }

  /// 다이어리 이미지 로드
  Future<void> _loadDiaryImages() async {
    if (diary == null) {
      AppLogger.warning(
        'Cannot load images - diary is null',
        'DiaryDetailPage',
      );
      return;
    }

    AppLogger.info(
      'Loading images for diary: ${diary!.id} (tempEntry: ${widget.tempEntry != null})',
      'DiaryDetailPage',
    );

    setState(() {
      isLoadingImages = true;
    });

    try {
      // 임시 다이어리인 경우 (temp_로 시작하는 ID) tempEntry의 이미지 사용
      if (diary!.id.startsWith('temp_')) {
        AppLogger.info(
          'Loading images from tempEntry for temporary diary: ${diary!.id}',
          'DiaryDetailPage',
        );

        if (widget.tempEntry != null && widget.tempEntry!.images.isNotEmpty) {
          final convertedImages = widget.tempEntry!.images
              .map(
                (imageUrl) => DiaryImage(
                  filePath: imageUrl,
                  id: 'temp_${DateTime.now().millisecondsSinceEpoch}_${widget.tempEntry!.images.indexOf(imageUrl)}',
                ),
              )
              .toList();

          if (mounted) {
            setState(() {
              diaryImages = convertedImages;
              isLoadingImages = false;
            });
          }

          AppLogger.info(
            'Loaded ${convertedImages.length} images from tempEntry as DiaryImage objects',
            'DiaryDetailPage',
          );
        } else {
          if (mounted) {
            setState(() {
              diaryImages = [];
              isLoadingImages = false;
            });
          }
        }
      } else {
        // 일반 다이어리인 경우 서버에서 이미지 로드
        final images = await DiaryApiService.instance.getDiaryImages(diary!.id);

        if (mounted) {
          setState(() {
            diaryImages = images;
            isLoadingImages = false;
          });
        }
      }
    } catch (e) {
      AppLogger.error(
        'Failed to load diary images: ${diary!.id}',
        tag: 'DiaryDetailPage',
        error: e,
      );
      if (mounted) {
        setState(() {
          isLoadingImages = false;
        });
      }
    }
  }

  /// 페이지 변경 시 현재 일기 업데이트
  void _onPageChanged(int index) {
    if (index < 0 || index >= dailyDiaries.length) return;

    setState(() {
      currentDiaryIndex = index;
      diary = dailyDiaries[index];
      // 편집 모드가 켜져있다면 끄기
      if (isEditMode) {
        isEditMode = false;
      }
      // 토글 상태 초기화
      _showPromptContent = false;
      _cachedPromptContent = null;
      _isLoadingPromptContent = false;
    });

    // 새 일기의 컨트롤러 초기화
    _initializeEditControllers();
    // 새 일기의 이미지 로드
    _loadDiaryImages();
    _initializeCategoryState(forceFetch: true);
  }

  /// 편집 컨트롤러 초기화
  void _initializeEditControllers() {
    if (diary == null) return;

    // 새 다이어리인 경우 제목을 빈 문자열로 초기화 (사용자가 입력할 수 있도록)
    if (widget.diaryId == 'new' || diary!.id.startsWith('temp_')) {
      _titleController.text = ''; // 새 다이어리는 빈 제목으로 시작
    } else {
      _titleController.text = diary!.title ?? '';
    }

    _keywordsController.text = diary!.keywords.join(', ');
    _aiGeneratedTextController.text = diary!.aiGeneratedText ?? '';

    // 사용자 감정 초기화 - 한글일 수 있으므로 영문 코드로 치환 후 검증
    final diaryEmotionRaw = diary!.emotion ?? diary!.aiEmotion;
    final diaryEmotion = _toEnglishEmotion(diaryEmotionRaw);

    // 디버깅을 위한 로그 추가
    AppLogger.info(
      'Diary emotion initialization - raw: $diaryEmotionRaw, converted: $diaryEmotion',
      'DiaryDetailPage',
    );

    // 감정 초기화 로직 개선
    if (diaryEmotionRaw != null && diaryEmotionRaw.isNotEmpty) {
      if (diaryEmotion.isNotEmpty &&
          _emotions.any((e) => e['value'] == diaryEmotion)) {
        // 영문으로 변환된 감정이 유효한 경우
        _selectedEmotion = diaryEmotion;
        AppLogger.info(
          'Emotion set from converted value: $_selectedEmotion',
          'DiaryDetailPage',
        );
      } else {
        // 한글 감정명이 직접 매칭되는지 확인
        final directMatch = _emotions.firstWhere(
          (e) => e['label'] == diaryEmotionRaw,
          orElse: () => {'value': '', 'label': ''},
        );
        if (directMatch['value']?.isNotEmpty == true) {
          _selectedEmotion = directMatch['value'];
          AppLogger.info(
            'Emotion set from direct match: $_selectedEmotion',
            'DiaryDetailPage',
          );
        } else {
          _selectedEmotion = null;
          AppLogger.warning(
            'No emotion match found for: $diaryEmotionRaw',
            'DiaryDetailPage',
          );
        }
      }
    } else {
      _selectedEmotion = null;
      AppLogger.info('No emotion data found in diary', 'DiaryDetailPage');
    }

    _selectedDate = diary!.diaryDate; // 날짜 초기화
  }

  /// 날짜 선택 다이얼로그
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: context.colorScheme.copyWith(
              primary: context.colorScheme.primary,
              onPrimary: context.colorScheme.onPrimary,
              surface: context.colorScheme.surface,
              onSurface: context.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// 편집 모드 시작
  void _startEditMode() {
    setState(() {
      isEditMode = true;
      // 편집 모드로 전환 시 토글 상태 초기화
      _showPromptContent = false;
    });
  }

  /// 편집 모드 취소
  void _cancelEditMode() {
    // 진입 경로에 따라 다른 동작 수행
    final uri = GoRouter.of(context).routeInformationProvider.value.uri;
    final from = uri.queryParameters['from'];

    if (from == 'handwriting') {
      // 1. 손글씨 다이어리 페이지에서 온 경우 - 해당 페이지로 돌아가기
      context.go(RoutePaths.handwritingDiary);
    } else {
      // 2. 일반적인 경로에서 온 경우 - 보기 모드로 전환
      setState(() {
        isEditMode = false;
        // 새로 추가된 이미지들 초기화
        newImages.clear();
      });
      // 원래 값으로 되돌리기
      _initializeEditControllers();
    }
  }

  /// 변경사항 저장
  Future<void> _saveChanges() async {
    AppLogger.info(
      'Save button pressed - starting _saveChanges method',
      'DiaryDetailPage',
    );

    if (diary == null) {
      AppLogger.warning('Cannot save - diary is null', 'DiaryDetailPage');
      return;
    }

    AppLogger.info(
      'Diary ID: ${diary!.id}, isTemp: ${diary!.id.startsWith('temp_')}, tempEntry: ${widget.tempEntry != null}',
      'DiaryDetailPage',
    );

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

      bool success = false;

      final trimmedAiText = _aiGeneratedTextController.text.trim();
      final contentToSave = trimmedAiText.isNotEmpty
          ? trimmedAiText
          : ((diary!.aiGeneratedText?.trim().isNotEmpty ?? false)
                ? diary!.aiGeneratedText!.trim()
                : diary!.content);

      // 새 다이어리인 경우 (diaryId가 "new"로 시작)
      if (widget.diaryId == 'new' || diary!.id.startsWith('temp_')) {
        // 다이어리 생성
        final date = _selectedDate ?? diary!.diaryDate;
        if (date == null) {
          throw Exception('Diary date is required');
        }
        final dateString =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        final titleText = _titleController.text.trim();

        // 손글씨 이미지가 있다면 uploadedImages 형태로 변환
        List<Map<String, dynamic>>? uploadedImages;

        // tempEntry에서 이미지 가져오기 (손글씨 다이어리인 경우)
        List<String> imagesToUse = [];
        if (widget.tempEntry != null && widget.tempEntry!.images.isNotEmpty) {
          imagesToUse = widget.tempEntry!.images;
          AppLogger.info(
            'Using images from tempEntry for diary creation: ${imagesToUse.length} images',
            'DiaryDetailPage',
          );
        } else if (diary!.images.isNotEmpty) {
          imagesToUse = diary!.images;
          AppLogger.info(
            'Using images from diary object for diary creation: ${imagesToUse.length} images',
            'DiaryDetailPage',
          );
        }

        if (imagesToUse.isNotEmpty) {
          uploadedImages = imagesToUse
              .map(
                (imageUrl) => {
                  'original_url': imageUrl,
                  'thumbnail_url': null,
                  'mime_type': null,
                  'file_size': null,
                },
              )
              .toList();

          AppLogger.info(
            'Converted images to uploadedImages format: ${uploadedImages.length} images',
            'DiaryDetailPage',
          );
        } else {
          AppLogger.warning(
            'No images found for diary creation',
            'DiaryDetailPage',
          );
        }

        // 새 다이어리 생성 시 편집 모드에서 입력한 데이터 사용
        final createdDiary = await DiaryApiService.instance.createDiary(
          content: contentToSave,
          title: titleText.isNotEmpty ? titleText : null, // 편집 모드에서 입력한 제목 사용
          aiGeneratedText: contentToSave.isNotEmpty ? contentToSave : null,
          userEmotion: _selectedEmotion,
          aiEmotion: diary!.aiEmotion,
          aiEmotionConfidence: 0.8,
          keywords: keywordsList.isNotEmpty ? keywordsList : null,
          diaryDate: dateString,
          uploadedImages: uploadedImages,
        );

        success = createdDiary != null;

        if (success) {
          // 새 다이어리 생성 성공 - diary 객체 업데이트
          diary = createdDiary.copyWith(
            content: contentToSave,
            aiGeneratedText: contentToSave,
            title: titleText.isNotEmpty ? titleText : createdDiary.title,
          );
        }
      } else {
        // 기존 다이어리 업데이트
        final titleText = _titleController.text.trim();

        // 제목이 비어있지 않으면 항상 전달 (빈 문자열도 포함)
        success = await DiaryApiService.instance.updateDiary(
          diaryId: diary!.id,
          title: titleText, // null 대신 빈 문자열도 허용
          emotion: _selectedEmotion,
          keywords: keywordsList,
          aiGeneratedText: contentToSave,
          diaryDate: _selectedDate, // 선택된 날짜 전달
        );

        if (success) {
          diary = diary!.copyWith(
            title: titleText,
            content: contentToSave,
            aiGeneratedText: contentToSave,
            emotion: _selectedEmotion,
            keywords: keywordsList,
          );
        }
      }

      // 2. 새로 추가된 이미지들 업로드 (여러 엔드포인트 시도)
      bool imageUploadSuccess = true;
      if (newImages.isNotEmpty) {
        AppLogger.info(
          'Attempting to upload ${newImages.length} images with multiple endpoints',
          'DiaryDetailPage',
        );

        final imagePaths = newImages.map((image) => image.path).toList();
        final uploadedImages = await DiaryApiService.instance.uploadDiaryImages(
          diaryId: diary!.id,
          imagePaths: imagePaths,
        );

        if (uploadedImages != null && uploadedImages.isNotEmpty) {
          // 업로드 성공 - 서버에서 최신 이미지 목록 다시 가져오기
          AppLogger.info(
            'Image upload successful, refreshing image list from server',
            'DiaryDetailPage',
          );

          // 서버에서 최신 이미지 목록 가져오기
          final latestImages = await DiaryApiService.instance.getDiaryImages(
            diary!.id,
          );
          setState(() {
            diaryImages = latestImages;
            newImages.clear(); // 업로드 완료 후 새 이미지 목록 클리어
          });
          imageUploadSuccess = true;
        } else {
          // 업로드 실패 - 하지만 다이어리 저장은 성공으로 처리
          imageUploadSuccess = true;
          AppLogger.warning(
            'Image upload failed for all attempted endpoints - continuing with diary save',
            'DiaryDetailPage',
          );
        }
      }

      if (success) {
        await DiaryCategoryService.instance.assignDiaryToCategory(
          diary!.id,
          _selectedCategoryId,
        );

        if (imageUploadSuccess) {
          // 다이어리와 이미지 모두 성공
          if (mounted) {
            setState(() {
              isSaving = false;
              isEditMode = false; // 성공 시 즉시 편집 모드 종료
            });
          }

          // 새 다이어리 생성인 경우 페이지 이동
          AppLogger.info(
            'Checking new diary condition - widget.diaryId: ${widget.diaryId}, diary.id: ${diary?.id}',
            'DiaryDetailPage',
          );

          if (widget.diaryId == 'new' ||
              widget.diaryId.startsWith('temp_') ||
              (diary?.id.startsWith('temp_') ?? false)) {
            AppLogger.info(
              'New diary creation detected - preparing navigation',
              'DiaryDetailPage',
            );

            if (mounted && context.mounted) {
              final hadImages = newImages.isNotEmpty;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    hadImages
                        ? '새 다이어리와 이미지가 성공적으로 생성되었습니다.'
                        : '새 다이어리가 성공적으로 생성되었습니다.',
                  ),
                  backgroundColor: context.colorScheme.primary,
                  duration: const Duration(seconds: 3),
                ),
              );

              AppLogger.info(
                'Success message shown - waiting before navigation',
                'DiaryDetailPage',
              );

              // 약간의 지연 후 목록 페이지로 이동 (새 다이어리 생성 후)
              await Future.delayed(const Duration(milliseconds: 500));

              if (mounted && context.mounted) {
                // 손글씨 다이어리 페이지 초기화 (새 다이어리 저장 완료 후)
                try {
                  ref.read(handwritingDiaryProvider.notifier).reset();
                  AppLogger.info(
                    'Handwriting diary page reset after successful diary creation',
                    'DiaryDetailPage',
                  );
                } catch (e) {
                  AppLogger.warning(
                    'Failed to reset handwriting diary page: $e',
                    'DiaryDetailPage',
                  );
                }

                // 새 다이어리 생성 후 목록 페이지로 이동하여 새로고침 트리거
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                AppLogger.info(
                  'Navigating to diary list after creation with refresh parameter: $timestamp',
                  'DiaryDetailPage',
                );
                context.pushReplacement('/diary?refresh=$timestamp');
              } else {
                AppLogger.warning(
                  'Widget not mounted during creation navigation',
                  'DiaryDetailPage',
                );
              }
            } else {
              AppLogger.warning(
                'Widget not mounted during creation flow',
                'DiaryDetailPage',
              );
            }
          } else {
            // 기존 다이어리 수정인 경우
            // 현재 다이어리 상태를 업데이트하고 편집 모드 해제
            setState(() {
              // 편집된 내용으로 다이어리 객체 업데이트
              diary = diary!.copyWith(
                title: _titleController.text.trim(),
                emotion: _selectedEmotion,
                keywords: keywordsList,
                aiGeneratedText: _aiGeneratedTextController.text.trim().isEmpty
                    ? null
                    : _aiGeneratedTextController.text.trim(),
                diaryDate: _selectedDate,
              );
              isEditMode = false; // 편집 모드 해제
              newImages.clear(); // 새로 추가된 이미지 목록 클리어
            });

            // 같은 날짜의 다른 다이어리들도 업데이트 (현재 다이어리 정보 반영)
            if (dailyDiaries.isNotEmpty) {
              final currentIndex = dailyDiaries.indexWhere(
                (d) => d.id == diary!.id,
              );
              if (currentIndex != -1) {
                setState(() {
                  dailyDiaries[currentIndex] = diary!;
                });
              }
            }

            if (mounted && context.mounted) {
              final hadImages = newImages.isNotEmpty;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    hadImages
                        ? '다이어리와 이미지가 성공적으로 저장되었습니다.'
                        : '다이어리가 성공적으로 저장되었습니다.',
                  ),
                  backgroundColor: context.colorScheme.primary,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } else {
          // 다이어리는 성공했지만 이미지 업로드 실패
          if (mounted) {
            setState(() {
              isSaving = false;
              isEditMode = false; // 성공 시 즉시 편집 모드 종료
            });
          }

          // 새 다이어리 생성인 경우 페이지 이동
          AppLogger.info(
            'Checking new diary condition (image failure) - widget.diaryId: ${widget.diaryId}, diary.id: ${diary?.id}',
            'DiaryDetailPage',
          );

          if (widget.diaryId == 'new' ||
              widget.diaryId.startsWith('temp_') ||
              (diary?.id.startsWith('temp_') ?? false)) {
            AppLogger.info(
              'New diary creation detected (with image upload failure) - preparing navigation',
              'DiaryDetailPage',
            );

            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '새 다이어리는 생성되었지만 이미지 업로드에 실패했습니다.\n네트워크 상태를 확인해주세요.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );

              AppLogger.info(
                'Warning message shown - waiting before navigation',
                'DiaryDetailPage',
              );

              // 약간의 지연 후 목록 페이지로 이동 (이미지 업로드 실패 시에도)
              await Future.delayed(const Duration(milliseconds: 500));

              if (mounted && context.mounted) {
                // 새 다이어리 생성 후 목록 페이지로 이동하여 새로고침 트리거
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                AppLogger.info(
                  'Navigating to diary list after creation (with image upload failure) with refresh parameter: $timestamp',
                  'DiaryDetailPage',
                );
                context.pushReplacement('/diary?refresh=$timestamp');
              } else {
                AppLogger.warning(
                  'Widget not mounted during creation navigation (image failure)',
                  'DiaryDetailPage',
                );
              }
            } else {
              AppLogger.warning(
                'Widget not mounted during creation flow (image failure)',
                'DiaryDetailPage',
              );
            }
          } else {
            // 기존 다이어리 수정인 경우 (이미지 업로드 실패)
            // 현재 다이어리 상태를 업데이트하고 편집 모드 해제
            setState(() {
              // 편집된 내용으로 다이어리 객체 업데이트
              diary = diary!.copyWith(
                title: _titleController.text.trim(),
                emotion: _selectedEmotion,
                keywords: keywordsList,
                aiGeneratedText: _aiGeneratedTextController.text.trim().isEmpty
                    ? null
                    : _aiGeneratedTextController.text.trim(),
                diaryDate: _selectedDate,
              );
              isEditMode = false; // 편집 모드 해제
              newImages.clear(); // 새로 추가된 이미지 목록 클리어
            });

            // 같은 날짜의 다른 다이어리들도 업데이트 (현재 다이어리 정보 반영)
            if (dailyDiaries.isNotEmpty) {
              final currentIndex = dailyDiaries.indexWhere(
                (d) => d.id == diary!.id,
              );
              if (currentIndex != -1) {
                setState(() {
                  dailyDiaries[currentIndex] = diary!;
                });
              }
            }

            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '다이어리는 저장되었지만 이미지 업로드에 실패했습니다.\n네트워크 상태를 확인해주세요.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        }
      } else {
        // 저장 실패
        if (mounted) {
          setState(() {
            isSaving = false;
          });
        }

        if (mounted && context.mounted) {
          _showUpdateNotAvailableDialog();
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
      }

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('다이어리 수정 중 오류가 발생했습니다.'),
            backgroundColor: context.colorScheme.error,
          ),
        );
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
              child: Text(
                '확인',
                style: TextStyle(color: context.colorScheme.primary),
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
            SnackBar(
              content: const Text('다이어리가 성공적으로 삭제되었습니다.'),
              backgroundColor: context.colorScheme.primary,
            ),
          );

          AppLogger.info(
            'Diary deletion successful - preparing navigation',
            'DiaryDetailPage',
          );

          // 삭제 후 약간의 지연을 두고 네비게이션 (안전한 방식)
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              AppLogger.info(
                'About to call _handleBackNavigation',
                'DiaryDetailPage',
              );
              _handleBackNavigation(context);
            } else {
              AppLogger.warning(
                'Widget not mounted - skipping navigation',
                'DiaryDetailPage',
              );
            }
          });
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
          SnackBar(
            content: const Text('다이어리 삭제 중 오류가 발생했습니다.'),
            backgroundColor: context.colorScheme.error,
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
              child: Text(
                '확인',
                style: TextStyle(color: context.colorScheme.primary),
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
      backgroundColor: context.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 앱바
            _buildCustomAppBar(context),

            // 스크롤 가능한 콘텐츠
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.colorScheme.primary,
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
                            color: context.secondaryText.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            style: TextStyle(
                              fontSize: 16,
                              color: context.secondaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadDiary,
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
                  : Column(
                      children: [
                        // 페이지 인디케이터 (여러 일기가 있을 때만 표시)
                        if (dailyDiaries.length > 1) _buildPageIndicator(),

                        // 일기 내용 (PageView 또는 단일 뷰)
                        Expanded(
                          child: dailyDiaries.length > 1
                              ? PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: _onPageChanged,
                                  itemCount: dailyDiaries.length,
                                  itemBuilder: (context, index) {
                                    return _buildDiaryContent();
                                  },
                                )
                              : _buildDiaryContent(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 페이지 인디케이터
  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 이전 버튼
          IconButton(
            onPressed: currentDiaryIndex > 0
                ? () => _pageController?.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                : null,
            icon: Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: currentDiaryIndex > 0
                  ? context.colorScheme.primary
                  : context.secondaryText.withOpacity(0.4),
            ),
          ),

          // 페이지 인디케이터 점들
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                dailyDiaries.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == currentDiaryIndex
                        ? context.colorScheme.primary
                        : context.secondaryText.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // 다음 버튼
          IconButton(
            onPressed: currentDiaryIndex < dailyDiaries.length - 1
                ? () => _pageController?.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                : null,
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: currentDiaryIndex < dailyDiaries.length - 1
                  ? context.colorScheme.primary
                  : context.secondaryText.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  // 일기 콘텐츠 위젯
  Widget _buildDiaryContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 날짜
          _buildTitleSection(),

          const SizedBox(height: 24),

          // 감정 분석 섹션 (사용자 vs AI 감정 비교)
          _buildEmotionAnalysisSection(),

          const SizedBox(height: 24),

          // 키워드 섹션 (AI 추출 키워드 표시)
          _buildKeywordSection(),

          const SizedBox(height: 24),

          // AI 생성 글 섹션
          _buildAiContentSection(),

          const SizedBox(height: 24),

          // 이미지 섹션
          _buildImageSection(),

          const SizedBox(height: 32),

          // 수정/삭제 버튼
          _buildActionButtons(context),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 커스텀 앱바
  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: context.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _handleBackNavigation(context),
            child: Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: context.secondaryText,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '뒤로가기',
            style: TextStyle(
              fontSize: 16,
              color: context.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          // 같은 날짜 일기 개수 표시
          if (dailyDiaries.length > 1) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${currentDiaryIndex + 1}/${dailyDiaries.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
    } else if (from == 'handwriting') {
      // 손글씨 변환 페이지에서 왔다면 그 페이지로 돌아가기
      context.go(RoutePaths.handwritingDiary);
    } else {
      // 그 외의 경우는 목록 페이지로 강제 새로고침과 함께 이동
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      AppLogger.info(
        'Navigating to diary list with refresh parameter: $timestamp',
        'DiaryDetailPage',
      );
      // 페이지를 완전히 새로 생성하여 새로고침 보장
      context.pushReplacement('/diary?refresh=$timestamp');
    }
  }

  // 제목과 날짜 섹션
  Widget _buildTitleSection() {
    if (diary == null) return const SizedBox.shrink();

    final diaryDate = diary!.diaryDate;
    final formattedDate = diaryDate != null
        ? '${diaryDate.month}월 ${diaryDate.day}일'
        : '날짜 미정';

    return Container(
      padding: isEditMode ? const EdgeInsets.all(16) : EdgeInsets.zero,
      decoration: isEditMode
          ? BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colorScheme.primary, width: 2),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditMode) ...[
            // 편집 모드: 제목 입력 필드
            Text(
              '제목',
              style: TextStyle(
                fontSize: 15,
                color: context.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요 (예: 오늘의 일기)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            // 날짜 선택 필드
            Text(
              '날짜 선택',
              style: TextStyle(
                fontSize: 14,
                color: context.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: context.colorScheme.primary),
                  borderRadius: BorderRadius.circular(8),
                  color: context.inputBackground,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.month}월 ${_selectedDate!.day}일'
                          : '날짜를 선택하세요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _selectedDate != null
                            ? context.primaryText
                            : context.placeholderText,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: context.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '저장 위치',
              style: TextStyle(
                fontSize: 14,
                color: context.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoadingCategories)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategoryId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('기본 다이어리'),
                  ),
                  ..._categories.map(
                    (category) => DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isLoadingCategories
                    ? null
                    : _showCreateCategoryDialog,
                icon: const Icon(Icons.add),
                label: const Text('새 다이어리 만들기'),
              ),
            ),
          ] else ...[
            // 보기 모드: 제목 표시
            Text(
              _titleController.text.isNotEmpty
                  ? _titleController.text
                  : (diary!.title ?? '$formattedDate 일기'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.primaryText,
              ),
            ),
          ],
          // 편집 모드가 아닐 때만 날짜 표시
          if (!isEditMode) ...[
            const SizedBox(height: 8),
            Text(
              _selectedDate != null
                  ? '${_selectedDate!.month}월 ${_selectedDate!.day}일'
                  : formattedDate,
              style: TextStyle(fontSize: 16, color: context.secondaryText),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest.withOpacity(
                  0.3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 18,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _resolveCategoryLabel(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    return Column(
      children: [
        // 감정 비교 섹션
        Row(
          children: [
            // 사용자 감정
            Expanded(
              child: Container(
                height: 120, // 고정 높이 설정
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEditMode
                        ? context.colorScheme.primary
                        : context.borderSubtle,
                    width: isEditMode ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: context.colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '사용자 감정',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isEditMode) ...[
                      // 편집 모드: 감정 선택 드롭다운
                      Expanded(child: _buildEmotionDropdown()),
                    ] else ...[
                      // 보기 모드: 현재 감정 표시
                      Row(
                        children: [
                          EmotionEmojiWidget(
                            emotion:
                                _selectedEmotion ??
                                diary!.emotion ??
                                'peaceful',
                            size: 24,
                            imageScale: 1.4,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userEmotion,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // AI 분석 감정
            Expanded(
              child: Container(
                height: 120, // 고정 높이 설정
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEditMode
                        ? context.colorScheme.primary
                        : context.borderSubtle,
                    width: isEditMode ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 16,
                          color: context.colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI 분석 감정',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        EmotionEmojiWidget(
                          emotion: diary!.aiEmotion ?? 'peaceful',
                          size: 24,
                          imageScale: 1.4,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            aiEmotion.isNotEmpty ? aiEmotion : '분석 결과 없음',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: aiEmotion.isNotEmpty
                                  ? context.primaryText
                                  : context.secondaryText,
                              fontStyle: aiEmotion.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 키워드 섹션
  Widget _buildKeywordSection() {
    if (diary == null) return const SizedBox.shrink();

    // 편집 모드에서 현재 키워드 목록 가져오기
    final currentKeywords = isEditMode
        ? _keywordsController.text
              .split(',')
              .map((keyword) => keyword.trim())
              .where((keyword) => keyword.isNotEmpty)
              .toList()
        : diary!.keywords;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditMode
              ? context.colorScheme.primary
              : context.borderSubtle,
          width: isEditMode ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label, size: 16, color: context.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '키워드',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.secondary,
                ),
              ),
              if (isEditMode) ...[
                const Spacer(),
                SizedBox(
                  width: 80,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      // 새 키워드 입력 다이얼로그 표시
                      _showAddKeywordDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      foregroundColor: context.colorScheme.onPrimary,
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
          if (currentKeywords.isNotEmpty) ...[
            // 키워드 태그들 표시 (편집/보기 모드 공통)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: currentKeywords
                  .map(
                    (keyword) => _buildKeywordChip(
                      '#$keyword',
                      isEditMode: isEditMode,
                      onDelete: isEditMode
                          ? () => _removeKeyword(keyword)
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ] else ...[
            // 키워드가 없는 경우
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest.withOpacity(
                  0.3,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: context.secondaryText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '키워드가 추출되지 않았습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.secondaryText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 키워드 칩
  Widget _buildKeywordChip(
    String keyword, {
    bool isEditMode = false,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            keyword,
            style: TextStyle(
              fontSize: 12,
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isEditMode && onDelete != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: context.colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: context.colorScheme.onError,
                  size: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // AI 생성 글 섹션
  Widget _buildAiContentSection() {
    if (diary == null) return const SizedBox.shrink();

    final aiContent = diary!.aiGeneratedText;
    final originalContent = diary!.content;

    // 편집 모드일 때
    if (isEditMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colorScheme.primary, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'AI 생성 글',
                  style: TextStyle(
                    fontSize: 15,
                    color: context.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 편집 모드: 텍스트 필드
            TextField(
              controller: _aiGeneratedTextController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'AI 생성 글을 수정하세요...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: context.primaryText,
              ),
            ),
          ],
        ),
      );
    }

    // 보기 모드일 때
    final displayContent = _showPromptContent
        ? (_cachedPromptContent ?? originalContent)
        : (aiContent ?? originalContent);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _showPromptContent ? '사용자 입력 글' : 'AI 생성 글',
                style: TextStyle(
                  fontSize: 15,
                  color: context.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // 토글 버튼
              if (_isLoadingPromptContent)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.colorScheme.primary,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: _toggleContentType,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showPromptContent
                              ? Icons.smart_toy
                              : Icons.edit_note,
                          size: 16,
                          color: context.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showPromptContent ? 'AI 글' : '입력 글',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 보기 모드: 텍스트 표시
          Text(
            displayContent,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: context.primaryText,
            ),
          ),
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
              color: context.colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextButton(
              onPressed: isSaving ? null : _saveChanges,
              style: TextButton.styleFrom(
                foregroundColor: context.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.colorScheme.onPrimary,
                        ),
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

          // 취소 버튼 → 상단 뒤로가기와 동일 동작
          Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextButton(
              onPressed: isSaving ? null : _cancelEditMode,
              style: TextButton.styleFrom(
                foregroundColor: context.colorScheme.onSurface,
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
              color: context.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextButton(
              onPressed: _startEditMode,
              style: TextButton.styleFrom(
                foregroundColor: context.colorScheme.onPrimaryContainer,
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
              color: context.colorScheme.error,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextButton(
              onPressed: () {
                _showDeleteConfirmDialog(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: context.colorScheme.onError,
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
              child: Text('취소', style: TextStyle(color: context.secondaryText)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDiary();
              },
              child: Text(
                '삭제',
                style: TextStyle(color: context.colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  // 이미지 섹션
  Widget _buildImageSection() {
    if (diary == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditMode
              ? context.colorScheme.primary
              : context.borderSubtle,
          width: isEditMode ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 20,
                color: context.secondaryText,
              ),
              const SizedBox(width: 8),
              Text(
                '이미지',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.secondary,
                ),
              ),
              const Spacer(),
              if (isEditMode) ...[
                // 편집 모드에서 사진 추가 버튼
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: _pickImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      foregroundColor: context.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    icon: const Icon(Icons.add_photo_alternate, size: 16),
                    label: const Text('사진 추가'),
                  ),
                ),
              ] else if (isLoadingImages) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (isLoadingImages)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.colorScheme.primary,
                  ),
                ),
              ),
            )
          else if (diaryImages.isEmpty && newImages.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_outlined,
                      size: 48,
                      color: context.placeholderText,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '등록된 이미지가 없습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.placeholderText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildImageGrid(),
        ],
      ),
    );
  }

  // 이미지 그리드
  Widget _buildImageGrid() {
    final totalImages = diaryImages.length + newImages.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: totalImages,
      itemBuilder: (context, index) {
        if (index < diaryImages.length) {
          // 기존 이미지
          final image = diaryImages[index];
          return _buildExistingImageCard(image, index);
        } else {
          // 새로 추가된 이미지
          final newImageIndex = index - diaryImages.length;
          final newImage = newImages[newImageIndex];
          return _buildNewImageCard(newImage, newImageIndex);
        }
      },
    );
  }

  // 기존 이미지 카드 (서버에서 가져온 이미지)
  Widget _buildExistingImageCard(DiaryImage image, int index) {
    final imageUrl = image.fullImageUrl;

    // 유효하지 않은 이미지 URL인 경우 에러 위젯 표시
    if (imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.borderSubtle),
          color: context.colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 32,
                color: context.placeholderText,
              ),
              const SizedBox(height: 8),
              Text(
                '이미지 경로 없음',
                style: TextStyle(fontSize: 12, color: context.placeholderText),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showImageFullScreen(image, index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.borderSubtle, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;

                  return Container(
                    color: context.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  AppLogger.error(
                    'Failed to load image: ${image.fullImageUrl}',
                    tag: 'DiaryDetailPage',
                    error: error,
                  );

                  return Container(
                    color: context.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 32,
                            color: context.placeholderText,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '이미지 로드 실패',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.placeholderText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // 편집 모드에서 삭제 버튼 표시
        if (isEditMode)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeExistingImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: context.colorScheme.onError,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 새로 추가된 이미지 카드 (로컬 파일)
  Widget _buildNewImageCard(XFile image, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colorScheme.primary, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(image.path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: context.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 32,
                          color: context.placeholderText,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '이미지 로드 실패',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.placeholderText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // 새 이미지 표시 배지
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: context.colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'NEW',
              style: TextStyle(
                color: context.colorScheme.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // 삭제 버튼
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeNewImage(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: context.colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: context.colorScheme.onError,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 이미지 풀스크린 표시
  void _showImageFullScreen(DiaryImage image, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: context.isDarkMode
            ? context.colorScheme.surface
            : Colors.black,
        child: Stack(
          children: [
            // 이미지 페이지뷰
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: diaryImages.length,
              itemBuilder: (context, index) {
                final currentImage = diaryImages[index];
                final imageUrl = currentImage.fullImageUrl;

                if (imageUrl.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: context.placeholderText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '이미지 경로가 없습니다',
                          style: TextStyle(
                            color: context.placeholderText,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;

                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.colorScheme.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 64,
                                color: context.placeholderText,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '이미지를 불러올 수 없습니다',
                                style: TextStyle(
                                  color: context.placeholderText,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            // 닫기 버튼
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: context.colorScheme.onSurface,
                  size: 32,
                ),
              ),
            ),
            // 이미지 정보
            if (diaryImages.length > 1)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainerHighest
                          .withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${initialIndex + 1} / ${diaryImages.length}',
                      style: TextStyle(
                        color: context.primaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
