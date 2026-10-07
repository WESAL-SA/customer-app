import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/storage/token_store.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/mock/mock_backend.dart';
import '../features/mock/mock_repositories.dart';
import '../features/payments/domain/payment_repository.dart';
import '../features/realtime/realtime_service.dart';
import '../features/trips/domain/trip_repository.dart';

/// Dependency wiring. This is the SINGLE place that chooses between the mock
/// service layer (now) and the real HTTP/WebSocket implementations (later).
///
/// To connect the real backend:
///   1. Implement `RealAuthRepository`, `RealTripRepository`, etc. against the
///      domain contracts, using `ApiClient` + the OpenAPI the backend exposes.
///   2. Return them from the providers below when `!config.useMockServices`.
/// No screen or controller changes — they depend only on the interfaces.

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.useMockServices ? InMemoryTokenStore() : SecureTokenStore();
});

/// Shared in-memory mock backend (only created in mock mode).
final mockBackendProvider = Provider<MockBackend>((ref) {
  final backend = MockBackend();
  ref.onDispose(backend.dispose);
  return backend;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockServices) return MockAuthRepository();
  // INTEGRATION POINT: return RealAuthRepository(ref.watch(apiClientProvider)).
  throw UnimplementedError(
    'RealAuthRepository not implemented yet — run with WESAL_USE_MOCKS=true.',
  );
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockServices) {
    return MockTripRepository(ref.watch(mockBackendProvider));
  }
  // INTEGRATION POINT: return RealTripRepository(ref.watch(apiClientProvider)).
  throw UnimplementedError(
    'RealTripRepository not implemented yet — run with WESAL_USE_MOCKS=true.',
  );
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockServices) return MockPaymentRepository();
  // INTEGRATION POINT: return RealPaymentRepository(...).
  throw UnimplementedError(
    'RealPaymentRepository not implemented yet — run with WESAL_USE_MOCKS=true.',
  );
});

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockServices) {
    return MockRealtimeService(ref.watch(mockBackendProvider));
  }
  // INTEGRATION POINT: return WebSocketRealtimeService(config.wsBaseUrl, ...).
  throw UnimplementedError(
    'WebSocketRealtimeService not implemented yet — run with WESAL_USE_MOCKS=true.',
  );
});
