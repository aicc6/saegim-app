// create_notifier.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:saegim/core/config/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 타입 정의
enum WritingStyle {
  poem('poem', '시'),
  shortStory('short_story', '단편글');

  const WritingStyle(this.value, this.label);
  final String value;
  final String label;
}

enum LengthOption {
  short('short', '단문'),
  medium('medium', '중문'),
  long('long', '장문');

  const LengthOption(this.value, this.label);
  final String value;
  final String label;
}

// AI 생성 결과 클래스
class AIGenerationResult {
  final String aiGeneratedText;
  final String aiEmotion;
  final double aiEmotionConfidence;
  final List<String> keywords;
  final int tokensUsed;
  final String sessionId;

  const AIGenerationResult({
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
}

// API 응답 클래스
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  const ApiResponse({required this.success, this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : null,
    );
  }
}

// API 에러 클래스
class APIError implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const APIError(this.message, {this.code, this.details});

  @override
  String toString() => 'APIError: $message';
}

// 설정 클래스들
class StyleOption {
  final WritingStyle value;
  final String label;
  final String displayName;

  const StyleOption({
    required this.value,
    required this.label,
    required this.displayName,
  });
}

class LengthConfig {
  final LengthOption value;
  final String label;
  final String displayName;

  const LengthConfig({
    required this.value,
    required this.label,
    required this.displayName,
  });
}

class CreateConfig {
  final List<StyleOption> styles;
  final List<LengthConfig> lengths;

  const CreateConfig({required this.styles, required this.lengths});
}

// 기본 설정
const CreateConfig defaultConfig = CreateConfig(
  styles: [
    StyleOption(value: WritingStyle.poem, label: '시', displayName: 'poem'),
    StyleOption(
      value: WritingStyle.shortStory,
      label: '단편글',
      displayName: 'prose',
    ),
  ],
  lengths: [
    LengthConfig(value: LengthOption.short, label: '단문', displayName: 'short'),
    LengthConfig(
      value: LengthOption.medium,
      label: '중문',
      displayName: 'medium',
    ),
    LengthConfig(value: LengthOption.long, label: '장문', displayName: 'long'),
  ],
);

// 생성 상태 클래스
class CreateState {
  final CreateConfig config;
  final String prompt;
  final String originalPrompt;
  final WritingStyle style;
  final LengthOption length;
  final String emotion;
  final bool isGenerating;
  final String? error;
  final String? generatedText;
  final List<String>? generatedKeywords;
  final String? sessionId;
  final bool wasJustGenerated;

  const CreateState({
    required this.config,
    required this.prompt,
    required this.originalPrompt,
    required this.style,
    required this.length,
    required this.emotion,
    required this.isGenerating,
    this.error,
    this.generatedText,
    this.generatedKeywords,
    this.sessionId,
    required this.wasJustGenerated,
  });

  CreateState copyWith({
    CreateConfig? config,
    String? prompt,
    String? originalPrompt,
    WritingStyle? style,
    LengthOption? length,
    String? emotion,
    bool? isGenerating,
    String? error,
    String? generatedText,
    List<String>? generatedKeywords,
    String? sessionId,
    bool? wasJustGenerated,
    bool clearError = false,
    bool clearGeneratedText = false,
  }) {
    return CreateState(
      config: config ?? this.config,
      prompt: prompt ?? this.prompt,
      originalPrompt: originalPrompt ?? this.originalPrompt,
      style: style ?? this.style,
      length: length ?? this.length,
      emotion: emotion ?? this.emotion,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
      generatedText: clearGeneratedText
          ? null
          : (generatedText ?? this.generatedText),
      generatedKeywords: clearGeneratedText
          ? null
          : (generatedKeywords ?? this.generatedKeywords),
      sessionId: clearGeneratedText ? null : (sessionId ?? this.sessionId),
      wasJustGenerated: wasJustGenerated ?? this.wasJustGenerated,
    );
  }

  String getStyleDisplayName(WritingStyle style) {
    final styleOption = config.styles.cast<StyleOption?>().firstWhere(
      (s) => s?.value == style,
      orElse: () => null,
    );
    return styleOption?.label ?? style.label;
  }

  String getLengthDisplayName(LengthOption length) {
    final lengthConfig = config.lengths.cast<LengthConfig?>().firstWhere(
      (l) => l?.value == length,
      orElse: () => null,
    );
    return lengthConfig?.label ?? length.label;
  }
}

// AI API 서비스 클래스
class AiApiService {
  static String get baseUrl => EnvironmentConfig.apiBaseUrl;

