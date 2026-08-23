import 'package:flutter/material.dart';

import '../theme/colors/dojo_brand_colors.dart';
import '../theme/colors/dojo_card_colors.dart';
import '../theme/colors/dojo_bottom_colors.dart';
import '../theme/colors/dojo_light_colors.dart';
import '../theme/colors/dojo_dark_colors.dart';

/// ============================================================
/// DOJO APP COLORS
/// ============================================================
///
/// Backward-compatible color facade.
///
/// Existing screens still use:
///     AppColors.primary
///     AppColors.secondary
///
/// New theme system uses:
///     DojoBrandColors
///     DojoCardColors
///     DojoBottomColors
///     DojoLightColors
///     DojoDarkColors
///
/// DO NOT remove this file unless every old AppColors reference
/// in the project has been migrated.
/// ============================================================

class AppColors {
  AppColors._();

  // ==========================================================
  // PRIMARY BRAND
  // ==========================================================

  static const Color primary =
      DojoBrandColors.orange;

  static const Color secondary =
      DojoBrandColors.mint;

  static const Color accent =
      DojoBrandColors.orange;

  // ==========================================================
  // BRAND COLORS
  // ==========================================================

  static const Color orange =
      DojoBrandColors.orange;

  static const Color orangeLight =
      DojoBrandColors.orangeLight;

  static const Color orangeDark =
      DojoBrandColors.orangeDark;

  static const Color mint =
      DojoBrandColors.mint;

  static const Color glow =
      DojoBrandColors.glow;

  static const Color slate =
      DojoBrandColors.slate;

  static const Color deepTeal =
      DojoBrandColors.deepTeal;

  // ==========================================================
  // SOFT COLORS
  // ==========================================================

  static const Color mintTint =
      DojoBrandColors.mintTint;

  static const Color aquaSoft =
      DojoBrandColors.aquaSoft;

  static const Color orangeSoft =
      Color(0xFFFFE8DD);

  // ==========================================================
  // LIGHT
  // ==========================================================

  static const Color background =
      DojoLightColors.background;

  static const Color surface =
      DojoLightColors.surface;

  static const Color text =
      DojoLightColors.text;

  static const Color border =
      DojoLightColors.border;

  static const Color secondaryText =
      DojoCardColors.lightSecondaryText;

  static const Color mutedText =
      DojoCardColors.lightMutedText;

  // ==========================================================
  // DARK
  // ==========================================================

  static const Color darkBackground =
      DojoDarkColors.background;

  static const Color darkSurface =
      DojoDarkColors.surface;

  static const Color darkText =
      DojoDarkColors.text;

  static const Color darkBorder =
      DojoDarkColors.border;

  // ==========================================================
  // STATUS
  // ==========================================================

  static const Color success =
      DojoCardColors.success;

  static const Color successSoft =
      DojoCardColors.successSoft;

  static const Color warning =
      DojoCardColors.warning;

  static const Color warningSoft =
      DojoCardColors.warningSoft;

  static const Color error =
      DojoCardColors.error;

  static const Color errorSoft =
      DojoCardColors.errorSoft;

  static const Color info =
      DojoCardColors.info;

  static const Color infoSoft =
      DojoCardColors.infoSoft;

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  static const Color bottomBackground =
      DojoBottomColors.lightBackground;

  static const Color bottomSelected =
      DojoBottomColors.lightSelected;

  static const Color bottomUnselected =
      DojoBottomColors.lightUnselected;
}
