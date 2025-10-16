import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/core/theme/app_colors.dart';
import 'package:saegim/core/theme/theme_extensions.dart';
import 'package:saegim/features/home/data/services/handwriting_diary_service.dart';
import 'package:saegim/features/home/presentation/riverpod/create_notifier.dart';
import 'package:saegim/features/home/presentation/riverpod/handwriting_diary_notifier.dart';
import 'package:saegim/shared/utils/app_logger.dart';
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
              // 이미지 선택 섹션
              _buildImageSelectionSection(
                handwritingState,
                handwritingNotifier,
              ),
              const SizedBox(height: 24),

              // 통합된 선택 섹션 (첫 번째 사진 구조)
              _buildUnifiedSelectionSection(
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.isDarkMode
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
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
    return Center(
      child: InkWell(
        onTap: () => _showImageSourceDialog(notifier),
        child: Container(
          height: 150, // 고정 높이로 크기 직접 제한
          width: 250,
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
                size: 36, // 아이콘 크기 줄임 (48 -> 36)
                color: context.colorScheme.primary,
              ),
              const SizedBox(height: 8), // 간격 줄임 (12 -> 8)
              Text(
                '손글씨 이미지 선택',
                style: TextStyle(
                  fontSize: 14, // 텍스트 크기 줄임 (16 -> 14)
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
        Center(
          child: Container(
            height: 150, // 고정 높이로 크기 직접 제한
            width: 250,
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

  Widget _buildUnifiedSelectionSection(
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    return Column(
      children: [
        // 첫 번째 행: 문체 선택과 길이 선택
        Row(
          children: [
            // 문체 선택
            Expanded(child: _buildStyleSelection(state, notifier)),
            const SizedBox(width: 16),
            // 길이 선택
            Expanded(child: _buildLengthSelection(state, notifier)),
          ],
        ),
        const SizedBox(height: 24),
        // 두 번째 행: 감정 선택
        _buildEmotionSelection(state, notifier),
      ],
    );
  }

  Widget _buildStyleSelection(
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '문체 선택',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.isDarkMode
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: WritingStyle.values.map((style) {
            final isSelected = state.style == style;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () => notifier.setStyle(style),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (context.isDarkMode
                                ? AppColors.darkInteractivePrimary
                                : AppColors.sage50)
                          : (context.isDarkMode
                                ? AppColors.darkBackgroundSecondary
                                : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? (context.isDarkMode
                                  ? AppColors.darkInteractivePrimary
                                  : AppColors.sage50)
                            : (context.isDarkMode
                                  ? AppColors.darkBorderStrong
                                  : AppColors.borderStrong),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      style.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (context.isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary),
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

  Widget _buildLengthSelection(
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '길이 선택',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.isDarkMode
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: LengthOption.values.map((length) {
            final isSelected = state.length == length;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () => notifier.setLength(length),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (context.isDarkMode
                                ? AppColors.darkInteractivePrimary
                                : AppColors.sage50)
                          : (context.isDarkMode
                                ? AppColors.darkBackgroundSecondary
                                : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? (context.isDarkMode
                                  ? AppColors.darkInteractivePrimary
                                  : AppColors.sage50)
                            : (context.isDarkMode
                                  ? AppColors.darkBorderStrong
                                  : AppColors.borderStrong),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      length.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (context.isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary),
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

  Widget _buildEmotionSelection(
    HandwritingDiaryState state,
    HandwritingDiaryNotifier notifier,
  ) {
    final emotions = ['행복', '평온', '불안', '분노', '슬픔'];
    final emotionEmojis = ['😊', '😌', '😨', '😠', '😢'];

    // home_page와 동일한 감정별 배경색 사용
    final emotionColors = {
      '행복': const Color.fromARGB(255, 255, 250, 203), // yellow
      '평온': const Color.fromARGB(255, 189, 217, 184), // green
      '불안': const Color.fromARGB(162, 247, 206, 255), // purple
      '분노': const Color.fromARGB(255, 255, 221, 169), // orange
      '슬픔': const Color.fromARGB(255, 227, 247, 255), // sky
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '감정을 선택해주세요 (선택 사항)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.isDarkMode
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(emotions.length, (index) {
            final emotion = emotions[index];
            final isSelected = state.emotion == emotion;
            final backgroundColor =
                emotionColors[emotion] ?? AppColors.borderStrong;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () => notifier.setEmotion(emotion),
                  child: Container(
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
                          ? backgroundColor
                          : context.colorScheme.surface,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: context.colorScheme.primary.withAlpha(
                                  38,
                                ),
                                blurRadius: 3,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        emotionEmojis[index],
                        style: TextStyle(
                          fontSize: isSelected ? 28 : 22,
                          color: isSelected
                              ? _getColorFromStyle(emotion)
                              : context.primaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// 감정에 따른 텍스트 색상 반환
  Color _getColorFromStyle(String emotion) {
    switch (emotion) {
      case '행복':
        return const Color.fromARGB(255, 255, 250, 203);
      case '평온':
        return const Color.fromARGB(255, 227, 247, 255);
      case '불안':
        return const Color.fromARGB(255, 255, 221, 169);
      case '분노':
        return const Color.fromARGB(162, 247, 206, 255);
      case '슬픔':
        return const Color.fromARGB(255, 227, 247, 255);
      default:
        return Colors.grey;
    }
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
          child: Text(
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
      // 일반 모드일 때: 편집하기/저장하기 + AI 재생성/작업 취소 버튼
      return Column(
        children: [
          Row(
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
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('저장하기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colorScheme.primary,
                    side: BorderSide(color: context.colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.hasResult && !state.isConverting
                      ? () => notifier.regenerateAiFromOcrOnly()
                      : null,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    (state.regenerationCount ?? 0) >= 5
                        ? 'AI 재생성(제한됨)'
                        : 'AI 재생성',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colorScheme.secondary,
                    side: BorderSide(color: context.colorScheme.secondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _cancelAndGoHome(),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('작업 취소'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
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

      // 디버깅을 위한 로그 추가
      AppLogger.info(
        'Creating temp diary entry - user emotion: ${state.emotion}, ai emotion: ${handwritingResult?.aiEmotion}',
        'HandwritingDiaryPage',
      );

      final tempEntry = createNotifier.createTempDiaryEntry(
        title: '손글씨 다이어리',
        diaryDate: DateTime.now().toIso8601String(),
        aiEmotion: handwritingResult?.aiEmotion, // AI 감정 전달
        userEmotion: state.emotion, // 사용자가 선택한 감정 전달
      );

      AppLogger.info(
        'Temp entry created - emotion field: ${tempEntry?.emotion}',
        'HandwritingDiaryPage',
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

  /// 작업 전체 취소하고 홈으로 이동
  void _cancelAndGoHome() {
    ref.read(handwritingDiaryProvider.notifier).reset();
    context.go(RoutePaths.home);
  }
}
