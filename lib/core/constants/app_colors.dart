import 'package:flutter/material.dart';

import '../theme/colors/dojo_brand_colors.dart';

/// ============================================================
/// DOJO WALK - APP COLORS
/// ============================================================
///
/// Central color compatibility layer.
///
/// IMPORTANT:
/// Existing screens use AppColors.card, AppColors.navy,
/// AppColors.primary, etc.
///
/// New brand colors are connected to DojoBrandColors.
/// Do not remove existing names unless all usages are migrated.
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
  // MAIN DARK / NAVY COLORS
  // ==========================================================

  static const Color navy =
      DojoBrandColors.slate;

  static const Color darkNavy =
      DojoBrandColors.slate;

  static const Color slate =
      DojoBrandColors.slate;

  static const Color darkSlate =
      Color(0xFF334155);

  // ==========================================================
  // DEEP BRAND COLORS
  // ==========================================================

  static const Color deepTeal =
      DojoBrandColors.deepTeal;

  static const Color glow =
      DojoBrandColors.glow;

  static const Color mintTint =
      DojoBrandColors.mintTint;

  static const Color aquaSoft =
      DojoBrandColors.aquaSoft;

  // ==========================================================
  // BACKGROUNDS
  // ==========================================================

  static const Color background =
      Color(0xFFF8FAFC);

  static const Color lightBackground =
      Color(0xFFF8FAFC);

  static const Color surface =
      Color(0xFFFFFFFF);

  static const Color white =
      Colors.white;

  // ==========================================================
  // CARD
  // ==========================================================

  static const Color card =
      Color(0xFFFFFFFF);

  static const Color cardBackground =
      Color(0xFFFFFFFF);

  // ==========================================================
  // TEXT
  // ==========================================================

  static const Color text =
      Color(0xFF0F172A);

  static const Color primaryText =
      Color(0xFF0F172A);

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
  // STATUS COLORS
  // ==========================================================

  static const Color success =
      Color(0xFF22C55E);

  static const Color error =
      Color(0xFFE76565);

  static const Color warning =
      Color(0xFFF59E0B);

  static const Color info =
      Color(0xFF3B82F6);

  // ==========================================================
  // COMMON UI COLORS
  // ==========================================================

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

  // ==========================================================
  // BUTTON
  // ==========================================================

  static const Color buttonPrimary =
      DojoBrandColors.orange;

  static const Color buttonText =
      Colors.white;

  // ==========================================================
  // EXTRA COMPATIBILITY COLORS
  // ==========================================================

  static const Color orangeLight =
      DojoBrandColors.orangeLight;

  static const Color orangeDark =
      DojoBrandColors.orangeDark;
}
