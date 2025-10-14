import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saegim/features/calendar/data/models/diary_image_model.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/features/calendar/data/services/diary_api_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

class DiaryDetailPage extends StatefulWidget {
  final String diaryId;
  final DiaryEntry? tempEntry; // 새 다이어리용 임시 데이터

  const DiaryDetailPage({super.key, required this.diaryId, this.tempEntry});

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
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
              const Text(
                '사진을 선택하는 방법을 선택해주세요.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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
                    backgroundColor: const Color(0xFF4A7C59),
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
                    _pickImageFromCamera();
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
              child: const Text(
                '취소',
                style: TextStyle(
                  color: Color(0xFF6B7280),
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
            backgroundColor: const Color(0xFF4A7C59),
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
        const SnackBar(
          content: Text('사진 선택 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
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
          const SnackBar(
            content: Text('1장의 사진이 추가되었습니다.\n저장 버튼을 눌러 업로드하세요.'),
            backgroundColor: Color(0xFF4A7C59),
            duration: Duration(seconds: 3),
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
        const SnackBar(
          content: Text('카메라 사용 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
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
            const SnackBar(
              content: Text('이미지가 성공적으로 삭제되었습니다.'),
              backgroundColor: Color(0xFF4A7C59),
            ),
          );

          AppLogger.info(
            '✅ Successfully deleted image: $imageId',
            'DiaryDetailPage',
          );
        } else {
          // 삭제 실패
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미지 삭제에 실패했습니다.\n네트워크 상태를 확인해주세요.'),
              backgroundColor: Colors.red,
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
          const SnackBar(
            content: Text('이미지 삭제 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
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
          isEditMode = true; // 새 다이어리는 편집 모드로 시작
        });

        // tempEntry에서 이미지 경로가 있으면 newImages에 추가
        if (widget.tempEntry != null && widget.tempEntry!.images.isNotEmpty) {
          final imageFiles = widget.tempEntry!.images
              .map((path) => XFile(path))
              .toList();
          setState(() {
            newImages = imageFiles;
          });

          AppLogger.info(
            'Loaded ${imageFiles.length} images from tempEntry',
            'DiaryDetailPage',
          );
        }

        _initializeEditControllers();
        return;
      }

      // 기존 다이어리 조회
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
            // 이미지 로드
            _loadDiaryImages();
            // 같은 날짜의 다른 일기들 로드
            _loadDailyDiaries();
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
    if (diary == null) return;

    setState(() {
      isLoadingImages = true;
    });

    try {
      final images = await DiaryApiService.instance.getDiaryImages(diary!.id);

      if (mounted) {
        setState(() {
          diaryImages = images;
          isLoadingImages = false;
        });
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
    });

    // 새 일기의 컨트롤러 초기화
    _initializeEditControllers();
    // 새 일기의 이미지 로드
    _loadDiaryImages();
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
    _selectedEmotion = diary!.emotion ?? _emotions.first['value'] as String;
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
    });
  }

  /// 편집 모드 취소
  void _cancelEditMode() {
    setState(() {
      isEditMode = false;
      // 새로 추가된 이미지들 초기화
      newImages.clear();
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

      bool success = false;

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

        // 새 다이어리 생성 시 편집 모드에서 입력한 데이터 사용
        final createdDiary = await DiaryApiService.instance.createDiary(
          content: diary!.content, // 필수 - 원본 콘텐츠 사용
          title: titleText.isNotEmpty ? titleText : null, // 편집 모드에서 입력한 제목 사용
          aiGeneratedText: _aiGeneratedTextController.text.trim().isEmpty
              ? null
              : _aiGeneratedTextController.text.trim(),
          userEmotion: _selectedEmotion,
          aiEmotion: diary!.aiEmotion,
          aiEmotionConfidence: 0.8,
          keywords: keywordsList.isNotEmpty ? keywordsList : null,
          diaryDate: dateString,
        );

        success = createdDiary != null;

        if (success) {
          // 새 다이어리 생성 성공 - diary 객체 업데이트
          diary = createdDiary;
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
          aiGeneratedText: _aiGeneratedTextController.text.trim().isEmpty
              ? null
              : _aiGeneratedTextController.text.trim(),
          diaryDate: _selectedDate, // 선택된 날짜 전달
        );
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
          // 업로드 실패
          imageUploadSuccess = false;
          AppLogger.warning(
            'Image upload failed for all attempted endpoints',
            'DiaryDetailPage',
          );
        }
      }

      if (success) {
        if (imageUploadSuccess) {
          // 다이어리와 이미지 모두 성공
          if (mounted) {
            setState(() {
              isSaving = false;
              isEditMode = false; // 성공 시 즉시 편집 모드 종료
            });
          }

          // 새 다이어리 생성인 경우 페이지 이동
          if (widget.diaryId == 'new' ||
              (diary?.id.startsWith('temp_') ?? false)) {
            if (mounted && context.mounted) {
              final hadImages = newImages.isNotEmpty;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    hadImages
                        ? '새 다이어리와 이미지가 성공적으로 생성되었습니다.'
                        : '새 다이어리가 성공적으로 생성되었습니다.',
                  ),
                  backgroundColor: const Color(0xFF4A7C59),
                  duration: const Duration(seconds: 3),
                ),
              );

              // 약간의 지연 후 페이지 이동
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted && context.mounted) {
                context.go('/diary/${diary!.id}');
              }
            }
          } else {
            // 기존 다이어리 수정인 경우
            // 선택된 날짜를 임시로 저장
            final savedSelectedDate = _selectedDate;

            await _loadDiary();

            // 로드 후 선택된 날짜를 다시 설정
            if (savedSelectedDate != null && diary != null) {
              setState(() {
                diary = diary!.copyWith(diaryDate: savedSelectedDate);
              });
            }

            if (mounted && context.mounted) {
              final hadImages = newImages.isNotEmpty;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    hadImages
                        ? '다이어리와 이미지가 성공적으로 수정되었습니다.'
                        : '다이어리가 성공적으로 수정되었습니다.',
                  ),
                  backgroundColor: const Color(0xFF4A7C59),
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
          if (widget.diaryId == 'new' ||
              (diary?.id.startsWith('temp_') ?? false)) {
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

              // 약간의 지연 후 페이지 이동
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted && context.mounted) {
                context.go('/diary/${diary!.id}');
              }
            }
          } else {
            // 기존 다이어리 수정인 경우
            // 선택된 날짜를 임시로 저장
            final savedSelectedDate = _selectedDate;

            await _loadDiary();

            // 로드 후 선택된 날짜를 다시 설정
            if (savedSelectedDate != null && diary != null) {
              setState(() {
                diary = diary!.copyWith(diaryDate: savedSelectedDate);
              });
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
          const SnackBar(
            content: Text('다이어리 수정 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
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
                  ? const Color(0xFF4A7C59)
                  : Colors.grey[400],
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
                        ? const Color(0xFF4A7C59)
                        : Colors.grey[300],
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
                  ? const Color(0xFF4A7C59)
                  : Colors.grey[400],
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

          // 감정 분석 섹션
          _buildEmotionAnalysisSection(),

          const SizedBox(height: 20),

          // 키워드 섹션
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
          // 같은 날짜 일기 개수 표시
          if (dailyDiaries.length > 1) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${currentDiaryIndex + 1}/${dailyDiaries.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A7C59),
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
    } else {
      // 그 외의 경우는 기본 pop 동작 (다이어리 목록으로)
      context.pop();
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
                hintText: '제목을 입력하세요 (예: 오늘의 일기)',
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
            const SizedBox(height: 16),

            // 날짜 선택 필드
            const Text(
              '📅 날짜 선택',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
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
                  border: Border.all(color: const Color(0xFF4A7C59)),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF8FFFE),
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
                            ? const Color(0xFF1F2937)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Color(0xFF4A7C59),
                    ),
                  ],
                ),
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
            _selectedDate != null
                ? '${_selectedDate!.month}월 ${_selectedDate!.day}일'
                : formattedDate,
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
                if (diary!.aiEmotion != null &&
                    diary!.aiEmotion!.isNotEmpty) ...[
                  // AI 분석 감정이 있는 경우에만 표시
                  Row(
                    children: [
                      const Text(
                        'AI 분석 감정 : ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
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
                SizedBox(
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

  // 이미지 섹션
  Widget _buildImageSection() {
    if (diary == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: 20,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              const Text(
                '이미지',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
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
                      backgroundColor: const Color(0xFF4A7C59),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    icon: const Icon(Icons.add_photo_alternate, size: 16),
                    label: const Text('사진 추가'),
                  ),
                ),
              ] else if (isLoadingImages) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4A7C59),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (isLoadingImages)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A7C59)),
                ),
              ),
            )
          else if (diaryImages.isEmpty && newImages.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_outlined,
                      size: 48,
                      color: Color(0xFF9CA3AF),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '등록된 이미지가 없습니다.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
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
          border: Border.all(color: const Color(0xFFE9ECEF)),
          color: Colors.grey[100],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 32,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(height: 8),
              Text(
                '이미지 경로 없음',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
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
              border: Border.all(color: const Color(0xFFE9ECEF)),
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
                    color: Colors.grey[100],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4A7C59),
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
                    color: Colors.grey[100],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 32,
                            color: Color(0xFF9CA3AF),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '이미지 로드 실패',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
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
  }

  // 새로 추가된 이미지 카드 (로컬 파일)
  Widget _buildNewImageCard(XFile image, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF4A7C59), width: 2),
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
                  color: Colors.grey[100],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 32,
                          color: Color(0xFF9CA3AF),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '이미지 로드 실패',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
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
              color: const Color(0xFF4A7C59),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
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
  }

  // 이미지 풀스크린 표시
  void _showImageFullScreen(DiaryImage image, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
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
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '이미지 경로가 없습니다',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
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

                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 64,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '이미지를 불러올 수 없습니다',
                                style: TextStyle(
                                  color: Colors.white54,
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
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
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
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${initialIndex + 1} / ${diaryImages.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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
