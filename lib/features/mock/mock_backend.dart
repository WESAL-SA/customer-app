import 'dart:async';
import 'dart:math';

import '../realtime/realtime_service.dart';
import '../trips/domain/models.dart';
import '../trips/domain/trip_status.dart';

/// ⚠️ MOCK BACKEND — NOT PRODUCTION ⚠️
///
/// This simulates the Wesal backend entirely in memory so the app runs and is
/// reviewable before the real services exist. It is deliberately obvious that
/// this is fake:
///   - No real drivers, no real payments, no real dispatch.
///   - Data is seeded locally and the trip "progresses" on timers.
///
/// It is wired in only when `AppConfig.useMockServices == true`. When the real
/// backend lands, the real repositories replace the mock ones in `di.dart` and
/// this file is NOT shipped to production (see the `useMockServices` guard).
///
/// Shared by MockTripRepository and MockRealtimeService so the realtime stream
/// reflects the same simulated trip the booking flow created.
class MockBackend {
  MockBackend();

  final _rng = Random();
  final _updates = StreamController<TripUpdate>.broadcast();

  Trip? _activeTrip;
  Timer? _progressTimer;
  Timer? _driverMoveTimer;

  Trip? get activeTrip =>
      (_activeTrip != null && _activeTrip!.status.isActive) ? _activeTrip : null;

  Stream<TripUpdate> get updates => _updates.stream;

  // ---- Seed data -----------------------------------------------------------

  static final List<Place> _savedPlaces = [
    const Place(
      id: 'home',
      title: 'Home',
      subtitle: 'Al Olaya, Riyadh',
      location: LatLng(24.6908, 46.6854),
      kind: PlaceKind.home,
    ),
    const Place(
      id: 'work',
      title: 'Work',
      subtitle: 'King Fahd Rd, Riyadh',
      location: LatLng(24.7136, 46.6753),
      kind: PlaceKind.work,
    ),
  ];

  static final List<Place> _recent = [
    const Place(
      id: 'r1',
      title: 'Kingdom Centre',
      subtitle: 'Al Olaya, Riyadh',
      location: LatLng(24.7114, 46.6744),
      kind: PlaceKind.recent,
    ),
    const Place(
      id: 'r2',
      title: 'Riyadh Park Mall',
      subtitle: 'Northern Ring Rd',
      location: LatLng(24.7606, 46.6361),
      kind: PlaceKind.recent,
    ),
  ];

  static final List<Place> _directory = [
    const Place(
      id: 'p_airport',
      title: 'King Khalid International Airport',
      subtitle: 'Airport Rd, Riyadh',
      location: LatLng(24.9576, 46.6988),
    ),
    const Place(
      id: 'p_kingdom',
      title: 'Kingdom Centre',
      subtitle: 'Al Olaya, Riyadh',
      location: LatLng(24.7114, 46.6744),
    ),
    const Place(
      id: 'p_masmak',
      title: 'Masmak Fortress',
      subtitle: 'Al Dirah, Riyadh',
      location: LatLng(24.6314, 46.7136),
    ),
    const Place(
      id: 'p_boulevard',
      title: 'Boulevard Riyadh City',
      subtitle: 'Hittin, Riyadh',
      location: LatLng(24.7742, 46.6186),
    ),
    const Place(
      id: 'p_park',
      title: 'Riyadh Park Mall',
      subtitle: 'Northern Ring Rd',
      location: LatLng(24.7606, 46.6361),
    ),
  ];

  List<Place> savedAndRecent() => [..._savedPlaces, ..._recent];

