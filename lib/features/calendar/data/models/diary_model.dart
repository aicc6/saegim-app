import 'package:json_annotation/json_annotation.dart';

part 'diary_model.g.dart';

/// 다이어리 엔트리 모델
@JsonSerializable()
class DiaryEntry {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'emotion')
  final String emotion;

  @JsonKey(name: 'emotion_emoji')
  final String emotionEmoji;

  @JsonKey(name: 'keywords')
  final List<String> keywords;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const DiaryEntry({
    required this.id,
    required this.userId,
    required this.content,
    required this.emotion,
    required this.emotionEmoji,
    required this.keywords,
    required this.createdAt,
    this.updatedAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DiaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$DiaryEntryToJson(this);

  /// 복사 메서드
  DiaryEntry copyWith({
    int? id,
    String? userId,
    String? content,
    String? emotion,
    String? emotionEmoji,
    List<String>? keywords,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      emotion: emotion ?? this.emotion,
      emotionEmoji: emotionEmoji ?? this.emotionEmoji,
      keywords: keywords ?? this.keywords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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
