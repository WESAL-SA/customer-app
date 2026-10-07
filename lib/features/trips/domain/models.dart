import 'package:equatable/equatable.dart';

import 'trip_status.dart';

/// Geographic point.
class LatLng extends Equatable {
  const LatLng(this.lat, this.lng);
  final double lat;
  final double lng;

  factory LatLng.fromJson(Map<String, dynamic> json) =>
      LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  @override
  List<Object?> get props => [lat, lng];
}

/// A place / address used for pickup or destination.
class Place extends Equatable {
  const Place({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.location,
    this.kind = PlaceKind.search,
  });

  final String id;
  final String title;
  final String subtitle;
  final LatLng location;
  final PlaceKind kind;

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: (json['subtitle'] as String?) ?? '',
        location: LatLng.fromJson(json['location'] as Map<String, dynamic>),
        kind: PlaceKind.values.byName(
          (json['kind'] as String?) ?? PlaceKind.search.name,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'location': location.toJson(),
        'kind': kind.name,
      };

  @override
  List<Object?> get props => [id, title, subtitle, location, kind];
}

enum PlaceKind { home, work, saved, recent, search }

/// A money amount. Kept as a value object so currency is never dropped and the
/// client never does arithmetic on fares (the backend is authoritative, §9).
class Money extends Equatable {
  const Money({required this.amount, this.currency = 'SAR'});

  final double amount;
  final String currency;

  factory Money.fromJson(Map<String, dynamic> json) => Money(
        amount: (json['amount'] as num).toDouble(),
        currency: (json['currency'] as String?) ?? 'SAR',
      );

  Map<String, dynamic> toJson() => {'amount': amount, 'currency': currency};

  String formatted({int decimals = 2}) =>
      '${amount.toStringAsFixed(decimals)} $currency';

  @override
  List<Object?> get props => [amount, currency];
}

/// A bookable ride category (configured by the backend, never hardcoded — §8).
class RideOption extends Equatable {
  const RideOption({
    required this.id,
    required this.name,
    required this.description,
    required this.capacity,
    required this.etaMinutes,
    required this.estimatedFare,
    this.estimatedFareMax,
    this.iconKey,
  });

  final String id;
  final String name;
  final String description;
  final int capacity;
  final int etaMinutes;
  final Money estimatedFare;

  /// Optional upper bound for a displayed fare range.
  final Money? estimatedFareMax;
  final String? iconKey;

  factory RideOption.fromJson(Map<String, dynamic> json) => RideOption(
        id: json['id'] as String,
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
        capacity: (json['capacity'] as num).toInt(),
        etaMinutes: (json['etaMinutes'] as num).toInt(),
        estimatedFare:
            Money.fromJson(json['estimatedFare'] as Map<String, dynamic>),
        estimatedFareMax: json['estimatedFareMax'] == null
            ? null
            : Money.fromJson(json['estimatedFareMax'] as Map<String, dynamic>),
        iconKey: json['iconKey'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, name, description, capacity, etaMinutes, estimatedFare];
}

/// Authoritative fare quote returned by the backend fare engine (§9).
/// The client only displays this; it never computes the total itself.
class FareQuote extends Equatable {
  const FareQuote({
    required this.quoteId,
    required this.options,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.expiresAt,
  });

  final String quoteId;
  final List<RideOption> options;
  final int distanceMeters;
  final int durationSeconds;
  final DateTime expiresAt;

  double get distanceKm => distanceMeters / 1000.0;
  int get durationMinutes => (durationSeconds / 60).round();
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory FareQuote.fromJson(Map<String, dynamic> json) => FareQuote(
        quoteId: json['quoteId'] as String,
        options: (json['options'] as List)
            .map((e) => RideOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        distanceMeters: (json['distanceMeters'] as num).toInt(),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );

  @override
  List<Object?> get props =>
      [quoteId, options, distanceMeters, durationSeconds, expiresAt];
}

class Vehicle extends Equatable {
  const Vehicle({
    required this.make,
    required this.model,
    required this.color,
    required this.plate,
  });

  final String make;
  final String model;
  final String color;
  final String plate;

  String get label => '$make $model';

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        make: json['make'] as String,
        model: json['model'] as String,
        color: json['color'] as String,
        plate: json['plate'] as String,
      );

