class DriverProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final VehicleType vehicleType;
  final VehicleInfo vehicle;
  final SubscriptionInfo? subscription;
  final DriverStats stats;
  final bool isOnline;
  final bool isAvailable;
  final LocationInfo? currentLocation;
  final Map<String, bool>? rideTypes;
  final DriverPreferences? preferences;
  final String driverType; // 'driver' ou 'courier'

  DriverProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.vehicle,
    this.subscription,
    required this.stats,
    required this.isOnline,
    required this.isAvailable,
    this.currentLocation,
    this.rideTypes,
    this.preferences,
    required this.driverType,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    // Gérer les différents formats et éviter les erreurs de type
    final dynamic rawVehicle = json['vehicle'];
    final Map<String, dynamic> vehicle =
        rawVehicle is Map<String, dynamic> ? rawVehicle : <String, dynamic>{};

    final dynamic rawStats = json['stats'];
    final Map<String, dynamic> stats =
        rawStats is Map<String, dynamic> ? rawStats : <String, dynamic>{};

    final rawDriverType = (json['driverType'] ?? '') as String;
    final computedType = (vehicle['category'] == 'moto' || vehicle['type'] == 'moto_delivery')
        ? 'courier'
        : 'driver';

    final dynamic rawSubscription = json['subscription'];
    final SubscriptionInfo? subscription =
        rawSubscription is Map<String, dynamic>
            ? SubscriptionInfo.fromJson(rawSubscription)
            : null;

    final dynamic rawCurrentLocation = json['currentLocation'];
    final LocationInfo? currentLocation =
        rawCurrentLocation is Map<String, dynamic>
            ? LocationInfo.fromJson(rawCurrentLocation)
            : null;

    final dynamic rawRideTypes = json['rideTypes'];
    final Map<String, bool>? rideTypes =
        rawRideTypes is Map
            ? Map<String, bool>.from(rawRideTypes.map(
                (key, value) => MapEntry(key.toString(), value == true),
              ))
            : null;

    final dynamic rawPreferences = json['preferences'];
    final DriverPreferences? preferences =
        rawPreferences is Map<String, dynamic>
            ? DriverPreferences.fromJson(rawPreferences)
            : null;

    return DriverProfile(
      id: json['id'] ?? json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      vehicleType: VehicleType.fromString(vehicle['type'] ?? 'car'),
      vehicle: VehicleInfo.fromJson(vehicle),
      subscription: subscription,
      stats: DriverStats.fromJson(stats),
      isOnline: json['status'] == 'online' || json['isOnline'] == true,
      isAvailable: json['isAvailable'] ?? false,
      currentLocation: currentLocation,
      rideTypes: rideTypes,
      preferences: preferences,
      driverType: rawDriverType.isNotEmpty ? rawDriverType : computedType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'vehicleType': vehicleType.toString(),
      'vehicle': vehicle.toJson(),
      'subscription': subscription?.toJson(),
      'stats': stats.toJson(),
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'currentLocation': currentLocation?.toJson(),
      'driverType': driverType,
    };
  }

  // Méthodes utilitaires
  bool get isCar => vehicleType == VehicleType.car;
  bool get isMoto => vehicleType == VehicleType.moto;
  bool get isCourier => driverType == 'courier' || isMoto;
  bool get isDriver => driverType == 'driver' && isCar;
  
  String get fullName => '$firstName $lastName';
  
  bool get hasActiveSubscription => 
      subscription != null && subscription!.isActive;
  
  bool get canAcceptRides => 
      isOnline && isAvailable && hasActiveSubscription;
  
  // Restrictions pour moto
  bool get canAcceptDeliveries => isMoto;
  bool get canAcceptPassengers => isCar;
  bool get canAcceptCarpool => isCar;
  bool get canAcceptLuggage => isCar && vehicle.type == 'cargo';
}

enum VehicleType {
  car,
  moto;

  static VehicleType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'car':
      case 'voiture':
        return VehicleType.car;
      case 'moto':
      case 'moto_delivery':
        return VehicleType.moto;
      default:
        return VehicleType.car;
    }
  }

  @override
  String toString() {
    switch (this) {
      case VehicleType.car:
        return 'car';
      case VehicleType.moto:
        return 'moto';
    }
  }

  String get displayName {
    switch (this) {
      case VehicleType.car:
        return 'Voiture';
      case VehicleType.moto:
        return 'Moto';
    }
  }

  String get icon {
    switch (this) {
      case VehicleType.car:
        return '🚗';
      case VehicleType.moto:
        return '🏍️';
    }
  }
}

