import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/ride.dart';
import '../config/app_config.dart';

class ApiService {
  // Utiliser la configuration centralisée
  static String get baseUrl => AppConfig.baseUrl;

  static Future<ApiResponse<User>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? language,
    String? currency,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: await _getHeaders(),
        body: json.encode({
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (email != null) 'email': email,
          if (language != null) 'language': language,
          if (currency != null) 'currency': currency,
        }),
      ).timeout(timeout);

      return _handleResponse(response, (data) {
        final dynamic raw = data['user'] ?? data;
        if (raw is Map<String, dynamic>) {
          return User.fromJson(raw);
        }
        throw Exception('Format de réponse updateProfile inattendu');
      });
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: 'Erreur mise à jour profil: $e',
        data: null,
      );
    }
  }

  static Future<ApiResponse<BudgetSettings>> updateBudgetSettings({
    double? maxPricePerKm,
    String? preferredPaymentMethod,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/budget-settings'),
        headers: await _getHeaders(),
        body: json.encode({
          if (maxPricePerKm != null) 'maxPricePerKm': maxPricePerKm,
          if (preferredPaymentMethod != null)
            'preferredPaymentMethod': preferredPaymentMethod,
        }),
      ).timeout(timeout);

      return _handleResponse(response, (data) {
        final dynamic raw = data['budgetSettings'] ?? data;
        if (raw is Map<String, dynamic>) {
          return BudgetSettings.fromJson(raw);
        }
        throw Exception('Format de réponse updateBudgetSettings inattendu');
      });
    } catch (e) {
      return ApiResponse<BudgetSettings>(
        success: false,
        message: 'Erreur mise à jour budget: $e',
        data: null,
      );
    }
  }

  static Future<ApiResponse<bool>> resendVerificationCode(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: await _getHeaders(),
        body: json.encode({'phone': phone}),
      ).timeout(timeout);

      return _handleResponse(response, (_) => true);
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        message: 'Erreur renvoi code: $e',
        data: null,
      );
    }
  }

  static Future<ApiResponse<bool>> deactivateAccount() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/account'),
        headers: await _getHeaders(),
      ).timeout(timeout);

      return _handleResponse(response, (_) => true);
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        message: 'Erreur suppression compte: $e',
        data: null,
      );
    }
  }

  /// Créer une course planifiée (trajet planifié)
  static Future<ApiResponse<Ride>> scheduleRide({
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required String destinationAddress,
    required double destinationLatitude,
    required double destinationLongitude,
    required String rideType,
    required int customPrice,
    required DateTime scheduledFor,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/schedule'),
        headers: await _getHeaders(),
        body: json.encode({
          'pickup': {
            'address': pickupAddress,
            'latitude': pickupLatitude,
            'longitude': pickupLongitude,
          },
          'destination': {
            'address': destinationAddress,
            'latitude': destinationLatitude,
            'longitude': destinationLongitude,
          },
          'rideType': rideType,
          'customPrice': customPrice,
          'scheduledFor': scheduledFor.toUtc().toIso8601String(),
        }),
      ).timeout(timeout);

      return _handleResponse(response, (data) => Ride.fromJson(data['ride']));
    } catch (e) {
      return ApiResponse<Ride>(
        success: false,
        message: 'Erreur de planification de course: $e',
        data: null,
      );
    }
  }

  /// Récupérer les courses planifiées à venir de l'utilisateur
  static Future<ApiResponse<List<Ride>>> getScheduledRides() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/scheduled-rides'),
        headers: await _getHeaders(),
      ).timeout(timeout);

      return _handleResponse(response, (data) {
        final List<dynamic> list = data['rides'] ?? [];
        return list.map((e) => Ride.fromJson(e)).toList();
      });
    } catch (e) {
      return ApiResponse<List<Ride>>(
        success: false,
        message: 'Erreur de récupération des trajets planifiés: $e',
        data: null,
      );
    }
  }

  /// Récupérer l'historique des courses de l'utilisateur
  static Future<ApiResponse<Map<String, dynamic>>> getUserRides({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      String url = '$baseUrl/users/rides?page=$page&limit=$limit';
      if (status != null) {
        url += '&status=$status';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(timeout);

      return _handleResponse(response, (data) {
        final List<dynamic> ridesList = data['rides'] ?? [];
        return {
          'rides': ridesList.map((e) => Ride.fromJson(e)).toList(),
          'pagination': data['pagination'] ?? {},
        };
      });
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Erreur de récupération des courses: $e',
        data: null,
      );
    }
  }
  
  static Duration get timeout => Duration(seconds: AppConfig.httpTimeout);

  // Headers par défaut
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Gestion des erreurs
  static ApiResponse<T> _handleResponse<T>(http.Response response, T Function(dynamic) fromJson) {
    try {
      final data = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>(
          success: data['success'] ?? true,
          message: data['message'] ?? 'Succès',
          data: data['data'] != null ? fromJson(data['data']) : null,
        );
      } else {
        return ApiResponse<T>(
          success: false,
          message: data['message'] ?? 'Erreur inconnue',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Erreur de parsing: $e',
        data: null,
      );
    }
  }

  // Authentification
  static Future<ApiResponse<AuthData>> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _getHeaders(),
        body: json.encode({
          'phone': phone,
          'password': password,
        }),
      ).timeout(timeout);

      if (kDebugMode) {
        print('📡 Réponse login: ${response.statusCode} - ${response.body}');
      }

      final result = _handleResponse(response, (data) => AuthData.fromJson(data));
      
      if (result.success && result.data != null) {
        // Sauvegarder le token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', result.data!.token);
        await prefs.setString('user_data', json.encode(result.data!.user.toJson()));
      }
      
      return result;
    } catch (e) {
      return ApiResponse<AuthData>(
        success: false,
        message: 'Erreur de connexion: $e',
        data: null,
      );
    }
  }

  static Future<ApiResponse<AuthData>> register({
    required String firstName,
    required String lastName,
    String? email,
    required String phone,
    required String password,
    String language = 'fr',
    String? referralCode,
  }) async {
    try {
      final requestData = {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'password': password,
        'language': language,
        if (email != null && email.isNotEmpty) 'email': email,
        if (referralCode != null) 'referralCode': referralCode,
      };
      
      print('🔍 Données d\'inscription envoyées: $requestData');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await _getHeaders(),
        body: json.encode(requestData),
      ).timeout(timeout);
      
      print('📡 Réponse du serveur: ${response.statusCode} - ${response.body}');

      final result = _handleResponse(response, (data) => AuthData.fromJson(data));
      
      if (result.success && result.data != null) {
        // Sauvegarder le token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', result.data!.token);
        await prefs.setString('user_data', json.encode(result.data!.user.toJson()));
      }
      
      return result;
    } catch (e) {
      return ApiResponse<AuthData>(
        success: false,
        message: 'Erreur d\'inscription: $e',
        data: null,
      );
    }
  }

  static Future<ApiResponse<AuthData>> verifyPhone(String phone, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify'),
        headers: await _getHeaders(),
        body: json.encode({
          'phone': phone,
          'code': code,
        }),
      ).timeout(timeout);

      final result = _handleResponse(response, (data) => AuthData.fromJson(data));
      
      if (result.success && result.data != null) {
        // Sauvegarder le token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', result.data!.token);
        await prefs.setString('user_data', json.encode(result.data!.user.toJson()));
      }
      
      return result;
    } catch (e) {
      return ApiResponse<AuthData>(
        success: false,
        message: 'Erreur de vérification: $e',
        data: null,
      );
    }
  }

  static Future<ApiResponse<User>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _getHeaders(),
      ).timeout(timeout);
      return _handleResponse(response, (data) {
        dynamic userJson;

        if (data is Map<String, dynamic>) {
          final dynamic inner = data['user'] ?? data['profile'];
          if (inner is Map<String, dynamic>) {
            userJson = inner;
          } else if (inner is List && inner.isNotEmpty) {
            userJson = inner.first;
          } else {
            userJson = data;
          }
        } else if (data is List && data.isNotEmpty) {
          userJson = data.first;
        }

        if (userJson is Map<String, dynamic>) {
          return User.fromJson(userJson);
        }

        throw Exception('Format de réponse profil utilisateur inattendu');
      });
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: 'Erreur de récupération du profil: $e',
        data: null,
      );
    }
  }

  // Courses
  static Future<ApiResponse<RideRequestResult>> requestRide({
    required RideLocation pickup,
    required RideLocation destination,
    required RidePricing pricing,
    String rideType = 'standard',
    int passengers = 1,
    List<String> specialRequests = const [],
    String? specialMode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/request'),
        headers: await _getHeaders(),
        body: json.encode({
          'pickup': pickup.toJson(),
          'destination': destination.toJson(),
          'pricing': pricing.toJson(),
          'rideType': rideType,
          'passengers': passengers,
          'specialRequests': specialRequests,
          'specialMode': specialMode,
        }),
      ).timeout(timeout);

      return _handleResponse(response, (data) => RideRequestResult.fromJson(data));
    } catch (e) {
      return ApiResponse<RideRequestResult>(
        success: false,
        message: 'Erreur de demande de course: $e',
        data: null,
      );
    }
  }

  static Future<ApiResponse<Ride>> getRide(String rideId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rides/$rideId'),
        headers: await _getHeaders(),
      ).timeout(timeout);

      return _handleResponse(response, (data) => Ride.fromJson(data));
    } catch (e) {
      return ApiResponse<Ride>(
        success: false,
        message: 'Erreur de récupération de la course: $e',
        data: null,
      );
    }
  }

  // Nouvelle méthode pour créer une course avec prix libre
  static Future<ApiResponse<dynamic>> createRide({
    required double pickupLatitude,
    required double pickupLongitude,
    required String pickupAddress,
    required double destinationLatitude,
    required double destinationLongitude,
    required String destinationAddress,
    required String rideType,
    required int customPrice,
    required double estimatedDistance,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/create'),
        headers: await _getHeaders(),
        body: json.encode({
          'pickup': {
            'latitude': pickupLatitude,
            'longitude': pickupLongitude,
            'address': pickupAddress,
          },
          'destination': {
            'latitude': destinationLatitude,
            'longitude': destinationLongitude,
            'address': destinationAddress,
          },
          'rideType': rideType,
          'customPrice': customPrice,
          'estimatedDistance': estimatedDistance,
          'paymentMethod': paymentMethod,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse<dynamic>(
          success: true,
          message: data['message'] ?? 'Course créée avec succès',
          data: data,
        );
      } else {
        final error = json.decode(response.body);
        return ApiResponse<dynamic>(
          success: false,
          message: error['message'] ?? 'Erreur lors de la création de la course',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<dynamic>(
        success: false,
        message: 'Erreur de connexion: $e',
        data: null,
      );
    }
  }

  static Future<ApiResponse<Ride>> cancelRide(String rideId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/cancel'),
        headers: await _getHeaders(),
        body: json.encode({'reason': reason}),
      ).timeout(timeout);

      return _handleResponse(response, (data) => Ride.fromJson(data));
    } catch (e) {
      return ApiResponse<Ride>(
        success: false,
        message: 'Erreur d\'annulation de la course: $e',
        data: null,
      );
    }
  }

  /// Noter une course terminée
  static Future<ApiResponse<bool>> rateRide(String rideId, int rating, {String? comment}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/rate'),
        headers: await _getHeaders(),
        body: json.encode({
          'rating': rating,
          if (comment != null) 'comment': comment,
        }),
      ).timeout(timeout);

      return _handleResponse(response, (data) => true);
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        message: 'Erreur lors de la notation: $e',
        data: null,
      );
    }
  }

  // Déconnexion
  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _getHeaders(),
      ).timeout(timeout);
    } catch (e) {
      // Ignorer les erreurs de déconnexion
    } finally {
      // Nettoyer le stockage local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    }
  }

  // Vérifier la santé de l'API
  static Future<ApiResponse<HealthCheck>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: await _getHeaders(),
      ).timeout(timeout);

      return _handleResponse(response, (data) => HealthCheck.fromJson(data));
    } catch (e) {
      return ApiResponse<HealthCheck>(
        success: false,
        message: 'API indisponible: $e',
        data: null,
      );
    }
  }
}

// Classes de réponse
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });
}

class AuthData {
  final User user;
  final String token;

  AuthData({
    required this.user,
    required this.token,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      user: User.fromJson(json['user']),
      token: json['token'] ?? '',
    );
  }
}

class RideRequestResult {
  final Ride ride;
  final int availableDrivers;

  RideRequestResult({
    required this.ride,
    required this.availableDrivers,
  });

  factory RideRequestResult.fromJson(Map<String, dynamic> json) {
    return RideRequestResult(
      ride: Ride.fromJson(json['ride']),
      availableDrivers: json['availableDrivers'] ?? 0,
    );
  }
}

class HealthCheck {
  final String status;
  final String message;
  final String timestamp;
  final String version;

  HealthCheck({
    required this.status,
    required this.message,
    required this.timestamp,
    required this.version,
  });

  factory HealthCheck.fromJson(Map<String, dynamic> json) {
    return HealthCheck(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? '',
      version: json['version'] ?? '',
    );
  }
}


