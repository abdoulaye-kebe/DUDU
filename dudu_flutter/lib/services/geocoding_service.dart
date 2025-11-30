import 'dart:convert';
import 'dart:math' as Math;
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places';
  static const String _accessToken = 'pk.eyJ1IjoiZHVkdS1zZW5lZ2FsIiwiYSI6ImNsc2V4Z2V4Z2V4Z2V4In0.example'; // Token d'exemple
  
  // Villes principales du Sénégal avec coordonnées
  static const Map<String, Map<String, dynamic>> _senegalCities = {
    'Dakar': {
      'latitude': 14.6928,
      'longitude': -17.4467,
      'region': 'Dakar',
      'population': 1438725
    },
    'Thiès': {
      'latitude': 14.7894,
      'longitude': -16.9260,
      'region': 'Thiès',
      'population': 320000
    },
    'Kaolack': {
      'latitude': 14.1514,
      'longitude': -16.0756,
      'region': 'Kaolack',
      'population': 233000
    },
    'Ziguinchor': {
      'latitude': 12.5833,
      'longitude': -16.2719,
      'region': 'Ziguinchor',
      'population': 205000
    },
    'Saint-Louis': {
      'latitude': 16.0333,
      'longitude': -16.5000,
      'region': 'Saint-Louis',
      'population': 176000
    },
    'Diourbel': {
      'latitude': 14.6561,
      'longitude': -16.2306,
      'region': 'Diourbel',
      'population': 100000
    },
    'Louga': {
      'latitude': 15.6167,
      'longitude': -16.2167,
      'region': 'Louga',
      'population': 90000
    },
    'Tambacounda': {
      'latitude': 13.7539,
      'longitude': -13.6936,
      'region': 'Tambacounda',
      'population': 80000
    },
    'Kolda': {
      'latitude': 12.8833,
      'longitude': -14.9500,
      'region': 'Kolda',
      'population': 70000
    },
    'Fatick': {
      'latitude': 14.3333,
      'longitude': -16.4167,
      'region': 'Fatick',
      'population': 60000
    }
  };

  // Lieux d'intérêt populaires au Sénégal
  static const Map<String, Map<String, dynamic>> _popularPlaces = {
    'Aéroport Léopold Sédar Senghor': {
      'latitude': 14.6708,
      'longitude': -17.0731,
      'city': 'Dakar',
      'type': 'airport'
    },
    'Place de l\'Indépendance': {
      'latitude': 14.6928,
      'longitude': -17.4467,
      'city': 'Dakar',
      'type': 'landmark'
    },
    'Université Cheikh Anta Diop': {
      'latitude': 14.6928,
      'longitude': -17.4467,
      'city': 'Dakar',
      'type': 'university'
    },
    'Marché Sandaga': {
      'latitude': 14.6928,
      'longitude': -17.4467,
      'city': 'Dakar',
      'type': 'market'
    },
    'Gare de Dakar': {
      'latitude': 14.6928,
      'longitude': -17.4467,
      'city': 'Dakar',
      'type': 'station'
    },
    'Port de Dakar': {
      'latitude': 14.6928,
      'longitude': -17.4467,
      'city': 'Dakar',
      'type': 'port'
    }
  };

  // Recherche d'autocomplétion - Filtre les adresses qui commencent par la saisie
  static Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    
    final queryLower = query.toLowerCase().trim();
    final suggestions = <PlaceSuggestion>[];
    final addedNames = <String>{}; // Pour éviter les doublons
    
    // Recherche dans les villes - commence par la saisie
    for (final entry in _senegalCities.entries) {
      final name = entry.key.toLowerCase();
      if (name.startsWith(queryLower) && !addedNames.contains(entry.key)) {
        suggestions.add(PlaceSuggestion(
          name: entry.key,
          address: '${entry.key}, ${entry.value['region']}, Sénégal',
          latitude: entry.value['latitude'],
          longitude: entry.value['longitude'],
          type: 'city',
          region: entry.value['region'],
        ));
        addedNames.add(entry.key);
      }
    }
    
    // Recherche dans les lieux d'intérêt - commence par la saisie
    for (final entry in _popularPlaces.entries) {
      final name = entry.key.toLowerCase();
      if (name.startsWith(queryLower) && !addedNames.contains(entry.key)) {
        suggestions.add(PlaceSuggestion(
          name: entry.key,
          address: '${entry.key}, ${entry.value['city']}, Sénégal',
          latitude: entry.value['latitude'],
          longitude: entry.value['longitude'],
          type: entry.value['type'],
          city: entry.value['city'],
        ));
        addedNames.add(entry.key);
      }
    }
    
    // Si pas de résultats qui commencent par, chercher les contenus (fallback)
    if (suggestions.isEmpty) {
      for (final entry in _senegalCities.entries) {
        final name = entry.key.toLowerCase();
        if (name.contains(queryLower) && !addedNames.contains(entry.key)) {
          suggestions.add(PlaceSuggestion(
            name: entry.key,
            address: '${entry.key}, ${entry.value['region']}, Sénégal',
            latitude: entry.value['latitude'],
            longitude: entry.value['longitude'],
            type: 'city',
            region: entry.value['region'],
          ));
          addedNames.add(entry.key);
        }
      }
      
      for (final entry in _popularPlaces.entries) {
        final name = entry.key.toLowerCase();
        if (name.contains(queryLower) && !addedNames.contains(entry.key)) {
          suggestions.add(PlaceSuggestion(
            name: entry.key,
            address: '${entry.key}, ${entry.value['city']}, Sénégal',
            latitude: entry.value['latitude'],
            longitude: entry.value['longitude'],
            type: entry.value['type'],
            city: entry.value['city'],
          ));
          addedNames.add(entry.key);
        }
      }
    }
    
    // Trier par pertinence (ceux qui commencent par en premier)
    suggestions.sort((a, b) {
      final aStarts = a.name.toLowerCase().startsWith(queryLower);
      final bStarts = b.name.toLowerCase().startsWith(queryLower);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      return a.name.compareTo(b.name);
    });
    
    return suggestions.take(10).toList();
  }

  // Géocodage inverse (coordonnées -> adresse)
  static Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      // Pour l'instant, retourner une adresse simulée
      // Dans une vraie implémentation, utiliser l'API Mapbox
      return 'Position: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      return null;
    }
  }

  // Obtenir les coordonnées du centre du Sénégal
  static Map<String, double> getSenegalCenter() {
    return {
      'latitude': 14.4974,
      'longitude': -14.4524,
    };
  }

  // Obtenir les limites du Sénégal
  static Map<String, double> getSenegalBounds() {
    return {
      'north': 16.6919,
      'south': 12.3071,
      'east': -11.3459,
      'west': -17.5352,
    };
  }

  // Vérifier si un point est dans les limites du Sénégal
  static bool isWithinSenegal(double latitude, double longitude) {
    final bounds = getSenegalBounds();
    return latitude >= bounds['south']! && 
           latitude <= bounds['north']! &&
           longitude >= bounds['west']! && 
           longitude <= bounds['east']!;
  }

  // Calculer la distance entre deux points
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = 
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_degreesToRadians(lat1)) * Math.cos(_degreesToRadians(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    final double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (Math.pi / 180);
  }
}

class PlaceSuggestion {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String type;
  final String? region;
  final String? city;

  PlaceSuggestion({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.region,
    this.city,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'region': region,
      'city': city,
    };
  }
}












