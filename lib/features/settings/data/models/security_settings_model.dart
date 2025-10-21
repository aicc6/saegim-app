class SecuritySettingsModel {
  SecuritySettingsModel({
    required this.diaryLockEnabled,
    required this.calendarLockEnabled,
    required this.appLockEnabled,
    required this.useBiometrics,
    required this.hasPin,
  });

  final bool diaryLockEnabled;
  final bool calendarLockEnabled;
  final bool appLockEnabled;
  final bool useBiometrics;
  final bool hasPin;

  SecuritySettingsModel copyWith({
    bool? diaryLockEnabled,
    bool? calendarLockEnabled,
    bool? appLockEnabled,
    bool? useBiometrics,
    bool? hasPin,
  }) {
    return SecuritySettingsModel(
      diaryLockEnabled: diaryLockEnabled ?? this.diaryLockEnabled,
      calendarLockEnabled: calendarLockEnabled ?? this.calendarLockEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      hasPin: hasPin ?? this.hasPin,
    );
  }

  static SecuritySettingsModel initial() {
    return SecuritySettingsModel(
      diaryLockEnabled: false,
      calendarLockEnabled: false,
      appLockEnabled: false,
      useBiometrics: false,
      hasPin: false,
    );
  }
}
