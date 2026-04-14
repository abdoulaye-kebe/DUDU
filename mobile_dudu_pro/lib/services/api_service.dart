import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, kDebugMode, debugPrint, defaultTargetPlatform, TargetPlatform;
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

  static Future<Map<String, dynamic>> updateRideTypes({
    bool? comfort,
    bool? luxe,
    bool? womenOnly,
    bool? delivery,
    bool? moto,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (comfort != null) body['comfort'] = comfort;
      if (luxe != null) body['luxe'] = luxe;
      if (womenOnly != null) body['women_only'] = womenOnly;
      if (delivery != null) body['delivery'] = delivery;
      if (moto != null) body['moto'] = moto;

      final response = await http.put(
        Uri.parse('$baseUrl/drivers/ride-types'),
        headers: _headers,
        body: jsonEncode(body),
      );

      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : {
              'success': false,
              'message': 'Réponse serveur inattendue'
            };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: $e'
      };
    }
  }

  static void clearAuthToken() {
    _authToken = null;
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

  /// Met à jour le véhicule (champs acceptés par PUT /drivers/profile)
  static Future<void> updateDriverVehicle({
    required String make,
    required String model,
    required int year,
    required String color,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/drivers/profile'),
      headers: _headers,
      body: jsonEncode({
        'vehicle': {
          'make': make,
          'model': model,
          'year': year,
          'color': color,
        },
      }),
    );

    if (response.statusCode != 200) {
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
      final msg = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Erreur mise à jour profil (HTTP ${response.statusCode})';
      throw Exception(msg);
    }
  }

  // Changer le mot de passe
  static Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/drivers/change-password'),
        headers: _headers,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final decoded = jsonDecode(response.body);
        throw Exception(decoded['message'] ?? 'Erreur lors du changement de mot de passe');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/drivers/account'),
        headers: _headers,
      );

      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : {
              'success': false,
              'message': 'Réponse serveur inattendue'
            };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: $e'
      };
    }
  }

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
      if (kDebugMode) {
        print('📤 applyAsDriver payload: ${jsonEncode(payload)}');
      }
      final response = await http.post(
        Uri.parse('$baseUrl/drivers/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (kDebugMode) {
        print('📥 applyAsDriver status: ${response.statusCode}');
        print('📥 applyAsDriver body: ${response.body}');
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      if (decoded is Map<String, dynamic>) {
        // Normal: backend returns {success, message, ...}
        return decoded;
      }

      // Fallback: non-json or unexpected format
      return {
        'success': false,
        'message': response.statusCode >= 400
            ? 'Données invalides (HTTP ${response.statusCode})'
            : 'Réponse serveur inattendue',
        'raw': response.body,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur candidature chauffeur: $e',
      };
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

            final dynamic rawRideTypes = driverJson['rideTypes'];
            final Map<String, bool>? rideTypes = rawRideTypes is Map
                ? Map<String, bool>.from(rawRideTypes.map(
                    (key, value) => MapEntry(key.toString(), value == true),
                  ))
                : null;

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

            final dynamic rawStats = driverJson['stats'];
            final DriverStats stats = rawStats is Map<String, dynamic>
                ? DriverStats.fromJson(rawStats)
                : DriverStats(
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
                    acceptanceRate: 0.0,
                  );

            final SubscriptionInfo? subscription =
                SubscriptionInfo.tryParseFromProfileField(
                    driverJson['subscription']);

            final dynamic rawEarnings = driverJson['earnings'];
            final EarningsInfo earnings;
            if (rawEarnings is Map<String, dynamic>) {
              earnings = EarningsInfo.fromJson(rawEarnings);
            } else if (rawStats is Map<String, dynamic>) {
              earnings = EarningsInfo(
                today: (rawStats['todayEarnings'] as num?)?.toDouble() ?? 0,
                thisWeek:
                    (rawStats['weeklyEarnings'] as num?)?.toDouble() ?? 0,
                thisMonth:
                    (rawStats['thisMonthEarnings'] as num?)?.toDouble() ?? 0,
                total: (rawStats['totalEarnings'] as num?)?.toDouble() ?? 0,
              );
            } else {
              earnings = EarningsInfo.empty();
            }

            return DriverProfile(
              id: driverId,
              firstName: firstName,
              lastName: lastName,
              phone: phone,
              email: email,
              vehicleType: vehicleType,
              vehicle: VehicleInfo.fromJson(vehicle),
              subscription: subscription,
              stats: stats,
              earnings: earnings,
              isOnline: driverJson['status'] == 'online' ||
                  driverJson['isOnline'] == true,
              isAvailable: driverJson['isAvailable'] ?? false,
              currentLocation: null,
              rideTypes: rideTypes,
              preferences: null,
              driverType: (driverJson['driverType'] ?? computedType) as String,
              isVerified: driverJson['isVerified'] == true,
              verificationStatus:
                  driverJson['verificationStatus']?.toString() ?? 'pending',
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
  static const Duration timeout = Duration(seconds: 30);
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

  /// Paiement abonnement via API Orange (QR + deeplinks MAX IT / OM).
  static Future<Map<String, dynamic>> initiateSubscriptionOrangeMoney({
    required String planType,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mobile-payments/subscription/orange-money/initiate'),
        headers: _headers,
        body: jsonEncode({
          'planType': planType,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          return decoded;
        }
      }
      final msg = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Erreur initiation paiement Orange';
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Statut d’un paiement (polling après MAX IT).
  static Future<String?> getPaymentStatus(String paymentMongoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mobile-payments/$paymentMongoId/status'),
        headers: _headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          decoded is Map<String, dynamic> &&
          decoded['success'] == true) {
        final data = decoded['data'];
        if (data is Map && data['status'] != null) {
          return data['status'].toString();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Abonnements - Achat
  static Future<Map<String, dynamic>> purchaseSubscription({
    required String planType,
    required String paymentMethod,
    String? phone,
    bool autoRenew = false,
    String? transactionCode,
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
          if (transactionCode != null && transactionCode.isNotEmpty) 'transactionCode': transactionCode,
          'status': 'pending', // En attente de validation
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        Map<String, dynamic>? error;
        try {
          error = jsonDecode(response.body);
        } catch (_) {}
        final message = error != null && error['message'] != null
            ? error['message'].toString()
            : 'Erreur d\'achat d\'abonnement (code ${response.statusCode})';
        throw Exception(message);
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
      }
      // 404 = aucun document ; 403 = ex. compte non encore approuvé (requireDriverApproved) — on s'appuie alors sur le profil.
      if (response.statusCode == 404 || response.statusCode == 403) {
        return null;
      }
      throw Exception('Erreur de récupération de l\'abonnement');
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  /// GET /subscriptions/:id/bonus-history (livreurs moto) — renvoie le corps `data` uniquement.
  static Future<Map<String, dynamic>> getBonusHistory(String subscriptionId) async {
    if (subscriptionId.isEmpty) {
      throw Exception('Aucun abonnement');
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/bonus-history'),
        headers: _headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          decoded is Map<String, dynamic> &&
          decoded['success'] == true) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) return data;
      }
      final msg = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Erreur bonus (HTTP ${response.statusCode})';
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
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
  static Future<List<Map<String, dynamic>>> getNearbyRides({int radius = 15, int limit = 10}) async {
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

  /// Détails d'une course (GET /rides/:id) — chauffeur assigné ou passager
  static Future<Map<String, dynamic>?> getRideDetails(String rideId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rides/$rideId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> ? decoded : null;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getRideDetails: $e');
      }
      return null;
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

  /// GET /drivers/earnings?period=today|week|month|year
  static Future<Map<String, dynamic>> getDriverEarningsSummary({
    required String period,
  }) async {
    final uri = Uri.parse('$baseUrl/drivers/earnings').replace(
      queryParameters: {'period': period},
    );
    final response = await http.get(uri, headers: _headers);
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 &&
        decoded is Map<String, dynamic> &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Erreur revenus (HTTP ${response.statusCode})';
    throw Exception(msg);
  }

  /// GET /drivers/rides
  static Future<Map<String, dynamic>> getDriverRidesList({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final uri =
        Uri.parse('$baseUrl/drivers/rides').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 &&
        decoded is Map<String, dynamic> &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
    }
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Erreur courses (HTTP ${response.statusCode})';
    throw Exception(msg);
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
    final String rawType = json['type'] ?? 'daily';

    // Prix renvoyé par le backend (fallback)
    double backendPrice = 0;
    try {
      backendPrice = (json['price'] ?? 0).toDouble();
    } catch (_) {}

    // Forcer les prix officiels pour les chauffeurs
    double forcedPrice;
    switch (rawType) {
      case 'daily':
        forcedPrice = AppConfig.dailySubscriptionPrice.toDouble();
        break;
      case 'weekly':
        forcedPrice = AppConfig.weeklySubscriptionPrice.toDouble();
        break;
      case 'monthly':
        forcedPrice = AppConfig.monthlySubscriptionPrice.toDouble();
        break;
      default:
        forcedPrice = backendPrice;
        break;
    }

    return SubscriptionPlan(
      type: rawType,
      name: json['name'] ?? 'Forfait',
      price: forcedPrice,
      currency: json['currency'] ?? 'XOF',
      duration: json['duration'] ?? 1,
      features: json['features'] is List
          ? List<String>.from(json['features'])
          : <String>[],
      savings: json['savings'],
      isAvailable: json['isAvailable'] ?? true,
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

// Extension pour les paiements d'abonnement
extension SubscriptionPaymentExtension on ApiService {
  /// Initier un paiement d'abonnement via Wave
  static Future<Map<String, dynamic>> initiateSubscriptionPayment({
    required String subscriptionId,
    required int amount,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/mobile-payments/subscription/wave/initiate'),
        headers: ApiService._headers,
        body: jsonEncode({
          'subscriptionId': subscriptionId,
          'amount': amount,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'paymentId': data['data']['paymentId'],
          'sessionId': data['data']['sessionId'],
          'checkoutUrl': data['data']['checkoutUrl'],
          'amount': data['data']['amount'],
        };
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'initiation du paiement');
      }
    } catch (e) {
      throw Exception('Erreur de connexion au serveur: $e');
    }
  }

  /// Initier un paiement d'abonnement via Orange Money
  Future<Map<String, dynamic>> initiateSubscriptionPaymentOM({
    required String subscriptionId,
    required int amount,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/mobile-payments/subscription/orange-money/initiate'),
        headers: ApiService._headers,
        body: jsonEncode({
          'subscriptionId': subscriptionId,
          'amount': amount,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'initiation du paiement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  /// Vérifier le statut d'un paiement
  static Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/mobile-payments/$paymentId/status'),
        headers: ApiService._headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'paymentId': data['data']['paymentId'],
          'status': data['data']['status'],
          'amount': data['data']['amount'],
        };
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la vérification');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}

