import 'package:flutter/material.dart';

import 'colors/dojo_appbar_colors.dart';
import 'colors/dojo_bottom_colors.dart';
import 'colors/dojo_brand_colors.dart';
import 'colors/dojo_button_colors.dart';
import 'colors/dojo_card_colors.dart';
import 'colors/dojo_dark_colors.dart';
import 'colors/dojo_input_colors.dart';
import 'colors/dojo_light_colors.dart';
import 'colors/dojo_tab_colors.dart';

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

      colorScheme: const ColorScheme.light(
        primary: DojoBrandColors.orange,
        secondary: DojoBrandColors.mint,
        surface: DojoLightColors.surface,
        onPrimary: Colors.white,
        onSecondary: DojoBrandColors.slate,
        onSurface: DojoLightColors.text,
        error: DojoCardColors.error,
      ),

      // ========================================================
      // APP BAR
      // ========================================================

      appBarTheme: const AppBarTheme(
        backgroundColor:
            DojoAppBarColors.lightBackground,
        foregroundColor:
            DojoAppBarColors.lightText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),

      // ========================================================
      // CARDS
      // ========================================================

      cardTheme: CardThemeData(
        color:
            DojoCardColors.lightBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
          side: const BorderSide(
            color:
                DojoCardColors.lightBorder,
          ),
        ),
      ),

      // ========================================================
      // INPUTS
      // ========================================================

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,

        fillColor:
            DojoInputColors.lightBackground,

        // FIX:
        // Typed text is now explicitly visible.
        textStyle: const TextStyle(
          color:
              DojoInputColors.lightText,
        ),

        hintStyle: const TextStyle(
          color:
              DojoInputColors.lightHint,
        ),

        prefixIconColor:
            DojoInputColors.lightIcon,

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color:
                DojoInputColors.lightBorder,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color:
                DojoBrandColors.orange,
            width: 1.5,
          ),
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      navigationBarTheme:
          const NavigationBarThemeData(
        backgroundColor:
            DojoBottomColors.lightBackground,

        indicatorColor:
            DojoBottomColors.lightIndicator,

        elevation: 8,

        labelTextStyle:
            WidgetStatePropertyAll(
          TextStyle(
            color:
                DojoBottomColors.lightSelected,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      // ========================================================
      // TABS
      // ========================================================

      tabBarTheme:
          const TabBarThemeData(
        labelColor:
            DojoTabColors.lightSelected,

        unselectedLabelColor:
            DojoTabColors.lightUnselected,

        indicatorColor:
            DojoTabColors.lightIndicator,
      ),

      // ========================================================
      // BUTTONS
      // ========================================================

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              DojoButtonColors.primary,

          foregroundColor:
              DojoButtonColors.primaryText,

          minimumSize:
              const Size(
            double.infinity,
            52,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
      ),

      // ========================================================
      // FAB
      // ========================================================

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor:
            DojoBrandColors.orange,

        foregroundColor:
            Colors.white,
      ),

      dividerColor:
          DojoLightColors.border,
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

      colorScheme: const ColorScheme.dark(
        primary: DojoBrandColors.orange,
        secondary: DojoBrandColors.mint,
        surface: DojoDarkColors.surface,
        onPrimary: Colors.white,
        onSecondary: DojoBrandColors.slate,
        onSurface: DojoDarkColors.text,
        error: DojoCardColors.error,
      ),

      // ========================================================
      // APP BAR
      // ========================================================

      appBarTheme: const AppBarTheme(
        backgroundColor:
            DojoAppBarColors.darkBackground,

        foregroundColor:
            DojoAppBarColors.darkText,

        elevation: 0,

        surfaceTintColor:
            Colors.transparent,

        centerTitle: false,
      ),

      // ========================================================
      // CARDS
      // ========================================================

      cardTheme: CardThemeData(
        color:
            DojoCardColors.darkBackground,

        elevation: 0,

        margin: EdgeInsets.zero,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),

          side: const BorderSide(
            color:
                DojoCardColors.darkBorder,
          ),
        ),
      ),

      // ========================================================
      // INPUTS
      // ========================================================

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,

        fillColor:
            DojoInputColors.darkBackground,

        // FIX:
        // Typed text is now explicitly visible.
        textStyle: const TextStyle(
          color:
              DojoInputColors.darkText,
        ),

        hintStyle: const TextStyle(
          color:
              DojoInputColors.darkHint,
        ),

        prefixIconColor:
            DojoInputColors.darkIcon,

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),

          borderSide: const BorderSide(
            color:
                DojoInputColors.darkBorder,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),

          borderSide: const BorderSide(
            color:
                DojoBrandColors.orange,

            width: 1.5,
          ),
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      navigationBarTheme:
          const NavigationBarThemeData(
        backgroundColor:
            DojoBottomColors.darkBackground,

        indicatorColor:
            DojoBottomColors.darkIndicator,

        elevation: 8,

        labelTextStyle:
            WidgetStatePropertyAll(
          TextStyle(
            color:
                DojoBottomColors.darkSelected,

            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      // ========================================================
      // TABS
      // ========================================================

      tabBarTheme:
          const TabBarThemeData(
        labelColor:
            DojoTabColors.darkSelected,

        unselectedLabelColor:
            DojoTabColors.darkUnselected,

        indicatorColor:
            DojoTabColors.darkIndicator,
      ),

      // ========================================================
      // BUTTONS
      // ========================================================

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              DojoButtonColors.primary,

          foregroundColor:
              DojoButtonColors.primaryText,

          minimumSize:
              const Size(
            double.infinity,
            52,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
      ),

      // ========================================================
      // FAB
      // ========================================================

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor:
            DojoBrandColors.orange,

        foregroundColor:
            Colors.white,
      ),

      dividerColor:
          DojoDarkColors.border,
    );
  }
}
