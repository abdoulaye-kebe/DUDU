import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api/v1';

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur de connexion');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  static Future<void> toggleOnlineStatus(String token, bool isOnline) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/drivers/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'isOnline': isOnline}),
      );
    } catch (e) {
      print('Erreur mise à jour statut: $e');
    }
  }
}

