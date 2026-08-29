import 'package:flutter/material.dart';

// ============================================================
// DOJO WALK - SINGLE SOURCE OF TRUTH
// Primary: Dark Orange #E85A2A
// ============================================================

class DojoBrandColors {
  DojoBrandColors._();

  // ----------------------------------------------------------
  // BRAND
  // ----------------------------------------------------------

  static const Color orangeDark = Color(0xFFE85A2A);
  static const Color orange = Color(0xFFFF6B35);
  static const Color orangeLight = Color(0xFFFF8A5B);

  static const Color mint = Color(0xFF62D6C7);
  static const Color mintTint = Color(0xFFE8FAF7);

  static const Color navy = Color(0xFF102A43);
  static const Color slate = Color(0xFF52606D);
  static const Color deepTeal = Color(0xFF087F8C);

  static const Color background = Color(0xFFF7F9FC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color glow = Color(0xFFFFC4A8);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
}

// ============================================================
// APP BAR
// ============================================================

class DojoAppBarColors {
  DojoAppBarColors._();

  static const Color lightBackground = DojoBrandColors.orangeDark;
  static const Color lightText = DojoBrandColors.white;

  static const Color darkBackground = DojoBrandColors.orangeDark;
  static const Color darkText = DojoBrandColors.white;
}

// ============================================================
// LIGHT
// ============================================================

class DojoLightColors {
  DojoLightColors._();

  static const Color background = Color(0xFFF5F8F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF0F8F6);
  static const Color elevated = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE0EBE9);

  static const Color text = Color(0xFF1C3136);
  static const Color secondaryText = Color(0xFF667B7D);
  static const Color mutedText = Color(0xFF91A2A3);

  static const Color divider = Color(0xFFE0EBE9);
}

// ============================================================
// DARK
// ============================================================

class DojoDarkColors {
  DojoDarkColors._();

  static const Color background = Color(0xFF0B1719);
  static const Color surface = Color(0xFF122326);
  static const Color elevated = Color(0xFF193237);
  static const Color deepSurface = Color(0xFF102023);

  static const Color border = Color(0xFF294347);
  static const Color strongBorder = Color(0xFF35565A);

  static const Color text = Color(0xFFF2FAF8);
  static const Color secondaryText = Color(0xFFA5B9B9);
  static const Color mutedText = Color(0xFF718889);

  static const Color divider = Color(0xFF294347);
}

// ============================================================
// INPUT
// ============================================================

class DojoInputColors {
  DojoInputColors._();

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0EBE9);
  static const Color lightFocus = DojoBrandColors.orangeDark;
  static const Color lightText = Color(0xFF1C3136);
  static const Color lightHint = Color(0xFF91A2A3);
  static const Color lightIcon = Color(0xFF667B7D);

  static const Color darkBackground = Color(0xFF122326);
  static const Color darkBorder = Color(0xFF294347);
  static const Color darkFocus = DojoBrandColors.orangeDark;
  static const Color darkText = Color(0xFFF2FAF8);
  static const Color darkHint = Color(0xFF718889);
  static const Color darkIcon = Color(0xFFA5B9B9);
}

// ============================================================
// BUTTON
// ============================================================

class DojoButtonColors {
  DojoButtonColors._();

  static const Color primary = DojoBrandColors.orangeDark;
  static const Color primaryDark = DojoBrandColors.orangeDark;
  static const Color primaryText = DojoBrandColors.white;

  static const Color secondary = DojoBrandColors.deepTeal;
  static const Color secondaryText = DojoBrandColors.white;

  static const Color mint = DojoBrandColors.mint;
  static const Color mintText = DojoBrandColors.slate;

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFD9E5E5);

  static const Color darkBackground = Color(0xFF0B1719);
  static const Color darkBorder = Color(0xFF294347);

  static const Color disabled = Color(0xFFB8C2C3);
  static const Color disabledText = Color(0xFF718889);
}

// ============================================================
// CARD
// ============================================================

class DojoCardColors {
  DojoCardColors._();

  static const Color lightBackground = DojoBrandColors.white;
  static const Color lightSurface = Color(0xFFF8FAF9);
  static const Color lightElevated = DojoBrandColors.white;
  static const Color lightBorder = Color(0xFFE0EBE9);

  static const Color lightText = DojoBrandColors.slate;
  static const Color lightSecondaryText = Color(0xFF667B7D);
  static const Color lightMutedText = Color(0xFF91A2A3);

  static const Color darkBackground = Color(0xFF122326);
  static const Color darkSurface = Color(0xFF193237);
  static const Color darkElevated = Color(0xFF203B40);
  static const Color darkBorder = Color(0xFF294347);

  static const Color darkText = Color(0xFFF2FAF8);
  static const Color darkSecondaryText = Color(0xFFA5B9B9);
  static const Color darkMutedText = Color(0xFF718889);

  static const Color orangeAccent = DojoBrandColors.orangeDark;
  static const Color mintAccent = DojoBrandColors.mint;
  static const Color mintSoft = DojoBrandColors.mintTint;
  static const Color orangeSoft = Color(0xFFFFE8DD);

  static const Color success = Color(0xFF45C98A);
  static const Color successSoft = Color(0xFFE2F8ED);

  static const Color warning = Color(0xFFD9AD55);
  static const Color warningSoft = Color(0xFFFFF4DB);

  static const Color error = Color(0xFFE76565);
  static const Color errorSoft = Color(0xFFFFE8E8);

  static const Color info = Color(0xFF5CA9D6);
  static const Color infoSoft = Color(0xFFE6F4FC);
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

class DojoBottomColors {
  DojoBottomColors._();

