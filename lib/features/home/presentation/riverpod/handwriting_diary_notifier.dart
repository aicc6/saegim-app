import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';
import 'package:saegim/features/home/data/services/handwriting_diary_service.dart';
import 'package:saegim/features/home/presentation/riverpod/create_notifier.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 손글씨 다이어리 변환 상태 클래스
class HandwritingDiaryState {
  final File? selectedImage;
  final WritingStyle style;
  final LengthOption length;
  final String? emotion;
  final bool isProcessing;
  final bool isConverting;
  final String? error;
  final HandwritingDiaryResult? result;
  final String? extractedText;
  final bool showExtractedText;
  final String? conversionStep;
  final bool isEditMode;
  final String? editedOcrText;
  final String? editedAiText;
  final int? regenerationCount; // AI 재생성 횟수 (null 허용, 기본 0)
  final bool? showRegenerationCount; // 재생성 횟수 표시 여부 (null 허용)

  const HandwritingDiaryState({
    this.selectedImage,
    required this.style,
    required this.length,
    this.emotion,
    required this.isProcessing,
    required this.isConverting,
    this.error,
    this.result,
    this.extractedText,
    this.showExtractedText = false,
    this.conversionStep,
    this.isEditMode = false,
    this.editedOcrText,
    this.editedAiText,
    this.regenerationCount = 0,
    this.showRegenerationCount = false,
  });

  HandwritingDiaryState copyWith({
    File? selectedImage,
    WritingStyle? style,
    LengthOption? length,
    String? emotion,
    bool? isProcessing,
    bool? isConverting,
    String? error,
    HandwritingDiaryResult? result,
    String? extractedText,
    bool? showExtractedText,
    String? conversionStep,
    bool? isEditMode,
    String? editedOcrText,
    String? editedAiText,
    int? regenerationCount,
    bool? showRegenerationCount,
    bool clearError = false,
    bool clearResult = false,
    bool clearExtractedText = false,
    bool clearSelectedImage = false,
  }) {
    return HandwritingDiaryState(
      selectedImage: clearSelectedImage
          ? null
          : (selectedImage ?? this.selectedImage),
      style: style ?? this.style,
      length: length ?? this.length,
      emotion: emotion, // null 값을 명시적으로 허용
      isProcessing: isProcessing ?? this.isProcessing,
      isConverting: isConverting ?? this.isConverting,
      error: clearError ? null : (error ?? this.error),
      result: clearResult ? null : (result ?? this.result),
      extractedText: clearExtractedText
          ? null
          : (extractedText ?? this.extractedText),
      showExtractedText: showExtractedText ?? this.showExtractedText,
      conversionStep: conversionStep,
      isEditMode: isEditMode ?? this.isEditMode,
      editedOcrText: editedOcrText ?? this.editedOcrText,
      editedAiText: editedAiText ?? this.editedAiText,
      regenerationCount: regenerationCount ?? this.regenerationCount,
      showRegenerationCount:
          showRegenerationCount ?? this.showRegenerationCount,
    );
  }

  /// 변환 가능 여부 확인
  bool get canConvert =>
      selectedImage != null && !isConverting && !isProcessing;

  /// 결과가 있는지 확인
  bool get hasResult => result != null;

  /// 추출된 텍스트가 있는지 확인
  bool get hasExtractedText =>
      extractedText != null && extractedText!.isNotEmpty;

  /// 에러가 있는지 확인
  bool get hasError => error != null && error!.isNotEmpty;
}

/// 손글씨 다이어리 변환 Notifier
class HandwritingDiaryNotifier extends StateNotifier<HandwritingDiaryState> {
  final HandwritingDiaryService _handwritingService =
      HandwritingDiaryService.instance;
  final Ref ref;

  // 텍스트 편집용 컨트롤러들
  final TextEditingController _ocrTextController = TextEditingController();
  final TextEditingController _aiTextController = TextEditingController();

  HandwritingDiaryNotifier(this.ref)
    : super(
        const HandwritingDiaryState(
          style: WritingStyle.poem,
          length: LengthOption.short,
          isProcessing: false,
          isConverting: false,
          regenerationCount: 0,
          showRegenerationCount: false,
        ),
      );

  @override
  void dispose() {
    _ocrTextController.dispose();
    _aiTextController.dispose();
    super.dispose();
  }

