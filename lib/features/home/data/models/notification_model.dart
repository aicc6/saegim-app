import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

/// 알림 API 응답 구조
@freezed
sealed class NotificationApiResponse with _$NotificationApiResponse {
  const factory NotificationApiResponse({
    required bool success,
    required String message,
    NotificationHistoryResponse? data,
    String? error,
  }) = _NotificationApiResponse;

  factory NotificationApiResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationApiResponseFromJson(json);
}

/// 알림 항목 모델
@freezed
sealed class NotificationItem with _$NotificationItem {
  const factory NotificationItem({
    required String id, // 서버에서 UUID 문자열로 옴
    required String title,
    @JsonKey(name: 'body') required String message, // 서버의 'body' → 'message'
    @Default(false) bool isRead, // status는 'sent' 등의 값이므로 별도 처리 필요
    @JsonKey(name: 'notification_type') required String type, // 서버의 'notification_type' → 'type'
    @JsonKey(name: 'created_at') required DateTime createdAt, // 서버의 'created_at' → 'createdAt'
    @JsonKey(name: 'read_at') DateTime? readAt,
    @JsonKey(name: 'fcm_response') Map<String, dynamic>? metadata, // 서버의 'fcm_response' → 'metadata'
  }) = _NotificationItem;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemFromJson(json);
}

/// 알림 히스토리 응답 모델
@freezed
sealed class NotificationHistoryResponse with _$NotificationHistoryResponse {
  const factory NotificationHistoryResponse({
    required List<NotificationItem> notifications,
    required int total,
    required int unreadCount,
    @Default(false) bool hasMore,
  }) = _NotificationHistoryResponse;

  factory NotificationHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationHistoryResponseFromJson(json);
}

/// 알림 요청 매개변수
@freezed
sealed class NotificationParams with _$NotificationParams {
  const factory NotificationParams({
    @Default(20) int limit,
    @Default(0) int offset,
  }) = _NotificationParams;

  factory NotificationParams.fromJson(Map<String, dynamic> json) =>
      _$NotificationParamsFromJson(json);
}

/// 알림 타입 열거형
enum NotificationType {
  @JsonValue('diary')
  diary,
  @JsonValue('system')
  system,
  @JsonValue('reminder')
  reminder,
  @JsonValue('achievement')
  achievement,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.diary:
        return '다이어리';
      case NotificationType.system:
        return '시스템';
      case NotificationType.reminder:
        return '리마인더';
      case NotificationType.achievement:
        return '성취';
    }
  }

  String get iconName {
    switch (this) {
      case NotificationType.diary:
        return 'book';
      case NotificationType.system:
        return 'settings';
      case NotificationType.reminder:
        return 'alarm';
      case NotificationType.achievement:
        return 'trophy';
    }
  }
}
