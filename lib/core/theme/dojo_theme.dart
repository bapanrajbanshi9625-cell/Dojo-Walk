import 'package:flutter/material.dart';

import 'dojo_appbar_colors.dart';
import 'dojo_bottom_colors.dart';
import 'dojo_brand_colors.dart';
import 'dojo_button_colors.dart';
import 'dojo_card_colors.dart';
import 'dojo_dark_colors.dart';
import 'dojo_gradients.dart';
import 'dojo_input_colors.dart';
import 'dojo_light_colors.dart';
import 'dojo_tab_colors.dart';

class DojoTheme {
  DojoTheme._();

  // ==========================================================
  // LIGHT THEME
  // ==========================================================

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor:
          DojoLightColors.background,

      colorScheme: ColorScheme.light(
        primary: DojoBrandColors.orange,
        secondary: DojoBrandColors.mint,
        surface: DojoLightColors.surface,
        error: const Color(0xFFE76565),
        onPrimary: Colors.white,
        onSecondary: DojoBrandColors.slate,
        onSurface: DojoLightColors.text,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: DojoAppBarColors.lightBackground,
        foregroundColor: DojoAppBarColors.lightText,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: DojoCardColors.lightBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: DojoCardColors.lightBorder,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DojoInputColors.lightBackground,

        hintStyle: const TextStyle(
          color: DojoInputColors.lightHint,
        ),

        prefixIconColor: DojoInputColors.lightIcon,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: DojoInputColors.lightBorder,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: DojoBrandColors.orange,
            width: 1.5,
          ),
        ),
      ),

      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor:
            DojoBottomColors.lightBackground,

        indicatorColor:
            DojoBottomColors.lightIndicator,

        selectedIconTheme: IconThemeData(
          color: DojoBottomColors.lightSelected,
        ),

        unselectedIconTheme: IconThemeData(
          color: DojoBottomColors.lightUnselected,
        ),

        elevation: 8,
      ),

      dividerColor: DojoLightColors.border,

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor: DojoBrandColors.orange,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      textTheme: _lightTextTheme(),
    );
  }

  // ==========================================================
  // DARK THEME
  // ==========================================================

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor:
          DojoDarkColors.background,

      colorScheme: ColorScheme.dark(
        primary: DojoBrandColors.orange,
        secondary: DojoBrandColors.mint,
        surface: DojoDarkColors.surface,
        error: const Color(0xFFE76565),
        onPrimary: Colors.white,
        onSecondary: DojoBrandColors.slate,
        onSurface: DojoDarkColors.text,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor:
            DojoAppBarColors.darkBackground,
        foregroundColor:
            DojoAppBarColors.darkText,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: DojoCardColors.darkBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: DojoCardColors.darkBorder,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DojoInputColors.darkBackground,

        hintStyle: const TextStyle(
          color: DojoInputColors.darkHint,
        ),

        prefixIconColor: DojoInputColors.darkIcon,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: DojoInputColors.darkBorder,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: DojoBrandColors.orange,
            width: 1.5,
          ),
        ),
      ),

      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor:
            DojoBottomColors.darkBackground,

        indicatorColor:
            DojoBottomColors.darkIndicator,

        selectedIconTheme: IconThemeData(
          color: DojoBottomColors.darkSelected,
        ),

        unselectedIconTheme: IconThemeData(
          color: DojoBottomColors.darkUnselected,
        ),

        elevation: 8,
      ),

      dividerColor: DojoDarkColors.border,

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor: DojoBrandColors.orange,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      textTheme: _darkTextTheme(),
    );
  }

  // ==========================================================
  // LIGHT TEXT
  // ==========================================================

  static TextTheme _lightTextTheme() {
    return const TextTheme(
      headlineLarge: TextStyle(
        color: DojoLightColors.text,
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),

      headlineMedium: TextStyle(
        color: DojoLightColors.text,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),

      titleLarge: TextStyle(
        color: DojoLightColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),

      titleMedium: TextStyle(
        color: DojoLightColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),

      bodyLarge: TextStyle(
        color: DojoLightColors.text,
        fontSize: 16,
      ),

      bodyMedium: TextStyle(
        color: DojoLightColors.secondary,
        fontSize: 14,
      ),

      bodySmall: TextStyle(
        color: DojoLightColors.muted,
        fontSize: 12,
      ),
    );
  }

  // ==========================================================
  // DARK TEXT
  // ==========================================================

  static TextTheme _darkTextTheme() {
    return const TextTheme(
      headlineLarge: TextStyle(
        color: DojoDarkColors.text,
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),

      headlineMedium: TextStyle(
        color: DojoDarkColors.text,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),

      titleLarge: TextStyle(
        color: DojoDarkColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),

      titleMedium: TextStyle(
        color: DojoDarkColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),

      bodyLarge: TextStyle(
        color: DojoDarkColors.text,
        fontSize: 16,
      ),

      bodyMedium: TextStyle(
        color: DojoDarkColors.secondary,
        fontSize: 14,
      ),

      bodySmall: TextStyle(
        color: DojoDarkColors.muted,
        fontSize: 12,
      ),
    );
  }
}
