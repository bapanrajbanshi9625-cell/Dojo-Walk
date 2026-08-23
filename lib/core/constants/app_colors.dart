import 'package:flutter/material.dart';

import 'dojo_brand_colors.dart';

class AppColors {
  AppColors._();

  // ==========================================================
  // BRAND
  // ==========================================================

  static const Color primary =
      DojoBrandColors.orange;

  static const Color secondary =
      DojoBrandColors.mint;

  static const Color orange =
      DojoBrandColors.orange;

  static const Color mint =
      DojoBrandColors.mint;

  // ==========================================================
  // OLD / COMPATIBILITY COLORS
  //
  // Existing screens still use these names.
  // Keep them so the whole app remains compatible.
  // ==========================================================

  static const Color navy =
      DojoBrandColors.slate;

  static const Color background =
      Color(0xFFF7FBFA);

  static const Color card =
      Colors.white;

  // ==========================================================
  // BRAND ALIASES
  // ==========================================================

  static const Color slate =
      DojoBrandColors.slate;

  static const Color deepTeal =
      DojoBrandColors.deepTeal;

  static const Color orangeLight =
      DojoBrandColors.orangeLight;

  static const Color orangeDark =
      DojoBrandColors.orangeDark;

  static const Color glow =
      DojoBrandColors.glow;

  static const Color mintTint =
      DojoBrandColors.mintTint;

  static const Color aquaSoft =
      DojoBrandColors.aquaSoft;
}