  static const Color lightBackground = DojoBrandColors.white;
  static const Color lightSelected = DojoBrandColors.orangeDark;
  static const Color lightSelectedText = DojoBrandColors.slate;
  static const Color lightIndicator = DojoBrandColors.orangeLight;
  static const Color lightUnselected = Color(0xFF91A2A3);
  static const Color lightBorder = Color(0xFFE0EBE9);

  static const Color darkBackground = Color(0xFF122326);
  static const Color darkSelected = DojoBrandColors.orangeDark;
  static const Color darkSelectedText = DojoBrandColors.orangeDark;
  static const Color darkIndicator = Color(0x33E85A2A);
  static const Color darkUnselected = Color(0xFF718889);
  static const Color darkBorder = Color(0xFF294347);

  static const Color accent = DojoBrandColors.mint;
  static const Color activeAccent = DojoBrandColors.orangeDark;
}

// ============================================================
// ICON
// ============================================================

class DojoIconColors {
  DojoIconColors._();

  static const Color primary = DojoBrandColors.orangeDark;
  static const Color mint = DojoBrandColors.mint;
  static const Color glow = DojoBrandColors.glow;

  static const Color success = Color(0xFF45C98A);
  static const Color warning = Color(0xFFD9AD55);
  static const Color error = Color(0xFFE76565);
  static const Color info = Color(0xFF5CA9D6);

  static const Color lightMuted = Color(0xFF91A2A3);
  static const Color darkMuted = Color(0xFF718889);
}

// ============================================================
// STATUS
// ============================================================

class DojoStatusColors {
  DojoStatusColors._();

  static const Color success = Color(0xFF45C98A);
  static const Color successSoft = Color(0xFFE2F8ED);
  static const Color successDark = Color(0xFF18372D);

  static const Color warning = Color(0xFFD9AD55);
  static const Color warningSoft = Color(0xFFFFF4DB);
  static const Color warningDark = Color(0xFF392F1C);

  static const Color error = Color(0xFFE76565);
  static const Color errorSoft = Color(0xFFFFE8E8);
  static const Color errorDark = Color(0xFF351F21);

  static const Color info = Color(0xFF5CA9D6);
  static const Color infoSoft = Color(0xFFE6F4FC);
  static const Color infoDark = Color(0xFF1D303A);
}

// ============================================================
// TAB
// ============================================================

class DojoTabColors {
  DojoTabColors._();

  static const Color lightSelected = DojoBrandColors.orangeDark;
  static const Color lightUnselected = Color(0xFF91A2A3);
  static const Color lightIndicator = DojoBrandColors.orangeLight;

  static const Color darkSelected = DojoBrandColors.orangeDark;
  static const Color darkUnselected = Color(0xFF718889);
  static const Color darkIndicator = Color(0x33E85A2A);
}

// ============================================================
// OVERLAY
// ============================================================

class DojoOverlayColors {
  DojoOverlayColors._();

  static const Color darkOverlay = Color(0x66000000);
  static const Color lightOverlay = Color(0x22000000);

  static const Color darkScrim = Color(0x99000000);
  static const Color lightScrim = Color(0x33000000);

  static const Color glow30 = Color(0x4DE85A2A);
  static const Color glow40 = Color(0x66E85A2A);
}

// ============================================================
// DOJO COLORS
// Compatibility shortcuts used by existing screens/widgets.
//
// IMPORTANT:
// Do NOT create another color file.
// Existing code can continue using:
// DojoColors.orange
// DojoColors.navy
// DojoColors.white
// DojoColors.black
// DojoColors.grey
// DojoColors.lightOrange
// ============================================================

class DojoColors {
  DojoColors._();

  // ----------------------------------------------------------
  // BRAND
  // ----------------------------------------------------------

  static const Color orangeDark = DojoBrandColors.orangeDark;
  static const Color orange = DojoBrandColors.orange;
  static const Color lightOrange = DojoBrandColors.orangeLight;

  static const Color mint = DojoBrandColors.mint;
  static const Color mintTint = DojoBrandColors.mintTint;

  static const Color navy = DojoBrandColors.navy;
  static const Color slate = DojoBrandColors.slate;
  static const Color deepTeal = DojoBrandColors.deepTeal;

  // ----------------------------------------------------------
  // BASIC
  // ----------------------------------------------------------

  static const Color white = DojoBrandColors.white;
  static const Color black = DojoBrandColors.black;
  static const Color transparent = DojoBrandColors.transparent;

  // ----------------------------------------------------------
  // BACKGROUND / SURFACE
  // ----------------------------------------------------------

  static const Color background = DojoLightColors.background;
  static const Color surface = DojoLightColors.surface;
  static const Color surfaceSoft = DojoLightColors.surfaceSoft;
  static const Color card = DojoBrandColors.card;

  // ----------------------------------------------------------
  // TEXT
  // ----------------------------------------------------------

  static const Color text = DojoLightColors.text;
  static const Color secondaryText = DojoLightColors.secondaryText;
  static const Color mutedText = DojoLightColors.mutedText;

  // Existing widgets use "grey".
  static const Color grey = DojoLightColors.secondaryText;

  // ----------------------------------------------------------
  // BORDER / DIVIDER
  // ----------------------------------------------------------

  static const Color border = DojoLightColors.border;
  static const Color divider = DojoLightColors.divider;

  // ----------------------------------------------------------
  // STATUS
  // ----------------------------------------------------------

  static const Color success = DojoStatusColors.success;
  static const Color successSoft = DojoStatusColors.successSoft;

  static const Color warning = DojoStatusColors.warning;
  static const Color warningSoft = DojoStatusColors.warningSoft;

  static const Color error = DojoStatusColors.error;
  static const Color errorSoft = DojoStatusColors.errorSoft;

  static const Color info = DojoStatusColors.info;
  static const Color infoSoft = DojoStatusColors.infoSoft;
}
