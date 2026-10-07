import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Builds the light and dark [ThemeData] from the Wesal tokens.
///
/// Screens should read colors from `Theme.of(context).colorScheme` and text
/// from `Theme.of(context).textTheme` rather than hardcoding, so dark mode and
/// rebrands come for free (spec §33, §35).
abstract final class WesalTheme {
  WesalTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: WesalColors.brand,
      onPrimary: WesalColors.white,
      primaryContainer: WesalColors.brandSurface,
      onPrimaryContainer: WesalColors.brandDark,
      secondary: WesalColors.brandLight,
      onSecondary: WesalColors.white,
      surface: WesalColors.white,
      onSurface: WesalColors.ink,
      surfaceContainerHighest: WesalColors.surface,
      outline: WesalColors.line,
      error: WesalColors.danger,
      onError: WesalColors.white,
    );
    return _base(scheme, Brightness.light, WesalColors.ink500);
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: WesalColors.brandLight,
      onPrimary: WesalColors.ink,
      primaryContainer: WesalColors.brandDark,
      onPrimaryContainer: WesalColors.white,
      secondary: WesalColors.brand,
      onSecondary: WesalColors.white,
      surface: WesalColors.darkSurface,
      onSurface: WesalColors.darkInk,
      surfaceContainerHighest: WesalColors.darkElevated,
      outline: WesalColors.darkLine,
      error: WesalColors.danger,
      onError: WesalColors.white,
    );
    return _base(scheme, Brightness.dark, WesalColors.darkInk500);
  }

  static ThemeData _base(
    ColorScheme scheme,
    Brightness brightness,
    Color muted,
  ) {
    final textTheme = WesalType.textTheme(scheme.onSurface, muted);
    final scaffoldBg =
        brightness == Brightness.dark ? WesalColors.darkBg : WesalColors.surface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: WesalType.fontFamily,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54), // large tap target (§35)
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WesalRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WesalRadii.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: WesalSpacing.lg,
          vertical: WesalSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WesalRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WesalRadii.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WesalRadii.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: muted),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WesalRadii.lg),
        ),
      ),
    );
  }
}
