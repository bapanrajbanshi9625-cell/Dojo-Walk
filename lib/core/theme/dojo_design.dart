import 'package:flutter/material.dart';

import 'dojo_colors.dart';

// ============================================================
// DOJO DIMENSIONS
// ============================================================

class DojoDimensions {
  DojoDimensions._();

  static const double screenPadding = 20.0;

  // Radius
  static const double radiusXS = 8.0;
  static const double radiusSmall = 12.0;
  static const double radiusButton = 15.0;
  static const double radiusCard = 20.0;
  static const double radiusLarge = 26.0;
  static const double radiusXL = 30.0;

  // Border
  static const double borderWidth = 1.0;

  // Spacing
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;

  // Component Height
  static const double buttonHeight = 52.0;
  static const double inputHeight = 52.0;
  static const double appBarHeight = 64.0;
  static const double bottomBarHeight = 72.0;

  // Icons
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 28.0;
}

// ============================================================
// DOJO GRADIENTS
// ============================================================

class DojoGradients {
  DojoGradients._();

  // Hero
  static const LinearGradient hero = LinearGradient(
    colors: [
      DojoBrandColors.slate,
      DojoBrandColors.deepTeal,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Mint
  static const LinearGradient mint = LinearGradient(
    colors: [
      DojoBrandColors.mint,
      DojoBrandColors.glow,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Primary Orange
  static const LinearGradient orange = LinearGradient(
    colors: [
      DojoBrandColors.orangeDark,
      DojoBrandColors.orange,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Premium
  static const LinearGradient premium = LinearGradient(
    colors: [
      DojoBrandColors.orangeDark,
      DojoBrandColors.deepTeal,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark
  static const LinearGradient dark = LinearGradient(
    colors: [
      DojoDarkColors.background,
      DojoDarkColors.elevated,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Mint
  static const LinearGradient darkMint = LinearGradient(
    colors: [
      DojoDarkColors.surface,
      DojoBrandColors.deepTeal,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
