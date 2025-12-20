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
      // Quartiers résidentiels
      {'name': 'Almadies', 'address': 'Almadies, Dakar, Sénégal', 'lat': 14.7467, 'lng': -17.5167, 'type': 'quartier'},
      {'name': 'Almadies Zone 1', 'address': 'Almadies Zone 1, Dakar, Sénégal', 'lat': 14.7450, 'lng': -17.5150, 'type': 'quartier'},
      {'name': 'Almadies Zone 2', 'address': 'Almadies Zone 2, Dakar, Sénégal', 'lat': 14.7480, 'lng': -17.5180, 'type': 'quartier'},
      {'name': 'Ngor', 'address': 'Ngor, Dakar, Sénégal', 'lat': 14.7500, 'lng': -17.5167, 'type': 'quartier'},
      {'name': 'Ouakam', 'address': 'Ouakam, Dakar, Sénégal', 'lat': 14.7167, 'lng': -17.4833, 'type': 'quartier'},
      {'name': 'Yoff', 'address': 'Yoff, Dakar, Sénégal', 'lat': 14.7667, 'lng': -17.4667, 'type': 'quartier'},
      {'name': 'Mamelles', 'address': 'Mamelles, Dakar, Sénégal', 'lat': 14.7333, 'lng': -17.5000, 'type': 'quartier'},
      {'name': 'Mermoz', 'address': 'Mermoz, Dakar, Sénégal', 'lat': 14.7083, 'lng': -17.4667, 'type': 'quartier'},
      {'name': 'Sacré-Cœur', 'address': 'Sacré-Cœur, Dakar, Sénégal', 'lat': 14.7167, 'lng': -17.4667, 'type': 'quartier'},
      {'name': 'Point E', 'address': 'Point E, Dakar, Sénégal', 'lat': 14.6917, 'lng': -17.4667, 'type': 'quartier'},
      {'name': 'Fann', 'address': 'Fann, Dakar, Sénégal', 'lat': 14.6917, 'lng': -17.4583, 'type': 'quartier'},
      {'name': 'Liberté', 'address': 'Liberté 1, 2, 3, 4, 5, 6, Dakar, Sénégal', 'lat': 14.7000, 'lng': -17.4583, 'type': 'quartier'},
      
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
    
    // Filtrage intelligent: commence par, contient, ou match partiel
    final filtered = localPlaces.where((place) {
      final name = (place['name'] as String).toLowerCase();
      final address = (place['address'] as String).toLowerCase();
      
      // Priorité 1: Commence par la requête
      if (name.startsWith(query)) return true;
      
      // Priorité 2: Contient la requête
      if (name.contains(query)) return true;
      
      // Priorité 3: L'adresse contient la requête
      if (address.contains(query)) return true;
      
      // Priorité 4: Match des 3 premiers caractères
      if (query.length >= 3 && name.length >= 3) {
        final namePrefix = name.substring(0, 3);
        final queryPrefix = query.substring(0, 3);
        if (namePrefix == queryPrefix) return true;
      }
      
      return false;
    }).toList();
    
    // Trier par pertinence: ceux qui commencent par la requête en premier
    filtered.sort((a, b) {
      final nameA = (a['name'] as String).toLowerCase();
      final nameB = (b['name'] as String).toLowerCase();
      
      final startsWithA = nameA.startsWith(query) ? 0 : 1;
      final startsWithB = nameB.startsWith(query) ? 0 : 1;
      
      if (startsWithA != startsWithB) return startsWithA - startsWithB;
      return nameA.compareTo(nameB);
    });
    
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

