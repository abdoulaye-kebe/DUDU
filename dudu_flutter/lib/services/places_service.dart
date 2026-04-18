import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../constants/senegal_map.dart';
import 'here_maps_service.dart';

class PlacesService {
  static const String _apiKey = 'AIzaSyBebPcA35Q6WKIiGxG1Xi4iW0ZErazWvZA';

  /// Clé Google Maps (Places / Directions / Geocoding) — ne pas exposer côté web non autorisé.
  static String get mapsApiKey => _apiKey;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  static bool _coordsLikelyInSenegal(double? lat, double? lng) {
    if (lat == null || lng == null) return true;
    return SenegalMap.countryBounds.contains(LatLng(lat, lng));
  }

  static bool _hereAddressLooksSenegal(String address) {
    final a = address.toLowerCase();
    return a.contains('sénégal') ||
        a.contains('senegal') ||
        a.contains(', sn') ||
        a.contains(' dakar') ||
        a.contains(' thiès') ||
        a.contains(' thies');
  }

  /// Autocomplete des adresses avec HERE Maps (prioritaire), Google SN, puis liste locale.
  static Future<List<PlaceSuggestion>> getPlaceSuggestions(String input, {double? userLat, double? userLng}) async {
    if (input.isEmpty) return [];

    print('🔍 Recherche adresse: "$input"');

    final biasLat = userLat ?? 14.6928;
    final biasLng = userLng ?? -17.4467;

    // 1. HERE Maps — restriction pays SEN + biais position
    try {
      final hereResults = await HereMapsService.getPlaceSuggestions(
        input,
        userLat: biasLat,
        userLng: biasLng,
      );

      final filteredHere = hereResults.where((place) {
        if (place.latitude != null &&
            place.longitude != null &&
            !_coordsLikelyInSenegal(place.latitude, place.longitude)) {
          return false;
        }
        if (place.latitude == null || place.longitude == null) {
          return _hereAddressLooksSenegal(place.address);
        }
        return true;
      }).toList();

      if (filteredHere.isNotEmpty) {
        print('✅ HERE Maps: ${filteredHere.length} résultats');
        return filteredHere
            .map(
              (place) => PlaceSuggestion(
                placeId: place.id,
                description: place.address,
                mainText: place.title,
                secondaryText: place.address.replaceFirst('${place.title}, ', ''),
                localLat: place.latitude,
                localLng: place.longitude,
              ),
            )
            .toList();
      }
    } catch (e) {
      print('⚠️ HERE Maps non disponible: $e');
    }

    // 2. Google Places Autocomplete — uniquement Sénégal (components=country:sn)
    try {
      final googleList = await _getGoogleAutocompleteSuggestions(input, biasLat, biasLng);
      if (googleList.isNotEmpty) {
        print('✅ Google Places (SN): ${googleList.length} résultats');
        return googleList;
      }
    } catch (e) {
      print('⚠️ Google Autocomplete: $e');
    }

    // 3. Fallback : suggestions locales (Sénégal)
    print('📍 Utilisation des suggestions locales');
    return _getLocalSuggestions(input);
  }

  static Future<List<PlaceSuggestion>> _getGoogleAutocompleteSuggestions(
    String input,
    double lat,
    double lng,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/autocomplete/json?input=${Uri.encodeComponent(input)}'
      '&key=$_apiKey&language=fr&components=country:sn'
      '&location=$lat,$lng&radius=250000',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
      return [];
    }

    final preds = data['predictions'];
    if (preds is! List) return [];

    return preds
        .map((p) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }
  
