import 'flavor.dart';

/// Central app configuration.
///
/// IMPORTANT (security): this file must NEVER contain secrets — no API secret
/// keys, no payment provider secret keys, no DB credentials. Only public,
/// non-sensitive configuration (base URLs, feature flags, timeouts) belongs
/// here. The backend remains the ultimate authority (see spec §28).
///
/// Base URLs are injected at build time via `--dart-define` so they are not
/// hardcoded per environment:
///   flutter run --dart-define=WESAL_FLAVOR=staging \
///               --dart-define=WESAL_API_BASE_URL=https://api.staging.wesal.sa \
///               --dart-define=WESAL_WS_BASE_URL=wss://realtime.staging.wesal.sa
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    required this.useMockServices,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 20),
  });

  final Flavor flavor;
  final String apiBaseUrl;
  final String wsBaseUrl;

  /// When true, the app wires up the mock service layer instead of the real
  /// HTTP/WebSocket implementations. This is the single switch that flips the
  /// whole app between "mock now" and "connected to the real backend later".
  ///
  /// It defaults to true until the backend exists. Flip it off per-environment
  /// with `--dart-define=WESAL_USE_MOCKS=false`.
  final bool useMockServices;

  final Duration connectTimeout;
  final Duration receiveTimeout;

  static AppConfig fromEnvironment() {
    const flavorName =
        String.fromEnvironment('WESAL_FLAVOR', defaultValue: 'dev');
    const apiBaseUrl = String.fromEnvironment(
      'WESAL_API_BASE_URL',
      // Intentionally blank in dev: the mock layer does not call it.
      defaultValue: '',
    );
    const wsBaseUrl = String.fromEnvironment(
      'WESAL_WS_BASE_URL',
      defaultValue: '',
    );
    const useMocks = bool.fromEnvironment(
      'WESAL_USE_MOCKS',
      defaultValue: true,
    );

    return AppConfig(
      flavor: FlavorX.fromName(flavorName),
      apiBaseUrl: apiBaseUrl,
      wsBaseUrl: wsBaseUrl,
      useMockServices: useMocks,
    );
  }

  bool get isProduction => flavor == Flavor.production;
}
