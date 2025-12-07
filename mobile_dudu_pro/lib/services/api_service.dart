import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform, TargetPlatform;
import '../models/driver_profile.dart';
import '../config/app_config.dart';

class ApiService {
  // Utiliser la configuration centralisée
  static String get baseUrl => AppConfig.baseUrl;
  
  static String? _authToken;
  static Map<String, dynamic>? _lastDriverData;

  // Gestion du token d'authentification
  static void setAuthToken(String token) {
    _authToken = token;
  }

  static String? get authToken => _authToken;

  static void setLastDriverData(Map<String, dynamic> driver) {
    _lastDriverData = driver;
  }

  static Map<String, dynamic>? get lastDriverData => _lastDriverData;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Authentification
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['data']['token'] != null) {
          _authToken = data['data']['token'];
        }
        return data;
      } else {
        throw Exception('Erreur de connexion: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  // Authentification chauffeur
  static Future<Map<String, dynamic>> loginDriver(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/drivers/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (data['token'] != null) {
            _authToken = data['token'];
          }
          final driver = data['driver'];
          if (driver is Map<String, dynamic>) {
            _lastDriverData = driver;
          }
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Identifiants incorrects'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion. Vérifiez que le backend est démarré.'
      };
    }
  }

  // Candidature chauffeur
  static Future<Map<String, dynamic>> applyAsDriver(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/drivers/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Erreur candidature chauffeur: $e');
    }
  }

  // Profil chauffeur
  static Future<DriverProfile> getDriverProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/drivers/profile'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final success = decoded['success'] == true;
          if (!success) {
            throw Exception(decoded['message'] ?? 'Erreur de récupération du profil');
          }

          dynamic driverJson;
          final dynamic data = decoded['data'];

          if (data is Map<String, dynamic>) {
            final dynamic driverField = data['driver'] ?? data['profile'];
            if (driverField is List && driverField.isNotEmpty) {
              driverJson = driverField.first;
            } else {
              driverJson = driverField ?? data;
            }
          } else if (data is List && data.isNotEmpty) {
            driverJson = data.first;
          } else {
            // Fallback: essayer au niveau racine
            final dynamic rootDriver = decoded['driver'];
            if (rootDriver != null) {
              driverJson = rootDriver;
            }
          }

          if (driverJson is Map<String, dynamic>) {
            // Construction manuelle d'un profil "sûr" sans fromJson imbriqués
            final dynamic rawVehicle = driverJson['vehicle'];
            final Map<String, dynamic> vehicle =
                rawVehicle is Map<String, dynamic> ? rawVehicle : <String, dynamic>{};

            final String driverId =
                driverJson['id'] ?? driverJson['_id'] ?? '';
            final String firstName = driverJson['firstName'] ?? '';
            final String lastName = driverJson['lastName'] ?? '';
            final String phone = driverJson['phone'] ?? '';
            final String email = driverJson['email'] ?? '';

            final String vehicleTypeStr = vehicle['type'] ?? 'car';
            final vehicleType = VehicleType.fromString(vehicleTypeStr);

            final computedType =
                (vehicle['category'] == 'moto' || vehicle['type'] == 'moto_delivery')
                    ? 'courier'
                    : 'driver';

            // Stats par défaut pour éviter toute erreur de parsing
            final stats = DriverStats(
              totalRides: 0,
              completedRides: 0,
              cancelledRides: 0,
              averageRating: 0.0,
              totalEarnings: 0.0,
              totalDistance: 0.0,
              todayRides: 0,
              todayEarnings: 0.0,
              weeklyRides: 0,
              weeklyEarnings: 0.0,
              bonusEarned: 0.0,
            );

            return DriverProfile(
              id: driverId,
              firstName: firstName,
              lastName: lastName,
              phone: phone,
              email: email,
              vehicleType: vehicleType,
              vehicle: VehicleInfo.fromJson(vehicle),
              subscription: null,
              stats: stats,
              isOnline: driverJson['status'] == 'online' || driverJson['isOnline'] == true,
              isAvailable: driverJson['isAvailable'] ?? false,
              currentLocation: null,
              rideTypes: null,
              preferences: null,
              driverType: (driverJson['driverType'] ?? computedType) as String,
            );
          }

          throw Exception('Format de réponse profil chauffeur inattendu');
        }
        throw Exception('Erreur de récupération du profil');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  // Statut en ligne/hors ligne
  static Future<void> toggleOnlineStatus(bool isOnline) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/drivers/status'),
        headers: _headers,
        body: jsonEncode({
          'status': isOnline ? 'online' : 'offline',
          'isAvailable': isOnline,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur mise à jour statut: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur mise à jour statut: $e');
    }
  }

  // Mise à jour localisation
  static Future<void> updateLocation(double latitude, double longitude, {String? address}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/drivers/location'),
        headers: _headers,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur mise à jour localisation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur mise à jour localisation: $e');
    }
  }

  // Abonnements - Plans disponibles
  static Future<List<SubscriptionPlan>> getAvailablePlans(VehicleType vehicleType) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/plans?vehicleType=${vehicleType.toString()}'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['data']['plans'] as List)
              .map((plan) => SubscriptionPlan.fromJson(plan))
              .toList();
        }
        throw Exception('Erreur de récupération des plans');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  // Abonnements - Achat
  static Future<Map<String, dynamic>> purchaseSubscription({
    required String planType,
    required String paymentMethod,
    String? phone,
    bool autoRenew = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions/purchase'),
        headers: _headers,
        body: jsonEncode({
          'planType': planType,
          'paymentMethod': paymentMethod,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'autoRenew': autoRenew,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur d\'achat d\'abonnement');
      }
    } catch (e) {
      throw Exception('Erreur achat abonnement: $e');
    }
  }

  // Abonnements - Abonnement actuel
  static Future<SubscriptionInfo?> getCurrentSubscription() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/current'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['data']['subscription'] != null) {
          return SubscriptionInfo.fromJson(data['data']['subscription']);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null; // Pas d'abonnement actif
      } else {
        throw Exception('Erreur de récupération de l\'abonnement');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  // Bonus - Historique pour livreurs moto
  static Future<Map<String, dynamic>> getBonusHistory(String subscriptionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/bonus-history'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur de récupération de l\'historique des bonus');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  // Historique des courses du chauffeur
  static Future<List<Map<String, dynamic>>> getDriverRides({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final query = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final uri = Uri.parse('$baseUrl/drivers/rides').replace(queryParameters: query);

      final response = await http.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final rides = data['data']?['rides'];
          if (rides is List) {
            return List<Map<String, dynamic>>.from(rides);
          }
        }
        throw Exception('Réponse inattendue du serveur');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération historique courses: $e');
    }
  }

  // Statistiques chauffeur
  static Future<DriverStats> getDriverStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/drivers/stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return DriverStats.fromJson(data['data']);
        }
        throw Exception('Erreur de récupération des statistiques');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  // Courses à proximité
  static Future<List<Map<String, dynamic>>> getNearbyRides({int radius = 2, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/drivers/nearby-rides?radius=$radius&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']['rides']);
        }
        throw Exception('Erreur de récupération des courses');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  // Accepter une course
  static Future<Map<String, dynamic>> acceptRide(String rideId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/accept'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur d\'acceptation de course');
      }
    } catch (e) {
      throw Exception('Erreur acceptation course: $e');
    }
  }

  // Signaler arrivée
  static Future<Map<String, dynamic>> arriveAtPickup(String rideId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/arrive'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur de signalisation d\'arrivée');
      }
    } catch (e) {
      throw Exception('Erreur signalisation arrivée: $e');
    }
  }

  // Démarrer course
  static Future<Map<String, dynamic>> startRide(String rideId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/start'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur de démarrage de course');
      }
    } catch (e) {
      throw Exception('Erreur démarrage course: $e');
    }
  }

  // Terminer course
  static Future<Map<String, dynamic>> completeRide(String rideId, {
    int? actualDuration,
    double? actualDistance,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/complete'),
        headers: _headers,
        body: jsonEncode({
          if (actualDuration != null) 'actualDuration': actualDuration,
          if (actualDistance != null) 'actualDistance': actualDistance,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur de finalisation de course');
      }
    } catch (e) {
      throw Exception('Erreur finalisation course: $e');
    }
  }
}

// Modèle pour les plans d'abonnement
class SubscriptionPlan {
  final String type;
  final String name;
  final double price;
  final String currency;
  final int duration;
  final List<String> features;
  final Map<String, dynamic>? savings;
  final bool isAvailable;

  SubscriptionPlan({
    required this.type,
    required this.name,
    required this.price,
    required this.currency,
    required this.duration,
    required this.features,
    this.savings,
    required this.isAvailable,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      type: json['type'],
      name: json['name'],
      price: json['price'].toDouble(),
      currency: json['currency'],
      duration: json['duration'],
      features: List<String>.from(json['features']),
      savings: json['savings'],
      isAvailable: json['isAvailable'],
    );
  }

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

