class Ride {
  final String id;
  final String rideId;
  final String passengerId;
  final String driverId;
  final RideLocation pickup;
  final RideLocation destination;
  final RidePricing pricing;
  final RideStatus status;
  final RideType rideType;
  final VehicleCategory vehicleCategory;
  final int passengers;
  final List<String> specialRequests;
  final RideTiming timing;
  final RidePayment payment;
  final RideRating? rating;
  final List<RideTracking> tracking;
  final RideCarpoolInfo? carpoolInfo;
  final RideDeliveryInfo? deliveryInfo;

  const Ride({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.driverId,
    required this.pickup,
    required this.destination,
    required this.pricing,
    required this.status,
    required this.rideType,
    required this.vehicleCategory,
    this.passengers = 1,
    this.specialRequests = const [],
    required this.timing,
    required this.payment,
    this.rating,
    this.tracking = const [],
    this.carpoolInfo,
    this.deliveryInfo,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['_id'] ?? json['id'] ?? '',
      rideId: json['rideId'] ?? '',
      passengerId: json['passenger'] ?? '',
      driverId: json['driver'] ?? '',
      pickup: RideLocation.fromJson(json['pickup'] ?? {}),
      destination: RideLocation.fromJson(json['destination'] ?? {}),
      pricing: RidePricing.fromJson(json['pricing'] ?? {}),
      status: RideStatus.fromString(json['status'] ?? 'requested'),
      rideType: RideType.fromString(json['rideType'] ?? 'standard'),
      vehicleCategory: VehicleCategory.fromString(json['vehicleCategory'] ?? 'car'),
      passengers: json['passengers'] ?? 1,
      specialRequests: List<String>.from(json['specialRequests'] ?? []),
      timing: RideTiming.fromJson(json),
      payment: RidePayment.fromJson(json['payment'] ?? {}),
      rating: json['rating'] != null ? RideRating.fromJson(json['rating']) : null,
      tracking: (json['tracking'] as List<dynamic>?)
          ?.map((e) => RideTracking.fromJson(e))
          .toList() ?? [],
      carpoolInfo: json['carpoolInfo'] != null 
          ? RideCarpoolInfo.fromJson(json['carpoolInfo']) 
          : null,
      deliveryInfo: json['delivery'] != null 
          ? RideDeliveryInfo.fromJson(json['delivery']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'passenger': passengerId,
      'driver': driverId,
      'pickup': pickup.toJson(),
      'destination': destination.toJson(),
      'pricing': pricing.toJson(),
      'status': status.value,
      'rideType': rideType.value,
      'vehicleCategory': vehicleCategory.value,
      'passengers': passengers,
      'specialRequests': specialRequests,
      'timing': timing.toJson(),
      'payment': payment.toJson(),
      'rating': rating?.toJson(),
      'tracking': tracking.map((e) => e.toJson()).toList(),
      'carpoolInfo': carpoolInfo?.toJson(),
      'delivery': deliveryInfo?.toJson(),
    };
  }

  Ride copyWith({
    String? id,
    String? rideId,
    String? passengerId,
    String? driverId,
    RideLocation? pickup,
    RideLocation? destination,
    RidePricing? pricing,
    RideStatus? status,
    RideType? rideType,
    VehicleCategory? vehicleCategory,
    int? passengers,
    List<String>? specialRequests,
    RideTiming? timing,
    RidePayment? payment,
    RideRating? rating,
    List<RideTracking>? tracking,
    RideCarpoolInfo? carpoolInfo,
    RideDeliveryInfo? deliveryInfo,
  }) {
    return Ride(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      passengerId: passengerId ?? this.passengerId,
      driverId: driverId ?? this.driverId,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      pricing: pricing ?? this.pricing,
      status: status ?? this.status,
      rideType: rideType ?? this.rideType,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      passengers: passengers ?? this.passengers,
      specialRequests: specialRequests ?? this.specialRequests,
      timing: timing ?? this.timing,
      payment: payment ?? this.payment,
      rating: rating ?? this.rating,
      tracking: tracking ?? this.tracking,
      carpoolInfo: carpoolInfo ?? this.carpoolInfo,
      deliveryInfo: deliveryInfo ?? this.deliveryInfo,
    );
  }
}

class RideLocation {
  final String address;
  final double latitude;
  final double longitude;
  final String? instructions;
  final String? landmark;