  /// 이미지 선택
  void selectImage(File image) {
    AppLogger.info(
      'Image selected for handwriting conversion',
      'HandwritingDiaryNotifier',
    );

    // 컨트롤러도 초기화
    _ocrTextController.clear();
    _aiTextController.clear();

    state = state.copyWith(
      selectedImage: image,
      clearError: true,
      clearResult: true,
      clearExtractedText: true,
      isEditMode: false,
      editedOcrText: null,
      editedAiText: null,
      regenerationCount: 0,
      showRegenerationCount: false,
    );
  }

  /// 재생성 횟수 표시 토글
  void toggleRegenerationCountDisplay() {
    state = state.copyWith(showRegenerationCount: true);

    // 3초 후 자동으로 숨김
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        state = state.copyWith(showRegenerationCount: false);
      }
    });
  }

  /// OCR 텍스트를 기반으로 AI 다이어리만 재생성 (최대 5회)
  Future<void> regenerateAiFromOcrOnly() async {
    if (!state.hasResult) return;

    if ((state.regenerationCount ?? 0) >= 5) {
      state = state.copyWith(error: 'AI 재생성은 최대 5회까지 가능합니다.');
      return;
    }

    final baseText = state.editedOcrText?.trim().isNotEmpty == true
        ? state.editedOcrText!
        : (state.result?.extractedText ?? '');

    if (baseText.isEmpty) {
      state = state.copyWith(error: 'OCR 텍스트가 없습니다. 먼저 텍스트를 추출해주세요.');
      return;
    }

    state = state.copyWith(
      isConverting: true,
      clearError: true,
      conversionStep: 'AI 다이어리 재생성 중...',
    );

    try {
      final result = await _handwritingService.generateDiaryFromText(
        extractedText: baseText,
        style: state.style,
        length: state.length,
        emotion: state.emotion,
      );

      if (result != null) {
        // 기존 extractedText는 유지하되, AI 생성 결과만 업데이트
        final updated = HandwritingDiaryResult(
          extractedText: baseText,
          aiGeneratedText: result.aiGeneratedText,
          aiEmotion: result.aiEmotion,
          userEmotion: state.emotion ?? result.userEmotion,
          aiEmotionConfidence: result.aiEmotionConfidence,
          keywords: result.keywords,
          tokensUsed: result.tokensUsed,
          sessionId: result.sessionId,
          imageUrl: state.result?.imageUrl ?? '',
        );

        state = state.copyWith(
          result: updated,
          isConverting: false,
          conversionStep: '완료',
          regenerationCount: (state.regenerationCount ?? 0) + 1,
          showRegenerationCount: false, // 재생성 완료 시 카운트 숨김
        );
      } else {
        state = state.copyWith(
          isConverting: false,
          conversionStep: null,
          error: 'AI 다이어리 생성에 실패했습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isConverting: false,
        conversionStep: null,
        error: 'AI 다이어리 생성 중 오류가 발생했습니다.',
      );
    }
  }

  /// 스타일 변경
  void setStyle(WritingStyle style) {
    AppLogger.info(
      'Writing style changed to: ${style.label}',
      'HandwritingDiaryNotifier',
    );
    state = state.copyWith(style: style);
  }

  /// 길이 변경
  void setLength(LengthOption length) {
    AppLogger.info(
      'Length option changed to: ${length.label}',
      'HandwritingDiaryNotifier',
    );
    state = state.copyWith(length: length);
  }

  /// 감정 설정
  void setEmotion(String? emotion) {
    AppLogger.info(
      'Emotion set to: $emotion (previous: ${state.emotion})',
      'HandwritingDiaryNotifier',
    );
    state = state.copyWith(emotion: emotion);
    AppLogger.info(
      'Emotion updated - new state.emotion: ${state.emotion}',
      'HandwritingDiaryNotifier',
    );
  }

  /// 에러 클리어
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// 결과 클리어
  void clearResult() {
    state = state.copyWith(clearResult: true, clearExtractedText: true);
  }

  /// 선택된 이미지 클리어
  void clearSelectedImage() {
    state = state.copyWith(
      clearSelectedImage: true,
      clearResult: true,
      clearExtractedText: true,
      clearError: true,
    );
  }

  /// 추출된 텍스트 표시/숨김 토글
  void toggleExtractedTextVisibility() {
    state = state.copyWith(showExtractedText: !state.showExtractedText);
  }

  /// 손글씨를 다이어리로 변환 (단계별 처리)
  Future<void> convertHandwritingToDiary() async {
    if (!state.canConvert) {
      AppLogger.warning(
        'Cannot convert: invalid state',
        'HandwritingDiaryNotifier',
      );
      return;
    }

    AppLogger.info(
      'Starting handwriting to diary conversion',
      'HandwritingDiaryNotifier',
    );

    state = state.copyWith(isConverting: true, clearError: true);

    try {
      final result = await _handwritingService.convertHandwritingToDiary(
        imageFile: state.selectedImage!,
        style: state.style,
        length: state.length,
        emotion: state.emotion,
      );

      if (result != null) {
        AppLogger.info(
          'Handwriting conversion completed successfully',
          'HandwritingDiaryNotifier',
        );
        state = state.copyWith(
          result: result,
          extractedText: result.extractedText,
          isConverting: false,
        );
      } else {
        throw const HandwritingDiaryException('변환 결과를 받을 수 없습니다.');
      }
    } on HandwritingDiaryException catch (e) {
      AppLogger.error(
        'Handwriting conversion failed',
        tag: 'HandwritingDiaryNotifier',
        error: e,
      );
      state = state.copyWith(error: e.message, isConverting: false);
    } catch (e) {
      AppLogger.error(
        'Unexpected error during handwriting conversion',
        tag: 'HandwritingDiaryNotifier',
        error: e,
      );
      state = state.copyWith(
        error: '손글씨 변환 중 예상치 못한 오류가 발생했습니다.',
        isConverting: false,
      );
    }
  }

  /// 2단계 프로세스: OCR → AI 생성
  Future<void> convertHandwritingToDiaryStepByStep() async {
    if (!state.canConvert) {
      AppLogger.warning(
        'Cannot convert: invalid state',
        'HandwritingDiaryNotifier',
      );
      return;
    }

    AppLogger.info(
      'Starting step-by-step handwriting conversion',
      'HandwritingDiaryNotifier',
    );

    // 1단계: OCR 텍스트 추출
    await _extractTextFromHandwriting();

    // OCR이 성공했고 텍스트가 있으면 2단계 진행
    if (state.hasExtractedText && !state.isConverting) {
      await _generateDiaryFromExtractedText();
    }
  }

  /// 1단계: OCR로 텍스트 추출
  Future<void> _extractTextFromHandwriting() async {
    AppLogger.info(
      'Step 1: Extracting text from handwriting',
      'HandwritingDiaryNotifier',
    );

    state = state.copyWith(
      isConverting: true,
      clearError: true,
      conversionStep: 'OCR 텍스트 추출 중...',
    );

    try {
      final result = await _handwritingService.extractTextFromHandwriting(
        state.selectedImage!,
      );

      if (result != null && result.extractedText.isNotEmpty) {
        AppLogger.info(
          'OCR text extraction completed successfully',
          'HandwritingDiaryNotifier',
        );
        state = state.copyWith(
          extractedText: result.extractedText,
          isConverting: false,
          conversionStep: 'OCR 완료',
        );
      } else {
        throw const HandwritingDiaryException('손글씨에서 텍스트를 추출할 수 없습니다.');
      }
    } on HandwritingDiaryException catch (e) {
      AppLogger.error(
        'OCR text extraction failed',
        tag: 'HandwritingDiaryNotifier',
        error: e,
      );
      state = state.copyWith(
        error: e.message,
        isConverting: false,
        conversionStep: null,
      );
    } catch (e) {
      AppLogger.error(
        'Unexpected error in OCR extraction',
        tag: 'HandwritingDiaryNotifier',
        error: e,
      );
      state = state.copyWith(
        error: 'OCR 텍스트 추출 중 예상치 못한 오류가 발생했습니다.',
        isConverting: false,
        conversionStep: null,
      );
    }
  }

  /// 2단계: 추출된 텍스트로 AI 다이어리 생성
  Future<void> _generateDiaryFromExtractedText() async {
    AppLogger.info(
      'Step 2: Generating diary from extracted text',
      'HandwritingDiaryNotifier',
    );

    state = state.copyWith(
      isConverting: true,
      clearError: true,
      conversionStep: 'AI 다이어리 생성 중...',
    );

    try {
      final result = await _handwritingService.generateDiaryFromText(
        extractedText: state.extractedText!,
        style: state.style,
        length: state.length,
        emotion: state.emotion,
      );

      if (result != null) {
        AppLogger.info(
          'AI diary generation completed successfully',
          'HandwritingDiaryNotifier',
        );
        state = state.copyWith(
          result: result,
          isConverting: false,
          conversionStep: '완료',
        );
      } else {
        throw const HandwritingDiaryException('AI 다이어리 생성에 실패했습니다.');
      }
    } on HandwritingDiaryException catch (e) {
      AppLogger.error(
        'AI diary generation failed',
        tag: 'HandwritingDiaryNotifier',
        error: e,
      );
      state = state.copyWith(
        error: e.message,
        isConverting: false,
        conversionStep: null,
      );
    } catch (e) {
      AppLogger.error(
        'Unexpected error in AI diary generation',
        tag: 'HandwritingDiaryNotifier',
        error: e,
      );
      state = state.copyWith(
        error: 'AI 다이어리 생성 중 예상치 못한 오류가 발생했습니다.',
        isConverting: false,
        conversionStep: null,
      );
    }
  }

  /// 손글씨를 다이어리로 직접 변환 (새로운 API 사용)
  Future<void> convertHandwritingToDiaryDirect() async {
    if (!state.canConvert) {
      AppLogger.warning(
        'Cannot convert: invalid state',
        'HandwritingDiaryNotifier',
      );
      return;
    }

    AppLogger.info(
      'Starting direct handwriting to diary conversion',
      'HandwritingDiaryNotifier',
    );

    state = state.copyWith(isConverting: true, clearError: true);

    try {
      final result = await _handwritingService.convertHandwritingToDiaryPreview(
        imageFile: state.selectedImage!,
        style: state.style,
        length: state.length,
        emotion: state.emotion,
      );

      if (result != null) {
        AppLogger.info(
          'Direct handwriting conversion completed successfully',
          'HandwritingDiaryNotifier',
        );
        state = state.copyWith(
          result: result,
          extractedText: result.extractedText,
          isConverting: false,
        );
      } else {
        throw const HandwritingDiaryException('변환 결과를 받을 수 없습니다.');
      }
    } on HandwritingDiaryException catch (e) {
      AppLogger.error(
        'Direct handwriting conversion failed',
        tag: 'HandwritingDiaryNotifier',
        error: e,
      );

      // 401 토큰 만료 오류인 경우 특별 처리
      if (e.message.contains('토큰이 만료되었습니다') || e.message.contains('401')) {
        state = state.copyWith(
          error: '로그인이 만료되었습니다. 다시 로그인해주세요.',
          isConverting: false,
        );
        // AuthNotifier를 통해 로그아웃 처리
        ref.read(authNotifierProvider.notifier).logout();
      } else {
        state = state.copyWith(error: e.message, isConverting: false);
      }
    } catch (e) {
      AppLogger.error(
        'Unexpected error during direct handwriting conversion',
        tag: 'HandwritingDiaryNotifier',
        error: e,
      );
      state = state.copyWith(
        error: '손글씨 변환 중 예상치 못한 오류가 발생했습니다.',
        isConverting: false,
      );
    }
  }

  /// 결과를 기존 CreateNotifier로 전송
  Future<void> transferToCreateNotifier() async {
    if (!state.hasResult) {
      AppLogger.warning('No result to transfer', 'HandwritingDiaryNotifier');
      return;
    }

    try {
      final createNotifier = ref.read(createProvider.notifier);
      final result = state.result!;

      // 이미지 URL 로깅 추가
      AppLogger.info(
        'Transferring result to CreateNotifier - imageUrl: ${result.imageUrl}',
        'HandwritingDiaryNotifier',
      );

      // CreateNotifier 상태 업데이트
      createNotifier.setPrompt(result.extractedText);
      createNotifier.setStyle(state.style);
      createNotifier.setLength(state.length);
      createNotifier.setEmotion(
        state.emotion ?? (result.aiEmotion.isNotEmpty ? result.aiEmotion : ''),
      );

      // 생성된 결과를 CreateNotifier에 직접 설정
      final currentCreateState = ref.read(createProvider);
      ref.read(createProvider.notifier).state = currentCreateState.copyWith(
        generatedText: result.aiGeneratedText,
        generatedKeywords: result.keywords,
        sessionId: result.sessionId,
        originalPrompt: result.extractedText,
        emotion:
            state.emotion ??
            result.userEmotion, // 사용자가 선택한 감정 우선, 없으면 백엔드에서 받은 사용자 감정
        wasJustGenerated: true,
        // 손글씨 이미지 URL을 CreateNotifier에 전달
        handwritingImageUrl: result.imageUrl,
      );

      AppLogger.info(
        'Successfully transferred result to CreateNotifier - handwritingImageUrl: ${result.imageUrl}',
        'HandwritingDiaryNotifier',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to transfer result to CreateNotifier',
        tag: 'HandwritingDiaryNotifier',
        error: e,
      );
      state = state.copyWith(error: '결과 전송 중 오류가 발생했습니다.');
    }
  }

  /// 편집 모드 토글
  void toggleEditMode() {
    if (state.isEditMode) {
      // 편집 모드 해제 - 현재 편집된 내용을 저장
      final currentOcrText = _ocrTextController.text;
      final currentAiText = _aiTextController.text;

      state = state.copyWith(
        isEditMode: false,
        editedOcrText: currentOcrText,
        editedAiText: currentAiText,
      );
    } else {
      // 편집 모드 활성화 - 컨트롤러에 초기 텍스트 설정
      final ocrText = state.result?.extractedText ?? '';
      final aiText = state.result?.aiGeneratedText ?? '';

      _ocrTextController.text = ocrText;
      _aiTextController.text = aiText;

      state = state.copyWith(
        isEditMode: true,
        editedOcrText: ocrText,
        editedAiText: aiText,
      );
    }
  }

  /// OCR 텍스트 업데이트
  void updateOcrText(String text) {
    state = state.copyWith(editedOcrText: text);
  }

  /// AI 생성 텍스트 업데이트
  void updateAiText(String text) {
    state = state.copyWith(editedAiText: text);
  }

  /// OCR 텍스트 컨트롤러 getter
  TextEditingController get ocrTextController => _ocrTextController;

  /// AI 텍스트 컨트롤러 getter
  TextEditingController get aiTextController => _aiTextController;

  /// 편집된 내용 저장
  void saveEditedContent() {
    if (state.result != null) {
      final updatedResult = HandwritingDiaryResult(
        extractedText: state.editedOcrText ?? state.result!.extractedText,
        aiGeneratedText: state.editedAiText ?? state.result!.aiGeneratedText,
        aiEmotion: state.result!.aiEmotion,
        userEmotion: state.result!.userEmotion, // 사용자 감정 유지
        aiEmotionConfidence: state.result!.aiEmotionConfidence,
        keywords: state.result!.keywords,
        tokensUsed: state.result!.tokensUsed,
        sessionId: state.result!.sessionId,
        imageUrl: state.result!.imageUrl,
      );

      state = state.copyWith(
        result: updatedResult,
        isEditMode: false,
        editedOcrText: null,
        editedAiText: null,
      );
    }
  }

  /// 편집 취소
  void cancelEdit() {
    // 편집 모드 해제 시 원본 텍스트로 복원
    final originalOcrText = state.result?.extractedText ?? '';
    final originalAiText = state.result?.aiGeneratedText ?? '';

    _ocrTextController.text = originalOcrText;
    _aiTextController.text = originalAiText;

    state = state.copyWith(
      isEditMode: false,
      editedOcrText: null,
      editedAiText: null,
    );
  }

  /// 상태 초기화
  void reset() {
    AppLogger.info(
      'Resetting handwriting diary state',
      'HandwritingDiaryNotifier',
    );

    // 컨트롤러 초기화
    _ocrTextController.clear();
    _aiTextController.clear();

    state = const HandwritingDiaryState(
      style: WritingStyle.poem,
      length: LengthOption.short,
      isProcessing: false,
      isConverting: false,
    );
  }
}

/// Provider 정의
final handwritingDiaryProvider =
    StateNotifierProvider<HandwritingDiaryNotifier, HandwritingDiaryState>(
      (ref) => HandwritingDiaryNotifier(ref),
    );
