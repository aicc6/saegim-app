import 'package:flutter/material.dart';
import 'package:saegim/core/theme/app_colors.dart';

/// BuildContext 확장으로 테마를 쉽게 사용
extension ThemeExtensions on BuildContext {
  // 현재 테마
  ThemeData get theme => Theme.of(this);

  // 현재 색상 스킴
  ColorScheme get colorScheme => theme.colorScheme;

  // 현재 텍스트 테마
  TextTheme get textTheme => theme.textTheme;

  // 다크모드 여부
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // Theme-aware 색상들
  Color get primaryBackground => isDarkMode
      ? AppColors.darkBackgroundPrimary
      : AppColors.backgroundPrimary;

  Color get secondaryBackground => isDarkMode
      ? AppColors.darkBackgroundSecondary
      : AppColors.backgroundSecondary;

  Color get primaryText =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get secondaryText =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get placeholderText =>
      isDarkMode ? AppColors.darkTextPlaceholder : AppColors.lightGray;

  Color get primaryInteractive => isDarkMode
      ? AppColors.darkInteractivePrimary
      : AppColors.interactivePrimary;

  Color get borderSubtle =>
      isDarkMode ? AppColors.darkBorderSubtle : AppColors.borderSubtle;

  Color get borderStrong =>
      isDarkMode ? AppColors.darkBorderStrong : AppColors.borderStrong;

  // 카드 배경색
  Color get cardBackground =>
      isDarkMode ? AppColors.darkBackgroundSecondary : Colors.white;

  // 입력 필드 배경색
  Color get inputBackground =>
      isDarkMode ? AppColors.darkBackgroundTertiary : Colors.white;

  // Scaffold 배경색
  Color get scaffoldBackground => theme.scaffoldBackgroundColor;

  // Divider 색상
  Color get dividerColor => theme.dividerColor;
}

/// Color 확장으로 투명도 조절 (deprecated withOpacity 대체)
extension ColorExtensions on Color {
  /// withOpacity 대신 withValues 사용 (Flutter 3.27+)
  Color withAlpha(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withValues(alpha: opacity);
  }
}
