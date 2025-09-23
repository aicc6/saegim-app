import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';

/// 알림 API 응답 구조
@freezed
sealed class NotificationApiResponse with _$NotificationApiResponse {
  const factory NotificationApiResponse({
    required bool success,
    required String message,
    NotificationHistoryResponse? data,
    String? error,
  }) = _NotificationApiResponse;

  factory NotificationApiResponse.fromJson(Map<String, dynamic> json) {
    return NotificationApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null ? NotificationHistoryResponse.fromJson(json['data'] as Map<String, dynamic>) : null,
      error: json['error'] as String?,
    );
  }
}

/// 알림 항목 모델
@freezed
sealed class NotificationItem with _$NotificationItem {
  factory NotificationItem({
    required String id, // 서버에서 UUID 문자열로 옴
    required String title,
    required String message, // 서버의 'body' → 'message'
    @Default(false) bool isRead, // status는 'sent' 등의 값이므로 별도 처리 필요
    required String type, // 서버의 'notification_type' → 'type'
    required DateTime createdAt, // 서버의 'created_at' → 'createdAt'
    DateTime? readAt,
    Map<String, dynamic>? metadata, // 서버의 'fcm_response' → 'metadata'
  }) = _NotificationItem;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    // status 필드를 사용하여 읽음 상태 판단
    bool isReadValue = false;

    // 우선 is_read 필드가 있는지 확인
    if (json.containsKey('is_read')) {
      final isReadRaw = json['is_read'];
      if (isReadRaw is bool) {
        isReadValue = isReadRaw;
      } else if (isReadRaw is String) {
        isReadValue = isReadRaw.toLowerCase() == 'true' || isReadRaw == '1';
      } else if (isReadRaw is int) {
        isReadValue = isReadRaw == 1;
      }
    } else if (json.containsKey('status')) {
      // status 필드로 읽음 상태 판단
      final status = json['status'] as String?;
      isReadValue = status?.toLowerCase() == 'opened';
    }

    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['body'] as String,
      isRead: isReadValue,
      type: json['notification_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      metadata: json['fcm_response'] as Map<String, dynamic>?,
    );
  }
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

  factory NotificationHistoryResponse.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryResponse(
      notifications: (json['notifications'] as List)
          .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      unreadCount: json['unread_count'] as int,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}

/// 알림 요청 매개변수
@freezed
sealed class NotificationParams with _$NotificationParams {
  const factory NotificationParams({
    @Default(20) int limit,
    @Default(0) int offset,
  }) = _NotificationParams;

  factory NotificationParams.fromJson(Map<String, dynamic> json) {
    return NotificationParams(
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
    );
  }
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
