// 알림 설정 모델
class NotificationSettingsModel {
  final bool pushEnabled;
  final bool diaryReminderEnabled;
  final String? diaryReminderTime;
  final bool reportNotificationEnabled;
  final bool aiProcessingNotificationEnabled;
  final bool commentNotificationEnabled;
  final bool likeNotificationEnabled;

  const NotificationSettingsModel({
    this.pushEnabled = true,
    this.diaryReminderEnabled = true,
    this.diaryReminderTime,
    this.reportNotificationEnabled = true,
    this.aiProcessingNotificationEnabled = true,
    this.commentNotificationEnabled = true,
    this.likeNotificationEnabled = true,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      pushEnabled: json['push_enabled'] ?? true,
      diaryReminderEnabled: json['diary_reminder_enabled'] ?? true,
      diaryReminderTime: json['diary_reminder_time'],
      reportNotificationEnabled: json['report_notification_enabled'] ?? true,
      aiProcessingNotificationEnabled: json['ai_processing_notification_enabled'] ?? true,
      commentNotificationEnabled: json['comment_notification_enabled'] ?? true,
      likeNotificationEnabled: json['like_notification_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'diary_reminder_enabled': diaryReminderEnabled,
      'diary_reminder_time': diaryReminderTime,
      'report_notification_enabled': reportNotificationEnabled,
      'ai_processing_notification_enabled': aiProcessingNotificationEnabled,
      'comment_notification_enabled': commentNotificationEnabled,
      'like_notification_enabled': likeNotificationEnabled,
    };
  }
}

// 알림 설정 업데이트 요청 모델
class NotificationSettingsUpdateRequest {
  final bool? pushEnabled;
  final bool? diaryReminderEnabled;
  final String? diaryReminderTime;
  final bool? reportNotificationEnabled;
  final bool? aiProcessingNotificationEnabled;
  final bool? commentNotificationEnabled;
  final bool? likeNotificationEnabled;

  const NotificationSettingsUpdateRequest({
    this.pushEnabled,
    this.diaryReminderEnabled,
    this.diaryReminderTime,
    this.reportNotificationEnabled,
    this.aiProcessingNotificationEnabled,
    this.commentNotificationEnabled,
    this.likeNotificationEnabled,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (pushEnabled != null) data['push_enabled'] = pushEnabled;
    if (diaryReminderEnabled != null) data['diary_reminder_enabled'] = diaryReminderEnabled;
    if (diaryReminderTime != null) data['diary_reminder_time'] = diaryReminderTime;
    if (reportNotificationEnabled != null) data['report_notification_enabled'] = reportNotificationEnabled;
    if (aiProcessingNotificationEnabled != null) data['ai_processing_notification_enabled'] = aiProcessingNotificationEnabled;
    if (commentNotificationEnabled != null) data['comment_notification_enabled'] = commentNotificationEnabled;
    if (likeNotificationEnabled != null) data['like_notification_enabled'] = likeNotificationEnabled;
    
    return data;
  }
}