class VehicleInfo {
  final String make;
  final String model;
  final int year;
  final String color;
  final String plateNumber;
  final String type; // 'standard', 'cargo', 'premium', 'moto_delivery'
  final int capacity;
  final Map<String, dynamic>? features;

  VehicleInfo({
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.plateNumber,
    required this.type,
    required this.capacity,
    this.features,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 2020,
      color: json['color'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      type: json['type'] ?? 'standard',
      capacity: json['capacity'] ?? 4,
      features: json['features'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'plateNumber': plateNumber,
      'type': type,
      'capacity': capacity,
      'features': features,
    };
  }

  String get displayName => '$make $model ($year)';
  String get fullInfo => '$displayName - $color - $plateNumber';
}

class SubscriptionInfo {
  final String id;
  final String type; // 'daily', 'weekly', 'monthly', 'yearly'
  final String name;
  final double price;
  final String currency;
  final int duration; // en jours
  final List<String> features;
  final String status; // 'active', 'expired', 'cancelled', 'pending'
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isExpiringSoon;
  final WeeklyBonus? weeklyBonus;
  final SubscriptionRestrictions? restrictions;

  SubscriptionInfo({
    required this.id,
    required this.type,
    required this.name,
    required this.price,
    required this.currency,
    required this.duration,
    required this.features,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isExpiringSoon,
    this.weeklyBonus,
    this.restrictions,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    // Certains endpoints renvoient les infos du plan imbriquées dans json['plan']
    final dynamic rawPlan = json['plan'];
    final Map<String, dynamic> plan =
        rawPlan is Map<String, dynamic> ? rawPlan : json;

    return SubscriptionInfo(
      id: json['id'] ?? json['_id'] ?? '',
      type: plan['type'] ?? json['type'] ?? 'daily',
      name: plan['name'] ?? json['name'] ?? 'Forfait',
      price: ((plan['price'] ?? json['price']) ?? 0).toDouble(),
      currency: plan['currency'] ?? json['currency'] ?? 'FCFA',
      duration: plan['duration'] ?? json['duration'] ?? 1,
      features: plan['features'] != null
          ? List<String>.from(plan['features'])
          : (json['features'] != null
              ? List<String>.from(json['features'])
              : <String>[]),
      status: json['status'] ?? 'active',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now().add(Duration(days: 1)),
      isActive: json['isActive'] ?? true,
      isExpiringSoon: json['isExpiringSoon'] ?? false,
      weeklyBonus: json['weeklyBonus'] is Map<String, dynamic>
          ? WeeklyBonus.fromJson(json['weeklyBonus'] as Map<String, dynamic>)
          : null,
      restrictions: json['restrictions'] is Map<String, dynamic>
          ? SubscriptionRestrictions.fromJson(json['restrictions'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'price': price,
      'currency': currency,
      'duration': duration,
      'features': features,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'isExpiringSoon': isExpiringSoon,
      'weeklyBonus': weeklyBonus?.toJson(),
      'restrictions': restrictions?.toJson(),
    };
  }

  String get displayName => name;
  String get priceFormatted => '${price.toStringAsFixed(0)} $currency';
  String get durationFormatted {
    switch (type) {
      case 'daily':
        return '1 jour';
      case 'weekly':
        return '7 jours';
      case 'monthly':
        return '30 jours';
      case 'yearly':
        return '365 jours';
      default:
        return '$duration jours';
    }
  }
}

class WeeklyBonus {
  final String type; // 'free_subscription', 'cash_bonus', 'none'
  final double amount;
  final DateTime? lastBonusDate;
  final List<BonusHistory> bonusHistory;

  WeeklyBonus({
    required this.type,
    required this.amount,
    this.lastBonusDate,
    required this.bonusHistory,
  });

  factory WeeklyBonus.fromJson(Map<String, dynamic> json) {
    return WeeklyBonus(
      type: json['type'],
      amount: json['amount'].toDouble(),
      lastBonusDate: json['lastBonusDate'] != null 
          ? DateTime.parse(json['lastBonusDate']) 
          : null,
      bonusHistory: (json['bonusHistory'] as List)
          .map((item) => BonusHistory.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'lastBonusDate': lastBonusDate?.toIso8601String(),
      'bonusHistory': bonusHistory.map((item) => item.toJson()).toList(),
    };
  }

  bool get hasBonus => type != 'none' && amount > 0;
  String get bonusDescription {
    switch (type) {
      case 'free_subscription':
        return '24h gratuites';
      case 'cash_bonus':
        return '${amount.toStringAsFixed(0)} FCFA';
      default:
        return 'Aucun bonus';
    }
  }
}

class BonusHistory {
  final String type;
  final double amount;
  final DateTime date;
  final String description;

  BonusHistory({
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
  });

  factory BonusHistory.fromJson(Map<String, dynamic> json) {
    return BonusHistory(
      type: json['type'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
    };
  }
}

class SubscriptionRestrictions {
  final int maxDailyRides;
  final List<String> allowedPlans;

  SubscriptionRestrictions({
    required this.maxDailyRides,
    required this.allowedPlans,
  });

  factory SubscriptionRestrictions.fromJson(Map<String, dynamic> json) {
    return SubscriptionRestrictions(
      maxDailyRides: json['maxDailyRides'],
      allowedPlans: List<String>.from(json['allowedPlans']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxDailyRides': maxDailyRides,
      'allowedPlans': allowedPlans,
    };
  }
}

class DriverStats {
  final int totalRides;
  final int completedRides;
  final int cancelledRides;
  final double averageRating;
  final double totalEarnings;
  final double totalDistance;
  final int todayRides;
  final double todayEarnings;
  final int weeklyRides;
  final double weeklyEarnings;
  final double bonusEarned;

  DriverStats({
    required this.totalRides,
    required this.completedRides,
    required this.cancelledRides,
    required this.averageRating,
    required this.totalEarnings,
    required this.totalDistance,
    required this.todayRides,
    required this.todayEarnings,
    required this.weeklyRides,
    required this.weeklyEarnings,
    required this.bonusEarned,
  });

  factory DriverStats.fromJson(Map<String, dynamic> json) {
    return DriverStats(
      totalRides: json['totalRides'] ?? 0,
      completedRides: json['completedRides'] ?? 0,
      cancelledRides: json['cancelledRides'] ?? 0,
      averageRating: json['averageRating']?.toDouble() ?? 0.0,
      totalEarnings: json['totalEarnings']?.toDouble() ?? 0.0,
      totalDistance: json['totalDistance']?.toDouble() ?? 0.0,
      todayRides: json['todayRides'] ?? 0,
      todayEarnings: json['todayEarnings']?.toDouble() ?? 0.0,
      weeklyRides: json['weeklyRides'] ?? 0,
      weeklyEarnings: json['weeklyEarnings']?.toDouble() ?? 0.0,
      bonusEarned: json['bonusEarned']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRides': totalRides,
      'completedRides': completedRides,
      'cancelledRides': cancelledRides,
      'averageRating': averageRating,
      'totalEarnings': totalEarnings,
      'totalDistance': totalDistance,
      'todayRides': todayRides,
      'todayEarnings': todayEarnings,
      'weeklyRides': weeklyRides,
      'weeklyEarnings': weeklyEarnings,
      'bonusEarned': bonusEarned,
    };
  }

  String get earningsFormatted => '${totalEarnings.toStringAsFixed(0)} FCFA';
  String get todayEarningsFormatted => '${todayEarnings.toStringAsFixed(0)} FCFA';
  String get weeklyEarningsFormatted => '${weeklyEarnings.toStringAsFixed(0)} FCFA';
  String get bonusFormatted => '${bonusEarned.toStringAsFixed(0)} FCFA';
}

class LocationInfo {
  final double latitude;
  final double longitude;
  final String? address;
  final double? accuracy;
  final DateTime timestamp;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    required this.timestamp,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'],
      accuracy: json['accuracy']?.toDouble(),
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class DriverPreferences {
  final bool acceptShared;
  final bool acceptWomenOnly;
  final int minPrice;
  final int maxDistance;

  DriverPreferences({
    required this.acceptShared,
    required this.acceptWomenOnly,
    required this.minPrice,
    required this.maxDistance,
  });

  factory DriverPreferences.fromJson(Map<String, dynamic> json) {
    return DriverPreferences(
      acceptShared: json['acceptShared'] ?? false,
      acceptWomenOnly: json['acceptWomenOnly'] ?? false,
      minPrice: json['minPrice'] ?? 500,
      maxDistance: json['maxDistance'] ?? 50,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acceptShared': acceptShared,
      'acceptWomenOnly': acceptWomenOnly,
      'minPrice': minPrice,
      'maxDistance': maxDistance,
    };
  }
}
