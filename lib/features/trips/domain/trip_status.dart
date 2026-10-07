/// Centralized trip state machine (spec §30).
///
/// The BACKEND is the single source of truth for trip state. The client never
/// invents states — it maps the backend's string to [TripStatus] via
/// [TripStatusX.fromWire] and renders accordingly. Any unknown value maps to
/// [TripStatus.unknown] and the client re-fetches authoritative state rather
/// than guessing.
enum TripStatus {
  // Happy-path progression.
  requested,
  searchingDriver,
  driverAssigned,
  driverArriving,
  driverArrived,
  tripStarted,
  tripCompleted,

  // Terminal / alternative outcomes.
  cancelledByCustomer,
  cancelledByDriver,
  cancelledBySystem,
  noDriverAvailable,
  paymentFailed,

  /// Fallback for an unrecognized backend value — treat as "re-sync needed".
  unknown,
}

extension TripStatusX on TripStatus {
  /// Maps the backend wire value (SCREAMING_SNAKE_CASE per spec §30) to the
  /// client enum. Keep this the ONLY place that knows wire strings.
  static TripStatus fromWire(String? wire) {
    switch (wire?.toUpperCase()) {
      case 'REQUESTED':
        return TripStatus.requested;
      case 'SEARCHING_DRIVER':
        return TripStatus.searchingDriver;
      case 'DRIVER_ASSIGNED':
        return TripStatus.driverAssigned;
      case 'DRIVER_ARRIVING':
        return TripStatus.driverArriving;
      case 'DRIVER_ARRIVED':
        return TripStatus.driverArrived;
      case 'TRIP_STARTED':
        return TripStatus.tripStarted;
      case 'TRIP_COMPLETED':
        return TripStatus.tripCompleted;
      case 'CANCELLED_BY_CUSTOMER':
        return TripStatus.cancelledByCustomer;
      case 'CANCELLED_BY_DRIVER':
        return TripStatus.cancelledByDriver;
      case 'CANCELLED_BY_SYSTEM':
        return TripStatus.cancelledBySystem;
      case 'NO_DRIVER_AVAILABLE':
        return TripStatus.noDriverAvailable;
      case 'PAYMENT_FAILED':
        return TripStatus.paymentFailed;
      default:
        return TripStatus.unknown;
    }
  }

  String get wire {
    switch (this) {
      case TripStatus.requested:
        return 'REQUESTED';
      case TripStatus.searchingDriver:
        return 'SEARCHING_DRIVER';
      case TripStatus.driverAssigned:
        return 'DRIVER_ASSIGNED';
      case TripStatus.driverArriving:
        return 'DRIVER_ARRIVING';
      case TripStatus.driverArrived:
        return 'DRIVER_ARRIVED';
      case TripStatus.tripStarted:
        return 'TRIP_STARTED';
      case TripStatus.tripCompleted:
        return 'TRIP_COMPLETED';
      case TripStatus.cancelledByCustomer:
        return 'CANCELLED_BY_CUSTOMER';
      case TripStatus.cancelledByDriver:
        return 'CANCELLED_BY_DRIVER';
      case TripStatus.cancelledBySystem:
        return 'CANCELLED_BY_SYSTEM';
      case TripStatus.noDriverAvailable:
        return 'NO_DRIVER_AVAILABLE';
      case TripStatus.paymentFailed:
        return 'PAYMENT_FAILED';
      case TripStatus.unknown:
        return 'UNKNOWN';
    }
  }

  /// A trip the customer is currently inside (drives active-trip UI + recovery).
  bool get isActive => const {
        TripStatus.requested,
        TripStatus.searchingDriver,
        TripStatus.driverAssigned,
        TripStatus.driverArriving,
        TripStatus.driverArrived,
        TripStatus.tripStarted,
      }.contains(this);

  bool get isTerminal => const {
        TripStatus.tripCompleted,
        TripStatus.cancelledByCustomer,
        TripStatus.cancelledByDriver,
        TripStatus.cancelledBySystem,
        TripStatus.noDriverAvailable,
        TripStatus.paymentFailed,
      }.contains(this);

  bool get isSearching => this == TripStatus.searchingDriver ||
      this == TripStatus.requested;

  bool get hasDriver => const {
        TripStatus.driverAssigned,
        TripStatus.driverArriving,
        TripStatus.driverArrived,
        TripStatus.tripStarted,
      }.contains(this);

  /// Whether the customer is still allowed to cancel (free vs. fee is decided
  /// by the backend — the client only shows/hides the action).
  bool get isCancellableByCustomer => const {
        TripStatus.requested,
        TripStatus.searchingDriver,
        TripStatus.driverAssigned,
        TripStatus.driverArriving,
        TripStatus.driverArrived,
      }.contains(this);
}
