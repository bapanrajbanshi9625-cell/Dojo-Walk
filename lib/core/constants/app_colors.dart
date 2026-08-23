import 'package:flutter/material.dart';

import 'dojo_brand_colors.dart';

/// ============================================================
/// DOJO WALK - APP COLORS
/// ============================================================
///
/// Compatibility layer for existing screens.
///
/// IMPORTANT:
/// DojoBrandColors is the master brand palette.
/// Existing AppColors references are kept so old screens
/// continue working without breaking.
/// ============================================================

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
  // MAIN DARK / TEAL
  // ==========================================================

  static const Color navy =
      DojoBrandColors.slate;

  static const Color darkNavy =
      DojoBrandColors.slate;

  static const Color slate =
      DojoBrandColors.slate;

  static const Color darkSlate =
      DojoBrandColors.deepTeal;

  // ==========================================================
  // BACKGROUNDS
  // ==========================================================

  static const Color background =
      Color(0xFFF8FAFC);

  static const Color lightBackground =
      Color(0xFFF8FAFC);

  static const Color surface =
      Colors.white;

  static const Color white =
      Colors.white;

  // ==========================================================
  // CARD
  // ==========================================================

  static const Color card =
      Colors.white;

  static const Color cardBackground =
      Colors.white;

  // ==========================================================
  // TEXT
  // ==========================================================

  static const Color text =
      DojoBrandColors.slate;

  static const Color primaryText =
      DojoBrandColors.slate;

  static const Color secondaryText =
      Color(0xFF64748B);

  static const Color mutedText =
      Color(0xFF94A3B8);

  static const Color lightText =
      Color(0xFF64748B);

  // ==========================================================
  // BORDER / DIVIDER
  // ==========================================================

  static const Color border =
      Color(0xFFE2E8F0);

  static const Color divider =
      Color(0xFFE2E8F0);

  // ==========================================================
  // STATUS
  // ==========================================================

  static const Color success =
      Color(0xFF22C55E);

  static const Color error =
      Color(0xFFE76565);

  static const Color warning =
      Color(0xFFF59E0B);

  static const Color info =
      Color(0xFF3B82F6);

  static const Color red =
      Color(0xFFEF4444);

  static const Color green =
      Color(0xFF22C55E);

  static const Color blue =
      Color(0xFF3B82F6);

  static const Color grey =
      Color(0xFF64748B);

  // ==========================================================
  // INPUT
  // ==========================================================

  static const Color inputBackground =
      Color(0xFFF1F5F9);

  static const Color inputBorder =
      Color(0xFFE2E8F0);

  static const Color hint =
      Color(0xFF94A3B8);

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  static const Color navBackground =
      Colors.white;

  static const Color navSelected =
      DojoBrandColors.orange;

  static const Color navUnselected =
      Color(0xFF64748B);

  // ==========================================================
  // ICON
  // ==========================================================

  static const Color icon =
      Color(0xFF64748B);

  static const Color primaryIcon =
      DojoBrandColors.orange;
}
