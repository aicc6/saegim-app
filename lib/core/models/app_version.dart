/// 플랫폼 타입
enum PlatformType {
  ios('ios'),
  android('android');

  const PlatformType(this.value);
  final String value;

  factory PlatformType.fromString(String value) {
    return PlatformType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => PlatformType.android,
    );
  }
}

/// 앱 버전 정보
class AppVersionInfo {
  final String id;
  final String versionName;
  final PlatformType platform;
  final String? description;
  final bool isMandatory;
  final String filePath;
  final int? fileSize;
  final String fileName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? downloadUrl;

  const AppVersionInfo({
    required this.id,
    required this.versionName,
    required this.platform,
    this.description,
    required this.isMandatory,
    required this.filePath,
    this.fileSize,
    required this.fileName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.downloadUrl,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      id: json['id'] as String,
      versionName: json['version_name'] as String,
      platform: PlatformType.fromString(json['platform'] as String),
      description: json['description'] as String?,
      isMandatory: json['is_mandatory'] as bool? ?? false,
      filePath: json['file_path'] as String,
      fileSize: json['file_size'] as int?,
      fileName: json['file_name'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      downloadUrl: json['download_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version_name': versionName,
      'platform': platform.value,
      'description': description,
      'is_mandatory': isMandatory,
      'file_path': filePath,
      'file_size': fileSize,
      'file_name': fileName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'download_url': downloadUrl,
    };
  }
}

/// 앱 버전 체크 응답
class CheckAppVersionResponse {
  final bool hasUpdate;
  final bool isMandatory;
  final AppVersionInfo? latestVersion;
  final String? message;

  const CheckAppVersionResponse({
    required this.hasUpdate,
    required this.isMandatory,
    this.latestVersion,
    this.message,
  });

  factory CheckAppVersionResponse.fromJson(Map<String, dynamic> json) {
    return CheckAppVersionResponse(
      hasUpdate: json['has_update'] as bool,
      isMandatory: json['is_mandatory'] as bool? ?? false,
      latestVersion: json['latest_version'] != null
          ? AppVersionInfo.fromJson(
              json['latest_version'] as Map<String, dynamic>,
            )
          : null,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_update': hasUpdate,
      'is_mandatory': isMandatory,
      'latest_version': latestVersion?.toJson(),
      'message': message,
    };
  }
}
