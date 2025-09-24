import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 모델 클래스들
class AIGenerationResult {
  final String aiGeneratedText;
  final String aiEmotion;
  final double aiEmotionConfidence;
  final List<String> keywords;
  final int tokensUsed;
  final String sessionId;

  AIGenerationResult({
    required this.aiGeneratedText,
    required this.aiEmotion,
    required this.aiEmotionConfidence,
    required this.keywords,
    required this.tokensUsed,
    required this.sessionId,
  });

  factory AIGenerationResult.fromJson(Map<String, dynamic> json) {
    return AIGenerationResult(
      aiGeneratedText: json['ai_generated_text'] ?? '',
      aiEmotion: json['ai_emotion'] ?? '',
      aiEmotionConfidence: (json['ai_emotion_confidence'] ?? 0.0).toDouble(),
      keywords: List<String>.from(json['keywords'] ?? []),
      tokensUsed: json['tokens_used'] ?? 0,
      sessionId: json['session_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ai_generated_text': aiGeneratedText,
      'ai_emotion': aiEmotion,
      'ai_emotion_confidence': aiEmotionConfidence,
      'keywords': keywords,
      'tokens_used': tokensUsed,
      'session_id': sessionId,
    };
  }
}

class OriginalUserInputResponse {
  final String originalInput;

  OriginalUserInputResponse({required this.originalInput});

  factory OriginalUserInputResponse.fromJson(Map<String, dynamic> json) {
    return OriginalUserInputResponse(
      originalInput: json['original_input'] ?? '',
    );
  }
}

class UploadedImage {
  final String fileId;
  final String originalUrl;
  final String thumbnailUrl;
  final String mimeType;
  final int fileSize;
  final String filename;

  UploadedImage({
    required this.fileId,
    required this.originalUrl,
    required this.thumbnailUrl,
    required this.mimeType,
    required this.fileSize,
    required this.filename,
  });

  Map<String, dynamic> toJson() {
    return {
      'file_id': fileId,
      'original_url': originalUrl,
      'thumbnail_url': thumbnailUrl,
      'mime_type': mimeType,
      'file_size': fileSize,
      'filename': filename,
    };
  }

  factory UploadedImage.fromJson(Map<String, dynamic> json) {
    return UploadedImage(
      fileId: json['file_id'] ?? '',
      originalUrl: json['original_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      mimeType: json['mime_type'] ?? '',
      fileSize: json['file_size'] ?? 0,
      filename: json['filename'] ?? '',
    );
  }
}

// 요청 데이터 모델
class GenerateTextRequest {
  final String prompt;
  final String style;
  final String length;
  final String? emotion;
  final int? regenerationCount;
  final String? sessionId;
  final List<UploadedImage>? uploadedImages;
  final String? diaryDate;

  GenerateTextRequest({
    required this.prompt,
    required this.style,
    required this.length,
    this.emotion,
    this.regenerationCount,
    this.sessionId,
    this.uploadedImages,
    this.diaryDate,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'prompt': prompt,
      'style': style,
      'length': length,
      'emotion': emotion ?? '',
      'regeneration_count': regenerationCount ?? 0,
    };

    if (sessionId != null) {
      data['sessionId'] = sessionId;
      data['session_id'] = sessionId;
    }

    if (uploadedImages != null) {
      data['uploaded_images'] = uploadedImages!
          .map((img) => img.toJson())
          .toList();
    }

    if (diaryDate != null) {
      data['diary_date'] = diaryDate;
    }

    return data;
  }
}

// API 클라이언트 (기본 클라이언트가 필요하다고 가정)
// 이 부분은 실제 프로젝트의 API 클라이언트 구조에 맞게 수정해야 합니다.
abstract class ApiClient {
  Future<Response> post(String path, Map<String, dynamic> data);
  Future<Response> get(String path);
  Stream<String> stream(String path, Map<String, dynamic> data);
}

// Dio를 사용한 기본 API 클라이언트 구현 예시
class DioApiClient implements ApiClient {
  final Dio _dio;

  DioApiClient(this._dio);

  @override
  Future<Response> post(String path, Map<String, dynamic> data) {
    return _dio.post(path, data: data);
  }

  @override
  Future<Response> get(String path) {
    return _dio.get(path);
  }

  @override
  Stream<String> stream(String path, Map<String, dynamic> data) async* {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;
      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        final lines = text.split('\n');

        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            // Server-Sent Events 형식 처리
            if (line.startsWith('data: ')) {
              yield line.substring(6); // 'data: ' 부분 제거
            } else {
              yield line;
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Stream error: $e');
    }
  }
}

// AI API 서비스 클래스
class AIApiService {
  final ApiClient _apiClient;

  AIApiService(this._apiClient);

