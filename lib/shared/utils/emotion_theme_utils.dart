import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 감정 기반 테마 유틸리티
///
/// 감정별로 다른 시각적 스타일을 제공합니다.
class EmotionThemeUtils {
  EmotionThemeUtils._(); // 인스턴스 생성 방지

  /// 감정별 카드 데코레이션
  ///
  /// [emotion]: 감정 타입 (happy, sad, angry, peaceful, worried)
  /// [isDark]: 다크 모드 여부
  static BoxDecoration getEmotionCardDecoration(
    String emotion, {
    bool isDark = false,
  }) {
    final color = AppColors.getEmotionColor(emotion, isDark: isDark);
    final backgroundColor = AppColors.getEmotionBackgroundColor(emotion);

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.3), width: 2),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// 감정별 버튼 스타일
  ///
  /// [context]: BuildContext (테마 접근용)
  /// [emotion]: 감정 타입
  /// [isDark]: 다크 모드 여부
  static ButtonStyle getEmotionButtonStyle(
    BuildContext context,
    String emotion, {
    bool isDark = false,
  }) {
    final color = AppColors.getEmotionColor(emotion, isDark: isDark);
    final backgroundColor = AppColors.getEmotionBackgroundColor(emotion);

    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
    );
  }

  /// 감정별 칩 테마
  ///
  /// [context]: BuildContext
  /// [emotion]: 감정 타입
  /// [isDark]: 다크 모드 여부
  static ChipThemeData getEmotionChipTheme(
    BuildContext context,
    String emotion, {
    bool isDark = false,
  }) {
    final color = AppColors.getEmotionColor(emotion, isDark: isDark);
    final backgroundColor = AppColors.getEmotionBackgroundColor(emotion);

    return ChipThemeData(
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  /// 감정별 그라디언트
  ///
  /// [emotion]: 감정 타입
  /// [isDark]: 다크 모드 여부
  static LinearGradient getEmotionGradient(
    String emotion, {
    bool isDark = false,
  }) {
    final color = AppColors.getEmotionColor(emotion, isDark: isDark);
    final backgroundColor = AppColors.getEmotionBackgroundColor(emotion);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [backgroundColor, color.withOpacity(0.1)],
      stops: const [0.0, 1.0],
    );
  }

  /// 감정별 아이콘 색상
  ///
  /// [emotion]: 감정 타입
  /// [isDark]: 다크 모드 여부
  static Color getEmotionIconColor(String emotion, {bool isDark = false}) {
    return AppColors.getEmotionColor(emotion, isDark: isDark);
  }

  /// 감정별 텍스트 색상
  ///
  /// [emotion]: 감정 타입
  /// [isDark]: 다크 모드 여부
  static Color getEmotionTextColor(String emotion, {bool isDark = false}) {
    return AppColors.getEmotionColor(emotion, isDark: isDark);
  }

  /// 감정별 구분선 색상
  ///
  /// [emotion]: 감정 타입
  /// [isDark]: 다크 모드 여부
  static Color getEmotionDividerColor(String emotion, {bool isDark = false}) {
    final color = AppColors.getEmotionColor(emotion, isDark: isDark);
    return color.withOpacity(0.2);
  }

  /// 감정별 배지 데코레이션
  ///
  /// [emotion]: 감정 타입
  /// [isDark]: 다크 모드 여부
  static BoxDecoration getEmotionBadgeDecoration(
    String emotion, {
    bool isDark = false,
  }) {
    final color = AppColors.getEmotionColor(emotion, isDark: isDark);

    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// 감정 타입 검증
  ///
  /// [emotion]: 감정 문자열
  /// 반환: 유효한 감정 타입인지 여부
  static bool isValidEmotion(String emotion) {
    const validEmotions = ['happy', 'sad', 'angry', 'peaceful', 'worried'];
    return validEmotions.contains(emotion.toLowerCase());
  }

  /// 감정 이름의 한국어 변환
  ///
  /// [emotion]: 감정 타입 (영문)
  /// 반환: 한국어 감정 이름
  static String getEmotionNameKo(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '행복';
      case 'sad':
        return '슬픔';
      case 'angry':
        return '분노';
      case 'peaceful':
        return '평온';
      case 'worried':
        return '불안';
      default:
        return '알 수 없음';
    }
  }

  /// 감정별 이모지
  ///
  /// [emotion]: 감정 타입
  /// 반환: 감정을 나타내는 이모지
  static String getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'peaceful':
        return '😌';
      case 'worried':
        return '😰';
      default:
        return '🤔';
    }
  }
}
