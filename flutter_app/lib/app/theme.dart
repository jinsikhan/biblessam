import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stitch 디자인 (docs/stitch) + CLAUDE.md — Manrope, primary #49ec13
class AppColors {
  // Stitch palette (Bible Stitch export)
  static const int stitchPrimary = 0xFF49EC13;
  static const int stitchBgLight = 0xFFF6F8F6;
  static const int stitchBgDark = 0xFF152210;
  static const int stitchCardDark = 0xFF1E293B; // slate-900

  static const int pointLight = 0xFF3B82F6;
  static const int pointDark = 0xFF60A5FA;
  static const int heart = 0xFFED4956;
  static const int streak = 0xFF2563EB;

  static const Color point = Color(0xFF3B82F6);
  static const Color pointEmphasis = Color(0xFF2563EB);

  // Light (Stitch: background-light #f6f8f6)
  static const Color backgroundLight = Color(stitchBgLight);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Dark (Stitch: background-dark #152210)
  static const Color backgroundDark = Color(stitchBgDark);
  static const Color cardDark = Color(stitchCardDark);
  static const Color dividerDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // 한 줄 기도 / AI 설명 카드 배경 (라이트: amber-50, 다크: 짙은 앰버 톤)
  static const Color explanationCardBgLight = Color(0xFFFFF8F0);
  static const Color explanationCardBgDark = Color(0xFF2A2520);

  // Shimmer / skeleton
  static const Color shimmerBase = Color(0xFFE5E5E5);
  static const Color shimmerHighlight = Color(0xFFFAFAFA);

  @Deprecated('Use explanationCardBgLight')
  static const Color explanationCardBg = explanationCardBgLight;
}

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      surface: AppColors.backgroundLight,
      onSurface: AppColors.textPrimaryLight,
      primary: AppColors.point,
      onPrimary: const Color(0xFF0F172A),
      secondary: AppColors.textSecondaryLight,
      outline: AppColors.dividerLight,
    ),
    fontFamily: GoogleFonts.manrope().fontFamily,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    cardColor: AppColors.cardLight,
    dividerColor: AppColors.dividerLight,
    textTheme: _textTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF262626),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundLight,
      selectedItemColor: AppColors.point,
      unselectedItemColor: AppColors.textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.point,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.point,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.point),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
  );
}

ThemeData buildDarkTheme() {
  const pointD = Color(0xFF3B82F6);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      surface: AppColors.backgroundDark,
      onSurface: AppColors.textPrimaryDark,
      primary: pointD,
      onPrimary: const Color(0xFF0F172A),
      secondary: AppColors.textSecondaryDark,
      outline: AppColors.dividerDark,
    ),
    fontFamily: GoogleFonts.manrope().fontFamily,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardColor: AppColors.cardDark,
    dividerColor: AppColors.dividerDark,
    textTheme: _textTheme(AppColors.textPrimaryDark, AppColors.textSecondaryDark),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF5F5F5),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundDark,
      selectedItemColor: pointD,
      unselectedItemColor: AppColors.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: pointD,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: pointD,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: pointD),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}

/// CLAUDE.md 타이포: h1 20sp Bold, h2 18sp SemiBold, 본문 16sp height 1.6, 보조 14sp, 캡션 12sp
TextTheme _textTheme(Color primary, Color secondary) {
  return TextTheme(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
    titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
    bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: primary),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: secondary),
    bodySmall: TextStyle(fontSize: 13, height: 1.4, color: secondary),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primary),
    labelSmall: TextStyle(fontSize: 12, color: secondary),
  );
}
