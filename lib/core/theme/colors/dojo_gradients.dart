import 'package:flutter/material.dart';
import 'colors/dojo_brand_colors.dart';

class DojoGradients {
  DojoGradients._();

  // HERO
  static const LinearGradient hero = LinearGradient(
    colors: [
      DojoBrandColors.slate,
      DojoBrandColors.deepTeal,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // PRIMARY BUTTON
  static const LinearGradient primary = LinearGradient(
    colors: [
      DojoBrandColors.mint,
      DojoBrandColors.glow,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // DARK PREMIUM CARD
  static const LinearGradient darkSurface = LinearGradient(
    colors: [
      Color(0xFF122326),
      Color(0xFF193237),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // MINT SURFACE
  static const LinearGradient mintSurface = LinearGradient(
    colors: [
      Color(0xFFECFAF8),
      Color(0xFFDDF7F3),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
