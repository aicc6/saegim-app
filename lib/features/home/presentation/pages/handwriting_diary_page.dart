import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/core/theme/theme_extensions.dart';
import 'package:saegim/features/home/data/services/handwriting_diary_service.dart';
import 'package:saegim/features/home/presentation/riverpod/create_notifier.dart';
import 'package:saegim/features/home/presentation/riverpod/handwriting_diary_notifier.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

/// 손글씨 이미지를 AI 다이어리로 변환하는 페이지
class HandwritingDiaryPage extends ConsumerStatefulWidget {
  const HandwritingDiaryPage({super.key});

  @override
  ConsumerState<HandwritingDiaryPage> createState() =>
      _HandwritingDiaryPageState();
}

class _HandwritingDiaryPageState extends ConsumerState<HandwritingDiaryPage> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final handwritingState = ref.watch(handwritingDiaryProvider);
    final handwritingNotifier = ref.read(handwritingDiaryProvider.notifier);

    return Scaffold(
      appBar: const CommonAppBar(title: '손글씨 다이어리', showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 설명
              _buildHeader(),
              const SizedBox(height: 24),

              // 이미지 선택 섹션
              _buildImageSelectionSection(
                handwritingState,
                handwritingNotifier,
              ),
              const SizedBox(height: 24),

              // 스타일 및 길이 선택 섹션
              _buildStyleSelectionSection(
                handwritingState,
                handwritingNotifier,
              ),
              const SizedBox(height: 24),

              // 길이 선택 섹션 (먼저 표시)
              _buildLengthSelectionSection(
                handwritingState,
                handwritingNotifier,
              ),
              const SizedBox(height: 24),

              // 감정 선택 섹션 (선택사항)
              _buildEmotionSelectionSection(
                handwritingState,
                handwritingNotifier,
              ),
              const SizedBox(height: 32),

              // 변환 버튼
              _buildConvertButton(handwritingState, handwritingNotifier),
              const SizedBox(height: 24),

              // 에러 메시지
              if (handwritingState.hasError)
                _buildErrorMessage(handwritingState),

              // 결과 섹션 (OCR 텍스트와 AI 생성 다이어리 모두 표시)
              if (handwritingState.hasResult)
                _buildResultSection(handwritingState, handwritingNotifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.isDarkMode
              ? const Color(0xFF404040)
              : const Color(0xFFE9ECEF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, color: context.colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                '손글씨 다이어리 변환',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '손글씨 이미지를 업로드하면 AI가 텍스트를 추출하고 다이어리로 변환해드립니다.',
            style: TextStyle(
              fontSize: 14,
              color: context.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelectionSection(
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '손글씨 이미지',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (state.selectedImage == null)
          _buildImagePickerButton(notifier)
        else
          _buildSelectedImagePreview(state.selectedImage!, notifier),
      ],
    );
  }

  Widget _buildImagePickerButton(HandwritingDiaryNotifier notifier) {
    return InkWell(
      onTap: () => _showImageSourceDialog(notifier),
      child: AspectRatio(
        aspectRatio: 16 / 9, // 가로세로 비율을 16:9로 설정
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: context.colorScheme.primary.withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
            color: context.colorScheme.primary.withOpacity(0.05),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: context.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                '손글씨 이미지 선택',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '카메라로 촬영하거나 갤러리에서 선택',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImagePreview(
    File image,
    HandwritingDiaryNotifier notifier,
  ) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9, // 가로세로 비율을 16:9로 설정
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showImageSourceDialog(notifier),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('다시 선택'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colorScheme.primary.withOpacity(0.1),
                  foregroundColor: context.colorScheme.primary,
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => notifier.clearSelectedImage(),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('제거'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStyleSelectionSection(
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '작성 스타일',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: WritingStyle.values.map((style) {
            final isSelected = state.style == style;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => notifier.setStyle(style),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colorScheme.primary
                          : (context.isDarkMode
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? context.colorScheme.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      style.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmotionSelectionSection(
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    // '자동 분석' 제거
    final emotions = ['행복', '평온', '불안', '분노', '슬픔'];
    final emotionLabels = ['행복', '평온', '불안', '분노', '슬픔'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '감정 (선택사항)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '선택하지 않으면 AI가 자동으로 감정을 분석합니다.',
          style: TextStyle(
            fontSize: 12,
            color: context.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: emotions.asMap().entries.map((entry) {
            final emotion = entry.value;
            final label = emotionLabels[entry.key];
            final isSelected = state.emotion == emotion;

            return InkWell(
              onTap: () {
                // 이미 선택된 감정을 다시 클릭하면 선택 취소
                if (isSelected) {
                  notifier.setEmotion(null);
                } else {
                  notifier.setEmotion(emotion);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colorScheme.primary
                      : (context.isDarkMode
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? context.colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : context.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLengthSelectionSection(
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '글의 길이',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xFF2A2A2A)
                : Colors.grey.shade100,
            border: Border.all(color: context.borderSubtle),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: LengthOption.values.map((length) {
              final isSelected = state.length == length;
              return Expanded(
                child: InkWell(
                  onTap: () => notifier.setLength(length),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getLoadingMessage(HandwritingDiaryState state) {
    final baseMessage = '손글씨 인식 및 AI 다이어리 생성 중입니다.\n잠시만 기다려주세요.';

    if (state.length == LengthOption.long) {
      return '$baseMessage\n\n📝 장문 생성으로 인해 시간이 더 오래 걸릴 수 있습니다.';
    } else if (state.length == LengthOption.medium) {
      return '$baseMessage\n\n📝 중문 생성으로 인해 시간이 조금 걸릴 수 있습니다.';
    }

    return baseMessage;
  }

  Widget _buildConvertButton(
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    final canConvert = state.canConvert;
    final isConverting = state.isConverting;

    return Column(
      children: [
        // 직접 변환 버튼 (새로운 API)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canConvert && !isConverting
                ? () => notifier.convertHandwritingToDiaryDirect()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isConverting
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
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
                          const SizedBox(width: 12),
                          Text(
                            state.conversionStep ?? '변환 중...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getLoadingMessage(state),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  )
                : const Text(
                    '손글씨를 다이어리로 변환',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOcrTextSection(
    String ocrText,
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    final displayText = state.isEditMode
        ? (state.editedOcrText ?? ocrText)
        : ocrText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.text_fields,
              size: 16,
              color: context.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'OCR로 추출된 텍스트',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: state.isEditMode
              ? TextField(
                  controller: notifier.ocrTextController,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colorScheme.onSurface,
                    height: 1.4,
                  ),
                  onChanged: (value) => notifier.updateOcrText(value),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colorScheme.onSurface,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.arrow_downward,
              size: 14,
              color: context.colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              'AI가 위 텍스트를 바탕으로 다이어리를 생성했습니다',
              style: TextStyle(
                fontSize: 12,
                color: context.colorScheme.primary.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAiTextSection(
    HandwritingDiaryResult result,
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    final displayText = state.isEditMode
        ? (state.editedAiText ?? result.aiGeneratedText)
        : result.aiGeneratedText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 16,
              color: context.colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              result.extractedText == result.aiGeneratedText
                  ? '손글씨 다이어리 (AI 변환 없음)'
                  : 'AI 생성 다이어리',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: result.extractedText == result.aiGeneratedText
                    ? Colors.orange
                    : context.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // AI 변환이 없는 경우 안내 메시지
        if (result.extractedText == result.aiGeneratedText &&
            !state.isEditMode) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI가 텍스트를 변환하지 않았습니다. 스타일이나 길이 옵션을 변경해보세요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.isDarkMode
                  ? const Color(0xFF404040)
                  : const Color(0xFFE9ECEF),
            ),
          ),
          child: state.isEditMode
              ? TextField(
                  controller: notifier.aiTextController,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colorScheme.onSurface,
                    height: 1.5,
                  ),
                  onChanged: (value) => notifier.updateAiText(value),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(HandwritingDiaryState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.error!,
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
          if (state.error!.contains('서버 내부 오류'))
            IconButton(
              onPressed: () => _showRetryDialog(context),
              icon: Icon(Icons.refresh, color: Colors.blue, size: 18),
              tooltip: '다시 시도',
            )
          else if (state.error!.contains('로그인이 만료되었습니다'))
            IconButton(
              onPressed: () => context.go('/login'),
              icon: Icon(Icons.login, color: Colors.blue, size: 18),
              tooltip: '로그인 페이지로 이동',
            ),
          IconButton(
            onPressed: () =>
                ref.read(handwritingDiaryProvider.notifier).clearError(),
            icon: Icon(Icons.close, color: Colors.red, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    final result = state.result!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                '손글씨 다이어리 생성 완료',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 감정 및 키워드 정보
          if (result.aiEmotion.isNotEmpty) ...[
            _buildResultInfo('감정', result.aiEmotion),
            const SizedBox(height: 8),
          ],

          if (result.keywords.isNotEmpty) ...[
            _buildResultInfo('키워드', result.keywords.join(', ')),
            const SizedBox(height: 8),
          ],

          // OCR로 추출된 원본 텍스트 (백엔드에서 ocr_text로 제공되는 경우 표시)
          if (result.extractedText.isNotEmpty &&
              !result.extractedText.contains(
                '손글씨에서 추출된 텍스트로 AI 다이어리가 생성되었습니다.',
              )) ...[
            _buildOcrTextSection(result.extractedText, state, notifier),
            const SizedBox(height: 16),
          ],

          // AI로 생성된 다이어리 텍스트
          _buildAiTextSection(result, state, notifier),

          const SizedBox(height: 16),

          // 액션 버튼들
          _buildActionButtons(state, notifier),
        ],
      ),
    );
  }

  Widget _buildResultInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog(HandwritingDiaryNotifier notifier) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, notifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, notifier);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    ImageSource source,
    HandwritingDiaryNotifier notifier,
  ) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        notifier.selectImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActionButtons(
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    if (state.isEditMode) {
      // 편집 모드일 때: 저장/취소 버튼
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => notifier.cancelEdit(),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('취소'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => notifier.saveEditedContent(),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('저장'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else {
      // 일반 모드일 때: 편집하기/다이어리 저장 버튼
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _toggleEditMode(notifier),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('편집하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _goToEditMode(),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('저장하기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colorScheme.primary,
                side: BorderSide(color: context.colorScheme.primary),
              ),
            ),
          ),
        ],
      );
    }
  }

  void _toggleEditMode(HandwritingDiaryNotifier notifier) {
    notifier.toggleEditMode();
  }

  void _showRetryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('다시 시도'),
          content: const Text(
            '서버 오류가 발생했습니다. 다시 시도하시겠습니까?\n\n'
            '• 손글씨 이미지가 명확한지 확인해주세요\n'
            '• 네트워크 연결을 확인해주세요\n'
            '• 잠시 후 다시 시도해주세요',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 에러를 클리어하고 다시 시도
                ref.read(handwritingDiaryProvider.notifier).clearError();
                ref
                    .read(handwritingDiaryProvider.notifier)
                    .convertHandwritingToDiaryDirect();
              },
              child: const Text('다시 시도'),
            ),
          ],
        );
      },
    );
  }

  /// 편집 모드로 이동 (실제 저장은 하지 않음)
  Future<void> _goToEditMode() async {
    final state = ref.read(handwritingDiaryProvider);
    if (!state.hasResult) return;

    try {
      // HandwritingDiaryNotifier의 transferToCreateNotifier 메서드 사용
      await ref
          .read(handwritingDiaryProvider.notifier)
          .transferToCreateNotifier();

      // CreateNotifier를 통해 임시 다이어리 엔트리 생성
      final createNotifier = ref.read(createProvider.notifier);
      final handwritingResult = state.result;
      final tempEntry = createNotifier.createTempDiaryEntry(
        title: '손글씨 다이어리',
        diaryDate: DateTime.now().toIso8601String(),
        aiEmotion: handwritingResult?.aiEmotion, // AI 감정 전달
        userEmotion: state.emotion, // 사용자가 선택한 감정 전달
      );

      if (mounted) {
        if (tempEntry != null) {
          // 다이어리 상세 페이지로 이동 (편집 모드로 시작)
          // 실제 저장은 diary_detail_page에서 편집 모드로만 가능
          final targetPath =
              '${RoutePaths.diaryDetailPath(tempEntry.id)}?from=handwriting';
          context.go(targetPath, extra: tempEntry);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('편집 모드로 이동할 수 없습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
