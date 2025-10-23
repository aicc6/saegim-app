// create_notifier.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:saegim/core/config/environment.dart';
import 'package:saegim/core/services/auth_storage_service.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/features/calendar/data/services/diary_api_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';
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
  final List<String> generationHistory;
  final int currentHistoryIndex;
  final String? handwritingImageUrl; // 손글씨 이미지 URL

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
    this.generationHistory = const [],
    this.currentHistoryIndex = 0,
    this.handwritingImageUrl,
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
    List<String>? generationHistory,
    int? currentHistoryIndex,
    String? handwritingImageUrl,
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
      generationHistory: generationHistory ?? this.generationHistory,
      currentHistoryIndex: currentHistoryIndex ?? this.currentHistoryIndex,
      handwritingImageUrl: handwritingImageUrl ?? this.handwritingImageUrl,
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

    final uri = Uri.parse('$baseUrl/api/ai/generate/stream');

    final requestBody = {
      'prompt': prompt,
      'style': style.value,
      'length': length.value,
      'emotion': emotion ?? '',
      'regeneration_count': regenerationCount,
    };

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        },
        body: jsonEncode(requestBody),
      );

      print('AI 생성 API 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        // SSE 응답 파싱
        final lines = response.body.split('\n');
        String accumulatedText = '';
        String? sessionId;
        String? aiEmotion;
        double aiEmotionConfidence = 0.0;
        List<String> keywords = [];

        for (final line in lines) {
          final trimmedLine = line.trim();

          // data: 접두사가 있는 줄만 처리
          if (trimmedLine.startsWith('data:')) {
            try {
              // data: 제거하고 JSON 파싱
              final jsonStr = trimmedLine.substring(5).trim();
              if (jsonStr.isNotEmpty) {
                final Map<String, dynamic> data = jsonDecode(jsonStr);

                // type에 따른 처리
                switch (data['type']) {
                  case 'start':
                    sessionId = data['session_id'];
                    break;
                  case 'content':
                    accumulatedText = data['accumulated'] ?? accumulatedText;
                    break;
                  case 'complete':
                    accumulatedText = data['generated_text'] ?? accumulatedText;

                    // AI 분석 emotion 정보 추출
                    if (data['emotion'] != null && data['emotion'] != '') {
                      aiEmotion = data['emotion'];
                    }

                    if (data['keywords'] != null) {
                      keywords = List<String>.from(data['keywords']);
                    }
                    break;
                }
              }
            } catch (e) {
              // JSON 파싱 실패 시 해당 줄은 무시
            }
          }
        }

        // 누적된 텍스트가 있으면 결과 반환
        if (accumulatedText.isNotEmpty) {
          return AIGenerationResult(
            aiGeneratedText: accumulatedText,
            aiEmotion: aiEmotion ?? emotion ?? '',
            aiEmotionConfidence: aiEmotionConfidence,
            keywords: keywords,
            tokensUsed: accumulatedText.length, // 추정값
            sessionId: sessionId ?? '',
          );
        } else {
          throw const APIError('AI 텍스트 생성에 실패했습니다. 응답이 비어있습니다.');
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['original_input'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 스트리밍 재생성 (백엔드 API 스펙에 맞춤)
  Future<AIGenerationResult> regenerateStream(String sessionId) async {
    final jwt = await _getJwtToken();
    if (jwt == null || jwt.isEmpty) {
      throw const APIError('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }

    final uri = Uri.parse('$baseUrl/api/ai/regenerate/$sessionId/stream');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        },
      );

      print('AI 재생성 API 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        // SSE 응답 파싱
        final lines = response.body.split('\n');
        String accumulatedText = '';
        String? newSessionId;
        String? aiEmotion;
        double aiEmotionConfidence = 0.0;
        List<String> keywords = [];

        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.startsWith('data:')) {
            try {
              final jsonStr = trimmedLine.substring(5).trim();
              if (jsonStr.isNotEmpty) {
                final Map<String, dynamic> data = jsonDecode(jsonStr);

                switch (data['type']) {
                  case 'start':
                    newSessionId = data['session_id'];
                    break;
                  case 'content':
                    accumulatedText = data['accumulated'] ?? accumulatedText;
                    break;
                  case 'complete':
                    accumulatedText = data['generated_text'] ?? accumulatedText;

                    // AI 분석 emotion 정보 추출
                    if (data['emotion'] != null && data['emotion'] != '') {
                      aiEmotion = data['emotion'];
                    }

                    if (data['keywords'] != null) {
                      keywords = List<String>.from(data['keywords']);
                    }
                    break;
                }
              }
            } catch (e) {
              // JSON 파싱 실패 시 해당 줄은 무시
            }
          }
        }

        if (accumulatedText.isNotEmpty) {
          return AIGenerationResult(
            aiGeneratedText: accumulatedText,
            aiEmotion: aiEmotion ?? '',
            aiEmotionConfidence: aiEmotionConfidence,
            keywords: keywords,
            tokensUsed: accumulatedText.length,
            sessionId: newSessionId ?? sessionId,
          );
        } else {
          throw const APIError('재생성된 텍스트가 비어있습니다.');
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
      if (e is APIError) rethrow;
      throw APIError('스트리밍 재생성 중 네트워크 오류: ${e.toString()}');
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

  // SharedPreferences에서 상태 로드 (사용자별)
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await AuthStorageService.instance.getUserId();

      // 사용자별 키 생성 (userId가 null이면 기본 키 사용)
      final userKey = userId ?? 'default';
      final generatedText = prefs.getString('generatedText_$userKey');
      final generatedKeywords = prefs.getStringList(
        'generatedKeywords_$userKey',
      );
      final sessionId = prefs.getString('sessionId_$userKey');

      if (!mounted) return;
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
      // 상태 로드 실패 시 무시
    }
  }

  // SharedPreferences에 상태 저장 (사용자별)
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await AuthStorageService.instance.getUserId();

      // 사용자별 키 생성 (userId가 null이면 기본 키 사용)
      final userKey = userId ?? 'default';

      if (state.generatedText != null) {
        await prefs.setString('generatedText_$userKey', state.generatedText!);
      } else {
        await prefs.remove('generatedText_$userKey');
      }

      if (state.generatedKeywords != null) {
        await prefs.setStringList(
          'generatedKeywords_$userKey',
          state.generatedKeywords!,
        );
      } else {
        await prefs.remove('generatedKeywords_$userKey');
      }

      if (state.sessionId != null) {
        await prefs.setString('sessionId_$userKey', state.sessionId!);
      } else {
        await prefs.remove('sessionId_$userKey');
      }
    } catch (e) {
      // 상태 저장 실패 시 무시
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
    state = state.copyWith(
      clearGeneratedText: true,
      generationHistory: const [],
      currentHistoryIndex: 0,
    );
    _saveState();
  }

  // AI 텍스트 생성
  Future<void> generateText({String? emotion}) async {
    if (state.prompt.trim().isEmpty) return;

    if (!mounted) return;
    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      final result = await _aiApiService.generateText(
        prompt: state.prompt.trim(),
        style: state.style,
        length: state.length,
        emotion: emotion ?? state.emotion,
        regenerationCount: 1,
      );

      if (!mounted) return;

      // 첫 번째 생성이면 히스토리에 추가
      final newHistory = state.generationHistory.isEmpty
          ? [result.aiGeneratedText]
          : [...state.generationHistory, result.aiGeneratedText];

      state = state.copyWith(
        generatedText: result.aiGeneratedText,
        generatedKeywords: result.keywords,
        sessionId: result.sessionId,
        originalPrompt: state.prompt,
        emotion: result.aiEmotion.isNotEmpty ? result.aiEmotion : state.emotion,
        isGenerating: false,
        wasJustGenerated: true,
        generationHistory: newHistory,
        currentHistoryIndex: newHistory.length - 1,
      );

      await _saveState();
    } catch (e) {
      final errorMessage = e is APIError ? e.message : '텍스트 생성 중 오류가 발생했습니다.';
      if (!mounted) return;
      state = state.copyWith(error: errorMessage, isGenerating: false);
    }
  }

  // 재생성
  Future<void> regenerateText() async {
    if (state.sessionId?.isEmpty ?? true) {
      if (!mounted) return;
      state = state.copyWith(error: '재생성할 세션이 없습니다.');
      return;
    }

    if (!mounted) return;
    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      final result = await _aiApiService.regenerateStream(state.sessionId!);

      if (!mounted) return;

      // 재생성 시 히스토리에 추가 (최대 5개)
      final newHistory = [...state.generationHistory, result.aiGeneratedText];
      final limitedHistory = newHistory.length > 5
          ? newHistory.sublist(newHistory.length - 5)
          : newHistory;

      state = state.copyWith(
        generatedText: result.aiGeneratedText,
        generatedKeywords: result.keywords,
        sessionId: result.sessionId, // 새로운 세션 ID일 수 있음
        emotion: result.aiEmotion.isNotEmpty ? result.aiEmotion : state.emotion,
        isGenerating: false,
        wasJustGenerated: true,
        generationHistory: limitedHistory,
        currentHistoryIndex: limitedHistory.length - 1,
      );

      await _saveState();
    } catch (e) {
      final errorMessage = e is APIError ? e.message : '텍스트 재생성 중 오류가 발생했습니다.';
      if (!mounted) return;
      state = state.copyWith(error: errorMessage, isGenerating: false);
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
      if (!mounted) return;
      if (originalInput != null) {
        state = state.copyWith(originalPrompt: originalInput);
      }
    } catch (e) {
      // 원본 입력 복구 실패 시 무시
    }
  }

  // 히스토리 네비게이션
  void goToPreviousHistory() {
    if (!mounted) return;
    if (state.generationHistory.isNotEmpty && state.currentHistoryIndex > 0) {
      final newIndex = state.currentHistoryIndex - 1;
      final historyText = state.generationHistory[newIndex];
      state = state.copyWith(
        generatedText: historyText,
        currentHistoryIndex: newIndex,
      );
    }
  }

  void goToNextHistory() {
    if (!mounted) return;
    if (state.generationHistory.isNotEmpty &&
        state.currentHistoryIndex < state.generationHistory.length - 1) {
      final newIndex = state.currentHistoryIndex + 1;
      final historyText = state.generationHistory[newIndex];
      state = state.copyWith(
        generatedText: historyText,
        currentHistoryIndex: newIndex,
      );
    }
  }

  // 재생성 가능 여부 확인
  bool get canRegenerate => state.generationHistory.length < 5;

  void resetToDefaults() {
    if (!mounted) return;
    state = const CreateState(
      config: defaultConfig,
      prompt: '',
      originalPrompt: '',
      style: WritingStyle.poem,
      length: LengthOption.short,
      emotion: '',
      isGenerating: false,
      wasJustGenerated: false,
      generationHistory: [],
      currentHistoryIndex: 0,
    );
    _saveState(); // 현재 사용자의 데이터만 삭제됨
  }

  // 로그인 시 사용자 데이터 복원을 위한 public 메서드
  Future<void> loadUserData() async {
    await _loadState();
  }

  // 생성된 글을 다이어리에 저장
  Future<String?> saveToDiary({String? title, String? diaryDate}) async {
    if (state.generatedText?.isEmpty ?? true) {
      if (!mounted) return null;
      state = state.copyWith(error: '저장할 글이 없습니다.');
      return null;
    }

    try {
      final diaryApiService = DiaryApiService.instance;

      // 날짜 형식 변환 (YYYY-MM-DD)
      String? formattedDate;
      if (diaryDate != null) {
        try {
          final date = DateTime.parse(diaryDate);
          formattedDate =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } catch (e) {
          // 날짜 파싱 실패 시 현재 날짜 사용
          final now = DateTime.now();
          formattedDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        }
      } else {
        // 날짜가 제공되지 않으면 현재 날짜 사용
        final now = DateTime.now();
        formattedDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      }

      final userInputText = state.originalPrompt.isNotEmpty
          ? state.originalPrompt
          : state.prompt;

      AppLogger.info(
        'Saving to diary - userInput: "${userInputText.length} chars", aiGenerated: "${state.generatedText!.length} chars"',
        'CreateNotifier',
      );

      final result = await diaryApiService.createDiary(
        content: userInputText, // 사용자 입력 텍스트
        title: title ?? 'AI 생성 글',
        aiGeneratedText: state.generatedText!, // AI 생성 텍스트
        userEmotion: state.emotion,
        aiEmotion: state.emotion,
        keywords: state.generatedKeywords,
        diaryDate: formattedDate,
      );

      if (result != null) {
        // 저장 성공 시 생성된 글 상태 초기화
        clearGeneratedText();
        return result.id;
      } else {
        if (!mounted) return null;
        state = state.copyWith(error: '다이어리 저장에 실패했습니다.');
        return null;
      }
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(error: '다이어리 저장 중 오류가 발생했습니다: ${e.toString()}');
      return null;
    }
  }

  /// 임시 다이어리 엔트리 생성 (저장하지 않고)
  DiaryEntry? createTempDiaryEntry({
    String? title,
    String? diaryDate,
    String? aiEmotion,
    String? userEmotion,
    String? ocrText, // OCR로 추출된 원본 텍스트
  }) {
    if (state.generatedText?.isEmpty ?? true) {
      return null;
    }

    try {
      // 디버깅을 위한 로그 추가
      AppLogger.info(
        'Creating temp diary entry - userEmotion: $userEmotion, aiEmotion: $aiEmotion, state.emotion: ${state.emotion}, handwritingImageUrl: ${state.handwritingImageUrl}',
        'CreateNotifier',
      );

      // 날짜 형식 변환 (YYYY-MM-DD)
      String? formattedDate;
      if (diaryDate != null) {
        try {
          final date = DateTime.parse(diaryDate);
          formattedDate =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } catch (e) {
          // 날짜 파싱 실패 시 현재 날짜 사용
          final now = DateTime.now();
          formattedDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        }
      } else {
        // 날짜가 제공되지 않으면 현재 날짜 사용
        final now = DateTime.now();
        formattedDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      }

      // 감정 설정 로직
      final finalUserEmotion = userEmotion ?? state.emotion;
      final finalAiEmotion = aiEmotion ?? state.emotion;

      AppLogger.info(
        'Final emotions - user: $finalUserEmotion, ai: $finalAiEmotion',
        'CreateNotifier',
      );

      // 이미지 URL 처리 로직 개선
      List<String> imageUrls = [];
      if (state.handwritingImageUrl != null &&
          state.handwritingImageUrl!.isNotEmpty) {
        imageUrls.add(state.handwritingImageUrl!);
        AppLogger.info(
          'Added handwriting image URL to temp entry: ${state.handwritingImageUrl}',
          'CreateNotifier',
        );
      } else {
        AppLogger.warning(
          'No handwriting image URL available for temp entry',
          'CreateNotifier',
        );
      }

      // 임시 다이어리 엔트리 생성
      final entry = DiaryEntry(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        title: title ?? '손글씨 다이어리',
        content: ocrText ?? state.generatedText!, // OCR 텍스트 우선, 없으면 AI 생성 텍스트
        aiGeneratedText: state.generatedText!,
        emotion: finalUserEmotion, // 사용자가 선택한 감정 우선
        aiEmotion: finalAiEmotion,
        keywords: state.generatedKeywords ?? [],
        createdAt: DateTime.now(),
        diaryDate: DateTime.parse(formattedDate),
        // 손글씨 이미지 URL을 images 리스트에 추가
        images: imageUrls,
      );

      AppLogger.info(
        'Temp diary entry created - content: "${entry.content.length} chars", aiGeneratedText: "${entry.aiGeneratedText?.length ?? 0} chars"',
        'CreateNotifier',
      );

      AppLogger.info(
        'Temp diary entry created - emotion: ${entry.emotion}, aiEmotion: ${entry.aiEmotion}, images: ${entry.images}',
        'CreateNotifier',
      );

      return entry;
    } catch (e) {
      AppLogger.error(
        'Failed to create temp diary entry',
        tag: 'CreateNotifier',
        error: e,
      );
      return null;
    }
  }
}

// Provider 정의
final createProvider = StateNotifierProvider<CreateNotifier, CreateState>(
  (ref) => CreateNotifier(ref),
);
