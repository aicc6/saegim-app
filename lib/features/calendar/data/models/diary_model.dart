import 'package:json_annotation/json_annotation.dart';
import 'package:saegim/features/home/data/models/diary_category_model.dart';

part 'diary_model.g.dart';

/// 다이어리 엔트리 모델
@JsonSerializable()
class DiaryEntry {
  static const _unset = Object();
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'ai_generated_text')
  final String? aiGeneratedText;

  @JsonKey(name: 'user_emotion')
  final String? emotion;

  @JsonKey(name: 'ai_emotion')
  final String? aiEmotion;

  @JsonKey(name: 'keywords')
  final List<String> keywords;

  @JsonKey(name: 'diary_date', toJson: _diaryDateToJson)
  final DateTime? diaryDate;

  static String? _diaryDateToJson(DateTime? date) => date?.toIso8601String();

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'is_public')
  final bool? isPublic;

  @JsonKey(name: 'images', fromJson: _imagesFromJson)
  final List<String> images;

  @JsonKey(
    name: 'category',
    fromJson: _categoryFromJson,
    toJson: _categoryToJson,
  )
  final DiaryCategory? category;

  static List<String> _imagesFromJson(dynamic json) {
    if (json == null) return [];
    if (json is! List) return [];

    return json
        .map((item) {
          // item이 String이면 그대로 사용
          if (item is String) return item;
          // item이 Map이면 file_path 추출
          if (item is Map) {
            return (item['file_path'] ?? item['url'] ?? '') as String;
          }
          return '';
        })
        .where((url) => url.isNotEmpty)
        .toList();
  }

  const DiaryEntry({
    required this.id,
    this.title,
    required this.content,
    this.aiGeneratedText,
    this.emotion,
    this.aiEmotion,
    required this.keywords,
    this.diaryDate,
    required this.createdAt,
    this.isPublic,
    this.images = const [],
    this.category,
  });

  // 감정 이모티콘 매핑 (5가지 기본 감정) - AI 분석 감정 우선
  String get emotionEmoji {
    final emotionValue = aiEmotion ?? emotion ?? '평온';
    switch (emotionValue.toLowerCase()) {
      case '행복':
      case 'happy':
        return '😊';
      case '평온':
      case 'peaceful':
        return '😌';
      case '불안':
      case 'unrest':
        return '😰';
      case '분노':
      case 'angry':
        return '😠';
      case '슬픔':
      case 'sad':
        return '😢';
      default:
        return '😌'; // 기본값: 평온
    }
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DiaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$DiaryEntryToJson(this);

  /// 복사 메서드
  DiaryEntry copyWith({
    String? id,
    String? title,
    String? content,
    String? aiGeneratedText,
    String? emotion,
    String? aiEmotion,
    List<String>? keywords,
    DateTime? diaryDate,
    DateTime? createdAt,
    bool? isPublic,
    List<String>? images,
    Object? category = _unset,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      aiGeneratedText: aiGeneratedText ?? this.aiGeneratedText,
      emotion: emotion ?? this.emotion,
      aiEmotion: aiEmotion ?? this.aiEmotion,
      keywords: keywords ?? this.keywords,
      diaryDate: diaryDate ?? this.diaryDate,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      images: images ?? this.images,
      category: category == _unset ? this.category : category as DiaryCategory?,
    );
  }

  static DiaryCategory? _categoryFromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) {
      final id = json['id'];
      final name = json['name'];
      if (id is String && name is String) {
        return DiaryCategory.fromApiJson(json);
      }
    }
    return null;
  }

  static Map<String, dynamic>? _categoryToJson(DiaryCategory? category) {
    return category?.toApiJson();
  }
}

/// 감정 통계 모델
@JsonSerializable()
class EmotionStatistics {
  @JsonKey(name: 'emotion')
  final String emotion;

  @JsonKey(name: 'emoji')
  final String emoji;

  @JsonKey(name: 'count')
  final int count;

  @JsonKey(name: 'percentage')
  final double percentage;

  const EmotionStatistics({
    required this.emotion,
    required this.emoji,
    required this.count,
    required this.percentage,
  });

  factory EmotionStatistics.fromJson(Map<String, dynamic> json) =>
      _$EmotionStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$EmotionStatisticsToJson(this);
}

/// 키워드 통계 모델
@JsonSerializable()
class KeywordStatistics {
  @JsonKey(name: 'keyword')
  final String keyword;

  @JsonKey(name: 'count')
  final int count;

  @JsonKey(name: 'percentage')
  final double percentage;

  const KeywordStatistics({
    required this.keyword,
    required this.count,
    required this.percentage,
  });

  factory KeywordStatistics.fromJson(Map<String, dynamic> json) =>
      _$KeywordStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$KeywordStatisticsToJson(this);
}

/// 월간 통계 응답 모델
@JsonSerializable()
class MonthlyStatisticsResponse {
  @JsonKey(name: 'emotions')
  final List<EmotionStatistics> emotions;

  @JsonKey(name: 'keywords')
  final List<KeywordStatistics> keywords;

  @JsonKey(name: 'total_entries')
  final int totalEntries;

  @JsonKey(name: 'month')
  final int month;

  @JsonKey(name: 'year')
  final int year;

  const MonthlyStatisticsResponse({
    required this.emotions,
    required this.keywords,
    required this.totalEntries,
    required this.month,
    required this.year,
  });

  factory MonthlyStatisticsResponse.fromJson(Map<String, dynamic> json) =>
      _$MonthlyStatisticsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MonthlyStatisticsResponseToJson(this);
}

/// 날짜별 다이어리 응답 모델
@JsonSerializable()
class DailyDiariesResponse {
  @JsonKey(name: 'diaries')
  final List<DiaryEntry> diaries;

  @JsonKey(name: 'date')
  final DateTime date;

  const DailyDiariesResponse({required this.diaries, required this.date});

  factory DailyDiariesResponse.fromJson(Map<String, dynamic> json) =>
      _$DailyDiariesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DailyDiariesResponseToJson(this);
}
