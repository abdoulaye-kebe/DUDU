import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String _apiKey = 'AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Autocomplete des adresses
  static Future<List<PlaceSuggestion>> getPlaceSuggestions(String input, {double? userLat, double? userLng}) async {
    if (input.isEmpty) return [];

    // Bias vers Dakar pour des résultats plus pertinents
    final dakarLat = userLat ?? 14.6928;
    final dakarLng = userLng ?? -17.4467;
    final radius = 50000; // 50km autour de la position

    final encodedInput = Uri.encodeComponent(input);

    // Essayer d'abord avec restriction Sénégal
    final url = Uri.parse(
      '$_baseUrl/autocomplete/json?input=$encodedInput&key=$_apiKey&language=fr&location=$dakarLat,$dakarLng&radius=$radius&components=country:sn',
    );

    print('🔍 Recherche Places API: "$input"');

    try {
      final response = await http.get(url);
      print('📡 Places API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];
        print('📍 Places autocomplete status: $status');
        
        // Afficher l'erreur si présente
        if (data['error_message'] != null) {
          print('❌ Places API error: ${data['error_message']}');
        }

        if (status == 'OK') {
          final predictions = data['predictions'] as List;
          print('✅ Trouvé ${predictions.length} suggestions');
          if (predictions.isNotEmpty) {
            final results = <PlaceSuggestion>[];
            for (final p in predictions) {
              try {
                results.add(PlaceSuggestion.fromJson(p as Map<String, dynamic>));
              } catch (e) {
                print('Erreur parsing suggestion: $e');
              }
            }
            return results;
          }
        } else if (status == 'ZERO_RESULTS') {
          print('⚠️ Aucun résultat pour "$input"');
          // Retourner des suggestions locales pour les quartiers connus
          return _getLocalSuggestions(input);
        } else if (status == 'REQUEST_DENIED') {
          print('❌ Clé API invalide ou non activée');
          return _getLocalSuggestions(input);
        }
      }

      // Fallback : suggestions locales
      return _getLocalSuggestions(input);
    } catch (e) {
      print('❌ Erreur autocomplete: $e');
      return _getLocalSuggestions(input);
    }
  }
  
  /// Suggestions locales pour les quartiers de Dakar (fallback)
  static List<PlaceSuggestion> _getLocalSuggestions(String input) {
    final query = input.toLowerCase();
    final localPlaces = [
      {'name': 'Médina', 'address': 'Médina, Dakar, Sénégal', 'lat': 14.6833, 'lng': -17.4500},
      {'name': 'Plateau', 'address': 'Plateau, Dakar, Sénégal', 'lat': 14.6697, 'lng': -17.4389},
      {'name': 'Almadies', 'address': 'Almadies, Dakar, Sénégal', 'lat': 14.7467, 'lng': -17.5167},
      {'name': 'Mamelles', 'address': 'Mamelles, Dakar, Sénégal', 'lat': 14.7333, 'lng': -17.5000},
      {'name': 'Ouakam', 'address': 'Ouakam, Dakar, Sénégal', 'lat': 14.7167, 'lng': -17.4833},
      {'name': 'Yoff', 'address': 'Yoff, Dakar, Sénégal', 'lat': 14.7667, 'lng': -17.4667},
      {'name': 'Ngor', 'address': 'Ngor, Dakar, Sénégal', 'lat': 14.7500, 'lng': -17.5167},
      {'name': 'Mermoz', 'address': 'Mermoz, Dakar, Sénégal', 'lat': 14.7083, 'lng': -17.4667},
      {'name': 'Sacré-Cœur', 'address': 'Sacré-Cœur, Dakar, Sénégal', 'lat': 14.7167, 'lng': -17.4667},
      {'name': 'Fann', 'address': 'Fann, Dakar, Sénégal', 'lat': 14.6917, 'lng': -17.4583},
      {'name': 'Point E', 'address': 'Point E, Dakar, Sénégal', 'lat': 14.6917, 'lng': -17.4667},
      {'name': 'Liberté', 'address': 'Liberté, Dakar, Sénégal', 'lat': 14.7000, 'lng': -17.4583},
      {'name': 'Grand Dakar', 'address': 'Grand Dakar, Dakar, Sénégal', 'lat': 14.6833, 'lng': -17.4667},
      {'name': 'Parcelles Assainies', 'address': 'Parcelles Assainies, Dakar, Sénégal', 'lat': 14.7667, 'lng': -17.4167},
      {'name': 'Pikine', 'address': 'Pikine, Dakar, Sénégal', 'lat': 14.7500, 'lng': -17.3833},
      {'name': 'Guédiawaye', 'address': 'Guédiawaye, Dakar, Sénégal', 'lat': 14.7833, 'lng': -17.3833},
      {'name': 'Rufisque', 'address': 'Rufisque, Dakar, Sénégal', 'lat': 14.7167, 'lng': -17.2667},
      {'name': 'Thiaroye', 'address': 'Thiaroye, Dakar, Sénégal', 'lat': 14.7333, 'lng': -17.3500},
      {'name': 'Keur Massar', 'address': 'Keur Massar, Dakar, Sénégal', 'lat': 14.7833, 'lng': -17.3167},
      {'name': 'Diamniadio', 'address': 'Diamniadio, Dakar, Sénégal', 'lat': 14.7000, 'lng': -17.1833},
      {'name': 'Aéroport AIBD', 'address': 'Aéroport Blaise Diagne, Diass, Sénégal', 'lat': 14.6700, 'lng': -17.0728},
      {'name': 'Gorée', 'address': 'Île de Gorée, Dakar, Sénégal', 'lat': 14.6667, 'lng': -17.4000},
      {'name': 'HLM', 'address': 'HLM, Dakar, Sénégal', 'lat': 14.7000, 'lng': -17.4500},
      {'name': 'Colobane', 'address': 'Colobane, Dakar, Sénégal', 'lat': 14.6917, 'lng': -17.4500},
      {'name': 'Sandaga', 'address': 'Marché Sandaga, Dakar, Sénégal', 'lat': 14.6667, 'lng': -17.4333},
      {'name': 'Corniche', 'address': 'Corniche Ouest, Dakar, Sénégal', 'lat': 14.6833, 'lng': -17.4667},
      {'name': 'Magic Land', 'address': 'Magic Land, Dakar, Sénégal', 'lat': 14.7333, 'lng': -17.5000},
      {'name': 'Sea Plaza', 'address': 'Sea Plaza, Dakar, Sénégal', 'lat': 14.7167, 'lng': -17.4750},
    ];
    
    final filtered = localPlaces.where((place) {
      final name = (place['name'] as String).toLowerCase();
      return name.contains(query) || query.contains(name.substring(0, query.length.clamp(0, name.length)));
    }).toList();
    
    print('📍 Suggestions locales pour "$input": ${filtered.length} résultats');
    
    return filtered.map((place) => PlaceSuggestion(
      placeId: 'local_${place['name']}',
      description: place['address'] as String,
      mainText: place['name'] as String,
      secondaryText: 'Dakar, Sénégal',
      localLat: place['lat'] as double,
      localLng: place['lng'] as double,
    )).toList();
  }

  /// Obtenir les détails d'un lieu (coordonnées)
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    // Si c'est un placeId local, on ne peut pas obtenir les détails via l'API
    // Les coordonnées sont déjà dans PlaceSuggestion
    if (placeId.startsWith('local_')) {
      print('⚠️ getPlaceDetails appelé pour un lieu local: $placeId');
      return null;
    }
    
    final url = Uri.parse(
      '$_baseUrl/details/json?place_id=$placeId&key=$_apiKey&language=fr&fields=geometry,formatted_address,name',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }

      return null;
    } catch (e) {
      print('Erreur details lieu: $e');
      return null;
    }
  }

  /// Géocodage inverse (coordonnées → adresse)
  static Future<String> reverseGeocode(double lat, double lng) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_apiKey&language=fr',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }

      return 'Dakar, Sénégal';
    } catch (e) {
      print('Erreur géocodage inverse: $e');
      return 'Dakar, Sénégal';
    }
  }
  
  /// Géocodage (adresse → coordonnées GPS)
  static Future<PlaceDetails?> geocodeAddress(String address) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_apiKey&language=fr&components=country:sn',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          
          return PlaceDetails(
            latitude: location['lat'],
            longitude: location['lng'],
            formattedAddress: result['formatted_address'],
            name: address,
          );
        }
      }

      return null;
    } catch (e) {
      print('Erreur géocodage adresse: $e');
      return null;
    }
  }
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double? localLat;  // Pour les suggestions locales
  final double? localLng;  // Pour les suggestions locales

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.localLat,
    this.localLng,
  });
  
  /// Vérifie si c'est une suggestion locale (pas besoin d'appeler l'API)
  bool get isLocal => placeId.startsWith('local_');

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] as Map<String, dynamic>?;
    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structured != null ? (structured['main_text'] ?? '') : '',
      secondaryText: structured != null ? (structured['secondary_text'] ?? '') : '',
    );
  }
}

class PlaceDetails {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String name;

  PlaceDetails({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.name,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    return PlaceDetails(
      latitude: location['lat'],
      longitude: location['lng'],
      formattedAddress: json['formatted_address'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

