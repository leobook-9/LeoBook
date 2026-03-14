// app_colors.dart — LeoBook Design System v2.0
// Part of LeoBook App — Constants
//
// WCAG Accessibility Guarantees:
//   primary (#6C63FF) on neutral900 (#0A0A0F): contrast ratio ~6.2:1 (AA large)
//   textPrimary (#FFFFFF) on neutral900 (#0A0A0F): 21:1 (AAA)
//   secondary (#00D4AA) on neutral900 (#0A0A0F): ~6.8:1 (AAA large)

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ─── Primary ─────────────────────────────────────────────
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color primaryDark = Color(0xFF4B44CC);

  // ─── Secondary ───────────────────────────────────────────
  static const Color secondary = Color(0xFF00D4AA);
  static const Color secondaryLight = Color(0xFF33DDBB);
  static const Color secondaryDark = Color(0xFF00A882);

  // ─── Semantic States ──────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF86EFAC);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFCD34D);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);

  // ─── Neutral Scale (Dark Theme Base) ─────────────────────
  static const Color neutral900 = Color(0xFF0A0A0F);
  static const Color neutral800 = Color(0xFF12121A);
  static const Color neutral700 = Color(0xFF1A1A26);
  static const Color neutral600 = Color(0xFF242432);
  static const Color neutral500 = Color(0xFF3D3D52);
  static const Color neutral400 = Color(0xFF6B6B8A);
  static const Color neutral300 = Color(0xFF9898B3);
  static const Color neutral200 = Color(0xFFC4C4D6);
  static const Color neutral100 = Color(0xFFE8E8F0);
  static const Color neutral50 = Color(0xFFF5F5FA);

  // ─── Glass / Overlay ──────────────────────────────────────
  static const Color glass = Color(0x1AFFFFFF);        // 10% white
  static const Color glassBorder = Color(0x33FFFFFF);  // 20% white
  static const Color glassDark = Color(0x1A000000);    // 10% black

  // ─── Text on Dark ─────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC4C4D6);
  static const Color textDisabled = Color(0xFF6B6B8A);
  static const Color textInverse = Color(0xFF0A0A0F);

  // ─── Text on Light ────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF0A0A0F);
  static const Color textSecondaryLight = Color(0xFF3D3D52);
  static const Color textDisabledLight = Color(0xFF9898B3);

  // ─── Surface ──────────────────────────────────────────────
  static const Color surfaceDark = Color(0xFF12121A);
  static const Color surfaceCard = Color(0xFF1A1A26);
  static const Color surfaceElevated = Color(0xFF242432);

  // ─── Divider ──────────────────────────────────────────────
  static const Color divider = Color(0x1AFFFFFF);

  // ─── Legacy aliases (kept for backward compat with existing widgets) ──
  static const Color backgroundDark = neutral900;
  static const Color backgroundLight = neutral50;
  static const Color liveRed = error;
  static const Color successGreen = success;
  static const Color textLight = textPrimary;
  static const Color textDark = textPrimaryLight;
  static const Color textGrey = neutral400;
  static const Color textHint = neutral500;
  static const Color aiPurple = primary;
  static const Color accentBlue = secondary;
  static const Color accentYellow = warningLight;
  static const Color cardDark = surfaceCard;
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color glassBorderDark = glassBorder;
  static const Color glassBorderLight = Color(0xFFE2E8F0);
  static const Color liquidGlassDark = Color(0xCC1A1A26);
  static const Color liquidGlassLight = Color(0xCCFFFFFF);
  static const Color liquidGlassBorderDark = glassBorder;
  static const Color liquidGlassBorderLight = Color(0x33FFFFFF);
  static const Color liquidInnerGlow = Color(0x08FFFFFF);
  static const Color bgGradientStart = neutral900;
  static const Color bgGradientEnd = neutral800;
  static const Color desktopSidebarBg = neutral900;
  static const Color desktopHeaderBg = neutral800;
  static const Color desktopActiveIndicator = primary;
  static const Color desktopSearchFill = neutral700;
  static const Color glassLight = Color(0xCCFFFFFF);
}