  List<Place> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _recent;
    return _directory
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.subtitle.toLowerCase().contains(q))
        .toList();
  }

  Place resolvePickup(LatLng location) => Place(
        id: 'pickup_current',
        title: 'Current location',
        subtitle: 'Riyadh',
        location: location,
        kind: PlaceKind.search,
      );

  // ---- Fare quote ----------------------------------------------------------

  FareQuote quote(Place pickup, Place destination) {
    final km = _haversineKm(pickup.location, destination.location);
    final minutes = max(5, (km * 1.8).round());
    // NOTE: this is a MOCK estimate. The real fare engine is authoritative (§9).
    double fareFor(double perKm, double base) =>
        (base + km * perKm).clamp(10.0, 500.0);

    final economy = fareFor(1.6, 8);
    final comfort = fareFor(2.4, 12);

    return FareQuote(
      quoteId: 'q_${DateTime.now().millisecondsSinceEpoch}',
      distanceMeters: (km * 1000).round(),
      durationSeconds: minutes * 60,
      expiresAt: DateTime.now().add(const Duration(minutes: 2)),
      options: [
        RideOption(
          id: 'economy',
          name: 'Wesal Economy',
          description: 'Affordable everyday rides',
          capacity: 4,
          etaMinutes: 3 + _rng.nextInt(4),
          estimatedFare: Money(amount: _round(economy)),
          estimatedFareMax: Money(amount: _round(economy * 1.15)),
          iconKey: 'economy',
        ),
        RideOption(
          id: 'comfort',
          name: 'Wesal Comfort',
          description: 'Newer cars, extra legroom',
          capacity: 4,
          etaMinutes: 4 + _rng.nextInt(5),
          estimatedFare: Money(amount: _round(comfort)),
          estimatedFareMax: Money(amount: _round(comfort * 1.15)),
          iconKey: 'comfort',
        ),
      ],
    );
  }

  // ---- Ride lifecycle ------------------------------------------------------

  Trip requestRide({
    required FareQuote quote,
    required RideOption option,
    required Place pickup,
    required Place destination,
    required String paymentLabel,
  }) {
    final trip = Trip(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      status: TripStatus.searchingDriver,
      pickup: pickup,
      destination: destination,
      estimatedFare: option.estimatedFare,
      rideOptionName: option.name,
      paymentMethodLabel: paymentLabel,
      createdAt: DateTime.now(),
    );
    _activeTrip = trip;
    _scheduleProgress();
    return trip;
  }

  void _scheduleProgress() {
    // Simulate dispatch assigning a driver, then the pickup + trip timeline.
    _progressTimer?.cancel();
    _progressTimer = Timer(const Duration(seconds: 4), () {
      _assignDriver();
      _advance(TripStatus.driverArriving, after: const Duration(seconds: 2));
      _advance(TripStatus.driverArrived, after: const Duration(seconds: 10));
      _advance(TripStatus.tripStarted, after: const Duration(seconds: 14));
      _complete(after: const Duration(seconds: 22));
    });
  }

  void _assignDriver() {
    final current = _activeTrip;
    if (current == null) return;
    const driver = Driver(
      id: 'drv_1',
      name: 'Ahmed',
      rating: 4.9,
      vehicle: Vehicle(
        make: 'Toyota',
        model: 'Camry',
        color: 'White',
        plate: 'ABC 1234',
      ),
    );
    _activeTrip = current.copyWith(
      status: TripStatus.driverAssigned,
      driver: driver,
      driverEtaMinutes: 4,
      driverLocation: _near(current.pickup.location, 0.01),
    );
    _emit(full: true);
    _startDriverMovement();
  }

  void _startDriverMovement() {
    _driverMoveTimer?.cancel();
    _driverMoveTimer =
        Timer.periodic(const Duration(seconds: 2), (_) {
      final current = _activeTrip;
      if (current == null || !current.status.isActive) {
        _driverMoveTimer?.cancel();
        return;
      }
      final target = current.status == TripStatus.tripStarted
          ? current.destination.location
          : current.pickup.location;
      final moved = _stepToward(
        current.driverLocation ?? _near(target, 0.01),
        target,
      );
      _activeTrip = current.copyWith(driverLocation: moved);
      _updates.add(TripUpdate(
        tripId: current.id,
        driverLocation: moved,
        driverEtaMinutes: current.driverEtaMinutes,
      ));
    });
  }

  void _advance(TripStatus status, {required Duration after}) {
    Timer(after, () {
      final current = _activeTrip;
      if (current == null || current.status.isTerminal) return;
      _activeTrip = current.copyWith(status: status);
      _emit(full: true);
    });
  }

  void _complete({required Duration after}) {
    Timer(after, () {
      final current = _activeTrip;
      if (current == null || current.status.isTerminal) return;
      final fare = current.estimatedFare;
      final base = Money(amount: _round(fare.amount * 0.35));
      final dist = Money(amount: _round(fare.amount * 0.45));
      final time = Money(amount: _round(fare.amount * 0.1));
      final vat = Money(amount: _round(fare.amount * 0.10));
      _activeTrip = current.copyWith(
        status: TripStatus.tripCompleted,
        finalFare: fare,
        completedAt: DateTime.now(),
        fareLines: [
          FareLine(label: 'baseFare', amount: base),
          FareLine(label: 'distanceFare', amount: dist),
          FareLine(label: 'timeFare', amount: time),
          FareLine(label: 'tax', amount: vat),
        ],
      );
      _emit(full: true);
      _driverMoveTimer?.cancel();
    });
  }

  Trip cancel(String tripId) {
    final current = _activeTrip;
    _progressTimer?.cancel();
    _driverMoveTimer?.cancel();
    if (current != null && current.id == tripId) {
      _activeTrip = current.copyWith(status: TripStatus.cancelledByCustomer);
      _emit(full: true);
      return _activeTrip!;
    }
    return current ?? _notFound(tripId);
  }

  Trip? getTrip(String tripId) {
    if (_activeTrip?.id == tripId) return _activeTrip;
    for (final t in _history) {
      if (t.id == tripId) return t;
    }
    return null;
  }

  void rate(String tripId, int stars) {
    if (_activeTrip?.id == tripId) {
      _activeTrip = _activeTrip!.copyWith(customerRating: stars.toDouble());
      _archiveIfTerminal();
    }
  }

  // ---- History -------------------------------------------------------------

  final List<Trip> _history = [
    Trip(
      id: 'trip_hist_1',
      status: TripStatus.tripCompleted,
      pickup: const Place(
        id: 'h1p',
        title: 'Kingdom Centre',
        subtitle: 'Al Olaya',
        location: LatLng(24.7114, 46.6744),
      ),
      destination: const Place(
        id: 'h1d',
        title: 'King Khalid International Airport',
        subtitle: 'Airport Rd',
        location: LatLng(24.9576, 46.6988),
      ),
      estimatedFare: const Money(amount: 32),
      finalFare: const Money(amount: 32),
      rideOptionName: 'Wesal Economy',
      paymentMethodLabel: 'Mada •••• 4821',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      completedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
      customerRating: 5,
    ),
    Trip(
      id: 'trip_hist_2',
      status: TripStatus.tripCompleted,
      pickup: const Place(
        id: 'h2p',
        title: 'Al Olaya',
        subtitle: 'Riyadh',
        location: LatLng(24.6908, 46.6854),
      ),
      destination: const Place(
        id: 'h2d',
        title: 'Riyadh Park Mall',
        subtitle: 'Northern Ring Rd',
        location: LatLng(24.7606, 46.6361),
      ),
      estimatedFare: const Money(amount: 21),
      finalFare: const Money(amount: 21),
      rideOptionName: 'Wesal Comfort',
      paymentMethodLabel: 'Cash',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      completedAt: DateTime.now().subtract(const Duration(days: 1)),
      customerRating: 4,
    ),
  ];

  List<Trip> history() => [
        if (_activeTrip != null && _activeTrip!.status.isTerminal) _activeTrip!,
        ..._history,
      ];

  void _archiveIfTerminal() {
    final current = _activeTrip;
    if (current != null &&
        current.status.isTerminal &&
        !_history.any((t) => t.id == current.id)) {
      _history.insert(0, current);
    }
  }

  // ---- helpers -------------------------------------------------------------

  void _emit({bool full = false}) {
    final current = _activeTrip;
    if (current == null) return;
    _updates.add(TripUpdate(tripId: current.id, trip: full ? current : null));
  }

  Trip _notFound(String id) => Trip(
        id: id,
        status: TripStatus.unknown,
        pickup: const Place(
            id: '_', title: '', subtitle: '', location: LatLng(0, 0)),
        destination: const Place(
            id: '_', title: '', subtitle: '', location: LatLng(0, 0)),
        estimatedFare: const Money(amount: 0),
      );

  LatLng _near(LatLng p, double jitter) => LatLng(
        p.lat + (_rng.nextDouble() - 0.5) * jitter,
        p.lng + (_rng.nextDouble() - 0.5) * jitter,
      );

  LatLng _stepToward(LatLng from, LatLng to, [double frac = 0.25]) => LatLng(
        from.lat + (to.lat - from.lat) * frac,
        from.lng + (to.lng - from.lng) * frac,
      );

  static double _round(double v) => (v * 100).round() / 100;

  static double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _rad(b.lat - a.lat);
    final dLng = _rad(b.lng - a.lng);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(a.lat)) * cos(_rad(b.lat)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  static double _rad(double deg) => deg * pi / 180;

  void dispose() {
    _progressTimer?.cancel();
    _driverMoveTimer?.cancel();
    _updates.close();
  }
}
