import '../trips/domain/models.dart';

/// Realtime trip updates contract (spec §14, §31).
///
/// INTEGRATION POINT: the real implementation connects to the Wesal realtime
/// service (WebSocket). Requirements it must satisfy:
///   - Auto-reconnect with backoff; re-authenticate on reconnect.
///   - On (re)connect, the caller fetches authoritative trip state via
///     TripRepository.getTrip — realtime is a delta stream, not the source of
///     truth (§31: never assume the last client state is correct).
///   - Smooth driver-marker interpolation happens in the UI layer.
///   - Do not poll unnecessarily; prefer pushed events (§14).
abstract interface class RealtimeService {
  /// Subscribes to updates for a single trip. The stream emits whenever the
  /// backend reports a change (status transition, driver movement, ETA).
  Stream<TripUpdate> subscribeToTrip(String tripId);

  /// Current connection status, for showing a reconnecting indicator.
  Stream<RealtimeConnectionState> get connectionState;

  Future<void> disconnect();
}

enum RealtimeConnectionState { connecting, connected, reconnecting, disconnected }

/// A delta applied on top of the authoritative Trip the client already holds.
class TripUpdate {
  const TripUpdate({
    required this.tripId,
    this.trip,
    this.driverLocation,
    this.driverEtaMinutes,
  });

  final String tripId;

  /// When present, a full authoritative trip snapshot (e.g. on status change).
  final Trip? trip;

  /// High-frequency driver location updates.
  final LatLng? driverLocation;
  final int? driverEtaMinutes;
}
