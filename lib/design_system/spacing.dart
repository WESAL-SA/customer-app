/// 4-pt spacing scale. Use these tokens instead of magic numbers so layout
/// stays consistent across screens (spec §33).
abstract final class WesalSpacing {
  WesalSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Default screen edge gutter.
  static const double screen = 20;
}

abstract final class WesalRadii {
  WesalRadii._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}