  /// 일반 POST 요청으로 텍스트 생성
  Future<AIGenerationResult> generateText({
    required String prompt,
    required WritingStyle style,
    required LengthOption length,
    String? emotion,
    int regenerationCount = 1,
  }) async {
    final jwt = await _getJwtToken();
    if (jwt == null || jwt.isEmpty) {
      throw const APIError('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }

    final uri = Uri.parse('$baseUrl/api/ai/generate');

    // 디버깅 로그
    print('API 요청 URL: $uri');
    print('JWT Token 존재: ${jwt.isNotEmpty}');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'prompt': prompt,
          'style': style.value,
          'length': length.value,
          'emotion': emotion ?? '',
          'regeneration_count': regenerationCount,
        }),
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        if (responseBody['success'] == true && responseBody['data'] != null) {
          return AIGenerationResult.fromJson(responseBody['data']);
        } else {
          throw APIError(responseBody['message'] ?? 'AI 텍스트 생성에 실패했습니다.');
        }
      } else {
        // 에러 응답 처리
        String errorMessage = '서버 오류: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (e) {
          errorMessage =
              '$errorMessage - ${response.reasonPhrase ?? 'Unknown error'}';
        }
        throw APIError(errorMessage);
      }
    } catch (e) {
      print('API 호출 오류: $e');
      if (e is APIError) rethrow;
      throw APIError('네트워크 오류: ${e.toString()}');
    }
  }

  /// 원본 사용자 입력 조회
  Future<String?> getOriginalUserInput(String sessionId) async {
    try {
      final jwt = await _getJwtToken();
      if (jwt == null || jwt.isEmpty) return null;

      final uri = Uri.parse('$baseUrl/api/ai/original-input/$sessionId');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
      );

      print('원본 입력 조회 - 상태 코드: ${response.statusCode}');
      print('원본 입력 조회 - 응답: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['original_input'];
        }
      }
      return null;
    } catch (e) {
      print('원본 입력 복구 실패: $e');
      return null;
    }
  }

  /// 재생성 (일반 POST 요청)
  Future<AIGenerationResult> regenerateText(String sessionId) async {
    final jwt = await _getJwtToken();
    if (jwt == null || jwt.isEmpty) {
      throw const APIError('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }

    final uri = Uri.parse('$baseUrl/api/ai/regenerate/$sessionId');

    print('재생성 API 요청 URL: $uri');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('재생성 응답 상태 코드: ${response.statusCode}');
      print('재생성 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        if (responseBody['success'] == true && responseBody['data'] != null) {
          return AIGenerationResult.fromJson(responseBody['data']);
        } else {
          throw APIError(responseBody['message'] ?? '재생성에 실패했습니다.');
        }
      } else {
        String errorMessage = '서버 오류: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (e) {
          errorMessage =
              '$errorMessage - ${response.reasonPhrase ?? 'Unknown error'}';
        }
        throw APIError(errorMessage);
      }
    } catch (e) {
      print('재생성 API 호출 오류: $e');
      if (e is APIError) rethrow;
      throw APIError('재생성 중 네트워크 오류: ${e.toString()}');
    }
  }

  /// 사용 로그 전송
  Future<void> sendUsageLog(Map<String, dynamic> body) async {
    try {
      final jwt = await _getJwtToken();
      if (jwt == null || jwt.isEmpty) return;

      final uri = Uri.parse('$baseUrl/api/ai/usage-log');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 400) {
        print('사용 로그 전송 실패: ${response.statusCode} - ${response.body}');
        throw APIError('사용 로그 전송 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('사용 로그 전송 오류: $e');
      // 로그 전송 실패는 치명적이지 않으므로 에러를 던지지 않음
    }
  }

  /// JWT 토큰 조회
  Future<String?> _getJwtToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      print('저장된 JWT 토큰 존재: ${token != null && token.isNotEmpty}');
      return token;
    } catch (e) {
      print('JWT 토큰 조회 실패: $e');
      return null;
    }
  }
}

// 생성 상태 Notifier
class CreateNotifier extends StateNotifier<CreateState> {
  final AiApiService _aiApiService = AiApiService();
  final Ref ref;

  CreateNotifier(this.ref)
    : super(
        const CreateState(
          config: defaultConfig,
          prompt: '',
          originalPrompt: '',
          style: WritingStyle.poem,
          length: LengthOption.short,
          emotion: '',
          isGenerating: false,
          wasJustGenerated: false,
        ),
      ) {
    _loadState();
  }

  // SharedPreferences에서 상태 로드
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final generatedText = prefs.getString('generatedText');
      final generatedKeywords = prefs.getStringList('generatedKeywords');
      final sessionId = prefs.getString('sessionId');

