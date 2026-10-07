import 'package:flutter_test/flutter_test.dart';
import 'package:wesal_customer/features/trips/domain/models.dart';
import 'package:wesal_customer/features/trips/domain/trip_status.dart';

void main() {
  group('TripStatus wire mapping', () {
    test('maps known backend values', () {
      expect(TripStatusX.fromWire('SEARCHING_DRIVER'),
          TripStatus.searchingDriver);
      expect(TripStatusX.fromWire('TRIP_COMPLETED'), TripStatus.tripCompleted);
      expect(TripStatusX.fromWire('NO_DRIVER_AVAILABLE'),
          TripStatus.noDriverAvailable);
    });

    test('unknown value falls back to unknown (never guesses)', () {
      expect(TripStatusX.fromWire('SOMETHING_NEW'), TripStatus.unknown);
      expect(TripStatusX.fromWire(null), TripStatus.unknown);
    });

    test('round-trips through wire', () {
      for (final s in TripStatus.values) {
        if (s == TripStatus.unknown) continue;
        expect(TripStatusX.fromWire(s.wire), s);
      }
    });

    test('active / terminal partitioning is consistent', () {
      for (final s in TripStatus.values) {
        if (s == TripStatus.unknown) continue;
        // A status is never both active and terminal.
        expect(s.isActive && s.isTerminal, isFalse, reason: s.name);
      }
      expect(TripStatus.tripStarted.isActive, isTrue);
      expect(TripStatus.tripCompleted.isTerminal, isTrue);
    });
  });

  group('Money', () {
    test('formats with currency and decimals', () {
      expect(const Money(amount: 32).formatted(decimals: 0), '32 SAR');
      expect(const Money(amount: 32.5).formatted(), '32.50 SAR');
    });
  });
}
