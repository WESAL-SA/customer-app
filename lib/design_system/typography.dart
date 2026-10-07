import 'package:flutter/material.dart';

import 'colors.dart';

/// Typography scale. A single [fontFamily] token drives the whole app so an
/// Arabic-first family can be dropped in later (see pubspec fonts note).
///
/// When [fontFamily] is null, Flutter uses the platform default, which keeps
/// the app running before brand fonts are bundled.
abstract final class WesalType {
  WesalType._();

  static const String? fontFamily = null; // set to 'Wesal' once fonts are added

  static TextTheme textTheme(Color onSurface, Color muted) => TextTheme(
        displaySmall: _s(28, FontWeight.w700, onSurface, height: 1.2),
        headlineMedium: _s(24, FontWeight.w700, onSurface, height: 1.25),
        headlineSmall: _s(20, FontWeight.w700, onSurface, height: 1.3),
        titleLarge: _s(18, FontWeight.w600, onSurface, height: 1.3),
        titleMedium: _s(16, FontWeight.w600, onSurface, height: 1.35),
        bodyLarge: _s(16, FontWeight.w400, onSurface, height: 1.45),
        bodyMedium: _s(14, FontWeight.w400, onSurface, height: 1.45),
        bodySmall: _s(12, FontWeight.w400, muted, height: 1.4),
        labelLarge: _s(15, FontWeight.w600, onSurface, height: 1.2),
        labelMedium: _s(13, FontWeight.w500, muted, height: 1.2),
      );

  static TextStyle _s(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.3,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  /// The large price figure used on fare/receipt surfaces.
  static TextStyle fare(Color color) =>
      _s(26, FontWeight.w700, color, height: 1.1);
}

/// Shadows / elevation tokens.
abstract final class WesalShadows {
  WesalShadows._();

  static List<BoxShadow> card(Brightness brightness) => [
        BoxShadow(
          color: brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.35)
              : WesalColors.ink.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> sheet(Brightness brightness) => [
        BoxShadow(
          color: brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.5)
              : WesalColors.ink.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, -4),
        ),
      ];
}
