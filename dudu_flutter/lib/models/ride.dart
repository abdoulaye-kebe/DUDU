import 'user.dart';

class Ride {
  final String id;
  final String rideId;
  final RideLocation pickup;
  final RideLocation destination;
  final double distance;
  final int estimatedDuration;
  final int? actualDuration;
  final RidePricing pricing;
  final RideStatus status;
  final String rideType;
  final int passengers;
  final List<String> specialRequests;
  final String? specialMode;
  final User? driver;
  final User? passenger;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final RideRating? rating;

  Ride({
    required this.id,
    required this.rideId,
    required this.pickup,
    required this.destination,
    required this.distance,
    required this.estimatedDuration,
    this.actualDuration,
    required this.pricing,
    required this.status,
    required this.rideType,
    required this.passengers,
    required this.specialRequests,
    this.specialMode,
    this.driver,
    this.passenger,
    required this.requestedAt,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.rating,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] ?? '',
      rideId: json['rideId'] ?? '',
      pickup: RideLocation.fromJson(json['pickup']),
      destination: RideLocation.fromJson(json['destination']),
      distance: (json['distance'] ?? 0).toDouble(),
      estimatedDuration: json['estimatedDuration'] ?? 0,
      actualDuration: json['actualDuration'],
      pricing: RidePricing.fromJson(json['pricing']),
      status: RideStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RideStatus.requested,
      ),
      rideType: json['rideType'] ?? 'standard',
      passengers: json['passengers'] ?? 1,
      specialRequests: List<String>.from(json['specialRequests'] ?? []),
      specialMode: json['specialMode'],
      driver: json['driver'] != null ? User.fromJson(json['driver']) : null,
      passenger: json['passenger'] != null ? User.fromJson(json['passenger']) : null,
      requestedAt: DateTime.parse(json['requestedAt']),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      arrivedAt: json['arrivedAt'] != null ? DateTime.parse(json['arrivedAt']) : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
      rating: json['rating'] != null ? RideRating.fromJson(json['rating']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'pickup': pickup.toJson(),
      'destination': destination.toJson(),
      'distance': distance,
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
      'pricing': pricing.toJson(),
      'status': status.name,
      'rideType': rideType,
      'passengers': passengers,
      'specialRequests': specialRequests,
      'specialMode': specialMode,
      'driver': driver?.toJson(),
      'passenger': passenger?.toJson(),
      'requestedAt': requestedAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'arrivedAt': arrivedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'rating': rating?.toJson(),
    };
  }
}

class RideLocation {
  final String address;
  final Coordinates coordinates;
  final String? instructions;
  final String? landmark;

  RideLocation({
    required this.address,
    required this.coordinates,
    this.instructions,
    this.landmark,
  });

  factory RideLocation.fromJson(Map<String, dynamic> json) {
    return RideLocation(
      address: json['address'] ?? '',
      coordinates: Coordinates.fromJson(json['coordinates']),
      instructions: json['instructions'],
      landmark: json['landmark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'coordinates': coordinates.toJson(),
      'instructions': instructions,
      'landmark': landmark,
    };
  }
}

class RidePricing {
  final double basePrice;
  final double distancePrice;
  final double timePrice;
  final double surgeMultiplier;
  final double totalPrice;
  final String currency;
  final bool isPriceFixed;

  RidePricing({
    required this.basePrice,
    required this.distancePrice,
    required this.timePrice,
    required this.surgeMultiplier,
    required this.totalPrice,
    required this.currency,
    required this.isPriceFixed,
  });

  factory RidePricing.fromJson(Map<String, dynamic> json) {
    return RidePricing(
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      distancePrice: (json['distancePrice'] ?? 0).toDouble(),
      timePrice: (json['timePrice'] ?? 0).toDouble(),
      surgeMultiplier: (json['surgeMultiplier'] ?? 1.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'XOF',
      isPriceFixed: json['isPriceFixed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basePrice': basePrice,
      'distancePrice': distancePrice,
      'timePrice': timePrice,
      'surgeMultiplier': surgeMultiplier,
      'totalPrice': totalPrice,
      'currency': currency,
      'isPriceFixed': isPriceFixed,
    };
  }
}

class RideRating {
  final RideRatingDetails? passenger;
  final RideRatingDetails? driver;

  RideRating({
    this.passenger,
    this.driver,
  });

  factory RideRating.fromJson(Map<String, dynamic> json) {
    return RideRating(
      passenger: json['passenger'] != null 
          ? RideRatingDetails.fromJson(json['passenger']) 
          : null,
      driver: json['driver'] != null 
          ? RideRatingDetails.fromJson(json['driver']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passenger': passenger?.toJson(),
      'driver': driver?.toJson(),
    };
  }
}

class RideRatingDetails {
  final int rating;
  final String? comment;
  final DateTime ratedAt;

  RideRatingDetails({
    required this.rating,
    this.comment,
    required this.ratedAt,
  });

  factory RideRatingDetails.fromJson(Map<String, dynamic> json) {
    return RideRatingDetails(
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      ratedAt: DateTime.parse(json['ratedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'ratedAt': ratedAt.toIso8601String(),
    };
  }
}

enum RideStatus {
  requested,
  searching,
  accepted,
  arriving,
  arrived,
  started,
  completed,
  cancelled,
  noDriver,
  expired,
}

extension RideStatusExtension on RideStatus {
  String get displayName {
    switch (this) {
      case RideStatus.requested:
        return 'Demandée';
      case RideStatus.searching:
        return 'Recherche en cours';
      case RideStatus.accepted:
        return 'Acceptée';
      case RideStatus.arriving:
        return 'Chauffeur en route';
      case RideStatus.arrived:
        return 'Chauffeur arrivé';
      case RideStatus.started:
        return 'Course commencée';
      case RideStatus.completed:
        return 'Terminée';
      case RideStatus.cancelled:
        return 'Annulée';
      case RideStatus.noDriver:
        return 'Aucun chauffeur';
      case RideStatus.expired:
        return 'Expirée';
    }
  }
}



