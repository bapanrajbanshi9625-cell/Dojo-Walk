import 'package:flutter/material.dart';

import '../theme/colors/dojo_brand_colors.dart';

/// ============================================================
/// APP COLORS
/// ============================================================
/// Backward-compatible color API used throughout the app.
///
/// IMPORTANT:
/// Existing screens use:
///   AppColors.navy
///   AppColors.background
///   AppColors.card
///
/// So these aliases must remain available.
/// ============================================================

class AppColors {
  AppColors._();

  // ==========================================================
  // BRAND
  // ==========================================================

  static const Color primary = DojoBrandColors.orange;

  static const Color secondary = DojoBrandColors.mint;

  static const Color orange = DojoBrandColors.orange;

  static const Color mint = DojoBrandColors.mint;

  // ==========================================================
  // DARK / NAVIGATION
  // ==========================================================

  static const Color navy = DojoBrandColors.navy;

  // ==========================================================
  // SURFACES
  // ==========================================================

  static const Color background = DojoBrandColors.background;

  static const Color card = DojoBrandColors.card;

  // ==========================================================
  // COMMON
  // ==========================================================

  static const Color white = DojoBrandColors.white;

  static const Color black = DojoBrandColors.black;

  static const Color grey = DojoBrandColors.grey;

  static const Color lightGrey = DojoBrandColors.lightGrey;

  static const Color border = DojoBrandColors.border;

  static const Color success = DojoBrandColors.success;

  static const Color error = DojoBrandColors.error;

  static const Color warning = DojoBrandColors.warning;

  static const Color info = DojoBrandColors.info;
}
