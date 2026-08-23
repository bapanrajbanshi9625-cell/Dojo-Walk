import 'package:flutter/material.dart';
import 'dojo_brand_colors.dart';

class DojoGradients {
  DojoGradients._();

  // ==========================================================
  // HERO
  // ==========================================================

  static const LinearGradient hero = LinearGradient(
    colors: [
      DojoBrandColors.slate,
      DojoBrandColors.deepTeal,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================================
  // MINT
  // ==========================================================

  static const LinearGradient mint = LinearGradient(
    colors: [
      DojoBrandColors.mint,
      DojoBrandColors.glow,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================================
  // ORANGE
  // ==========================================================

  static const LinearGradient orange = LinearGradient(
    colors: [
      DojoBrandColors.orange,
      DojoBrandColors.orangeDark,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================================
  // PREMIUM MIX
  // ==========================================================

  static const LinearGradient premium = LinearGradient(
    colors: [
      DojoBrandColors.orange,
      DojoBrandColors.deepTeal,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================================
  // DARK
  // ==========================================================

  static const LinearGradient dark = LinearGradient(
    colors: [
      Color(0xFF0B1719),
      Color(0xFF193237),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================================
  // DARK MINT
  // ==========================================================

  static const LinearGradient darkMint = LinearGradient(
    colors: [
      Color(0xFF122326),
      DojoBrandColors.deepTeal,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
