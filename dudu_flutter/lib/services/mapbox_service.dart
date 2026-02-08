import 'package:mapbox_search/mapbox_search.dart';

class MapboxService {
  // Clé API Mapbox publique (à remplacer par la vraie clé)
  // Pour obtenir une clé gratuite : https://account.mapbox.com/
  static const String _accessToken = 'pk.eyJ1IjoiZHVkdS1zZW5lZ2FsIiwiYSI6ImNsc2V4Z2V4Z2V4Z2V4In0.VOTRE_CLE_ICI';
  
  static late PlacesSearch _placesSearch;
  static bool _initialized = false;

  /// Initialiser le service Mapbox
  static void initialize() {
    if (!_initialized) {
      _placesSearch = PlacesSearch(
        apiKey: _accessToken,
        limit: 10,
        country: 'SN', // Sénégal
        language: 'fr',
      );
      _initialized = true;
      print('✅ Mapbox Service initialisé');
    }
  }

  /// Autocomplétion des adresses avec Mapbox
  static Future<List<MapboxPlace>> getPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];
    
    initialize();

    try {
      print('🔍 Mapbox Search: "$query"');
      
      // Recherche avec proximité à Dakar
      final response = await _placesSearch.getPlaces(
        query,
        proximity: Location(lat: 14.6928, lng: -17.4467), // Centre de Dakar
      );

      if (response != null && response.isNotEmpty) {
        print('✅ Mapbox: ${response.length} résultats trouvés');
        return response;
      } else {
        print('⚠️ Mapbox: Aucun résultat');
        return [];
      }
    } catch (e) {
      print('❌ Erreur Mapbox: $e');
      return [];
    }
  }

  /// Géocodage inverse (coordonnées → adresse)
  static Future<String> reverseGeocode(double lat, double lng) async {
    initialize();

    try {
      final reverseGeocoding = ReverseGeoCoding(
        apiKey: _accessToken,
        limit: 1,
        country: 'SN',
        language: 'fr',
      );

      final response = await reverseGeocoding.getAddress(
        Location(lat: lat, lng: lng),
      );

      if (response != null && response.isNotEmpty) {
        return response.first.placeName ?? 'Dakar, Sénégal';
      }

      return 'Dakar, Sénégal';
    } catch (e) {
      print('❌ Erreur géocodage inverse Mapbox: $e');
      return 'Dakar, Sénégal';
    }
  }

  /// Géocodage (adresse → coordonnées)
  static Future<MapboxPlace?> geocodeAddress(String address) async {
    if (address.isEmpty) return null;
    
    initialize();

    try {
      final response = await _placesSearch.getPlaces(
        address,
        proximity: Location(lat: 14.6928, lng: -17.4467),
      );

      if (response != null && response.isNotEmpty) {
        return response.first;
      }

      return null;
    } catch (e) {
      print('❌ Erreur géocodage Mapbox: $e');
      return null;
    }
  }
}

/// Classe pour représenter un lieu Mapbox
class MapboxPlaceSuggestion {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? type;

  MapboxPlaceSuggestion({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.type,
  });

  factory MapboxPlaceSuggestion.fromMapboxPlace(MapboxPlace place) {
    return MapboxPlaceSuggestion(
      placeId: place.id ?? '',
      name: place.text ?? '',
      address: place.placeName ?? '',
      latitude: place.geometry?.coordinates?.last ?? 0.0,
      longitude: place.geometry?.coordinates?.first ?? 0.0,
      type: place.placeType?.isNotEmpty == true ? place.placeType!.first : null,
    );
  }
}