  const RideLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.instructions,
    this.landmark,
  });

  factory RideLocation.fromJson(Map<String, dynamic> json) {
    return RideLocation(
      address: json['address'] ?? '',
      latitude: (json['coordinates']?['latitude'] ?? json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['coordinates']?['longitude'] ?? json['longitude'] ?? 0.0).toDouble(),
      instructions: json['instructions'],
      landmark: json['landmark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'coordinates': {
        'latitude': latitude,
        'longitude': longitude,
      },
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

  const RidePricing({
    required this.basePrice,
    required this.distancePrice,
    required this.timePrice,
    this.surgeMultiplier = 1.0,
    required this.totalPrice,
    this.currency = 'XOF',
    this.isPriceFixed = false,
  });

  factory RidePricing.fromJson(Map<String, dynamic> json) {
    return RidePricing(
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      distancePrice: (json['distancePrice'] ?? 0.0).toDouble(),
      timePrice: (json['timePrice'] ?? 0.0).toDouble(),
      surgeMultiplier: (json['surgeMultiplier'] ?? 1.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
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
  expired;

  String get value {
    switch (this) {
      case RideStatus.requested: return 'requested';
      case RideStatus.searching: return 'searching';
      case RideStatus.accepted: return 'accepted';
      case RideStatus.arriving: return 'arriving';
      case RideStatus.arrived: return 'arrived';
      case RideStatus.started: return 'started';
      case RideStatus.completed: return 'completed';
      case RideStatus.cancelled: return 'cancelled';
      case RideStatus.noDriver: return 'no_driver';
      case RideStatus.expired: return 'expired';
    }
  }

  static RideStatus fromString(String status) {
    switch (status) {
      case 'requested': return RideStatus.requested;
      case 'searching': return RideStatus.searching;
      case 'accepted': return RideStatus.accepted;
      case 'arriving': return RideStatus.arriving;
      case 'arrived': return RideStatus.arrived;
      case 'started': return RideStatus.started;
      case 'completed': return RideStatus.completed;
      case 'cancelled': return RideStatus.cancelled;
      case 'no_driver': return RideStatus.noDriver;
      case 'expired': return RideStatus.expired;
      default: return RideStatus.requested;
    }
  }

  String get displayName {
    switch (this) {
      case RideStatus.requested: return 'Demande envoyée';
      case RideStatus.searching: return 'Recherche de chauffeur';
      case RideStatus.accepted: return 'Chauffeur accepté';
      case RideStatus.arriving: return 'Chauffeur en route';
      case RideStatus.arrived: return 'Chauffeur arrivé';
      case RideStatus.started: return 'Course commencée';
      case RideStatus.completed: return 'Course terminée';
      case RideStatus.cancelled: return 'Course annulée';
      case RideStatus.noDriver: return 'Aucun chauffeur trouvé';
      case RideStatus.expired: return 'Demande expirée';
    }
  }
}

enum RideType {
  standard,
  comfort,
  womenOnly,
  delivery,
  luxe,
  moto;

  String get value {
    switch (this) {
      case RideType.standard: return 'standard';
      case RideType.womenOnly: return 'women_only';
      case RideType.comfort: return 'comfort';
      case RideType.delivery: return 'delivery';
      case RideType.luxe: return 'luxe';
      case RideType.moto: return 'moto';
    }
  }

  static RideType fromString(String type) {
    switch (type) {
      case 'standard': return RideType.standard;
      case 'comfort': return RideType.comfort;
      case 'express': return RideType.comfort;
      case 'women_only': return RideType.womenOnly;
      case 'delivery': return RideType.delivery;
      case 'luxe': return RideType.luxe;
      case 'moto': return RideType.moto;
      default: return RideType.standard;
    }
  }

  String get displayName {
    switch (this) {
      case RideType.standard: return 'Standard';
      case RideType.comfort: return 'Confort';
      case RideType.womenOnly: return 'Femme';
      case RideType.delivery: return 'Livraison';
      case RideType.luxe: return 'Luxe';
      case RideType.moto: return 'Moto';
    }
  }
}

enum VehicleCategory {
  car,
  moto;

  String get value {
    switch (this) {
      case VehicleCategory.car: return 'car';
      case VehicleCategory.moto: return 'moto';
    }
  }

  static VehicleCategory fromString(String category) {
    switch (category) {
      case 'car': return VehicleCategory.car;
      case 'moto': return VehicleCategory.moto;
      default: return VehicleCategory.car;
    }
  }

  String get displayName {
    switch (this) {
      case VehicleCategory.car: return 'Voiture';
      case VehicleCategory.moto: return 'Moto';
    }
  }
}

class RideTiming {
  final DateTime? scheduledFor;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const RideTiming({
    this.scheduledFor,
    required this.requestedAt,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });

  factory RideTiming.fromJson(Map<String, dynamic> json) {
    return RideTiming(
      scheduledFor: json['scheduledFor'] != null 
          ? DateTime.parse(json['scheduledFor']) 
          : null,
      requestedAt: json['requestedAt'] != null 
          ? DateTime.parse(json['requestedAt']) 
          : DateTime.now(),
      acceptedAt: json['acceptedAt'] != null 
          ? DateTime.parse(json['acceptedAt']) 
          : null,
      arrivedAt: json['arrivedAt'] != null 
          ? DateTime.parse(json['arrivedAt']) 
          : null,
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt']) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      cancelledAt: json['cancelledAt'] != null 
          ? DateTime.parse(json['cancelledAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheduledFor': scheduledFor?.toIso8601String(),
      'requestedAt': requestedAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'arrivedAt': arrivedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }
}

class RidePayment {
  final String method;
  final String status;
  final String? transactionId;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  final double? refundAmount;

  const RidePayment({
    required this.method,
    required this.status,
    this.transactionId,
    this.paidAt,
    this.refundedAt,
    this.refundAmount,
  });

  factory RidePayment.fromJson(Map<String, dynamic> json) {
    return RidePayment(
      method: json['method'] ?? '',
      status: json['status'] ?? 'pending',
      transactionId: json['transactionId'],
      paidAt: json['paidAt'] != null 
          ? DateTime.parse(json['paidAt']) 
          : null,
      refundedAt: json['refundedAt'] != null 
          ? DateTime.parse(json['refundedAt']) 
          : null,
      refundAmount: json['refundAmount']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'status': status,
      'transactionId': transactionId,
      'paidAt': paidAt?.toIso8601String(),
      'refundedAt': refundedAt?.toIso8601String(),
      'refundAmount': refundAmount,
    };
  }
}

class RideRating {
  final int? passengerRating;
  final String? passengerComment;
  final DateTime? passengerRatedAt;
  final int? driverRating;
  final String? driverComment;
  final DateTime? driverRatedAt;

  const RideRating({
    this.passengerRating,
    this.passengerComment,
    this.passengerRatedAt,
    this.driverRating,
    this.driverComment,
    this.driverRatedAt,
  });

  factory RideRating.fromJson(Map<String, dynamic> json) {
    return RideRating(
      passengerRating: json['passenger']?['rating'],
      passengerComment: json['passenger']?['comment'],
      passengerRatedAt: json['passenger']?['ratedAt'] != null 
          ? DateTime.parse(json['passenger']['ratedAt']) 
          : null,
      driverRating: json['driver']?['rating'],
      driverComment: json['driver']?['comment'],
      driverRatedAt: json['driver']?['ratedAt'] != null 
          ? DateTime.parse(json['driver']['ratedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passenger': {
        'rating': passengerRating,
        'comment': passengerComment,
        'ratedAt': passengerRatedAt?.toIso8601String(),
      },
      'driver': {
        'rating': driverRating,
        'comment': driverComment,
        'ratedAt': driverRatedAt?.toIso8601String(),
      },
    };
  }
}

class RideTracking {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
  final double? heading;

  const RideTracking({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.heading,
  });

  factory RideTracking.fromJson(Map<String, dynamic> json) {
    return RideTracking(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'heading': heading,
    };
  }
}

class RideCarpoolInfo {
  final bool isCarpool;
  final int requestedSeats;
  final int? availableSeats;
  final List<String> otherPassengers;

  const RideCarpoolInfo({
    required this.isCarpool,
    required this.requestedSeats,
    this.availableSeats,
    this.otherPassengers = const [],
  });

  factory RideCarpoolInfo.fromJson(Map<String, dynamic> json) {
    return RideCarpoolInfo(
      isCarpool: json['isCarpool'] ?? false,
      requestedSeats: json['requestedSeats'] ?? 1,
      availableSeats: json['availableSeats'],
      otherPassengers: List<String>.from(json['otherPassengers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCarpool': isCarpool,
      'requestedSeats': requestedSeats,
      'availableSeats': availableSeats,
      'otherPassengers': otherPassengers,
    };
  }
}

class RideDeliveryInfo {
  final String packageType;
  final double? weight;
  final PackageDimensions? dimensions;
  final String? description;
  final String? recipientName;
  final String? recipientPhone;
  final String? instructions;
  final String? pickupContact;
  final String? pickupContactPhone;
  final bool isFragile;
  final bool requiresSignature;
  final String? confirmationCode;

  const RideDeliveryInfo({
    required this.packageType,
    this.weight,
    this.dimensions,
    this.description,
    this.recipientName,
    this.recipientPhone,
    this.instructions,
    this.pickupContact,
    this.pickupContactPhone,
    this.isFragile = false,
    this.requiresSignature = false,
    this.confirmationCode,
  });

  factory RideDeliveryInfo.fromJson(Map<String, dynamic> json) {
    return RideDeliveryInfo(
      packageType: json['packageType'] ?? 'small_package',
      weight: json['weight']?.toDouble(),
      dimensions: json['dimensions'] != null 
          ? PackageDimensions.fromJson(json['dimensions']) 
          : null,
      description: json['description'],
      recipientName: json['recipientName'],
      recipientPhone: json['recipientPhone'],
      instructions: json['instructions'],
      pickupContact: json['pickupContact'],
      pickupContactPhone: json['pickupContactPhone'],
      isFragile: json['isFragile'] ?? false,
      requiresSignature: json['requiresSignature'] ?? false,
      confirmationCode: json['confirmationCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageType': packageType,
      'weight': weight,
      'dimensions': dimensions?.toJson(),
      'description': description,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'instructions': instructions,
      'pickupContact': pickupContact,
      'pickupContactPhone': pickupContactPhone,
      'isFragile': isFragile,
      'requiresSignature': requiresSignature,
      'confirmationCode': confirmationCode,
    };
  }
}

class PackageDimensions {
  final double length;
  final double width;
  final double height;

  const PackageDimensions({
    required this.length,
    required this.width,
    required this.height,
  });

  factory PackageDimensions.fromJson(Map<String, dynamic> json) {
    return PackageDimensions(
      length: (json['length'] ?? 0.0).toDouble(),
      width: (json['width'] ?? 0.0).toDouble(),
      height: (json['height'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'length': length,
      'width': width,
      'height': height,
    };
  }
}
