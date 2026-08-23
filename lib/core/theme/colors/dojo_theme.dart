import 'package:flutter/material.dart';

import 'colors/dojo_appbar_colors.dart';
import 'colors/dojo_bottom_colors.dart';
import 'colors/dojo_brand_colors.dart';
import 'colors/dojo_dark_colors.dart';
import 'colors/dojo_light_colors.dart';

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

      colorScheme: ColorScheme.fromSeed(
        seedColor: DojoBrandColors.mint,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor:
            DojoAppBarColors.lightBackground,
        foregroundColor:
            DojoAppBarColors.lightTitle,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      navigationBarTheme:
          const NavigationBarThemeData(
        backgroundColor:
            DojoBottomColors.lightBackground,
        indicatorColor:
            DojoBottomColors.lightIndicator,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: const CardThemeData(
        color: DojoLightColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: DojoLightColors.divider,
        thickness: 1,
      ),
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

      colorScheme: ColorScheme.fromSeed(
        seedColor: DojoBrandColors.mint,
        brightness: Brightness.dark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor:
            DojoAppBarColors.darkBackground,
        foregroundColor:
            DojoAppBarColors.darkTitle,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      navigationBarTheme:
          const NavigationBarThemeData(
        backgroundColor:
            DojoBottomColors.darkBackground,
        indicatorColor:
            DojoBottomColors.darkIndicator,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: const CardThemeData(
        color: DojoDarkColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: DojoDarkColors.divider,
        thickness: 1,
      ),
    );
  }
}
