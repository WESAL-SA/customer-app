import 'dart:async';

import '../../core/network/api_result.dart';
import '../auth/domain/auth_repository.dart';
import '../auth/domain/user.dart';
import '../payments/domain/payment_method.dart';
import '../payments/domain/payment_repository.dart';
import '../realtime/realtime_service.dart';
import '../trips/domain/models.dart';
import '../trips/domain/trip_repository.dart';
import 'mock_backend.dart';

/// ⚠️ MOCK IMPLEMENTATIONS — NOT PRODUCTION ⚠️
///
/// These satisfy the domain contracts with in-memory data and artificial
/// latency so the UI can be built and reviewed. They are wired only when
/// `AppConfig.useMockServices == true`. No real network, drivers, or payments.

const _latency = Duration(milliseconds: 500);

class MockAuthRepository implements AuthRepository {
  WesalUser? _user;

  @override
  Future<WesalUser?> restoreSession() async {
    await Future<void>.delayed(_latency);
    return _user; // null until the user signs in during this run
  }

  @override
  Future<Result<OtpChallenge>> requestOtp(String phone) async {
    await Future<void>.delayed(_latency);
    // A real backend sends an SMS. Here we DO NOT generate or reveal any code —
    // the mock verify step accepts any 4 digits. (Never log OTPs, §25/§40.)
    return Ok(OtpChallenge(
      challengeId: 'chal_${DateTime.now().millisecondsSinceEpoch}',
      phone: phone,
      resendCooldown: const Duration(seconds: 30),
      codeLength: 4,
    ));
  }

  @override
  Future<Result<WesalUser>> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    await Future<void>.delayed(_latency);
    if (code.length != 4) {
      return const Err(Failure(kind: FailureKind.validation, code: 'OTP_INVALID'));
    }
    _user = const WesalUser(
      id: 'user_mock',
      phone: '+9665XXXXXXXX',
      isProfileComplete: false,
    );
    return Ok(_user!);
  }

  @override
  Future<Result<WesalUser>> updateProfile({String? name, String? email}) async {
    await Future<void>.delayed(_latency);
    _user = (_user ?? const WesalUser(id: 'user_mock', phone: '+9665XXXXXXXX'))
        .copyWith(name: name, email: email, isProfileComplete: true);
    return Ok(_user!);
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(_latency);
    _user = null;
  }
}

class MockTripRepository implements TripRepository {
  MockTripRepository(this._backend);
  final MockBackend _backend;

  @override
  Future<Result<List<Place>>> searchPlaces(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return Ok(_backend.search(query));
  }

  @override
  Future<Result<List<Place>>> savedAndRecentPlaces() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return Ok(_backend.savedAndRecent());
  }

  @override
  Future<Result<Place>> resolvePickup(LatLng location) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return Ok(_backend.resolvePickup(location));
  }

  @override
  Future<Result<FareQuote>> requestQuote({
    required Place pickup,
    required Place destination,
  }) async {
    await Future<void>.delayed(_latency);
    return Ok(_backend.quote(pickup, destination));
  }

  // The mock keeps the last quote so requestRide can resolve option by id.
  FareQuote? _lastQuote;

  @override
  Future<Result<Trip>> requestRide({
    required String quoteId,
    required String rideOptionId,
    required String paymentMethodId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(_latency);
    final quote = _lastQuote;
    if (quote == null) {
      return const Err(Failure(kind: FailureKind.conflict, code: 'NO_QUOTE'));
    }
    final option = quote.options.firstWhere(
      (o) => o.id == rideOptionId,
      orElse: () => quote.options.first,
    );
    // Pickup/destination are carried on the quote request flow; the controller
    // passes them through setQuoteContext below.
    final trip = _backend.requestRide(
      quote: quote,
      option: option,
      pickup: _pickup!,
      destination: _destination!,
      paymentLabel: _paymentLabel ?? 'Cash',
    );
    return Ok(trip);
  }

  // Lightweight context the booking controller sets before requestRide, so the
  // mock can build a realistic trip. The REAL API takes these in the request
  // body instead; this indirection does not exist in the real repo.
  Place? _pickup;
  Place? _destination;
  String? _paymentLabel;
  void setQuoteContext({
    required FareQuote quote,
    required Place pickup,
    required Place destination,
    required String paymentLabel,
  }) {
    _lastQuote = quote;
    _pickup = pickup;
    _destination = destination;
    _paymentLabel = paymentLabel;
  }

  @override
  Future<Result<Trip>> getTrip(String tripId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final trip = _backend.getTrip(tripId);
    if (trip == null) {
      return const Err(Failure(kind: FailureKind.notFound));
    }
    return Ok(trip);
  }

  @override
  Future<Result<Trip?>> activeTrip() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return Ok(_backend.activeTrip);
  }

  @override
  Future<Result<Trip>> cancelTrip(String tripId) async {
    await Future<void>.delayed(_latency);
    return Ok(_backend.cancel(tripId));
  }

  @override
  Future<Result<void>> rateTrip({
    required String tripId,
    required int stars,
    String? comment,
  }) async {
    await Future<void>.delayed(_latency);
    _backend.rate(tripId, stars);
    return const Ok(null);
  }

  @override
  Future<Result<TripPage>> history({String? cursor, int limit = 20}) async {
    await Future<void>.delayed(_latency);
    return Ok(TripPage(trips: _backend.history()));
  }
}

class MockPaymentRepository implements PaymentRepository {
  final List<PaymentMethod> _methods = [
    const PaymentMethod(
      id: 'pm_mada',
      type: PaymentType.mada,
      brand: 'Mada',
      maskedNumber: '4821',
      isDefault: true,
      providerTokenRef: 'mock_token_ref',
    ),
    const PaymentMethod(id: 'pm_cash', type: PaymentType.cash),
  ];

  @override
  Future<Result<List<PaymentMethod>>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return Ok(List.unmodifiable(_methods));
  }

  @override
  Future<Result<PaymentMethod>> add({
    required PaymentType type,
    String? providerTokenRef,
  }) async {
    await Future<void>.delayed(_latency);
    final pm = PaymentMethod(
      id: 'pm_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      providerTokenRef: providerTokenRef,
    );
    _methods.add(pm);
    return Ok(pm);
  }

  @override
  Future<Result<void>> remove(String id) async {
    await Future<void>.delayed(_latency);
    _methods.removeWhere((m) => m.id == id);
    return const Ok(null);
  }

  @override
  Future<Result<void>> setDefault(String id) async {
    await Future<void>.delayed(_latency);
    for (var i = 0; i < _methods.length; i++) {
      final m = _methods[i];
      _methods[i] = PaymentMethod(
        id: m.id,
        type: m.type,
        maskedNumber: m.maskedNumber,
        brand: m.brand,
        isDefault: m.id == id,
        providerTokenRef: m.providerTokenRef,
      );
    }
    return const Ok(null);
  }
}

class MockRealtimeService implements RealtimeService {
  MockRealtimeService(this._backend);
  final MockBackend _backend;

  final _conn = StreamController<RealtimeConnectionState>.broadcast();

  @override
  Stream<RealtimeConnectionState> get connectionState => _conn.stream;

  @override
  Stream<TripUpdate> subscribeToTrip(String tripId) {
    _conn.add(RealtimeConnectionState.connected);
    return _backend.updates.where((u) => u.tripId == tripId);
  }

  @override
  Future<void> disconnect() async {
    _conn.add(RealtimeConnectionState.disconnected);
  }
}