      if (!ref.mounted) return;
      if (generatedText != null ||
          generatedKeywords != null ||
          sessionId != null) {
        state = state.copyWith(
          generatedText: generatedText,
          generatedKeywords: generatedKeywords,
          sessionId: sessionId,
        );
      }
    } catch (e) {
      print('생성 상태 로드 실패: $e');
    }
  }

  // SharedPreferences에 상태 저장
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (state.generatedText != null) {
        await prefs.setString('generatedText', state.generatedText!);
      } else {
        await prefs.remove('generatedText');
      }

      if (state.generatedKeywords != null) {
        await prefs.setStringList(
          'generatedKeywords',
          state.generatedKeywords!,
        );
      } else {
        await prefs.remove('generatedKeywords');
      }

      if (state.sessionId != null) {
        await prefs.setString('sessionId', state.sessionId!);
      } else {
        await prefs.remove('sessionId');
      }
    } catch (e) {
      print('생성 상태 저장 실패: $e');
    }
  }

  // 기본 액션들
  void setPrompt(String prompt) {
    state = state.copyWith(prompt: prompt);
  }

  void setStyle(WritingStyle style) {
    state = state.copyWith(style: style);
  }

  void setLength(LengthOption length) {
    state = state.copyWith(length: length);
  }

  void setEmotion(String emotion) {
    state = state.copyWith(emotion: emotion);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearGeneratedText() {
    state = state.copyWith(clearGeneratedText: true);
    _saveState();
  }

  // AI 텍스트 생성
  Future<void> generateText({String? emotion}) async {
    if (state.prompt.trim().isEmpty) return;

    if (!ref.mounted) return;
    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      print('텍스트 생성 시작 - 프롬프트: ${state.prompt}');

      final result = await _aiApiService.generateText(
        prompt: state.prompt.trim(),
        style: state.style,
        length: state.length,
        emotion: emotion ?? state.emotion,
        regenerationCount: 1,
      );

      if (!ref.mounted) return;
      state = state.copyWith(
        generatedText: result.aiGeneratedText,
        generatedKeywords: result.keywords,
        sessionId: result.sessionId,
        originalPrompt: state.prompt,
        isGenerating: false,
        wasJustGenerated: true,
      );

      await _saveState();

      print('AI 텍스트 생성 성공 - 세션 ID: ${result.sessionId}');
      print('생성된 텍스트 길이: ${result.aiGeneratedText.length}');
    } catch (e) {
      final errorMessage = e is APIError ? e.message : '텍스트 생성 중 오류가 발생했습니다.';
      if (!ref.mounted) return;
      state = state.copyWith(error: errorMessage, isGenerating: false);

      print('AI 텍스트 생성 실패: $e');
    }
  }

  // 재생성
  Future<void> regenerateText() async {
    if (state.sessionId?.isEmpty ?? true) {
      if (!ref.mounted) return;
      state = state.copyWith(error: '재생성할 세션이 없습니다.');
      return;
    }

    if (!ref.mounted) return;
    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      print('텍스트 재생성 시작 - 세션 ID: ${state.sessionId}');

      final result = await _aiApiService.regenerateText(state.sessionId!);

      if (!ref.mounted) return;
      state = state.copyWith(
        generatedText: result.aiGeneratedText,
        generatedKeywords: result.keywords,
        sessionId: result.sessionId, // 새로운 세션 ID일 수 있음
        isGenerating: false,
        wasJustGenerated: true,
      );

      await _saveState();

      print('AI 텍스트 재생성 성공 - 새 세션 ID: ${result.sessionId}');
    } catch (e) {
      final errorMessage = e is APIError ? e.message : '텍스트 재생성 중 오류가 발생했습니다.';
      if (!ref.mounted) return;
      state = state.copyWith(error: errorMessage, isGenerating: false);

      print('AI 텍스트 재생성 실패: $e');
    }
  }

  void markAsProcessed() {
    state = state.copyWith(wasJustGenerated: false);
  }

  // 세션ID로 원본 입력 복구
  Future<void> restoreOriginalInput() async {
    if (state.sessionId?.isEmpty ?? true) return;

    try {
      final originalInput = await _aiApiService.getOriginalUserInput(
        state.sessionId!,
      );
      if (!ref.mounted) return;
      if (originalInput != null) {
        state = state.copyWith(originalPrompt: originalInput);
      }
    } catch (e) {
      print('원본 입력 복구 실패: $e');
    }
  }

  void resetToDefaults() {
    if (!ref.mounted) return;
    state = const CreateState(
      config: defaultConfig,
      prompt: '',
      originalPrompt: '',
      style: WritingStyle.poem,
      length: LengthOption.short,
      emotion: '',
      isGenerating: false,
      wasJustGenerated: false,
    );
    _saveState();
  }
}

// Provider 정의
final createProvider = StateNotifierProvider<CreateNotifier, CreateState>(
  (ref) => CreateNotifier(ref),
);
