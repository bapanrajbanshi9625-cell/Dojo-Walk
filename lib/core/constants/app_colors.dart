import 'package:flutter/material.dart';

/// ============================================================
/// DOJO WALK - APP COLORS
/// ============================================================
///
/// Central color compatibility layer.
///
/// IMPORTANT:
/// Existing screens use AppColors.card, AppColors.navy,
/// AppColors.primary, etc.
/// Do not remove these names unless all usages are migrated.
/// ============================================================

class AppColors {
  AppColors._();

  // ==========================================================
  // BRAND
  // ==========================================================

  static const Color primary = Color(0xFFFF8A00);
  static const Color secondary = Color(0xFF2DD4BF);

  static const Color orange = Color(0xFFFF8A00);
  static const Color mint = Color(0xFF2DD4BF);

  // ==========================================================
  // MAIN DARK / NAVY COLORS
  // ==========================================================

  static const Color navy = Color(0xFF0F172A);
  static const Color darkNavy = Color(0xFF0F172A);

  static const Color slate = Color(0xFF64748B);
  static const Color darkSlate = Color(0xFF334155);

  // ==========================================================
  // BACKGROUNDS
  // ==========================================================

  static const Color background = Color(0xFFF8FAFC);
  static const Color lightBackground = Color(0xFFF8FAFC);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color white = Colors.white;

  // ==========================================================
  // CARD
  // ==========================================================

  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ==========================================================
  // TEXT
  // ==========================================================

  static const Color text = Color(0xFF0F172A);
  static const Color primaryText = Color(0xFF0F172A);

  static const Color secondaryText = Color(0xFF64748B);
  static const Color mutedText = Color(0xFF94A3B8);

  static const Color lightText = Color(0xFF64748B);

  // ==========================================================
  // BORDER / DIVIDER
  // ==========================================================

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // ==========================================================
  // STATUS COLORS
  // ==========================================================

  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFE76565);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ==========================================================
  // COMMON UI COLORS
  // ==========================================================

  static const Color red = Color(0xFFEF4444);
  static const Color green = Color(0xFF22C55E);
  static const Color blue = Color(0xFF3B82F6);
  static const Color grey = Color(0xFF64748B);

  // ==========================================================
  // INPUT
  // ==========================================================

  static const Color inputBackground = Color(0xFFF1F5F9);
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color hint = Color(0xFF94A3B8);

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  static const Color navBackground = Colors.white;
  static const Color navSelected = Color(0xFFFF8A00);
  static const Color navUnselected = Color(0xFF64748B);

  // ==========================================================
  // ICON
  // ==========================================================

  static const Color icon = Color(0xFF64748B);
  static const Color primaryIcon = Color(0xFFFF8A00);
}
