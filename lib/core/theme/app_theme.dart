import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFFB2C5B8); // sage-100
  static const Color _darkNavy = Color(0xFF2E3A59);
  static const Color _lightGray = Color(0xFF6B7280);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _cardColor = Colors.white;

  // Dark mode colors
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkCard = Color(0xFF2D2D2D);
  static const Color _darkOnPrimary = Color(0xFF121212);
  static const Color _darkOnSurface = Color(0xFFFFFFFF);
  static const Color _darkOnBackground = Color(0xFFFFFFFF);
  static const Color _darkSecondaryText = Color(0xFFB0B0B0);
  static const Color _darkLinkText = Color(0xFFB2C5B8); // 파란색 대신 primary 색상 사용

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
        primary: _primaryColor,
        onPrimary: Colors.white,
        secondary: _darkNavy,
        onSecondary: Colors.white,
        surface: _cardColor,
        onSurface: _darkNavy,
        background: _backgroundColor,
        onBackground: _darkNavy,
      ),
      useMaterial3: true,
      fontFamily: 'System',
      scaffoldBackgroundColor: _backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _primaryColor,
        ),
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      cardTheme: CardThemeData(
        color: _cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _darkNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _primaryColor),
          foregroundColor: _darkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        iconColor: _primaryColor,
        textColor: _darkNavy,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColor;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColor.withValues(alpha: 0.5);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
        primary: _primaryColor,
        onPrimary: _darkOnPrimary,
        secondary: _primaryColor,
        onSecondary: _darkOnPrimary,
        surface: _darkSurface,
        onSurface: _darkOnSurface,
        background: _darkBackground,
        onBackground: _darkOnBackground,
        // 파란색 링크 텍스트 방지
        tertiary: _primaryColor,
        onTertiary: _darkOnPrimary,
        error: const Color(0xFFFF6B6B),
        onError: _darkOnPrimary,
      ),
      useMaterial3: true,
      fontFamily: 'System',
      scaffoldBackgroundColor: _darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _primaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _primaryColor,
        ),
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _darkNavy,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _darkNavy,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor, // 파란색 대신 primary 색상 사용
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _primaryColor),
          foregroundColor: _primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryColor),
        ),
        fillColor: _darkSurface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        iconColor: _primaryColor,
        textColor: _darkOnSurface,
        titleTextStyle: TextStyle(
          color: _darkOnSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: _darkSecondaryText,
          fontSize: 14,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColor;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primaryColor.withValues(alpha: 0.5);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: _darkOnBackground),
        bodyMedium: TextStyle(color: _darkOnBackground),
        bodySmall: TextStyle(color: _darkSecondaryText),
        titleLarge: TextStyle(color: _darkOnBackground, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: _darkOnBackground, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: _darkOnBackground, fontWeight: FontWeight.w500),
        headlineLarge: TextStyle(color: _darkOnBackground, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: _darkOnBackground, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: _darkOnBackground, fontWeight: FontWeight.bold),
        labelLarge: TextStyle(color: _darkOnBackground),
        labelMedium: TextStyle(color: _darkSecondaryText),
        labelSmall: TextStyle(color: _darkSecondaryText),
        displayLarge: TextStyle(color: _darkOnBackground, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: _darkOnBackground, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: _darkOnBackground, fontWeight: FontWeight.bold),
      ),
      // 추가 컴포넌트 테마
      dialogTheme: DialogThemeData(
        backgroundColor: _darkCard,
        titleTextStyle: const TextStyle(
          color: _darkOnSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: _darkSecondaryText,
          fontSize: 14,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _darkCard,
        contentTextStyle: TextStyle(color: _darkOnSurface),
      ),
    );
  }
}