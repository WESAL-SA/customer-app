import 'package:flutter/material.dart';

/// Wesal brand color tokens.
///
/// Do not use raw `Color(0x...)` in screens — always reference these tokens or
/// the themed `ColorScheme`. This keeps light/dark and future rebrands to a
/// single source of truth (spec §33).
abstract final class WesalColors {
  WesalColors._();

  // Brand — Wesal gold (the pin + road mark), used as the accent on dark and
  // light surfaces alike. Gold carries dark text, not white (see onPrimary).
  static const Color brand = Color(0xFFD7A93C);
  static const Color brandDark = Color(0xFFB2851F);
  static const Color brandLight = Color(0xFFECCB6E);
  static const Color brandSurface = Color(0xFFFAF3E0); // pale gold tint (light)

  // Brand dark — the charcoal/navy from the logo backdrop.
  static const Color brandInk = Color(0xFF14161B);

  // Ink / neutrals.
  static const Color ink = Color(0xFF14161B);
  static const Color ink700 = Color(0xFF3A3D45);
  static const Color ink500 = Color(0xFF6B6E78);
  static const Color ink300 = Color(0xFFABAEB6);
  static const Color line = Color(0xFFE6E6EA);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color white = Color(0xFFFFFFFF);

  // Dark mode neutrals (tuned to the logo's charcoal-navy).
  static const Color darkBg = Color(0xFF101217);
  static const Color darkSurface = Color(0xFF1A1D24);
  static const Color darkElevated = Color(0xFF242832);
  static const Color darkLine = Color(0xFF2E333D);
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
