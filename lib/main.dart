import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

/// Entry point.
///
/// Run with mocks (default, no backend needed):
///   flutter run
/// Run against a real environment later:
///   flutter run --dart-define=WESAL_USE_MOCKS=false \
///               --dart-define=WESAL_FLAVOR=staging \
///               --dart-define=WESAL_API_BASE_URL=https://api.staging.wesal.sa \
///               --dart-define=WESAL_WS_BASE_URL=wss://realtime.staging.wesal.sa
void main() {
  // INTEGRATION POINT (spec §40): initialize crash/observability here
  // (e.g. runZonedGuarded + FlutterError.onError → Crashlytics/Sentry) before
  // runApp, wiring AppLogger.sink to the provider.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: WesalApp()));
}
