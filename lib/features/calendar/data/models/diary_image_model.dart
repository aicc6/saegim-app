import 'package:json_annotation/json_annotation.dart';

part 'diary_image_model.g.dart';

/// 다이어리 이미지 모델
@JsonSerializable(fieldRename: FieldRename.snake)
class DiaryImage {
  final String? id;
  @JsonKey(name: 'diary_id')
  final String? diaryId;
  @JsonKey(name: 'file_path')
  final String? filePath;
  @JsonKey(name: 'original_name')
  final String? originalName;
  @JsonKey(name: 'file_size')
  final int? fileSize;
  @JsonKey(name: 'mime_type')
  final String? mimeType;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  DiaryImage({
    this.id,
    this.diaryId,
    this.filePath,
    this.originalName,
    this.fileSize,
    this.mimeType,
    this.createdAt,
    this.updatedAt,
  });

  factory DiaryImage.fromJson(Map<String, dynamic> json) =>
      _$DiaryImageFromJson(json);

  Map<String, dynamic> toJson() => _$DiaryImageToJson(this);

  /// 전체 이미지 URL 반환
  String get fullImageUrl {
    final path = filePath;
    if (path == null || path.isEmpty) {
      return ''; // 빈 경로인 경우 빈 문자열 반환
    }

    // 이미 완전한 URL인 경우 그대로 반환
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // 상대 경로인 경우 베이스 URL과 결합
    const baseUrl = 'https://saegim-api.aicc-project.com';
    return path.startsWith('/') ? '$baseUrl$path' : '$baseUrl/$path';
  }
}

/// 다이어리 이미지 목록 응답
@JsonSerializable()
class DiaryImagesResponse {
  final List<DiaryImage> images;
  final int total;

  DiaryImagesResponse({required this.images, required this.total});

  factory DiaryImagesResponse.fromJson(Map<String, dynamic> json) =>
      _$DiaryImagesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DiaryImagesResponseToJson(this);
}