  @override
  List<Object?> get props => [make, model, color, plate];
}

class Driver extends Equatable {
  const Driver({
    required this.id,
    required this.name,
    required this.rating,
    required this.vehicle,
    this.photoUrl,
  });

  final String id;
  final String name;
  final double rating;
  final Vehicle vehicle;
  final String? photoUrl;

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: json['id'] as String,
        name: json['name'] as String,
        rating: (json['rating'] as num).toDouble(),
        vehicle: Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
        photoUrl: json['photoUrl'] as String?,
      );

  @override
  List<Object?> get props => [id, name, rating, vehicle, photoUrl];
}

/// Fare breakdown line shown on receipts (§19). Lines come from the backend so
/// the client never assembles pricing itself.
class FareLine extends Equatable {
  const FareLine({required this.label, required this.amount});
  final String label;
  final Money amount;

  factory FareLine.fromJson(Map<String, dynamic> json) => FareLine(
        label: json['label'] as String,
        amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [label, amount];
}

/// A trip. The authoritative record lives on the backend; this is the client's
/// view of it, kept in sync via realtime events and re-fetches.
class Trip extends Equatable {
  const Trip({
    required this.id,
    required this.status,
    required this.pickup,
    required this.destination,
    required this.estimatedFare,
    this.rideOptionName,
    this.driver,
    this.driverLocation,
    this.driverEtaMinutes,
    this.finalFare,
    this.fareLines = const [],
    this.paymentMethodLabel,
    this.createdAt,
    this.completedAt,
    this.customerRating,
  });

  final String id;
  final TripStatus status;
  final Place pickup;
  final Place destination;
  final Money estimatedFare;
  final String? rideOptionName;

  final Driver? driver;
  final LatLng? driverLocation;
  final int? driverEtaMinutes;

  final Money? finalFare;
  final List<FareLine> fareLines;
  final String? paymentMethodLabel;

  final DateTime? createdAt;
  final DateTime? completedAt;
  final double? customerRating;

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        status: TripStatusX.fromWire(json['status'] as String?),
        pickup: Place.fromJson(json['pickup'] as Map<String, dynamic>),
        destination:
            Place.fromJson(json['destination'] as Map<String, dynamic>),
        estimatedFare:
            Money.fromJson(json['estimatedFare'] as Map<String, dynamic>),
        rideOptionName: json['rideOptionName'] as String?,
        driver: json['driver'] == null
            ? null
            : Driver.fromJson(json['driver'] as Map<String, dynamic>),
        driverLocation: json['driverLocation'] == null
            ? null
            : LatLng.fromJson(json['driverLocation'] as Map<String, dynamic>),
        driverEtaMinutes: (json['driverEtaMinutes'] as num?)?.toInt(),
        finalFare: json['finalFare'] == null
            ? null
            : Money.fromJson(json['finalFare'] as Map<String, dynamic>),
        fareLines: (json['fareLines'] as List? ?? [])
            .map((e) => FareLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        paymentMethodLabel: json['paymentMethodLabel'] as String?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
        customerRating: (json['customerRating'] as num?)?.toDouble(),
      );

  Trip copyWith({
    TripStatus? status,
    Driver? driver,
    LatLng? driverLocation,
    int? driverEtaMinutes,
    Money? finalFare,
    List<FareLine>? fareLines,
    DateTime? completedAt,
    double? customerRating,
  }) =>
      Trip(
        id: id,
        status: status ?? this.status,
        pickup: pickup,
        destination: destination,
        estimatedFare: estimatedFare,
        rideOptionName: rideOptionName,
        driver: driver ?? this.driver,
        driverLocation: driverLocation ?? this.driverLocation,
        driverEtaMinutes: driverEtaMinutes ?? this.driverEtaMinutes,
        finalFare: finalFare ?? this.finalFare,
        fareLines: fareLines ?? this.fareLines,
        paymentMethodLabel: paymentMethodLabel,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
        customerRating: customerRating ?? this.customerRating,
      );

  @override
  List<Object?> get props => [
        id,
        status,
        driver,
        driverLocation,
        driverEtaMinutes,
        finalFare,
        customerRating,
      ];
}
