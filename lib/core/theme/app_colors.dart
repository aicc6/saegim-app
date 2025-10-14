import 'package:flutter/material.dart';

/// 새김 앱의 통합 색상 시스템
/// 디자인 시스템 문서와 완전히 일치하도록 재구성
class AppColors {
  // ========== 브랜드 컬러: Sage Green 10단계 그라데이션 ==========
  static const sage10 = Color(0xFFF7F9F8);
  static const sage20 = Color(0xFFEDF2EE);
  static const sage30 = Color(0xFFDFE8E1);
  static const sage40 = Color(0xFFC9D6CB);
  static const sage50 = Color(0xFFB2C5B8); // Primary Brand Color
  static const sage60 = Color(0xFF9BB5A2);
  static const sage70 = Color(0xFF84A68C);
  static const sage80 = Color(0xFF6D9676);
  static const sage90 = Color(0xFF568660);
  static const sage100 = Color(0xFF3F764A);

  // ========== 보조 컬러 팔레트 ==========
  static const offWhite = Color(0xFFFDFDFD);
  static const lightGray = Color(0xFF9CA3AF);
  static const mediumGray = Color(0xFF6D7275);
  static const darkGray = Color(0xFF111827);

  // ========== 의미론적 토큰 (라이트 모드) ==========
  static const backgroundPrimary = offWhite;
  static const backgroundSecondary = Color(0xFFF9FAFB);
  static const backgroundTertiary = sage20;
  static const backgroundBrand = sage50;

  static const textPrimary = mediumGray;
  static const textSecondary = lightGray;
  static const textOnColor = Colors.white;
  static const textOnBrand = sage100;

  static const borderSubtle = sage20;
  static const borderStrong = sage40;
  static const borderFocus = sage70;

  static const interactivePrimary = sage50;
  static const interactivePrimaryHover = sage60;
  static const interactivePrimaryActive = sage80;

  // ========== 감정별 색상 시스템 ==========
  static const emotionHappy = Color(0xFFE6C55A); // Soft Gold
  static const emotionSad = Color(0xFF6B8AC7); // Calm Blue
  static const emotionAngry = Color(0xFFD67D5C); // Warm Orange
  static const emotionPeaceful = Color(0xFF7DB87D); // Natural Green
  static const emotionWorried = Color(0xFFE6B366); // Gentle Orange

  // 감정별 보조 색상
  static const emotionHappySecondary = Color(0xFFF5F0DB);
  static const emotionSadSecondary = Color(0xFFE8EEF7);
  static const emotionAngrySecondary = Color(0xFFF3E5E0);
  static const emotionPeacefulSecondary = Color(0xFFE8F0E8);
  static const emotionWorriedSecondary = Color(0xFFF5EBDC);

  // 감정별 배경 색상
  static const emotionHappyBg = Color(0xFFFAF7E8);
  static const emotionSadBg = Color(0xFFF2F6FB);
  static const emotionAngryBg = Color(0xFFF8F0EC);
  static const emotionPeacefulBg = Color(0xFFF0F7F0);
  static const emotionWorriedBg = Color(0xFFFAF4E8);

  // ========== 시스템 색상 ==========
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // ========== 다크 모드 색상 시스템 ==========
  static const darkBackgroundPrimary = Color(0xFF1A1E1C);
  static const darkBackgroundSecondary = Color(0xFF232822);
  static const darkBackgroundTertiary = Color(0xFF2C322B);

  static const darkTextPrimary = Color(0xFFE5E7E6);
  static const darkTextSecondary = Color(0xFFB8BAB9);
  static const darkTextPlaceholder = Color(0xFF8A8C8B);

  static const darkInteractivePrimary = Color(0xFF8FB59C);
  static const darkInteractivePrimaryHover = Color(0xFFA3C4B0);

  static const darkBorderSubtle = Color(0xFF2C322B);
  static const darkBorderStrong = Color(0xFF3C443B);

  // 다크모드 감정 색상 (더 밝게 조정)
  static const darkEmotionHappy = emotionHappy; // 유지
  static const darkEmotionSad = Color(0xFF7A9BD1); // 더 밝게
  static const darkEmotionAngry = Color(0xFFE08A6B); // 더 밝게
  static const darkEmotionPeaceful = Color(0xFF8FC28F); // 더 밝게
  static const darkEmotionWorried = Color(0xFFEBC170); // 더 밝게

  /// 감정 타입에 따른 주요 색상 반환
  static Color getEmotionColor(String emotion, {bool isDark = false}) {
    if (isDark) {
      switch (emotion.toLowerCase()) {
        case 'happy':
          return darkEmotionHappy;
        case 'sad':
          return darkEmotionSad;
        case 'angry':
          return darkEmotionAngry;
        case 'peaceful':
          return darkEmotionPeaceful;
        case 'worried':
          return darkEmotionWorried;
        default:
          return darkInteractivePrimary;
      }
    }

    switch (emotion.toLowerCase()) {
      case 'happy':
        return emotionHappy;
      case 'sad':
        return emotionSad;
      case 'angry':
        return emotionAngry;
      case 'peaceful':
        return emotionPeaceful;
      case 'worried':
        return emotionWorried;
      default:
        return interactivePrimary;
    }
  }

  /// 감정 타입에 따른 배경 색상 반환
  static Color getEmotionBackgroundColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return emotionHappyBg;
      case 'sad':
        return emotionSadBg;
      case 'angry':
        return emotionAngryBg;
      case 'peaceful':
        return emotionPeacefulBg;
      case 'worried':
        return emotionWorriedBg;
      default:
        return backgroundSecondary;
    }
  }

  /// 감정 타입에 따른 보조 색상 반환
  static Color getEmotionSecondaryColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return emotionHappySecondary;
      case 'sad':
        return emotionSadSecondary;
      case 'angry':
        return emotionAngrySecondary;
      case 'peaceful':
        return emotionPeacefulSecondary;
      case 'worried':
        return emotionWorriedSecondary;
      default:
        return backgroundTertiary;
    }
  }
}
