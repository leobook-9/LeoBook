// app_theme_v2.dart — LeoBook Design System v2.0
// Part of LeoBook App — Theme
//
// AppThemeV2 replaces AppTheme as the active theme.
// AppTheme (Lexend/legacy) is kept for reference but no longer wired into main.

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/spacing_constants.dart';
import 'leo_typography.dart';

class AppThemeV2 {
  AppThemeV2._();

  // ─────────────────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.textPrimary,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textInverse,
      secondaryContainer: AppColors.secondaryDark,
      onSecondaryContainer: AppColors.secondaryLight,
      error: AppColors.error,
      onError: AppColors.textPrimary,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.error,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.neutral500,
      outlineVariant: AppColors.neutral600,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: AppColors.neutral100,
      onInverseSurface: AppColors.textInverse,
      inversePrimary: AppColors.primaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.neutral900,
      primaryColor: AppColors.primary,
      cardColor: AppColors.surfaceCard,

      // ── Typography ──
      textTheme: LeoTypography.toTextTheme(colorScheme),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.neutral800,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: LeoTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: SpacingScale.iconSize,
        ),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingScale.cardRadius),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral700,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingScale.lg,
          vertical: SpacingScale.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpacingScale.borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpacingScale.borderRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpacingScale.borderRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: LeoTypography.bodyMedium.copyWith(
          color: AppColors.textDisabled,
        ),
        labelStyle: LeoTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // ── Bottom Sheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      // ── Snack Bar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: LeoTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingScale.borderRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingScale.borderRadius),
        ),
      ),

      // ── Divider ──
      dividerColor: AppColors.divider,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
      ),

      // ── Icon ──
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: SpacingScale.iconSize,
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutral700,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.neutral600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingScale.chipRadius),
        ),
        labelStyle: LeoTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingScale.cardRadius),
        ),
        titleTextStyle: LeoTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        contentTextStyle: LeoTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(SpacingScale.xs),
        ),
        textStyle: LeoTypography.bodySmall.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textPrimary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.secondaryLight,
      onSecondaryContainer: AppColors.secondaryDark,
      error: AppColors.error,
      onError: AppColors.textPrimary,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.error,
      surface: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.neutral300,
      outlineVariant: AppColors.neutral200,
      shadow: Colors.black12,
      scrim: Colors.black26,
      inverseSurface: AppColors.neutral800,
      onInverseSurface: AppColors.textPrimary,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.neutral50,
      primaryColor: AppColors.primary,
      cardColor: Colors.white,

      // ── Typography ──
      textTheme: LeoTypography.toTextTheme(colorScheme),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: LeoTypography.titleLarge.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryLight,
          size: SpacingScale.iconSize,
        ),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.black12,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingScale.cardRadius),
          side: BorderSide(color: AppColors.neutral200, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingScale.lg,
          vertical: SpacingScale.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpacingScale.borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpacingScale.borderRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpacingScale.borderRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: LeoTypography.bodyMedium.copyWith(
          color: AppColors.textDisabledLight,
        ),
        labelStyle: LeoTypography.labelMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),

      // ── Bottom Sheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      // ── Snack Bar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.neutral800,
        contentTextStyle: LeoTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingScale.borderRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingScale.borderRadius),
        ),
      ),

      // ── Divider ──
      dividerColor: AppColors.neutral200,
      dividerTheme: DividerThemeData(
        color: AppColors.neutral200,
        thickness: 0.5,
      ),

      // ── Icon ──
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryLight,
        size: SpacingScale.iconSize,
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutral100,
        selectedColor: AppColors.primary,
        side: BorderSide(color: AppColors.neutral200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingScale.chipRadius),
        ),
        labelStyle: LeoTypography.labelMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingScale.cardRadius),
        ),
        titleTextStyle: LeoTypography.titleLarge.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        contentTextStyle: LeoTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.neutral800,
          borderRadius: BorderRadius.circular(SpacingScale.xs),
        ),
        textStyle: LeoTypography.bodySmall.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
