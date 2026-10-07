import '../../../core/network/api_result.dart';
import 'models.dart';

/// Trips + booking contract (spec §5–§20, §30).
///
/// INTEGRATION POINT: the real implementation calls the Wesal fare, dispatch
/// and trip APIs. Key invariants the real impl must preserve:
///   - The fare engine is authoritative (§9): the client never computes fares.
///   - Dispatch chooses the driver (§12): the client never selects one.
///   - Trip state comes from the backend (§30): mapped via TripStatus.fromWire.
///   - Duplicate ride requests must be prevented server-side (idempotency key).
abstract interface class TripRepository {
  /// Autocomplete / place search for the destination field (§5).
  Future<Result<List<Place>>> searchPlaces(String query);

  /// Recent + saved places (home/work/favorites) (§5).
  Future<Result<List<Place>>> savedAndRecentPlaces();

  /// Reverse-geocode the device location into a Place for pickup (§6).
  Future<Result<Place>> resolvePickup(LatLng location);

  /// Requests an authoritative fare quote with available ride options (§8, §9).
  Future<Result<FareQuote>> requestQuote({
    required Place pickup,
    required Place destination,
  });

  /// Requests a ride. [idempotencyKey] prevents duplicate trips on retries /
  /// double taps (§11). The returned Trip starts in REQUESTED/SEARCHING_DRIVER.
  Future<Result<Trip>> requestRide({
    required String quoteId,
    required String rideOptionId,
    required String paymentMethodId,
    required String idempotencyKey,
  });

  /// Fetches authoritative current state for a trip (used on reconnect /
  /// app relaunch recovery — §41).
  Future<Result<Trip>> getTrip(String tripId);

  /// Returns the customer's active trip, if any (§41 recovery).
  Future<Result<Trip?>> activeTrip();

  /// Cancels the trip. The backend decides any cancellation fee (§9, §30).
  Future<Result<Trip>> cancelTrip(String tripId);

  /// Submits a rating + optional comment after completion (§18).
  Future<Result<void>> rateTrip({
    required String tripId,
    required int stars,
    String? comment,
  });

  /// Paginated trip history (§20).
  Future<Result<TripPage>> history({String? cursor, int limit = 20});
}

class TripPage {
  const TripPage({required this.trips, this.nextCursor});
  final List<Trip> trips;
  final String? nextCursor;
  bool get hasMore => nextCursor != null;
}
