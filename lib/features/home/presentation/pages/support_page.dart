import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saegim/features/home/data/models/support_inquiry_model.dart';
import 'package:saegim/features/home/presentation/riverpod/support_inquiry_notifier.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key});

  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends ConsumerState<SupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    try {
      AppLogger.debug('이미지 선택 시작');

      // 사용자에게 갤러리 또는 카메라 선택하도록 함
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '이미지 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  Navigator.pop(context, ImageSource.gallery),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.photo_library,
                                      size: 40,
                                      color: Color(0xFFB2C5B8),
                                    ),
                                    SizedBox(height: 8),
                                    Text('갤러리'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  Navigator.pop(context, ImageSource.camera),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                      color: Color(0xFFB2C5B8),
                                    ),
                                    SizedBox(height: 8),
                                    Text('카메라'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) {
        AppLogger.debug('이미지 소스 선택 취소됨');
        return;
      }

      AppLogger.debug('선택된 소스: $source');

      // image_picker가 내장된 권한 처리를 사용
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      AppLogger.debug('이미지 선택 결과: ${image?.path}');

      if (image != null) {
        // 파일 크기 확인 (10MB 제한)
        final File file = File(image.path);
        final int fileSizeInBytes = await file.length();
        const int maxSizeInBytes = 10 * 1024 * 1024; // 10MB

        AppLogger.debug('파일 크기: ${fileSizeInBytes / 1024 / 1024}MB');

        if (fileSizeInBytes > maxSizeInBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('파일 크기는 10MB를 초과할 수 없습니다.'),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = image;
        });
        AppLogger.debug('이미지 설정 완료');

        // 성공 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('이미지가 성공적으로 선택되었습니다.'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        AppLogger.debug('이미지 선택 취소됨');
      }
    } catch (e, stackTrace) {
      AppLogger.debug('이미지 선택 에러: $e');
      AppLogger.debug('스택 트레이스: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('이미지 선택 중 오류가 발생했습니다: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportState = ref.watch(supportInquiryNotifierProvider);

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            const Center(
              child: Column(
                children: [
                  Icon(Icons.support, size: 60, color: Color(0xFFB2C5B8)),
                  SizedBox(height: 16),
                  Text(
                    '고객지원',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3A59),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '문제나 건의사항을 알려주세요.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 문의 폼
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 입력
                      const Text(
                        '문의 제목',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E3A59),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: '문의 제목을 입력해주세요',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E5E5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E5E5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFB2C5B8),
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '제목을 입력해주세요.';
                          }
                          if (value.trim().length < 5) {
                            return '제목은 5자 이상 입력해주세요.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // 내용 입력
                      const Text(
                        '문의 내용',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E3A59),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contentController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: '문의하실 내용을 상세히 입력해주세요',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E5E5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E5E5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFB2C5B8),
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '문의 내용을 입력해주세요.';
                          }
                          if (value.trim().length < 10) {
                            return '문의 내용은 10자 이상 입력해주세요.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // 이미지 첨부
                      const Text(
                        '이미지 첨부 (선택사항)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E3A59),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 이미지 선택 버튼
                      GestureDetector(
                        onTap: _selectImage,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE5E5E5),
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _selectedImage == null
                              ? const Column(
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: Color(0xFFB2C5B8),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '이미지를 선택해주세요',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'JPG, PNG 파일만 업로드 가능 (최대 10MB)',
                                      style: TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_selectedImage!.path),
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedImage!.name,
                                            style: const TextStyle(
                                              color: Color(0xFF2E3A59),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedImage = null;
                                            });
                                          },
                                          child: const Text(
                                            '삭제',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 에러 메시지 표시
                      if (supportState.error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  supportState.error!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  ref
                                      .read(
                                        supportInquiryNotifierProvider.notifier,
                                      )
                                      .clearError();
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.red[700],
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),

                      // 제출 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: supportState.isSubmitting
                              ? null
                              : _submitInquiry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB2C5B8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: supportState.isSubmitting
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('문의 등록 중...'),
                                  ],
                                )
                              : const Text(
                                  '문의 등록하기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 참고 안내
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFB2C5B8),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '문의 안내',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E3A59),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• 문의 답변은 영업일 기준 1-2일 내에 처리됩니다.\n'
                              '• 긴급한 문의는 앱 내 채팅 기능을 이용해주세요.\n'
                              '• 버그 신고 시 기기 정보와 증상을 상세히 기록해주세요.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String? imageData;
    String? imageFilename;
    String? imageType;

    // 이미지가 선택된 경우 base64로 인코딩
    if (_selectedImage != null) {
      try {
        final File file = File(_selectedImage!.path);
        final List<int> imageBytes = await file.readAsBytes();
        imageData = base64Encode(imageBytes);
        imageFilename = _selectedImage!.name;

        // MIME 타입 결정
        final String extension = _selectedImage!.name
            .toLowerCase()
            .split('.')
            .last;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            imageType = 'image/jpeg';
            break;
          case 'png':
            imageType = 'image/png';
            break;
          default:
            imageType = 'image/jpeg';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('이미지 처리 중 오류가 발생했습니다.'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }
    }

    final request = SupportInquiryRequest(
      title: _subjectController.text.trim(),
      content: _contentController.text.trim(),
      imageAttached: _selectedImage != null,
      imageData: imageData,
      imageFilename: imageFilename,
      imageType: imageType,
    );

    final success = await ref
        .read(supportInquiryNotifierProvider.notifier)
        .submitInquiry(request);

    if (success && mounted) {
      // 성공시 폼 초기화 및 성공 메시지
      _subjectController.clear();
      _contentController.clear();
      setState(() {
        _selectedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('문의가 성공적으로 등록되었습니다.'),
            ],
          ),
          backgroundColor: const Color(0xFFB2C5B8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
