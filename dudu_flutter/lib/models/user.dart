class User {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final bool isVerified;
  final String referralCode;
  final String language;
  final String currency;
  final UserAddress? address;
  final String? profilePicture;
  final int totalRides;
  final double totalSpent;
  final double averageRating;
  final BudgetSettings? budgetSettings;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.isVerified,
    required this.referralCode,
    required this.language,
    required this.currency,
    this.address,
    this.profilePicture,
    required this.totalRides,
    required this.totalSpent,
    required this.averageRating,
    this.budgetSettings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      isVerified: json['isVerified'] ?? false,
      referralCode: json['referralCode'] ?? '',
      language: json['language'] ?? 'fr',
      currency: json['currency'] ?? 'XOF',
      address: json['address'] != null ? UserAddress.fromJson(json['address']) : null,
      profilePicture: json['profilePicture'],
      totalRides: json['totalRides'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      budgetSettings: json['budgetSettings'] != null 
          ? BudgetSettings.fromJson(json['budgetSettings']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'isVerified': isVerified,
      'referralCode': referralCode,
      'language': language,
      'currency': currency,
      'address': address?.toJson(),
      'profilePicture': profilePicture,
      'totalRides': totalRides,
      'totalSpent': totalSpent,
      'averageRating': averageRating,
      'budgetSettings': budgetSettings?.toJson(),
    };
  }

  String get fullName => '$firstName $lastName';
}

class UserAddress {
  final String street;
  final String city;
  final String? neighborhood;
  final Coordinates coordinates;

  UserAddress({
    required this.street,
    required this.city,
    this.neighborhood,
    required this.coordinates,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? 'Dakar',
      neighborhood: json['neighborhood'],
      coordinates: Coordinates.fromJson(json['coordinates']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'neighborhood': neighborhood,
      'coordinates': coordinates.toJson(),
    };
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({
    required this.latitude,
    required this.longitude,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class BudgetSettings {
  final double? maxPricePerKm;
  final String preferredPaymentMethod;

  BudgetSettings({
    this.maxPricePerKm,
    required this.preferredPaymentMethod,
  });

  factory BudgetSettings.fromJson(Map<String, dynamic> json) {
    return BudgetSettings(
      maxPricePerKm: json['maxPricePerKm']?.toDouble(),
      preferredPaymentMethod: json['preferredPaymentMethod'] ?? 'orange_money',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxPricePerKm': maxPricePerKm,
      'preferredPaymentMethod': preferredPaymentMethod,
    };
  }
}



