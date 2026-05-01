import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();

  static const backgroundPrimary = Color(0xFF0A0A0A);
  static const backgroundSurface = Color(0xFF111318);
  static const backgroundElevated = Color(0xFF1A1E27);
  static const accentGold = Color(0xFFF0C040);
  static const accentBlue = Color(0xFF2A3A5C);
  static const textPrimary = Color(0xFFE8E8E8);
  static const textSecondary = Color(0xFF7A7D8A);
  static const destructive = Color(0xFF8B2020);
  static const cardBorder = Color(0xFF1E2230);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGold,
        onPrimary: AppColors.backgroundPrimary,
        secondary: AppColors.accentBlue,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.backgroundSurface,
        onSurface: AppColors.textPrimary,
        error: AppColors.destructive,
        onError: AppColors.textPrimary,
      ),
      fontFamily: 'IBMPlexMono',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w700,
          fontSize: 56,
          letterSpacing: 2,
          color: AppColors.accentGold,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w700,
          fontSize: 40,
          letterSpacing: 1.5,
          color: AppColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w700,
          fontSize: 28,
          letterSpacing: 1,
          color: AppColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w600,
          fontSize: 24,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          letterSpacing: 1.5,
          color: AppColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontWeight: FontWeight.w400,
          fontSize: 11,
          letterSpacing: 1,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.backgroundSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          side: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          foregroundColor: AppColors.backgroundPrimary,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentGold,
          side: const BorderSide(color: AppColors.accentBlue),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          textStyle: const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.accentBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.accentBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.accentGold, width: 1.5),
        ),
        labelStyle: TextStyle(
          fontFamily: 'IBMPlexMono',
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        hintStyle: TextStyle(
          fontFamily: 'IBMPlexMono',
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundSurface,
        indicatorColor: AppColors.accentBlue.withOpacity(0.5),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accentGold, size: 22);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              letterSpacing: 1,
              color: AppColors.accentGold,
            );
          }
          return const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
            letterSpacing: 1,
            color: AppColors.textSecondary,
          );
        }),
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.backgroundElevated,
        contentTextStyle: TextStyle(
          fontFamily: 'IBMPlexMono',
          color: AppColors.textPrimary,
          fontSize: 12,
        ),
        actionTextColor: AppColors.accentGold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          letterSpacing: 2,
          color: AppColors.textPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundSurface,
        selectedColor: AppColors.accentBlue,
        labelStyle: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 11,
          color: AppColors.textPrimary,
        ),
        side: const BorderSide(color: AppColors.accentBlue),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}
