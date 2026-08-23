import 'package:flutter/material.dart';

/// ============================================================
/// DOJO BRAND COLORS
/// ============================================================
/// Central source of truth for Dojo brand colors.
/// Keep these values const so AppColors can safely reference them.
/// ============================================================

class DojoBrandColors {
  DojoBrandColors._();

  // ==========================================================
  // PRIMARY BRAND
  // ==========================================================

  static const Color orange = Color(0xFFFF7A00);

  // ==========================================================
  // SECONDARY BRAND
  // ==========================================================

  static const Color mint = Color(0xFF8FE3CF);

  // ==========================================================
  // DARK BRAND
  // ==========================================================

  static const Color navy = Color(0xFF102A43);

  // ==========================================================
  // LIGHT SURFACES
  // ==========================================================

  static const Color background = Color(0xFFF7F9FC);

  static const Color card = Colors.white;

  // ==========================================================
  // COMMON
  // ==========================================================

  static const Color white = Colors.white;

  static const Color black = Colors.black;

  static const Color grey = Color(0xFF6B7280);

  static const Color lightGrey = Color(0xFFE5E7EB);

  static const Color border = Color(0xFFE2E8F0);

  static const Color success = Color(0xFF16A34A);

  static const Color error = Color(0xFFDC2626);

  static const Color warning = Color(0xFFF59E0B);

  static const Color info = Color(0xFF2563EB);
}
