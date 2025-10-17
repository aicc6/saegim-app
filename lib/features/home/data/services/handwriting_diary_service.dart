import 'dart:io';

import 'package:dio/dio.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/core/services/auth_storage_service.dart';
import 'package:saegim/features/home/presentation/riverpod/create_notifier.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 손글씨 이미지 인식 → AI 다이어리 자동생성 서비스
class HandwritingDiaryService {
  HandwritingDiaryService._();

  static final HandwritingDiaryService _instance = HandwritingDiaryService._();
  static HandwritingDiaryService get instance => _instance;

  /// 중앙화된 Dio 인스턴스 사용
  Dio get dio => DioClient.instance.dio;

  /// 한국어 감정을 영어로 변환
  String _convertKoreanEmotionToEnglish(String koreanEmotion) {
    switch (koreanEmotion) {
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
        return 'peaceful'; // 기본값
    }
  }

  /// 손글씨 이미지를 다이어리로 변환하는 메인 메서드
  ///
  /// [imageFile]: 손글씨 이미지 파일
  /// [style]: 작성 스타일 (시, 단편글)
  /// [length]: 길이 옵션 (단문, 중문, 장문)
  /// [emotion]: 선택적 감정 (없으면 AI가 자동 분석)
  Future<HandwritingDiaryResult?> convertHandwritingToDiary({
    required File imageFile,
    required WritingStyle style,
    required LengthOption length,
    String? emotion,
  }) async {
    try {
      AppLogger.info(
        '🖋️ Starting handwriting to diary conversion',
        'HandwritingDiaryService',
      );

      // 1. 이미지 업로드 및 OCR 처리
      final ocrResult = await _extractTextFromHandwriting(imageFile);
      if (ocrResult == null || ocrResult.extractedText.isEmpty) {
        throw HandwritingDiaryException(
          '손글씨에서 텍스트를 추출할 수 없습니다. 더 선명한 이미지를 사용해주세요.',
        );
      }

      AppLogger.info(
        '📝 OCR completed: "${ocrResult.extractedText.substring(0, ocrResult.extractedText.length > 50 ? 50 : ocrResult.extractedText.length)}..."',
        'HandwritingDiaryService',
      );

      // 2. 추출된 텍스트로 AI 다이어리 생성
      final aiResult = await _generateDiaryFromText(
        prompt: ocrResult.extractedText,
        style: style,
        length: length,
        emotion: emotion,
      );

      if (aiResult == null) {
        throw HandwritingDiaryException('AI 다이어리 생성에 실패했습니다.');
      }

      AppLogger.info(
        '✅ Handwriting to diary conversion completed successfully',
        'HandwritingDiaryService',
      );

      return HandwritingDiaryResult(
        extractedText: ocrResult.extractedText,
        aiGeneratedText: aiResult.aiGeneratedText,
        aiEmotion: aiResult.aiEmotion,
        userEmotion: emotion ?? '', // 사용자가 선택한 감정 전달
        aiEmotionConfidence: aiResult.aiEmotionConfidence,
        keywords: aiResult.keywords,
        tokensUsed: aiResult.tokensUsed,
        sessionId: aiResult.sessionId,
        imageUrl: ocrResult.imageUrl,
      );
    } on HandwritingDiaryException {
      rethrow;
    } catch (e) {
      AppLogger.error(
        'Failed to convert handwriting to diary',
        tag: 'HandwritingDiaryService',
        error: e,
      );
      throw HandwritingDiaryException(
        '손글씨 다이어리 변환 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  /// 손글씨를 임시 변환 (저장하지 않음)
  ///
  /// [imageFile]: 손글씨 이미지 파일
  /// [style]: 작성 스타일
  /// [length]: 길이 옵션
  /// [emotion]: 선택적 감정
  Future<HandwritingDiaryResult?> convertHandwritingToDiaryPreview({
    required File imageFile,
    required WritingStyle style,
    required LengthOption length,
    String? emotion,
  }) async {
    try {
      AppLogger.info(
        '🖋️ Using preview handwriting to diary API (no save)',
        'HandwritingDiaryService',
      );

      final jwt = await _getJwtToken();
      if (jwt == null || jwt.isEmpty) {
        throw HandwritingDiaryException('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      // 1단계: 이미지 업로드
      AppLogger.info(
        '📤 Step 1: Uploading handwriting image',
        'HandwritingDiaryService',
      );

      final uploadFormData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final uploadResponse = await dio.post(
        '/api/diary/handwriting/upload',
        data: uploadFormData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (uploadResponse.statusCode != 200) {
        throw HandwritingDiaryException('이미지 업로드에 실패했습니다.');
      }

      final uploadData = uploadResponse.data;
      final imageUrl = uploadData['data']['original_url'];

      if (imageUrl == null || imageUrl.isEmpty) {
        throw HandwritingDiaryException('이미지 업로드 후 URL을 받을 수 없습니다.');
      }

      AppLogger.info(
        '✅ Image uploaded successfully: $imageUrl',
        'HandwritingDiaryService',
      );

      // 2단계: 손글씨 다이어리 변환
      AppLogger.info(
        '📤 Step 2: Converting handwriting to diary',
        'HandwritingDiaryService',
      );

      final requestBody = {
        'image_url': imageUrl,
        'style': style.value,
        'length': length.value,
        'save': false, // 저장하지 않음
        if (emotion != null && emotion.isNotEmpty) ...{
          'emotion': _convertKoreanEmotionToEnglish(emotion),
          'user_emotion': _convertKoreanEmotionToEnglish(
            emotion,
          ), // 백엔드에서 추가된 사용자 감정 필드
        },
      };

      AppLogger.info(
        '📤 Sending handwriting conversion request: $requestBody',
        'HandwritingDiaryService',
      );

      // 요청 데이터 상세 로깅
      AppLogger.info(
        '📤 Request body details: ${requestBody.toString()}',
        'HandwritingDiaryService',
      );

      // 요청 데이터 상세 로깅
      AppLogger.info(
        '📤 Request details - Image URL: $imageUrl, Style: ${style.value}, Length: ${length.value}, Emotion: ${emotion != null ? "$emotion -> ${_convertKoreanEmotionToEnglish(emotion)}" : "None"}, User Emotion: ${emotion != null ? "$emotion -> ${_convertKoreanEmotionToEnglish(emotion)}" : "None"}',
        'HandwritingDiaryService',
      );

      final response = await dio.post(
        '/api/diary/handwriting/to-diary',
        data: requestBody,
        options: Options(
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        AppLogger.info(
          '✅ Handwriting to diary conversion successful',
          'HandwritingDiaryService',
        );

        final data = response.data;

        // 성공 응답 로깅
        AppLogger.info(
          '📄 Success response data: $data',
          'HandwritingDiaryService',
        );

        return _parseDiaryResponse(data, imageUrl);
      } else {
        AppLogger.warning(
          'Handwriting conversion failed with status: ${response.statusCode}',
          'HandwritingDiaryService',
        );
        throw HandwritingDiaryException('서버 오류: ${response.statusCode}');
      }
    } on DioException catch (dioError) {
      final statusCode = dioError.response?.statusCode;
      final errorData = dioError.response?.data;

      AppLogger.error(
        'DioException in handwriting conversion - Status: $statusCode',
        tag: 'HandwritingDiaryService',
        error: dioError,
      );

      String errorMessage = '손글씨 처리 중 오류가 발생했습니다.';
      if (errorData is Map<String, dynamic>) {
        errorMessage =
            errorData['message'] ?? errorData['detail'] ?? errorMessage;

        // 상세 오류 정보 로깅
        AppLogger.error(
          'Detailed server error response: $errorData',
          tag: 'HandwritingDiaryService',
        );
      } else {
        // 응답 데이터가 Map이 아닌 경우 전체 응답 로깅
        AppLogger.error(
          'Server error response (not Map): $errorData',
          tag: 'HandwritingDiaryService',
        );
      }

      // 500 에러인 경우 더 구체적인 메시지 제공
      if (statusCode == 500) {
        errorMessage = '서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      }

      throw HandwritingDiaryException(errorMessage);
    } catch (e) {
      if (e is HandwritingDiaryException) rethrow;

      AppLogger.error(
        'Unexpected error in handwriting conversion',
        tag: 'HandwritingDiaryService',
        error: e,
      );
      throw HandwritingDiaryException(
        '손글씨 다이어리 변환 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  /// 새로운 /handwriting/to-diary 엔드포인트 사용 (저장 포함)
  ///
  /// [imageFile]: 손글씨 이미지 파일
  /// [style]: 작성 스타일
  /// [length]: 길이 옵션
  /// [emotion]: 선택적 감정
  Future<HandwritingDiaryResult?> convertHandwritingToDiaryDirect({
    required File imageFile,
    required WritingStyle style,
    required LengthOption length,
    String? emotion,
  }) async {
    try {
      AppLogger.info(
        '🖋️ Using direct handwriting to diary API (with save)',
        'HandwritingDiaryService',
      );

      final jwt = await _getJwtToken();
      if (jwt == null || jwt.isEmpty) {
        throw HandwritingDiaryException('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      // 1단계: 이미지 업로드
      AppLogger.info(
        '📤 Step 1: Uploading handwriting image',
        'HandwritingDiaryService',
      );

      final uploadFormData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final uploadResponse = await dio.post(
        '/api/diary/handwriting/upload',
        data: uploadFormData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (uploadResponse.statusCode != 200) {
        throw HandwritingDiaryException('이미지 업로드에 실패했습니다.');
      }

      final uploadData = uploadResponse.data;
      final imageUrl = uploadData['data']['original_url'];

      if (imageUrl == null || imageUrl.isEmpty) {
        throw HandwritingDiaryException('이미지 업로드 후 URL을 받을 수 없습니다.');
      }

      AppLogger.info(
        '✅ Image uploaded successfully: $imageUrl',
        'HandwritingDiaryService',
      );

      // 2단계: 손글씨 다이어리 변환
      AppLogger.info(
        '📤 Step 2: Converting handwriting to diary',
        'HandwritingDiaryService',
      );

      final requestBody = {
        'image_url': imageUrl,
        'style': style.value,
        'length': length.value,
        'save': true, // 저장함
        if (emotion != null && emotion.isNotEmpty) ...{
          'emotion': _convertKoreanEmotionToEnglish(emotion),
          'user_emotion': _convertKoreanEmotionToEnglish(emotion),
        },
      };

      AppLogger.info(
        '📤 Sending handwriting conversion request: $requestBody',
        'HandwritingDiaryService',
      );

      final response = await dio.post(
        '/api/diary/handwriting/to-diary',
        data: requestBody,
        options: Options(
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        AppLogger.info(
          '✅ Handwriting to diary conversion successful',
          'HandwritingDiaryService',
        );

        final data = response.data;
        return _parseDiaryResponse(data, imageUrl);
      } else {
        AppLogger.warning(
          'Handwriting conversion failed with status: ${response.statusCode}',
          'HandwritingDiaryService',
        );
        throw HandwritingDiaryException('서버 오류: ${response.statusCode}');
      }
    } on DioException catch (dioError) {
      final statusCode = dioError.response?.statusCode;
      final errorData = dioError.response?.data;

      AppLogger.error(
        'DioException in handwriting conversion - Status: $statusCode',
        tag: 'HandwritingDiaryService',
        error: dioError,
      );

      String errorMessage = '손글씨 처리 중 오류가 발생했습니다.';
      if (errorData is Map<String, dynamic>) {
        errorMessage =
            errorData['message'] ?? errorData['detail'] ?? errorMessage;
      }

      if (statusCode == 500) {
        errorMessage = '서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      }

      throw HandwritingDiaryException(errorMessage);
    } catch (e) {
      if (e is HandwritingDiaryException) rethrow;

      AppLogger.error(
        'Unexpected error in handwriting conversion',
        tag: 'HandwritingDiaryService',
        error: e,
      );
      throw HandwritingDiaryException(
        '손글씨 다이어리 변환 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  /// 이미지에서 텍스트 추출 (OCR) - 공개 메서드
  Future<HandwritingDiaryResult?> extractTextFromHandwriting(
    File imageFile,
  ) async {
    try {
      final ocrResult = await _extractTextFromHandwriting(imageFile);
      if (ocrResult != null) {
        return HandwritingDiaryResult(
          extractedText: ocrResult.extractedText,
          aiGeneratedText: '',
          aiEmotion: '',
          userEmotion: '', // OCR만 수행하는 경우 사용자 감정 없음
          aiEmotionConfidence: 0.0,
          keywords: [],
          tokensUsed: 0,
          sessionId: '',
          imageUrl: ocrResult.imageUrl,
        );
      }
      return null;
    } catch (e) {
      AppLogger.error(
        'Failed to extract text from handwriting',
        tag: 'HandwritingDiaryService',
        error: e,
      );
      throw HandwritingDiaryException('OCR 텍스트 추출에 실패했습니다: ${e.toString()}');
    }
  }

  /// 추출된 텍스트로 AI 다이어리 생성
  Future<HandwritingDiaryResult?> generateDiaryFromText({
    required String extractedText,
    required WritingStyle style,
    required LengthOption length,
    String? emotion,
  }) async {
    try {
      AppLogger.info(
        '🤖 Generating diary from extracted text',
        'HandwritingDiaryService',
      );

      // 기존 AiApiService의 generateText 메서드 활용
      final aiApiService = AiApiService();
      final aiResult = await aiApiService.generateText(
        prompt: extractedText,
        style: style,
        length: length,
        emotion: emotion,
        regenerationCount: 1,
      );

      return HandwritingDiaryResult(
        extractedText: extractedText,
        aiGeneratedText: aiResult.aiGeneratedText,
        aiEmotion: aiResult.aiEmotion,
        userEmotion: emotion ?? '', // 사용자가 선택한 감정 전달
        aiEmotionConfidence: aiResult.aiEmotionConfidence,
        keywords: aiResult.keywords,
        tokensUsed: aiResult.tokensUsed,
        sessionId: aiResult.sessionId,
        imageUrl: '', // 텍스트 생성에는 이미지 URL이 없음
      );
    } catch (e) {
      AppLogger.error(
        'Failed to generate diary from extracted text',
        tag: 'HandwritingDiaryService',
        error: e,
      );
      throw HandwritingDiaryException('AI 다이어리 생성에 실패했습니다: ${e.toString()}');
    }
  }

  /// 이미지에서 텍스트 추출 (OCR) - 내부 메서드
  Future<OcrResult?> _extractTextFromHandwriting(File imageFile) async {
    try {
      final jwt = await _getJwtToken();
      if (jwt == null || jwt.isEmpty) {
        throw HandwritingDiaryException('인증 토큰이 없습니다.');
      }

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      AppLogger.info(
        '🔍 Extracting text from handwriting image',
        'HandwritingDiaryService',
      );

      final response = await dio.post(
        '/api/ocr/extract-text',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final extractedText = data['extracted_text'] ?? '';
        final imageUrl = data['image_url'] ?? '';

        if (extractedText.isEmpty) {
          AppLogger.warning(
            'No text extracted from handwriting image',
            'HandwritingDiaryService',
          );
          return null;
        }

        AppLogger.info(
          '✅ Text extraction successful: ${extractedText.length} characters',
          'HandwritingDiaryService',
        );

        return OcrResult(extractedText: extractedText, imageUrl: imageUrl);
      } else {
        AppLogger.warning(
          'OCR API failed with status: ${response.statusCode}',
          'HandwritingDiaryService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        'Failed to extract text from handwriting',
        tag: 'HandwritingDiaryService',
        error: e,
      );
      return null;
    }
  }

  /// 추출된 텍스트로 AI 다이어리 생성
  Future<AIGenerationResult?> _generateDiaryFromText({
    required String prompt,
    required WritingStyle style,
    required LengthOption length,
    String? emotion,
  }) async {
    try {
      // 기존 AiApiService의 generateText 메서드 활용
      final aiApiService = AiApiService();
      return await aiApiService.generateText(
        prompt: prompt,
        style: style,
        length: length,
        emotion: emotion,
        regenerationCount: 1,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to generate diary from extracted text',
        tag: 'HandwritingDiaryService',
        error: e,
      );
      return null;
    }
  }

  /// 백엔드 다이어리 API 응답 파싱
  HandwritingDiaryResult? _parseDiaryResponse(
    dynamic responseData,
    String imageUrl,
  ) {
    try {
      Map<String, dynamic> data = {};

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data')) {
          data = responseData['data'];
        } else {
          data = responseData;
        }
      }

      if (data.isEmpty) {
        AppLogger.warning(
          'Empty response data from diary API',
          'HandwritingDiaryService',
        );
        return null;
      }

      // AI가 생성한 다이어리 텍스트 (ai_generated_text 우선, 없으면 content 사용)
      final diaryContent = data['ai_generated_text'] ?? data['content'] ?? '';

      // OCR로 추출된 원본 텍스트 (백엔드에서 ocr_text 필드로 제공)
      final extractedText =
          data['ocr_text'] ??
          data['extracted_text'] ??
          data['original_text'] ??
          data['title'] ??
          (diaryContent.isNotEmpty ? '손글씨에서 추출된 텍스트로 AI 다이어리가 생성되었습니다.' : '');

      AppLogger.info(
        '📄 Parsed diary response - Content length: ${diaryContent.length}, Extracted text: ${extractedText.isNotEmpty ? "Available" : "Not available"}',
        'HandwritingDiaryService',
      );

      // 백엔드 응답 전체 로깅 (디버깅용)
      AppLogger.info(
        '📄 Full backend response data: $data',
        'HandwritingDiaryService',
      );

      // AI 생성 필드 상태 확인
      AppLogger.info(
        '🤖 AI Generation Status - ai_generated_text: ${data['ai_generated_text'] != null ? "Available" : "NULL"}, content: ${data['content'] != null ? "Available" : "NULL"}, ocr_text: ${data['ocr_text'] != null ? "Available" : "NULL"}',
        'HandwritingDiaryService',
      );

      // OCR 텍스트와 AI 생성 텍스트 비교
      AppLogger.info(
        '📊 Text comparison - OCR: "${extractedText.length} chars", AI: "${diaryContent.length} chars"',
        'HandwritingDiaryService',
      );

      if (extractedText == diaryContent) {
        AppLogger.warning(
          '⚠️ OCR text and AI generated text are identical - AI may not be processing properly',
          'HandwritingDiaryService',
        );
      } else {
        AppLogger.info(
          '✅ AI successfully transformed the OCR text',
          'HandwritingDiaryService',
        );
      }

      // AI 감정 필드 확인 및 로깅
      final aiEmotion = data['ai_emotion'] ?? data['emotion'] ?? '';
      final userEmotion = data['user_emotion'] ?? ''; // 백엔드에서 추가된 사용자 감정 필드 사용

      AppLogger.info(
        '🤖 Emotion Analysis - ai_emotion: ${data['ai_emotion']}, user_emotion: ${data['user_emotion']}, emotion: ${data['emotion']}, final ai: $aiEmotion, final user: $userEmotion',
        'HandwritingDiaryService',
      );

      return HandwritingDiaryResult(
        extractedText: extractedText,
        aiGeneratedText: diaryContent,
        aiEmotion: aiEmotion,
        userEmotion: userEmotion, // 사용자 감정 추가
        aiEmotionConfidence: 0.8, // 기본값
        keywords: List<String>.from(data['keywords'] ?? []),
        tokensUsed: 0, // 백엔드에서 제공하지 않음
        sessionId: data['id'] ?? '', // 다이어리 ID를 세션 ID로 사용
        imageUrl: imageUrl,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to parse diary response',
        tag: 'HandwritingDiaryService',
        error: e,
      );
      return null;
    }
  }

  /// JWT 토큰 조회
  Future<String?> _getJwtToken() async {
    try {
      return await AuthStorageService.instance.getAuthToken();
    } catch (e) {
      return null;
    }
  }
}

/// OCR 결과 모델
class OcrResult {
  final String extractedText;
  final String imageUrl;

  const OcrResult({required this.extractedText, required this.imageUrl});
}

/// 손글씨 다이어리 변환 결과 모델
class HandwritingDiaryResult {
  final String extractedText;
  final String aiGeneratedText;
  final String aiEmotion;
  final String userEmotion; // 사용자가 선택한 감정 추가
  final double aiEmotionConfidence;
  final List<String> keywords;
  final int tokensUsed;
  final String sessionId;
  final String imageUrl;

  const HandwritingDiaryResult({
    required this.extractedText,
    required this.aiGeneratedText,
    required this.aiEmotion,
    required this.userEmotion, // 사용자 감정 필수 필드로 추가
    required this.aiEmotionConfidence,
    required this.keywords,
    required this.tokensUsed,
    required this.sessionId,
    required this.imageUrl,
  });
}

/// 손글씨 다이어리 예외 클래스
class HandwritingDiaryException implements Exception {
  final String message;

  const HandwritingDiaryException(this.message);

  @override
  String toString() => 'HandwritingDiaryException: $message';
}
