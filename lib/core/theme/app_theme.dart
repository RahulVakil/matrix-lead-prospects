import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData? _cachedLightTheme;

  static ThemeData get light {
    _cachedLightTheme ??= _buildLightTheme();
    return _cachedLightTheme!;
  }

  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.navyPrimary,
      scaffoldBackgroundColor: AppColors.surfacePrimary,
      cardColor: AppColors.cardBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navyPrimary,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        displayLarge: GoogleFonts.roboto(
            fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
        displayMedium: GoogleFonts.roboto(
            fontSize: 28, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.roboto(color: Colors.black87),
        bodyMedium: GoogleFonts.roboto(color: Colors.black54),
        bodySmall: GoogleFonts.roboto(color: Colors.grey),
        titleMedium: GoogleFonts.roboto(color: AppColors.textOnDark),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.navyDark,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnDark,
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnDark),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: AppColors.textOnDark,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.navyPrimary,
        unselectedItemColor: Color(0xFF5E5F60),
        backgroundColor: AppColors.surfacePrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSecondary,
        selectedColor: AppColors.navyPrimary,
        labelStyle: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w500),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
    );
  }
}
