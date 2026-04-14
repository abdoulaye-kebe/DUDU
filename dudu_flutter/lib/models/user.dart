class User {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final bool isVerified;
  final String? gender;
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
    this.gender,
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
    final dynamic rawAddress = json['address'];
    final UserAddress? address =
        rawAddress is Map<String, dynamic>
            ? UserAddress.fromJson(rawAddress)
            : null;

    final dynamic rawBudget = json['budgetSettings'];
    final BudgetSettings? budgetSettings =
        rawBudget is Map<String, dynamic>
            ? BudgetSettings.fromJson(rawBudget)
            : null;

    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      isVerified: json['isVerified'] ?? false,
      gender: json['gender'],
      referralCode: json['referralCode'] ?? '',
      language: json['language'] ?? 'fr',
      currency: json['currency'] ?? 'XOF',
      address: address,
      profilePicture: json['profilePicture'],
      totalRides: json['totalRides'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      budgetSettings: budgetSettings,
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
      'gender': gender,
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
    final dynamic rawCoordinates = json['coordinates'];
    final Coordinates coordinates =
        rawCoordinates is Map<String, dynamic>
            ? Coordinates.fromJson(rawCoordinates)
            : Coordinates(latitude: 0, longitude: 0);

    return UserAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? 'Dakar',
      neighborhood: json['neighborhood'],
      coordinates: coordinates,
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
      preferredPaymentMethod: json['preferredPaymentMethod'] ?? 'wave',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxPricePerKm': maxPricePerKm,
      'preferredPaymentMethod': preferredPaymentMethod,
    };
  }
}





