import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Service de paiement mobile Wave
class MobilePaymentService {
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Initier un paiement Wave
  static Future<Map<String, dynamic>> initiateWavePayment({
    required String rideId,
    required int amount,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/mobile-payments/wave/initiate'),
        headers: await _headers(),
        body: jsonEncode({
          'rideId': rideId,
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
          'currency': data['data']['currency'],
          'expiresAt': data['data']['expiresAt'],
        };
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'initiation du paiement');
      }
    } catch (e) {
      print('Erreur initiation paiement Wave: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  /// Vérifier le statut d'un paiement
  static Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/mobile-payments/$paymentId/status'),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'paymentId': data['data']['paymentId'],
          'status': data['data']['status'],
          'amount': data['data']['amount'],
          'currency': data['data']['currency'],
          'method': data['data']['method'],
          'transactionId': data['data']['transactionId'],
          'completedAt': data['data']['completedAt'],
        };
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la vérification du statut');
      }
    } catch (e) {
      print('Erreur vérification statut paiement: $e');
      throw Exception('Erreur de connexion au serveur');
    }
  }

  /// Annuler un paiement
  static Future<bool> cancelPayment(String paymentId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/mobile-payments/$paymentId/cancel'),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'annulation');
      }
    } catch (e) {
      print('Erreur annulation paiement: $e');
      return false;
    }
  }

  /// Calculer les frais de transaction (Wave)
  static Map<String, dynamic> calculateFees(int amount) {
    const feePercentage = 0.015; // 1.5%

    final fees = (amount * feePercentage).round();
    final netAmount = amount - fees;

    return {
      'amount': amount,
      'fees': fees,
      'netAmount': netAmount,
      'feePercentage': (feePercentage * 100).toStringAsFixed(1),
    };
  }

  /// Normaliser le numéro de téléphone
  static String normalizePhoneNumber(String phone) {
    String normalized = phone.trim().replaceAll(RegExp(r'\s+'), '');
    
    // Retirer le + si présent
    if (normalized.startsWith('+')) {
      normalized = normalized.substring(1);
    }
    
    // Ajouter 221 si nécessaire (Sénégal)
    if (normalized.length == 9) {
      normalized = '221$normalized';
    }
    
    // Ajouter le + au début
    if (!normalized.startsWith('+')) {
      normalized = '+$normalized';
    }
    
    return normalized;
  }

  /// Valider le numéro de téléphone
  static bool isValidPhoneNumber(String phone) {
    final normalized = normalizePhoneNumber(phone);
    // Format: +221XXXXXXXXX (12 caractères)
    return RegExp(r'^\+221[0-9]{9}$').hasMatch(normalized);
  }
}
