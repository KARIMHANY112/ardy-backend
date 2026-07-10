import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens from the ARDI brand brief (design handoff, direction 1a "Grid Market").
class AppColors {
  AppColors._();

  static const nileGreen = Color(0xFF0E6B58);
  static const deepGreen = Color(0xFF0A5244);
  static const gold = Color(0xFFC9A227);
  static const sandy = Color(0xFFF3F1EC);
  static const ink = Color(0xFF1C2B26);
  static const divider = Color(0xFFD8D3C8);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.nileGreen,
        primary: AppColors.nileGreen,
        secondary: AppColors.gold,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.sandy,
      dividerColor: AppColors.divider,
    );

    final headingFont = GoogleFonts.cairoTextTheme();
    final bodyFont = GoogleFonts.tajawalTextTheme();

    return base.copyWith(
      textTheme: bodyFont.merge(base.textTheme).copyWith(
            headlineLarge: headingFont.headlineLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800),
            headlineMedium: headingFont.headlineMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
            titleLarge: headingFont.titleLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
            titleMedium: headingFont.titleMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
            bodyLarge: bodyFont.bodyLarge?.copyWith(color: AppColors.ink),
            bodyMedium: bodyFont.bodyMedium?.copyWith(color: AppColors.ink),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        titleTextStyle: headingFont.titleLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.nileGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: bodyFont.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.nileGreen,
          side: const BorderSide(color: AppColors.nileGreen),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.nileGreen, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: AppColors.nileGreen,
        labelStyle: bodyFont.bodyMedium?.copyWith(color: AppColors.ink),
        secondaryLabelStyle: bodyFont.bodyMedium?.copyWith(color: Colors.white),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.divider)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.nileGreen,
        unselectedItemColor: AppColors.ink,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
