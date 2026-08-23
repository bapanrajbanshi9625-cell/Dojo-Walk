import 'package:flutter/material.dart';

/// ============================================================
/// DOJO BRAND COLORS
/// ============================================================
/// Single source of truth for the Dojo Walk color system.
/// Keep every value const so the theme/color classes can also
/// use const expressions.
/// ============================================================

class DojoBrandColors {
  DojoBrandColors._();

  // ==========================================================
  // PRIMARY BRAND
  // ==========================================================

  static const Color orange = Color(0xFFFF6B35);

  static const Color orangeLight = Color(0xFFFF8A5B);

  static const Color orangeDark = Color(0xFFE85A2A);

  // ==========================================================
  // SECONDARY BRAND
  // ==========================================================

  static const Color mint = Color(0xFF62D6C7);

  static const Color mintTint = Color(0xFFE8FAF7);

  // ==========================================================
  // DARK / TEXT
  // ==========================================================

  static const Color navy = Color(0xFF102A43);

  static const Color slate = Color(0xFF52606D);

  static const Color deepTeal = Color(0xFF087F8C);

  // ==========================================================
  // BACKGROUNDS
  // ==========================================================

  static const Color background = Color(0xFFF7F9FC);

  static const Color card = Color(0xFFFFFFFF);

  // ==========================================================
  // EFFECT / GLOW
  // ==========================================================

  static const Color glow = Color(0xFFFFC4A8);

  // ==========================================================
  // COMMON
  // ==========================================================

  static const Color white = Color(0xFFFFFFFF);

  static const Color black = Color(0xFF000000);

  static const Color transparent = Color(0x00000000);
}
