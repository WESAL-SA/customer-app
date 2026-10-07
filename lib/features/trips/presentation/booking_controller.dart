import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/network/api_result.dart';
import '../../mock/mock_repositories.dart';
import '../domain/models.dart';
import '../domain/trip_repository.dart';
import 'trip_controller.dart';

/// Holds the in-progress booking selection across the booking screens
/// (destination → confirm → ride select → payment → request).
class BookingState {
  const BookingState({
    this.pickup,
    this.destination,
    this.quote,
    this.selectedOptionId,
    this.paymentMethodId,
    this.paymentLabel,
    this.isRequesting = false,
  });

  final Place? pickup;
  final Place? destination;
  final FareQuote? quote;
  final String? selectedOptionId;
  final String? paymentMethodId;
  final String? paymentLabel;
  final bool isRequesting;

  RideOption? get selectedOption {
    final q = quote;
    if (q == null) return null;
    for (final o in q.options) {
      if (o.id == selectedOptionId) return o;
    }
    return q.options.isNotEmpty ? q.options.first : null;
  }

  BookingState copyWith({
    Place? pickup,
    Place? destination,
    FareQuote? quote,
    String? selectedOptionId,
    String? paymentMethodId,
    String? paymentLabel,
    bool? isRequesting,
  }) =>
      BookingState(
        pickup: pickup ?? this.pickup,
        destination: destination ?? this.destination,
        quote: quote ?? this.quote,
        selectedOptionId: selectedOptionId ?? this.selectedOptionId,
        paymentMethodId: paymentMethodId ?? this.paymentMethodId,
        paymentLabel: paymentLabel ?? this.paymentLabel,
        isRequesting: isRequesting ?? this.isRequesting,
      );
}

class BookingController extends Notifier<BookingState> {
  TripRepository get _repo => ref.read(tripRepositoryProvider);

  @override
  BookingState build() => const BookingState();

  void setPickup(Place pickup) => state = state.copyWith(pickup: pickup);
  void setDestination(Place destination) =>
      state = state.copyWith(destination: destination);
  void selectOption(String id) => state = state.copyWith(selectedOptionId: id);
  void setPayment(String id, String label) =>
      state = state.copyWith(paymentMethodId: id, paymentLabel: label);

  Future<Result<FareQuote>> requestQuote() async {
    final pickup = state.pickup;
    final destination = state.destination;
    if (pickup == null || destination == null) {
      return const Err(Failure(kind: FailureKind.validation));
    }
    final result =
        await _repo.requestQuote(pickup: pickup, destination: destination);
    result.fold((quote) {
      state = state.copyWith(
        quote: quote,
        selectedOptionId:
            quote.options.isNotEmpty ? quote.options.first.id : null,
      );
    }, (_) {});
    return result;
  }

  /// Requests the ride and attaches the resulting trip to the TripController.
  /// [idempotencyKey] guards against duplicate requests from double taps /
  /// retries (spec §11).
  Future<Result<Trip>> requestRide() async {
    final quote = state.quote;
    final option = state.selectedOption;
    final pickup = state.pickup;
    final destination = state.destination;
    if (quote == null ||
        option == null ||
        pickup == null ||
        destination == null) {
      return const Err<Trip>(Failure(kind: FailureKind.validation));
    }
    if (state.isRequesting) {
      // in-flight guard against duplicate requests (§11)
      return const Err<Trip>(Failure(kind: FailureKind.conflict));
    }
    state = state.copyWith(isRequesting: true);

    // MOCK-ONLY: pass booking context to the mock repo. The real repo takes
    // these in the request body and this block is removed.
    final repo = _repo;
    if (repo is MockTripRepository) {
      repo.setQuoteContext(
        quote: quote,
        pickup: pickup,
        destination: destination,
        paymentLabel: state.paymentLabel ?? 'Cash',
      );
    }

    final result = await repo.requestRide(
      quoteId: quote.quoteId,
      rideOptionId: option.id,
      paymentMethodId: state.paymentMethodId ?? 'pm_cash',
      idempotencyKey: 'idem_${DateTime.now().millisecondsSinceEpoch}',
    );

    state = state.copyWith(isRequesting: false);
    result.fold(
      (trip) => ref.read(tripControllerProvider.notifier).attachTrip(trip),
      (_) {},
    );
    return result;
  }

  void reset() => state = const BookingState();
}

final bookingControllerProvider =
    NotifierProvider<BookingController, BookingState>(BookingController.new);
