import 'package:flutter/material.dart';

import '../theme/dojo_colors.dart';

/// ============================================================
/// DOJO WALK - APP COLORS COMPATIBILITY BRIDGE
/// ============================================================
///
/// Existing UI files can continue using:
///   AppColors.primary
///   AppColors.orange
///   AppColors.success
///   AppColors.error
///   etc.
///
/// Actual colors are controlled by:
///   lib/core/theme/dojo_colors.dart
///
/// PRIMARY = DARK ORANGE
/// ============================================================

class AppColors {
AppColors._();

// ==========================================================
// BRAND
// ==========================================================

static const Color primary =
DojoBrandColors.orangeDark;

static const Color secondary =
DojoBrandColors.mint;

static const Color orange =
DojoBrandColors.orangeDark;

static const Color orangeLight =
DojoBrandColors.orangeLight;

static const Color orangeDark =
DojoBrandColors.orangeDark;

static const Color mint =
DojoBrandColors.mint;

static const Color mintTint =
DojoBrandColors.mintTint;

// ==========================================================
// TEXT / BRAND SUPPORT
// ==========================================================

static const Color navy =
DojoBrandColors.navy;

static const Color slate =
DojoBrandColors.slate;

static const Color deepTeal =
DojoBrandColors.deepTeal;

// ==========================================================
// BACKGROUND
// ==========================================================

static const Color background =
DojoBrandColors.background;

static const Color card =
DojoBrandColors.card;

// ==========================================================
// EFFECT
// ==========================================================

static const Color glow =
DojoBrandColors.glow;

// ==========================================================
// COMMON
// ==========================================================

static const Color white =
DojoBrandColors.white;

static const Color black =
DojoBrandColors.black;

static const Color transparent =
DojoBrandColors.transparent;

// ==========================================================
// NEUTRAL
// ==========================================================

static const Color grey =
DojoLightColors.secondaryText;

static const Color lightGrey =
DojoLightColors.surfaceSoft;

static const Color border =
DojoLightColors.border;

// ==========================================================
// STATUS
// ==========================================================

static const Color success =
DojoStatusColors.success;

static const Color error =
DojoStatusColors.error;

static const Color warning =
DojoStatusColors.warning;

static const Color info =
DojoStatusColors.info;
}

مین کنیکشن ہائیلی یہ کلر کا، اندر سے یہی بلاک لاتا۔