  /// Suggestions locales pour les quartiers de Dakar (fallback)
  static List<PlaceSuggestion> _getLocalSuggestions(String input) {
    final query = input.toLowerCase();
    final localPlaces = [
      // Quartiers résidentiels
      {'name': 'Almadies', 'address': 'Almadies, Dakar, Sénégal', 'lat': 14.7467, 'lng': -17.5167, 'type': 'quartier'},
      {'name': 'Almadies Zone 1', 'address': 'Almadies Zone 1, Dakar, Sénégal', 'lat': 14.7450, 'lng': -17.5150, 'type': 'quartier'},
      {'name': 'Almadies Zone 2', 'address': 'Almadies Zone 2, Dakar, Sénégal', 'lat': 14.7480, 'lng': -17.5180, 'type': 'quartier'},
      {'name': 'Ngor', 'address': 'Ngor, Dakar, Sénégal', 'lat': 14.7500, 'lng': -17.5167, 'type': 'quartier'},
      {'name': 'Ngor Virage', 'address': 'Ngor Virage, Dakar, Sénégal', 'lat': 14.7520, 'lng': -17.5180, 'type': 'quartier'},
      {'name': 'Ouakam', 'address': 'Ouakam, Dakar, Sénégal', 'lat': 14.7167, 'lng': -17.4833, 'type': 'quartier'},
      {'name': 'Yoff', 'address': 'Yoff, Dakar, Sénégal', 'lat': 14.7667, 'lng': -17.4667, 'type': 'quartier'},
      {'name': 'Yoff Tonghor', 'address': 'Yoff Tonghor, Dakar, Sénégal', 'lat': 14.7680, 'lng': -17.4650, 'type': 'quartier'},
      {'name': 'Mamelles', 'address': 'Mamelles, Dakar, Sénégal', 'lat': 14.7333, 'lng': -17.5000, 'type': 'quartier'},
      {'name': 'Mermoz', 'address': 'Mermoz, Dakar, Sénégal', 'lat': 14.7083, 'lng': -17.4667, 'type': 'quartier'},
      {'name': 'Mermoz Pyrotechnie', 'address': 'Mermoz Pyrotechnie, Dakar, Sénégal', 'lat': 14.7100, 'lng': -17.4650, 'type': 'quartier'},
      {'name': 'Sacré-Cœur', 'address': 'Sacré-Cœur, Dakar, Sénégal', 'lat': 14.7167, 'lng': -17.4667, 'type': 'quartier'},
      {'name': 'Sacré-Cœur 1', 'address': 'Sacré-Cœur 1, Dakar, Sénégal', 'lat': 14.7170, 'lng': -17.4670, 'type': 'quartier'},
      {'name': 'Sacré-Cœur 2', 'address': 'Sacré-Cœur 2, Dakar, Sénégal', 'lat': 14.7180, 'lng': -17.4680, 'type': 'quartier'},
      {'name': 'Sacré-Cœur 3', 'address': 'Sacré-Cœur 3, Dakar, Sénégal', 'lat': 14.7190, 'lng': -17.4690, 'type': 'quartier'},
      {'name': 'Point E', 'address': 'Point E, Dakar, Sénégal', 'lat': 14.6917, 'lng': -17.4667, 'type': 'quartier'},
      {'name': 'Fann', 'address': 'Fann, Dakar, Sénégal', 'lat': 14.6917, 'lng': -17.4583, 'type': 'quartier'},
      {'name': 'Fann Résidence', 'address': 'Fann Résidence, Dakar, Sénégal', 'lat': 14.6920, 'lng': -17.4590, 'type': 'quartier'},
      {'name': 'Liberté', 'address': 'Liberté, Dakar, Sénégal', 'lat': 14.7000, 'lng': -17.4583, 'type': 'quartier'},
      {'name': 'Liberté 1', 'address': 'Liberté 1, Dakar, Sénégal', 'lat': 14.7010, 'lng': -17.4590, 'type': 'quartier'},
      {'name': 'Liberté 2', 'address': 'Liberté 2, Dakar, Sénégal', 'lat': 14.7020, 'lng': -17.4600, 'type': 'quartier'},
      {'name': 'Liberté 3', 'address': 'Liberté 3, Dakar, Sénégal', 'lat': 14.7030, 'lng': -17.4610, 'type': 'quartier'},
      {'name': 'Liberté 4', 'address': 'Liberté 4, Dakar, Sénégal', 'lat': 14.7040, 'lng': -17.4620, 'type': 'quartier'},
      {'name': 'Liberté 5', 'address': 'Liberté 5, Dakar, Sénégal', 'lat': 14.7050, 'lng': -17.4630, 'type': 'quartier'},
      {'name': 'Liberté 6', 'address': 'Liberté 6, Dakar, Sénégal', 'lat': 14.7060, 'lng': -17.4640, 'type': 'quartier'},
      {'name': 'Dieuppeul', 'address': 'Dieuppeul, Dakar, Sénégal', 'lat': 14.7250, 'lng': -17.4750, 'type': 'quartier'},
      {'name': 'Derklé', 'address': 'Derklé, Dakar, Sénégal', 'lat': 14.7280, 'lng': -17.4780, 'type': 'quartier'},
      {'name': 'Sicap Baobabs', 'address': 'Sicap Baobabs, Dakar, Sénégal', 'lat': 14.7100, 'lng': -17.4550, 'type': 'quartier'},
      {'name': 'Sicap Foire', 'address': 'Sicap Foire, Dakar, Sénégal', 'lat': 14.7150, 'lng': -17.4600, 'type': 'quartier'},
      {'name': 'Sicap Liberté', 'address': 'Sicap Liberté, Dakar, Sénégal', 'lat': 14.7080, 'lng': -17.4580, 'type': 'quartier'},
      {'name': 'Amitié', 'address': 'Amitié, Dakar, Sénégal', 'lat': 14.7200, 'lng': -17.4650, 'type': 'quartier'},
      {'name': 'Cité Keur Gorgui', 'address': 'Cité Keur Gorgui, Dakar, Sénégal', 'lat': 14.7150, 'lng': -17.4700, 'type': 'quartier'},
      
      // Pikine et ses zones
      {'name': 'Pikine', 'address': 'Pikine, Dakar, Sénégal', 'lat': 14.7500, 'lng': -17.3833, 'type': 'ville'},
      {'name': 'Pikine Ancien', 'address': 'Pikine Ancien, Dakar, Sénégal', 'lat': 14.7520, 'lng': -17.3850, 'type': 'quartier'},
      {'name': 'Pikine Icotaf', 'address': 'Pikine Icotaf, Dakar, Sénégal', 'lat': 14.7480, 'lng': -17.3820, 'type': 'quartier'},
      {'name': 'Pikine Tally Bou Bess', 'address': 'Tally Bou Bess, Pikine, Sénégal', 'lat': 14.7550, 'lng': -17.3900, 'type': 'quartier'},
      {'name': 'Pikine Guinaw Rail', 'address': 'Guinaw Rail, Pikine, Sénégal', 'lat': 14.7600, 'lng': -17.3950, 'type': 'quartier'},
      
      // Centres commerciaux et lieux populaires
      {'name': 'Sea Plaza', 'address': 'Sea Plaza, Almadies, Dakar', 'lat': 14.7167, 'lng': -17.4750, 'type': 'centre'},
      {'name': 'Magic Land', 'address': 'Magic Land, Almadies, Dakar', 'lat': 14.7333, 'lng': -17.5000, 'type': 'centre'},
      {'name': 'Dakar Almadies', 'address': 'Centre Commercial Dakar Almadies', 'lat': 14.7400, 'lng': -17.5100, 'type': 'centre'},
      
      // Autres quartiers importants
      {'name': 'Médina', 'address': 'Médina, Dakar, Sénégal', 'lat': 14.6833, 'lng': -17.4500, 'type': 'quartier'},
      {'name': 'Plateau', 'address': 'Plateau, Dakar, Sénégal', 'lat': 14.6697, 'lng': -17.4389, 'type': 'quartier'},
      {'name': 'Grand Dakar', 'address': 'Grand Dakar, Dakar, Sénégal', 'lat': 14.6833, 'lng': -17.4667, 'type': 'quartier'},
      {'name': 'HLM', 'address': 'HLM Grand Yoff, Dakar, Sénégal', 'lat': 14.7000, 'lng': -17.4500, 'type': 'quartier'},
      {'name': 'Parcelles Assainies', 'address': 'Parcelles Assainies, Dakar, Sénégal', 'lat': 14.7667, 'lng': -17.4167, 'type': 'quartier'},
      {'name': 'Guédiawaye', 'address': 'Guédiawaye, Dakar, Sénégal', 'lat': 14.7833, 'lng': -17.3833, 'type': 'ville'},
      {'name': 'Rufisque', 'address': 'Rufisque, Dakar, Sénégal', 'lat': 14.7167, 'lng': -17.2667, 'type': 'ville'},
      {'name': 'Thiaroye', 'address': 'Thiaroye, Dakar, Sénégal', 'lat': 14.7333, 'lng': -17.3500, 'type': 'quartier'},
      {'name': 'Keur Massar', 'address': 'Keur Massar, Dakar, Sénégal', 'lat': 14.7833, 'lng': -17.3167, 'type': 'ville'},
      {'name': 'Diamniadio', 'address': 'Diamniadio, Dakar, Sénégal', 'lat': 14.7000, 'lng': -17.1833, 'type': 'ville'},
      {'name': 'Colobane', 'address': 'Colobane, Dakar, Sénégal', 'lat': 14.6917, 'lng': -17.4500, 'type': 'quartier'},
      
      // Lieux touristiques et monuments
      {'name': 'Gorée', 'address': 'Île de Gorée, Dakar, Sénégal', 'lat': 14.6667, 'lng': -17.4000, 'type': 'ile'},
      {'name': 'Monument de la Renaissance', 'address': 'Monument de la Renaissance Africaine, Dakar', 'lat': 14.7167, 'lng': -17.4417, 'type': 'monument'},
      {'name': 'Place de l\'Indépendance', 'address': 'Place de l\'Indépendance, Plateau, Dakar', 'lat': 14.6697, 'lng': -17.4389, 'type': 'place'},
      
      // Marchés
      {'name': 'Sandaga', 'address': 'Marché Sandaga, Dakar, Sénégal', 'lat': 14.6667, 'lng': -17.4333, 'type': 'marche'},
      {'name': 'Marché Kermel', 'address': 'Marché Kermel, Plateau, Dakar', 'lat': 14.6697, 'lng': -17.4400, 'type': 'marche'},
      {'name': 'Marché HLM', 'address': 'Marché HLM, Dakar, Sénégal', 'lat': 14.7020, 'lng': -17.4520, 'type': 'marche'},
      
      // Aéroports
      {'name': 'Aéroport AIBD', 'address': 'Aéroport Blaise Diagne, Diass, Sénégal', 'lat': 14.6700, 'lng': -17.0728, 'type': 'aeroport'},
      {'name': 'Aéroport LSS', 'address': 'Aéroport Léopold Sédar Senghor, Yoff', 'lat': 14.7397, 'lng': -17.4902, 'type': 'aeroport'},
      
      // Autres
      {'name': 'Corniche', 'address': 'Corniche Ouest, Dakar, Sénégal', 'lat': 14.6833, 'lng': -17.4667, 'type': 'route'},
      {'name': 'VDN', 'address': 'Voie de Dégagement Nord, Dakar', 'lat': 14.7200, 'lng': -17.4600, 'type': 'route'},
    ];
    
    // Filtrage intelligent avec scoring de pertinence
    final scoredPlaces = <Map<String, dynamic>>[];
    
    for (final place in localPlaces) {
      final name = (place['name'] as String).toLowerCase();
      final address = (place['address'] as String).toLowerCase();
      int score = 0;
      
      // Score basé sur la correspondance
      if (name == query) {
        score = 1000; // Match exact parfait
      } else if (name.startsWith(query)) {
        score = 500 + (100 - query.length); // Commence par (plus court = mieux)
      } else if (name.contains(' $query')) {
        score = 300; // Commence un mot dans le nom
      } else if (name.contains(query)) {
        score = 200; // Contient quelque part
      } else if (address.contains(query)) {
        score = 100; // Dans l'adresse
      } else {
        // Match partiel des caractères
        int matchCount = 0;
        for (int i = 0; i < query.length && i < name.length; i++) {
          if (query[i] == name[i]) matchCount++;
        }
        if (matchCount > 0) {
          score = matchCount * 10;
        }
      }
      
      if (score > 0) {
        scoredPlaces.add({
          'place': place,
          'score': score,
        });
      }
    }
    
    // Trier par score décroissant
    scoredPlaces.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    
    // Limiter à 10 résultats les plus pertinents
    final filtered = scoredPlaces.take(10).map((sp) => sp['place'] as Map<String, dynamic>).toList();
    
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

