import 'package:flutter/material.dart';

import 'dojo_walk_colors.dart';

class DojoWalkTheme {
  DojoWalkTheme._();

  static ThemeData light = ThemeData(
    useMaterial3: true,

    // ============================================================
    // COLOR SCHEME
    // ============================================================

    colorScheme: ColorScheme.fromSeed(
      seedColor: DojoWalkColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: DojoWalkColors.primary,
      onPrimary: DojoWalkColors.white,

      secondary: DojoWalkColors.blue,
      onSecondary: DojoWalkColors.white,

      surface: DojoWalkColors.surface,
      onSurface: DojoWalkColors.textPrimary,

      error: DojoWalkColors.red,
      onError: DojoWalkColors.white,
    ),

    // ============================================================
    // APP BACKGROUND
    // ============================================================

    scaffoldBackgroundColor: DojoWalkColors.background,

    // ============================================================
    // APP BAR
    // ============================================================

    appBarTheme: const AppBarTheme(
      backgroundColor: DojoWalkColors.primary,
      foregroundColor: DojoWalkColors.white,
      elevation: 0,
      centerTitle: false,

      titleTextStyle: TextStyle(
        color: DojoWalkColors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),

      iconTheme: IconThemeData(
        color: DojoWalkColors.white,
      ),
    ),

    // ============================================================
    // CARD
    // ============================================================

    cardTheme: CardThemeData(
      color: DojoWalkColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: DojoWalkColors.border,
          width: 1,
        ),
      ),
    ),

    // ============================================================
    // ELEVATED BUTTON
    // ============================================================

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DojoWalkColors.primary,
        foregroundColor: DojoWalkColors.white,

        minimumSize: const Size(double.infinity, 52),

        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),

        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // ============================================================
    // OUTLINED BUTTON
    // ============================================================

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DojoWalkColors.primary,

        minimumSize: const Size(double.infinity, 52),

        side: const BorderSide(
          color: DojoWalkColors.primary,
          width: 1.2,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),

        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    // ============================================================
    // TEXT BUTTON
    // ============================================================

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DojoWalkColors.primary,

        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ============================================================
    // INPUT FIELDS
    // ============================================================

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DojoWalkColors.surface,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: DojoWalkColors.border,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: DojoWalkColors.border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: DojoWalkColors.primary,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: DojoWalkColors.red,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: DojoWalkColors.red,
          width: 1.5,
        ),
      ),

      hintStyle: const TextStyle(
        color: DojoWalkColors.textTertiary,
        fontSize: 14,
      ),

      labelStyle: const TextStyle(
        color: DojoWalkColors.textSecondary,
        fontSize: 14,
      ),
    ),

    // ============================================================
    // BOTTOM NAVIGATION
    // ============================================================

    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: DojoWalkColors.surface,

      indicatorColor: DojoWalkColors.primaryLight,

      elevation: 8,

      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),

      iconTheme: WidgetStatePropertyAll(
        IconThemeData(
          color: DojoWalkColors.textSecondary,
        ),
      ),
    ),

    // ============================================================
    // DIVIDER
    // ============================================================

    dividerTheme: const DividerThemeData(
      color: DojoWalkColors.divider,
      thickness: 1,
      space: 1,
    ),

    // ============================================================
    // CHECKBOX
    // ============================================================

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return DojoWalkColors.primary;
          }

          return DojoWalkColors.surface;
        },
      ),
      side: const BorderSide(
        color: DojoWalkColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
    ),

    // ============================================================
    // SWITCH
    // ============================================================

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return DojoWalkColors.white;
          }

          return DojoWalkColors.textTertiary;
        },
      ),
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return DojoWalkColors.primary;
          }

          return DojoWalkColors.border;
        },
      ),
    ),

    // ============================================================
    // PROGRESS INDICATOR
    // ============================================================

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: DojoWalkColors.primary,
    ),

    // ============================================================
    // SNACKBAR
    // ============================================================

    snackBarTheme: SnackBarThemeData(
      backgroundColor: DojoWalkColors.dark,
      contentTextStyle: const TextStyle(
        color: DojoWalkColors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // ============================================================
    // TYPOGRAPHY
    // ============================================================

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: DojoWalkColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),

      headlineMedium: TextStyle(
        color: DojoWalkColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),

      titleLarge: TextStyle(
        color: DojoWalkColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),

      titleMedium: TextStyle(
        color: DojoWalkColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),

      bodyLarge: TextStyle(
        color: DojoWalkColors.textPrimary,
        fontSize: 16,
      ),

      bodyMedium: TextStyle(
        color: DojoWalkColors.textSecondary,
        fontSize: 14,
      ),

      bodySmall: TextStyle(
        color: DojoWalkColors.textTertiary,
        fontSize: 12,
      ),
    ),
  );
}
