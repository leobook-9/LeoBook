// spacing_constants.dart — LeoBook Design System v2.0
// Part of LeoBook App — Constants
//
// 8dp-grid spacing scale with semantic aliases.
// All values are logical pixels.

abstract final class SpacingScale {
  // ─── Raw Scale ────────────────────────────────────────────
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xl2 = 24.0;
  static const double xl3 = 32.0;
  static const double xl4 = 40.0;
  static const double xl5 = 48.0;
  static const double xl6 = 64.0;
  static const double xl7 = 80.0;
  static const double xl8 = 96.0;

  // ─── Semantic Aliases ─────────────────────────────────────
  static const double cardPadding   = lg;   // 16 — internal card padding
  static const double screenPadding = xl2;  // 24 — horizontal page margin
  static const double sectionGap    = xl3;  // 32 — between page sections
  static const double componentGap  = lg;   // 16 — between sibling components
  static const double iconSize      = xl2;  // 24 — default icon size
  static const double touchTarget   = xl5;  // 48 — WCAG 2.5.5 minimum touch target
  static const double borderRadius  = md;   // 12 — default input / chip radius
  static const double cardRadius    = xl;   // 20 — card corner radius
  static const double chipRadius    = xl3;  // 32 — pill / tag radius
}
