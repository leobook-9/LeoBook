// responsive_constants.dart — LeoBook Design System v2.0
// Part of LeoBook App — Constants
//
// DeviceType enum, Breakpoints, and Responsive utilities.
// Additive over v1: all existing helpers preserved.

library;

import 'package:flutter/material.dart';

// ─── Device Type ──────────────────────────────────────────────
enum DeviceType { mobile, tablet, desktop }

// ─── Breakpoints ──────────────────────────────────────────────
abstract final class Breakpoints {
  static const double mobile  = 480.0;
  static const double tablet  = 768.0;
  static const double desktop = 1024.0;
}

// ─── Responsive Utilities ─────────────────────────────────────
class Responsive {
  Responsive._();

  // ── Legacy breakpoints (kept for backward compat) ──
  static const double breakpointMobile  = 600;
  static const double breakpointTablet  = 900;
  static const double breakpointDesktop = 1024;
  static const double breakpointWide    = 1400;

  // ── Reference width (iPhone SE = 375) ──
  static const double _ref = 375;

  /// Returns the [DeviceType] for the current viewport width.
  static DeviceType of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= Breakpoints.desktop) return DeviceType.desktop;
    if (width >= Breakpoints.tablet)  return DeviceType.tablet;
    return DeviceType.mobile;
  }

  /// Scale-proportional value.
  /// Returns [base] scaled to the current viewport relative to [_ref].
  /// Clamped to [0.65x, 1.6x] to prevent extreme scaling.
  static double sp(BuildContext context, double base) {
    final w = MediaQuery.sizeOf(context).width;
    final scale = (w / _ref).clamp(0.65, 1.6);
    return base * scale;
  }

  /// Density-proportional value.
  /// On desktop (≥1024dp) scales relative to a 1440dp reference.
  /// Delegates to [sp] on mobile/tablet.
  static double dp(BuildContext context, double base) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= Breakpoints.desktop) {
      final scale = (w / 1440).clamp(0.7, 1.3);
      return base * scale;
    }
    return sp(context, base);
  }

  // ── Layout helpers (legacy, preserved) ──

  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w > breakpointDesktop) return sp(context, 24);
    if (w > breakpointTablet)  return sp(context, 16);
    return sp(context, 10);
  }

  static double cardWidth(double availableWidth,
      {double minWidth = 160, double maxWidth = 300}) {
    return (availableWidth * 0.28).clamp(minWidth, maxWidth);
  }

  static double listHeight(double availableWidth,
      {double min = 120, double max = 200}) {
    return (availableWidth * 0.12).clamp(min, max);
  }

  static EdgeInsets bottomNavMargin(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final horizontal = (w * 0.04).clamp(16.0, 40.0);
    final bottom = (w * 0.025).clamp(8.0, 20.0);
    return EdgeInsets.fromLTRB(horizontal, 0, horizontal, bottom);
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < breakpointTablet;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= breakpointTablet && w < breakpointDesktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpointDesktop;
}
