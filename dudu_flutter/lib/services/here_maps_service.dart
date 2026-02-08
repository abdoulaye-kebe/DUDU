import 'package:dio/dio.dart';

class HereMapsService {
  // Clé API HERE Maps (gratuite, sans carte bancaire)
  // Pour obtenir: https://developer.here.com/sign-up
  static const String _apiKey = 'VOTRE_CLE_HERE_MAPS';
  static final Dio _dio = Dio();

  /// Autocomplétion des adresses avec HERE Maps
  static Future<List<HerePlaceSuggestion>> getPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];

    try {
      print('🔍 HERE Maps Search: "$query"');

      // API Autosuggest de HERE Maps
      final response = await _dio.get(
        'https://autosuggest.search.hereapi.com/v1/autosuggest',
        queryParameters: {
          'q': query,
          'at': '14.6928,-17.4467', // Centre de Dakar
          'limit': 10,
          'lang': 'fr',
          'apiKey': _apiKey,
        },
      );

      if (response.statusCode == 200 && response.data['items'] != null) {
        final items = response.data['items'] as List;
        print('✅ HERE Maps: ${items.length} résultats');

        return items.map((item) => HerePlaceSuggestion.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      print('❌ Erreur HERE Maps: $e');
      return [];
    }
  }

  /// Géocodage inverse (coordonnées → adresse)
  static Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://revgeocode.search.hereapi.com/v1/revgeocode',
        queryParameters: {
          'at': '$lat,$lng',
          'lang': 'fr',
          'apiKey': _apiKey,
        },
      );

      if (response.statusCode == 200 && response.data['items'] != null) {
        final items = response.data['items'] as List;
        if (items.isNotEmpty) {
          return items[0]['address']['label'] ?? 'Dakar, Sénégal';
        }
      }

      return 'Dakar, Sénégal';
    } catch (e) {
      print('❌ Erreur géocodage inverse HERE: $e');
      return 'Dakar, Sénégal';
    }
  }
}

/// Classe pour représenter une suggestion HERE Maps
class HerePlaceSuggestion {
  final String id;
  final String title;
  final String address;
  final double? latitude;
  final double? longitude;

  HerePlaceSuggestion({
    required this.id,
    required this.title,
    required this.address,
    this.latitude,
    this.longitude,
  });

  factory HerePlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final position = json['position'];
    
    return HerePlaceSuggestion(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      address: json['address']?['label'] ?? json['title'] ?? '',
      latitude: position?['lat']?.toDouble(),
      longitude: position?['lng']?.toDouble(),
    );
  }
}
