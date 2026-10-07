import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/logger.dart';
import '../../realtime/realtime_service.dart';
import '../domain/models.dart';
import '../domain/trip_repository.dart';
import '../domain/trip_status.dart';

/// Owns the current active trip and keeps it in sync with the backend via the
/// realtime stream (spec §14, §31). On (re)connect it re-fetches authoritative
/// state rather than trusting the last client value.
class TripController extends Notifier<AsyncValue<Trip?>> {
  StreamSubscription<TripUpdate>? _sub;

  TripRepository get _repo => ref.read(tripRepositoryProvider);
  RealtimeService get _realtime => ref.read(realtimeServiceProvider);

  @override
  AsyncValue<Trip?> build() {
    ref.onDispose(() => _sub?.cancel());
    _recoverActiveTrip();
    return const AsyncValue.loading();
  }

  /// Spec §41 recovery: on launch, ask the backend for the active trip.
  Future<void> _recoverActiveTrip() async {
    final result = await _repo.activeTrip();
    result.fold(
      (trip) {
        state = AsyncValue.data(trip);
        if (trip != null && trip.status.isActive) _listen(trip.id);
      },
      (failure) => state = AsyncValue.data(null),
    );
  }

  /// Called by the booking flow once a ride has been requested.
  void attachTrip(Trip trip) {
    state = AsyncValue.data(trip);
    _listen(trip.id);
  }

  void _listen(String tripId) {
    _sub?.cancel();
    _sub = _realtime.subscribeToTrip(tripId).listen(
      _onUpdate,
      onError: (Object e, StackTrace s) {
        AppLogger.w('Realtime error; will rely on re-fetch', error: e);
      },
    );
  }

  Future<void> _onUpdate(TripUpdate update) async {
    final current = state.valueOrNull;
    if (current == null || current.id != update.tripId) return;

    // A full snapshot is authoritative; a delta only patches driver position.
    if (update.trip != null) {
      state = AsyncValue.data(update.trip);
      if (update.trip!.status.isTerminal) await _sub?.cancel();
    } else {
      state = AsyncValue.data(current.copyWith(
        driverLocation: update.driverLocation,
        driverEtaMinutes: update.driverEtaMinutes,
      ));
    }
  }

  /// Re-sync after a reconnect / foreground (spec §31, §41).
  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current == null) return _recoverActiveTrip();
    final result = await _repo.getTrip(current.id);
    result.fold((trip) => state = AsyncValue.data(trip), (_) {});
  }

  Future<Result<Trip>> cancel() async {
    final current = state.valueOrNull;
    if (current == null) {
      return const Err<Trip>(Failure(kind: FailureKind.notFound));
    }
    final result = await _repo.cancelTrip(current.id);
    result.fold((trip) => state = AsyncValue.data(trip), (_) {});
    return result;
  }

  Future<Result<void>> rate({required int stars, String? comment}) async {
    final current = state.valueOrNull;
    if (current == null) {
      return const Err<void>(Failure(kind: FailureKind.notFound));
    }
    return _repo.rateTrip(tripId: current.id, stars: stars, comment: comment);
  }

  void clear() {
    _sub?.cancel();
    state = const AsyncValue.data(null);
  }
}

final tripControllerProvider =
    NotifierProvider<TripController, AsyncValue<Trip?>>(TripController.new);