  /// AI 텍스트 재생성 (session_id 기반)
  Future<AIGenerationResult> regenerate(String sessionId) async {
    try {
      final response = await _apiClient.post(
        '/api/ai/regenerate/$sessionId',
        {},
      );
      return AIGenerationResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to regenerate: $e');
    }
  }

  /// AI 텍스트 스트리밍 재생성 (session_id 기반)
  Stream<String> regenerateStream(String sessionId) {
    return _apiClient.stream('/api/ai/regenerate/$sessionId/stream', {});
  }

  /// 원본 사용자 입력 조회
  Future<OriginalUserInputResponse> getOriginalUserInput(
    String sessionId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/api/ai/session/$sessionId/original-input',
      );
      return OriginalUserInputResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get original user input: $e');
    }
  }

  /// AI 텍스트 생성
  Future<AIGenerationResult> generateText(GenerateTextRequest request) async {
    try {
      final response = await _apiClient.post(
        '/api/ai/generate',
        request.toJson(),
      );
      return AIGenerationResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to generate text: $e');
    }
  }

  /// AI 텍스트 스트리밍 생성
  Stream<String> generateTextStream(GenerateTextRequest request) {
    return _apiClient.stream('/api/ai/generate/stream', request.toJson());
  }
}

// Riverpod providers
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  // 기본 설정
  dio.options.baseUrl = 'https://your-api-base-url.com'; // 실제 API URL로 변경
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);

  // 인터셉터 추가 (필요한 경우)
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return DioApiClient(dio);
});

final aiApiServiceProvider = Provider<AIApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AIApiService(apiClient);
});

// AI 생성 상태 관리를 위한 StateNotifier
class AIGenerationState {
  final bool isLoading;
  final AIGenerationResult? result;
  final String? error;
  final bool isStreaming;

  AIGenerationState({
    this.isLoading = false,
    this.result,
    this.error,
    this.isStreaming = false,
  });

  AIGenerationState copyWith({
    bool? isLoading,
    AIGenerationResult? result,
    String? error,
    bool? isStreaming,
  }) {
    return AIGenerationState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class AIGenerationNotifier extends StateNotifier<AIGenerationState> {
  final AIApiService _aiApiService;

  AIGenerationNotifier(this._aiApiService) : super(AIGenerationState());

  /// AI 텍스트 생성
  Future<void> generateText(GenerateTextRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _aiApiService.generateText(request);
      state = state.copyWith(isLoading: false, result: result, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// AI 텍스트 재생성
  Future<void> regenerate(String sessionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _aiApiService.regenerate(sessionId);
      state = state.copyWith(isLoading: false, result: result, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 스트리밍 생성
  Stream<String> generateTextStream(GenerateTextRequest request) async* {
    state = state.copyWith(isStreaming: true, error: null);

    try {
      yield* _aiApiService.generateTextStream(request);
    } catch (e) {
      state = state.copyWith(isStreaming: false, error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isStreaming: false);
    }
  }

  /// 스트리밍 재생성
  Stream<String> regenerateStream(String sessionId) async* {
    state = state.copyWith(isStreaming: true, error: null);

    try {
      yield* _aiApiService.regenerateStream(sessionId);
    } catch (e) {
      state = state.copyWith(isStreaming: false, error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isStreaming: false);
    }
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 상태 초기화
  void reset() {
    state = AIGenerationState();
  }
}

final aiGenerationProvider =
    StateNotifierProvider<AIGenerationNotifier, AIGenerationState>((ref) {
      final aiApiService = ref.watch(aiApiServiceProvider);
      return AIGenerationNotifier(aiApiService);
    });

// 편의를 위한 Future Provider들
final originalUserInputProvider =
    FutureProvider.family<OriginalUserInputResponse, String>((ref, sessionId) {
      final aiApiService = ref.watch(aiApiServiceProvider);
      return aiApiService.getOriginalUserInput(sessionId);
    });

// 사용 예시를 위한 헬퍼 클래스
class AIApiHelper {
  static GenerateTextRequest createGenerateRequest({
    required String prompt,
    required String style,
    required String length,
    String? emotion,
    int? regenerationCount,
    String? sessionId,
    List<UploadedImage>? uploadedImages,
    String? diaryDate,
  }) {
    return GenerateTextRequest(
      prompt: prompt,
      style: style,
      length: length,
      emotion: emotion,
      regenerationCount: regenerationCount,
      sessionId: sessionId,
      uploadedImages: uploadedImages,
      diaryDate: diaryDate,
    );
  }

  static UploadedImage createUploadedImage({
    required String fileId,
    required String originalUrl,
    required String thumbnailUrl,
    required String mimeType,
    required int fileSize,
    required String filename,
  }) {
    return UploadedImage(
      fileId: fileId,
      originalUrl: originalUrl,
      thumbnailUrl: thumbnailUrl,
      mimeType: mimeType,
      fileSize: fileSize,
      filename: filename,
    );
  }
}
