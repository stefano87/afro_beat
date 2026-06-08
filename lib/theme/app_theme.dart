import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const card = Color(0xFF1E1E1E);
  static const itemBg = Color(0xF21E1E1E);
  static const toolbarStart = Color(0xFF232323);
  static const toolbarEnd = Color(0xFF2D2D2D);
  static const tabBarStart = Color(0xFF1A1A1A);
  static const tabBarEnd = Color(0xFF2D2D2D);
  static const accentGreen = Color(0xFF4CAF50);
  static const accentOrange = Color(0xFFFF5500);
  static const accentOrangeLight = Color(0xFFFF8800);
  static const textSecondary = Color(0xFFB3B3B3);
  static const buttonBg = Color(0xFF2C2C2C);
  static const success = Color(0xFF27AE60);
  static const danger = Color(0xFFC0392B);
  static const purple = Color(0xFF8E44AD);
  static const statusBar = Color(0xFF282828);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accentGreen,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGreen,
        secondary: AppColors.purple,
        surface: AppColors.surface,
        error: AppColors.danger,
        tertiary: AppColors.purple,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.statusBar,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentOrange,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
        thumbColor: Colors.white,
        overlayColor: AppColors.accentOrange.withValues(alpha: 0.2),
        trackHeight: 4,
      ),
    );
  }
}
