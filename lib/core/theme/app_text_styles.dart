import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 새김 앱의 통합 텍스트 스타일
class AppTextStyles {
  // ========== Heading Styles ==========
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.25,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // ========== Body Styles ==========
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // ========== Special Styles ==========
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.5,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1.0,
    color: AppColors.textSecondary,
  );

  // ========== Dark Mode Styles ==========
  static TextStyle h1Dark = h1.copyWith(color: AppColors.darkTextPrimary);
  static TextStyle h2Dark = h2.copyWith(color: AppColors.darkTextPrimary);
  static TextStyle h3Dark = h3.copyWith(color: AppColors.darkTextPrimary);
  static TextStyle h4Dark = h4.copyWith(color: AppColors.darkTextPrimary);
  static TextStyle body1Dark = body1.copyWith(color: AppColors.darkTextPrimary);
  static TextStyle body2Dark = body2.copyWith(
    color: AppColors.darkTextSecondary,
  );
  static TextStyle captionDark = caption.copyWith(
    color: AppColors.darkTextSecondary,
  );
  static TextStyle labelDark = label.copyWith(color: AppColors.darkTextPrimary);
  static TextStyle overlineDark = overline.copyWith(
    color: AppColors.darkTextSecondary,
  );
}
