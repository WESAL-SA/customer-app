import 'package:flutter/material.dart';

/// Wesal brand color tokens.
///
/// Do not use raw `Color(0x...)` in screens — always reference these tokens or
/// the themed `ColorScheme`. This keeps light/dark and future rebrands to a
/// single source of truth (spec §33).
abstract final class WesalColors {
  WesalColors._();

  // Brand — a confident Saudi-market teal/emerald ("wesal" = connection).
  static const Color brand = Color(0xFF0E7C66);
  static const Color brandDark = Color(0xFF0A5E4E);
  static const Color brandLight = Color(0xFF3FA793);
  static const Color brandSurface = Color(0xFFE7F4F0);

  // Ink / neutrals.
  static const Color ink = Color(0xFF12121A);
  static const Color ink700 = Color(0xFF3A3A44);
  static const Color ink500 = Color(0xFF6B6B76);
  static const Color ink300 = Color(0xFFABABB4);
  static const Color line = Color(0xFFE6E6EA);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color white = Color(0xFFFFFFFF);

  // Dark mode neutrals.
  static const Color darkBg = Color(0xFF0E0F13);
  static const Color darkSurface = Color(0xFF17191F);
  static const Color darkElevated = Color(0xFF20232B);
  static const Color darkLine = Color(0xFF2C2F38);
  static const Color darkInk = Color(0xFFF2F3F5);
  static const Color darkInk500 = Color(0xFF9A9CA6);

  // Semantic.
  static const Color success = Color(0xFF1C9E63);
  static const Color warning = Color(0xFFCB8A00);
  static const Color danger = Color(0xFFD64545);
  static const Color info = Color(0xFF2F6FED);

  // Emergency / safety (always high-contrast red regardless of theme).
  static const Color emergency = Color(0xFFD12D2D);
}
